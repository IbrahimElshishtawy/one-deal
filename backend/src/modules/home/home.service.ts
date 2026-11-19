import { Injectable, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { HomeQueryDto } from './dto/home-query.dto';

@Injectable()
export class HomeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  private buildBaseWhere(query: HomeQueryDto) {
    const where: any = {
      publicationStatus: 'published',
      deletedAt: null,
    };

    const isProd =
      this.configService.get<string>('NODE_ENV', 'development') ===
      'production';
    const enableDemo =
      this.configService.get<boolean>('ENABLE_DEMO_DATA', false) === true;

    if (isProd && !enableDemo) {
      where.isDemo = false;
    }

    if (query.cityId) {
      where.area = { cityId: query.cityId };
    } else if (query.governorateId) {
      where.area = { city: { governorateId: query.governorateId } };
    }

    return where;
  }

  private async applyCategoryFilter(where: any, categorySlug?: string) {
    if (!categorySlug) return;
    const hyphenSlug = categorySlug.toLowerCase().replace(/_/g, '-');
    const underscoreSlug = categorySlug.toLowerCase().replace(/-/g, '_');
    const category = await this.prisma.category.findFirst({
      where: {
        OR: [
          { slug: hyphenSlug },
          { slug: underscoreSlug },
          { slug: categorySlug },
        ],
      },
      include: { children: { select: { id: true } } },
    });

    if (category) {
      where.categoryId = {
        in: [category.id, ...category.children.map((c) => c.id)],
      };
    }
  }

  private readonly listingInclude = {
    category: {
      select: {
        id: true,
        slug: true,
        nameAr: true,
        nameEn: true,
        parentId: true,
      },
    },
    media: {
      where: { mediaType: 'image' },
      orderBy: { sortOrder: 'asc' as const },
      take: 3,
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
        slug: true,
        accountType: true,
        logoUrl: true,
        verificationStatus: true,
      },
    },
    _count: {
      select: { favorites: true },
    },
  };

  private mapListing(item: any, now: Date) {
    const attrs = (item.attributes as any) || {};
    return {
      id: item.id,
      title: item.title,
      description: item.description,
      price: Number(item.price),
      currency: item.currency || 'EGP',
      condition: attrs.condition || 'USED',
      listingKind: item.listingKind,
      isDemo: item.isDemo,
      isFeatured: Boolean(item.promotedUntil && item.promotedUntil > now),
      categoryId: item.categoryId,
      category: item.category,
      governorateName: item.area?.city?.governorate?.nameAr ?? '',
      cityName: item.area?.city?.nameAr ?? '',
      areaName: item.area?.nameAr ?? '',
      location: item.area?.city
        ? `${item.area.city.nameAr}، ${item.area.city.governorate?.nameAr ?? ''}`
        : '',
      primaryImageUrl: item.media?.[0]?.publicUrl ?? null,
      imageUrl: item.media?.[0]?.publicUrl ?? null,
      thumbnail:
        item.media?.[0]?.thumbnailUrl ?? item.media?.[0]?.publicUrl ?? null,
      media: item.media || [],
      attributes: attrs,
      viewsCount: item.viewsCount,
      favoritesCount: item._count?.favorites ?? 0,
      sellerName: item.account?.displayName ?? '',
      sellerType: item.account?.accountType ?? 'individual',
      isVerified: item.account?.verificationStatus === 'approved',
      refreshedAt: item.refreshedAt,
      createdAt: item.createdAt,
    };
  }

  /**
   * Returns active root categories with subcategories and aggregated live listing counts (no N+1).
   */
  async getPopularCategories() {
    const cacheKey = 'home:popular-categories';
    const cached = await this.redis?.get<any[]>(cacheKey);
    if (cached) return cached;

    const isProd =
      this.configService.get<string>('NODE_ENV', 'development') ===
      'production';
    const enableDemo =
      this.configService.get<boolean>('ENABLE_DEMO_DATA', false) === true;

    const listingWhere: any = {
      publicationStatus: 'published',
      deletedAt: null,
    };
    if (isProd && !enableDemo) {
      listingWhere.isDemo = false;
    }

    const [rootCategories, groupedCounts] = await Promise.all([
      this.prisma.category.findMany({
        where: { parentId: null, isActive: true },
        orderBy: { sortOrder: 'asc' },
        include: {
          children: {
            where: { isActive: true },
            orderBy: { sortOrder: 'asc' },
          },
        },
      }),
      this.prisma.listing.groupBy({
        by: ['categoryId'],
        where: listingWhere,
        _count: { _all: true },
      }),
    ]);

    const countByCatId = new Map<string, number>();
    for (const row of groupedCounts) {
      countByCatId.set(row.categoryId, row._count._all);
    }

    const result = rootCategories.map((root) => {
      const childrenWithCounts = root.children.map((sub) => ({
        ...sub,
        listingsCount: countByCatId.get(sub.id) ?? 0,
      }));
      const totalCount =
        (countByCatId.get(root.id) ?? 0) +
        childrenWithCounts.reduce((acc, s) => acc + s.listingsCount, 0);

      return {
        ...root,
        listingsCount: totalCount,
        children: childrenWithCounts,
      };
    });

    await this.redis?.set(cacheKey, result, 120);
    return result;
  }

  async getFeaturedListings(query: HomeQueryDto) {
    const limit = query.limit ?? 10;
    const now = new Date();
    const where = this.buildBaseWhere(query);
    where.promotedUntil = { gt: now };
    await this.applyCategoryFilter(where, query.categorySlug);

    const items = await this.prisma.listing.findMany({
      where,
      take: limit,
      orderBy: [{ promotedUntil: 'desc' }, { refreshedAt: 'desc' }],
      include: this.listingInclude,
    });

    return items.map((item) => this.mapListing(item, now));
  }

  async getLatestListings(query: HomeQueryDto) {
    const limit = query.limit ?? 12;
    const now = new Date();
    const where = this.buildBaseWhere(query);
    await this.applyCategoryFilter(where, query.categorySlug);

    const items = await this.prisma.listing.findMany({
      where,
      take: limit,
      orderBy: [{ refreshedAt: 'desc' }, { createdAt: 'desc' }],
      include: this.listingInclude,
    });

    return items.map((item) => this.mapListing(item, now));
  }

  async getRecommendedListings(query: HomeQueryDto) {
    const limit = query.limit ?? 10;
    const now = new Date();
    const where = this.buildBaseWhere(query);
    await this.applyCategoryFilter(where, query.categorySlug);

    const items = await this.prisma.listing.findMany({
      where,
      take: limit,
      orderBy: [{ viewsCount: 'desc' }, { refreshedAt: 'desc' }],
      include: this.listingInclude,
    });

    return items.map((item) => this.mapListing(item, now));
  }

  /**
   * Aggregated Home Feed endpoint — fetches all sections in parallel with short-TTL Redis caching.
   */
  async getHomeFeed(query: HomeQueryDto) {
    const hash = crypto
      .createHash('sha1')
      .update(JSON.stringify(query))
      .digest('hex');
    const cacheKey = `home:feed:${hash}`;
    const cached = await this.redis?.get<any>(cacheKey);
    if (cached) return cached;

    const [categories, featured, latest, recommended] = await Promise.all([
      this.getPopularCategories(),
      this.getFeaturedListings({ ...query, limit: query.limit ?? 10 }),
      this.getLatestListings({ ...query, limit: query.limit ?? 12 }),
      this.getRecommendedListings({ ...query, limit: query.limit ?? 10 }),
    ]);

    const promotions = [
      {
        id: 'promo-building-materials',
        badgeAr: 'خامات التأسيس',
        badgeEn: 'Construction Essentials',
        titleAr: 'ابنِ بيتك على أساس متين',
        titleEn: 'Build Your Home on a Solid Foundation',
        subtitleAr: 'حديد، إسمنت، طوب وكافة مواد البناء بأعلى جودة',
        subtitleEn: 'Steel, cement, bricks & building materials at best prices',
        ctaAr: 'تصفح المواد',
        ctaEn: 'Browse Materials',
        categorySlug: 'building-materials',
        imageUrl:
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=1000&q=80',
      },
      {
        id: 'promo-real-estate',
        badgeAr: 'عقارات مميزة',
        badgeEn: 'Featured Properties',
        titleAr: 'شقتك أو فيلتك في أرقى المناطق',
        titleEn: 'Find Your Dream Home Across Egypt',
        subtitleAr: 'شقق، فيلات، وأراضٍ للبيع والإيجار من مطورين وملاك معتمدين',
        subtitleEn: 'Apartments, villas & lands from verified sellers',
        ctaAr: 'استكشف العقارات',
        ctaEn: 'Explore Real Estate',
        categorySlug: 'real-estate',
        imageUrl:
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
      },
      {
        id: 'promo-cars',
        badgeAr: 'عروض السيارات',
        badgeEn: 'Top Car Deals',
        titleAr: 'عربية أحلامك بسعر مفيش زيه',
        titleEn: 'Your Next Car at Unbeatable Value',
        subtitleAr: 'سيارات زيرو ومستعملة بحالة ممتازة وقطع غيار أصلية',
        subtitleEn: 'Verified sedans, SUVs & genuine spare parts',
        ctaAr: 'تصفح السيارات',
        ctaEn: 'Browse Cars',
        categorySlug: 'cars',
        imageUrl:
          'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=1000&q=80',
      },
    ];

    const payload = {
      categories,
      featured,
      latest,
      recommended,
      promotions,
    };

    await this.redis?.set(cacheKey, payload, 30);
    return payload;
  }
}
