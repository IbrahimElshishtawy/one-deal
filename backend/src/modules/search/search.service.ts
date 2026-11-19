import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { SearchQueryDto } from './dto/search-query.dto';
import {
  generateArabicSearchVariants,
  normalizeArabicText,
} from './arabic-normalizer';

@Injectable()
export class SearchService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Performs fuzzy full-text keyword search and parametric faceted filtering.
   * Supports dynamic category attributes, PostGIS spatial queries, and Egyptian dialect variants.
   */
  async searchListings(queryDto: SearchQueryDto) {
    const {
      q,
      categoryId,
      categorySlug,
      category_slug,
      governorateId,
      cityId,
      minPrice,
      maxPrice,
      condition,
      listingKind,
      featured,
      size,
      color,
      sort,
      sort_by,
      lat,
      latitude,
      lng,
      longitude,
      radiusKm,
      radius_km,
      rooms,
      baths,
      finishing,
      furnished,
      brand,
      make,
      model,
      year,
      transmission,
      fuelType,
      fuel_type,
      unitType,
      unit_type,
      attributes,
      isDemo,
      page = 1,
      limit = 20,
    } = queryDto;

    const skip = (page - 1) * limit;

    const where: any = {
      publicationStatus: 'published',
      deletedAt: null,
    };

    if (listingKind) {
      where.listingKind = listingKind;
    }

    if (featured === true) {
      where.promotedUntil = { gt: new Date() };
    }

    const isProd = process.env.NODE_ENV === 'production';
    const enableDemo = process.env.ENABLE_DEMO_DATA === 'true';

    if (isProd && !enableDemo) {
      where.isDemo = false;
    } else if (isDemo !== undefined) {
      where.isDemo = isDemo;
    }

    // Keyword search with normalized indexed column & capped Egyptian dialect expansion
    const searchTerm = (q || queryDto.query || '').trim();
    if (searchTerm.length > 0) {
      const normalizedQuery = normalizeArabicText(searchTerm);
      const variants = generateArabicSearchVariants(searchTerm).slice(0, 4);
      where.OR = [
        {
          searchNormalizedText: {
            contains: normalizedQuery,
            mode: 'insensitive',
          },
        },
      ];
      for (const v of variants) {
        where.OR.push({ title: { contains: v, mode: 'insensitive' } });
        where.OR.push({ description: { contains: v, mode: 'insensitive' } });
      }
    }

    // Category resolution with hierarchical subcategory inclusion
    const targetSlug = categorySlug || category_slug;
    if (targetSlug && !categoryId) {
      const hyphenSlug = targetSlug.toLowerCase().replace(/_/g, '-');
      const underscoreSlug = targetSlug.toLowerCase().replace(/-/g, '_');
      const category = await this.prisma.category.findFirst({
        where: {
          OR: [
            { slug: hyphenSlug },
            { slug: underscoreSlug },
            { slug: targetSlug },
          ],
        },
        include: { children: { select: { id: true } } },
      });

      if (category) {
        const categoryIds = [
          category.id,
          ...category.children.map((c) => c.id),
        ];
        where.categoryId = { in: categoryIds };
      }
    } else if (categoryId) {
      const category = await this.prisma.category.findUnique({
        where: { id: categoryId },
        include: { children: { select: { id: true } } },
      });
      if (category) {
        const categoryIds = [
          category.id,
          ...category.children.map((c) => c.id),
        ];
        where.categoryId = { in: categoryIds };
      } else {
        where.categoryId = categoryId;
      }
    }

    if (cityId) where.area = { cityId };
    if (governorateId) where.area = { city: { governorateId } };

    if (minPrice !== undefined || maxPrice !== undefined) {
      where.price = {};
      if (minPrice !== undefined) where.price.gte = minPrice;
      if (maxPrice !== undefined) where.price.lte = maxPrice;
    }

    // Dynamic Category Attribute Filters inside JSONB
    const andFilters: any[] = [];
    if (condition) {
      andFilters.push({
        attributes: { path: ['condition'], equals: condition },
      });
    }
    if (size) {
      andFilters.push({
        attributes: { path: ['size'], equals: size },
      });
    }
    if (color) {
      andFilters.push({
        attributes: { path: ['color'], equals: color },
      });
    }
    if (rooms !== undefined) {
      andFilters.push({
        attributes: { path: ['rooms'], equals: Number(rooms) },
      });
    }
    if (baths !== undefined) {
      andFilters.push({
        attributes: { path: ['baths'], equals: Number(baths) },
      });
    }
    if (finishing) {
      andFilters.push({
        attributes: { path: ['finishing'], equals: finishing },
      });
    }
    if (furnished !== undefined) {
      andFilters.push({
        attributes: { path: ['furnished'], equals: Boolean(furnished) },
      });
    }
    const brandVal = brand || make;
    if (brandVal) {
      andFilters.push({
        OR: [
          { attributes: { path: ['brand'], equals: brandVal } },
          { attributes: { path: ['make'], equals: brandVal } },
        ],
      });
    }
    if (model) {
      andFilters.push({ attributes: { path: ['model'], equals: model } });
    }
    if (year !== undefined) {
      andFilters.push({ attributes: { path: ['year'], equals: Number(year) } });
    }
    if (transmission) {
      andFilters.push({
        attributes: { path: ['transmission'], equals: transmission },
      });
    }
    const fuelVal = fuelType || fuel_type;
    if (fuelVal) {
      andFilters.push({ attributes: { path: ['fuel_type'], equals: fuelVal } });
    }
    const unitVal = unitType || unit_type;
    if (unitVal) {
      andFilters.push({ attributes: { path: ['unit_type'], equals: unitVal } });
    }
    if (attributes) {
      try {
        const parsed =
          typeof attributes === 'string' ? JSON.parse(attributes) : attributes;
        if (parsed && typeof parsed === 'object') {
          for (const [key, val] of Object.entries(parsed)) {
            if (val !== undefined && val !== null && val !== '') {
              andFilters.push({ attributes: { path: [key], equals: val } });
            }
          }
        }
      } catch {}
    }
    if (andFilters.length > 0) {
      where.AND = andFilters;
    }

    // Geographic spatial radius filtering via PostGIS
    const targetLat = lat ?? latitude;
    const targetLng = lng ?? longitude;
    const targetRadius = (radiusKm ?? radius_km ?? 25) * 1000;
    if (targetLat !== undefined && targetLng !== undefined) {
      try {
        const nearbyListings = await this.prisma.$queryRaw<
          Array<{ id: string }>
        >`
          SELECT id FROM listings
          WHERE publication_status = 'published'
            AND deleted_at IS NULL
            AND ST_DWithin(
              display_location,
              ST_SetSRID(ST_MakePoint(${targetLng}, ${targetLat}), 4326)::geography,
              ${targetRadius}
            )
          ORDER BY display_location <-> ST_SetSRID(ST_MakePoint(${targetLng}, ${targetLat}), 4326) ASC
          LIMIT 300;
        `;
        where.id = { in: nearbyListings.map((r) => r.id) };
      } catch {}
    }

    // Ordering logic
    const sortVal = sort || sort_by;
    let orderBy: any = [{ refreshedAt: 'desc' }];
    if (sortVal === 'price_asc') {
      orderBy = [{ price: 'asc' }, { refreshedAt: 'desc' }];
    } else if (sortVal === 'price_desc') {
      orderBy = [{ price: 'desc' }, { refreshedAt: 'desc' }];
    }

    const [total, items] = await Promise.all([
      this.prisma.listing.count({ where }),
      this.prisma.listing.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          category: {
            select: { id: true, slug: true, nameAr: true, nameEn: true },
          },
          media: {
            where: { mediaType: 'image' },
            orderBy: { sortOrder: 'asc' },
            take: 5,
          },
          area: {
            include: {
              city: {
                include: { governorate: true },
              },
            },
          },
          account: {
            select: {
              id: true,
              displayName: true,
              accountType: true,
              logoUrl: true,
              verificationStatus: true,
            },
          },
        },
      }),
    ]);

    return {
      data: items.map((item) => ({
        id: item.id,
        title: item.title,
        description: item.description,
        price: Number(item.price),
        currency: item.currency || 'EGP',
        listingKind: item.listingKind,
        category: item.category,
        governorateName: item.area?.city?.governorate?.nameAr ?? '',
        cityName: item.area?.city?.nameAr ?? '',
        areaName: item.area?.nameAr ?? '',
        location: item.area?.city
          ? `${item.area.city.nameAr}، ${item.area.city.governorate.nameAr}`
          : '',
        primaryImageUrl: item.media?.[0]?.publicUrl ?? null,
        imageUrl: item.media?.[0]?.publicUrl ?? null,
        media: item.media ?? [],
        attributes: (item.attributes as any) || {},
        account: item.account
          ? {
              id: item.account.id,
              displayName: item.account.displayName,
              accountType: item.account.accountType,
              logoUrl: item.account.logoUrl,
              verificationStatus: item.account.verificationStatus,
            }
          : null,
        sellerName: item.account?.displayName ?? '',
        sellerPhone: null,
        sellerType: item.account?.accountType ?? 'individual',
        isVerified: item.account?.verificationStatus === 'approved',
        isDemo: item.isDemo,
        refreshedAt: item.refreshedAt,
        createdAt: item.createdAt,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        query: q || '',
      },
    };
  }
}
