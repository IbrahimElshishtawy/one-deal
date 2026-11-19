import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { HomeQueryDto } from './dto/home-query.dto';

const SECTION_SLUG_ALIASES: Record<string, string> = {
  'real-estate': 'real-estate',
  real_estate: 'real-estate',
  'home-appliances': 'home-appliances',
  home_appliances: 'home-appliances',
  'appliances-decor': 'home-appliances',
  appliances_decor: 'home-appliances',
  services: 'services',
  'services-engineering': 'services',
  services_engineering: 'services',
  'home-services': 'services',
  'building-materials': 'building-materials',
  building_materials: 'building-materials',
  'construction-electrical': 'building-materials',
  construction_electrical: 'building-materials',
  cars: 'cars',
  'cars-maintenance': 'cars',
  cars_maintenance: 'cars',
  fashion: 'fashion',
  'fashion-accessories': 'fashion',
  fashion_accessories: 'fashion',
};

@Injectable()
export class HomeService {
  static readonly SCHEMA_VERSION = '1.0';
  static readonly PRICE_FRESHNESS_TTL_SECONDS = 60;
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
    const homeVer = (await this.redis?.get<number>('home:feed:ver')) ?? 1;
    const cacheKey = `home:popular-categories:v${homeVer}`;
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
    const feedVer = (await this.redis?.get<number>('home:feed:ver')) ?? 0;
    const hash = crypto
      .createHash('sha1')
      .update(JSON.stringify(query))
      .digest('hex');
    const cacheKey = `home:feed:v${feedVer}:${hash}`;
    const cached = await this.redis?.get<any>(cacheKey);
    if (cached) return cached;

    const [categories, featured, latest, recommended] = await Promise.all([
      this.getPopularCategories(),
      this.getFeaturedListings({ ...query, limit: query.limit ?? 10 }),
      this.getLatestListings({ ...query, limit: query.limit ?? 12 }),
      this.getRecommendedListings({ ...query, limit: query.limit ?? 10 }),
    ]);

    const promotions = this.getSectionPromotions('main-hub');

    const payload = {
      schemaVersion: HomeService.SCHEMA_VERSION,
      generatedAt: new Date().toISOString(),
      priceFreshnessTtlSeconds: HomeService.PRICE_FRESHNESS_TTL_SECONDS,
      categories,
      featured,
      latest,
      recommended,
      promotions,
    };

    await this.redis?.set(cacheKey, payload, 30);
    return payload;
  }

  /**
   * Server-driven Section Home Feed for each of the 6 independent sections.
   * Returns section metadata, subcategories with counts, promotions, live previews,
   * featured/latest/recommended listings, verified providers, and DB-driven filterConfig.
   */
  async getSectionHome(rawSlug: string, query: HomeQueryDto) {
    const normalizedInput = rawSlug.trim().toLowerCase();
    const canonicalSlug =
      SECTION_SLUG_ALIASES[normalizedInput] ??
      normalizedInput.replace(/_/g, '-');

    const feedVer = (await this.redis?.get<number>('home:feed:ver')) ?? 0;
    const hash = crypto
      .createHash('sha1')
      .update(JSON.stringify({ canonicalSlug, ...query }))
      .digest('hex');
    const cacheKey = `home:section:v${feedVer}:${canonicalSlug}:${hash}`;
    const cached = await this.redis?.get<any>(cacheKey);
    if (cached) return cached;

    const rootCategory = await this.prisma.category.findFirst({
      where: { slug: canonicalSlug, isActive: true },
      include: {
        children: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
          include: {
            fields: {
              where: { isActive: true, isFilterable: true },
              orderBy: { sortOrder: 'asc' },
            },
          },
        },
        fields: {
          where: { isActive: true, isFilterable: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    if (!rootCategory) {
      throw new NotFoundException(`Section '${rawSlug}' not found`);
    }

    const allCategoryIds = [
      rootCategory.id,
      ...rootCategory.children.map((c) => c.id),
    ];

    const baseWhere = this.buildBaseWhere(query);
    baseWhere.categoryId = { in: allCategoryIds };

    const limit = query.limit ?? 12;
    const now = new Date();

    const [groupedCounts, featuredRows, latestRows, recommendedRows] =
      await Promise.all([
        this.prisma.listing.groupBy({
          by: ['categoryId'],
          where: { ...this.buildBaseWhere(query), categoryId: { in: allCategoryIds } },
          _count: { _all: true },
        }),
        this.prisma.listing.findMany({
          where: { ...baseWhere, promotedUntil: { gt: now } },
          take: Math.min(limit, 10),
          orderBy: [{ promotedUntil: 'desc' }, { refreshedAt: 'desc' }],
          include: this.listingInclude,
        }),
        this.prisma.listing.findMany({
          where: baseWhere,
          take: limit,
          orderBy: [{ refreshedAt: 'desc' }, { createdAt: 'desc' }],
          include: this.listingInclude,
        }),
        this.prisma.listing.findMany({
          where: baseWhere,
          take: Math.min(limit, 10),
          orderBy: [{ viewsCount: 'desc' }, { refreshedAt: 'desc' }],
          include: this.listingInclude,
        }),
      ]);

    const countByCatId = new Map<string, number>();
    for (const row of groupedCounts) {
      countByCatId.set(row.categoryId, row._count._all);
    }

    const subcategories = rootCategory.children.map((sub) => ({
      id: sub.id,
      parentId: sub.parentId,
      slug: sub.slug,
      nameAr: sub.nameAr,
      nameEn: sub.nameEn,
      iconUrl: sub.iconUrl,
      sortOrder: sub.sortOrder,
      listingsCount: countByCatId.get(sub.id) ?? 0,
    }));

    const totalListingsCount =
      (countByCatId.get(rootCategory.id) ?? 0) +
      subcategories.reduce((acc, s) => acc + s.listingsCount, 0);

    const featured = featuredRows.map((item) => this.mapListing(item, now));
    const latest = latestRows.map((item) => this.mapListing(item, now));
    const recommended = recommendedRows.map((item) =>
      this.mapListing(item, now),
    );

    // Live previews derived from real listings with images (for Real Estate & Cars)
    const livePreviewSource = featured.length > 0 ? featured : latest;
    const livePreviews =
      canonicalSlug === 'real-estate' || canonicalSlug === 'cars'
        ? livePreviewSource.slice(0, 8).map((item) => ({
            listingId: item.id,
            title: item.title,
            price: item.price,
            currency: item.currency,
            imageUrl: item.primaryImageUrl,
            mediaCount: Math.max(item.media.length, 1),
            sellerName: item.sellerName,
            isVerified: item.isVerified,
            createdAt: item.createdAt,
          }))
        : [];

    // Aggregate unique verified providers from real section listings
    const providerMap = new Map<string, any>();
    for (const row of [...featuredRows, ...recommendedRows, ...latestRows]) {
      const acc = row.account;
      if (acc && !providerMap.has(acc.id)) {
        providerMap.set(acc.id, {
          id: acc.id,
          displayName: acc.displayName,
          slug: acc.slug,
          accountType: acc.accountType,
          logoUrl: acc.logoUrl,
          isVerified: acc.verificationStatus === 'approved',
          specialtyAr: row.category?.nameAr ?? rootCategory.nameAr,
          specialtyEn: row.category?.nameEn ?? rootCategory.nameEn,
          listingsCount: 1,
        });
      } else if (acc && providerMap.has(acc.id)) {
        providerMap.get(acc.id).listingsCount += 1;
      }
      if (providerMap.size >= 8) break;
    }

    // Build server-driven Filter Configuration from DB CategoryField rows
    const fieldMap = new Map<string, any>();
    for (const f of [
      ...rootCategory.fields,
      ...rootCategory.children.flatMap((c) => c.fields),
    ]) {
      if (!fieldMap.has(f.fieldKey)) {
        const rules = (f.validationRules as Record<string, any>) || {};
        fieldMap.set(f.fieldKey, {
          key: f.fieldKey,
          labelAr: f.labelAr,
          labelEn: f.labelEn,
          type: f.fieldType,
          options: Array.isArray(rules.options) ? rules.options : [],
          sortOrder: f.sortOrder,
        });
      }
    }

    const filterConfig = {
      sectionSlug: canonicalSlug,
      supportsPriceRange: true,
      supportsLocation: true,
      supportsCondition:
        canonicalSlug === 'home-appliances' ||
        canonicalSlug === 'cars' ||
        canonicalSlug === 'fashion',
      supportsListingKind:
        canonicalSlug === 'real-estate' || canonicalSlug === 'cars',
      listingKindOptions:
        canonicalSlug === 'real-estate' || canonicalSlug === 'cars'
          ? [
              { value: 'sale', labelAr: 'للبيع', labelEn: 'For Sale' },
              { value: 'rent', labelAr: 'للإيجار', labelEn: 'For Rent' },
            ]
          : [],
      sortOptions: [
        { value: 'newest', labelAr: 'الأحدث', labelEn: 'Newest' },
        {
          value: 'price_asc',
          labelAr: 'السعر: الأقل للأعلى',
          labelEn: 'Price: Low to High',
        },
        {
          value: 'price_desc',
          labelAr: 'السعر: الأعلى للأقل',
          labelEn: 'Price: High to Low',
        },
      ],
      fields: Array.from(fieldMap.values()).sort(
        (a, b) => a.sortOrder - b.sortOrder,
      ),
    };

    const payload = {
      schemaVersion: HomeService.SCHEMA_VERSION,
      generatedAt: now.toISOString(),
      priceFreshnessTtlSeconds: HomeService.PRICE_FRESHNESS_TTL_SECONDS,
      section: {
        id: rootCategory.id,
        slug: rootCategory.slug,
        canonicalSlug,
        nameAr: rootCategory.nameAr,
        nameEn: rootCategory.nameEn,
        iconUrl: rootCategory.iconUrl,
        sortOrder: rootCategory.sortOrder,
        listingsCount: totalListingsCount,
        subcategories,
      },
      promotions: this.getSectionPromotions(canonicalSlug),
      livePreviews,
      featured,
      latest,
      recommended,
      providers: Array.from(providerMap.values()),
      filterConfig,
    };

    await this.redis?.set(cacheKey, payload, 30);
    return payload;
  }

  private getSectionPromotions(sectionSlug: string) {
    switch (sectionSlug) {
      case 'real-estate':
        return [
          {
            id: 'promo-re-1',
            badgeAr: 'عقارات مميزة',
            badgeEn: 'Featured Properties',
            titleAr: 'شقتك أو فيلتك بأفضل أنظمة تقسيط',
            titleEn: 'Apartments & Villas with Flexible Installments',
            subtitleAr: 'وحدات موثقة للبيع والإيجار من مطورين وملاك معتمدين',
            subtitleEn: 'Verified units for sale and rent across Egypt',
            ctaAr: 'تصفح العقارات',
            ctaEn: 'Browse Properties',
            categorySlug: 'real-estate',
            imageUrl:
              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
          },
        ];
      case 'home-appliances':
        return [
          {
            id: 'promo-app-1',
            badgeAr: 'عرض اليوم',
            badgeEn: 'Deal of the Day',
            titleAr: 'خصم يصل إلى 30% على الأجهزة الكهربائية',
            titleEn: 'Up to 30% Off Home Appliances',
            subtitleAr: 'أحدث الموديلات السمارت بضمان الوكيل وتوصيل سريع',
            subtitleEn: 'Latest smart models with official warranty & fast delivery',
            ctaAr: 'تسوق الآن',
            ctaEn: 'Shop Now',
            categorySlug: 'home-appliances',
            imageUrl:
              'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=1000&q=80',
          },
        ];
      case 'services':
        return [
          {
            id: 'promo-srv-1',
            badgeAr: 'خدمة فورية معتمدة',
            badgeEn: 'Verified Instant Service',
            titleAr: 'خصم 20% على صيانة وتأسيس السباكة والتكييف',
            titleEn: '20% Off AC, Plumbing & Engineering Services',
            subtitleAr: 'فنيين معتمدين وضمان شامل على كل أعمال الصيانة',
            subtitleEn: 'Certified technicians with full service warranty',
            ctaAr: 'احجز فني الآن',
            ctaEn: 'Book Technician',
            categorySlug: 'services',
            imageUrl:
              'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=1000&q=80',
          },
        ];
      case 'building-materials':
        return [
          {
            id: 'promo-bm-1',
            badgeAr: 'خصم كميات',
            badgeEn: 'Bulk Discount',
            titleAr: 'باقة تأسيس الكهرباء والسباكة ومواد البناء',
            titleEn: 'Bulk Construction & Electrical Packages',
            subtitleAr: 'خصم حتى 12% للطلبيات الكبيرة شامل الضمان وتوريد فوري',
            subtitleEn: 'Up to 12% off bulk orders with direct site delivery',
            ctaAr: 'احصل على العرض',
            ctaEn: 'Get Offer',
            categorySlug: 'building-materials',
            imageUrl:
              'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=1000&q=80',
          },
        ];
      case 'cars':
        return [
          {
            id: 'promo-cars-1',
            badgeAr: 'تقسيط مرن',
            badgeEn: 'Flexible Financing',
            titleAr: 'عربية أحلامك بسعر مفيش زيه',
            titleEn: 'Drive Your Dream Car Today',
            subtitleAr: 'أفضل السيارات المستعملة والجديدة مع أنظمة تقسيط مرنة',
            subtitleEn: 'New & certified pre-owned vehicles with easy installments',
            ctaAr: 'تصفح السيارات',
            ctaEn: 'Browse Cars',
            categorySlug: 'cars',
            imageUrl:
              'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=1000&q=80',
          },
        ];
      case 'fashion':
        return [
          {
            id: 'promo-fash-1',
            badgeAr: 'وصول حديث',
            badgeEn: 'New Arrivals',
            titleAr: 'تشكيلة الموسم الجديد وصلت!',
            titleEn: 'New Season Collection Has Arrived!',
            subtitleAr: 'أحدث صيحات الموضة والأناقة من أشهر الماركات',
            subtitleEn: 'Latest fashion trends, footwear, watches & accessories',
            ctaAr: 'تسوق التشكيلة',
            ctaEn: 'Shop Collection',
            categorySlug: 'fashion',
            imageUrl:
              'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1000&q=80',
          },
        ];
      default:
        return [
          {
            id: 'promo-building-materials',
            badgeAr: 'خامات التأسيس',
            badgeEn: 'Construction Essentials',
            titleAr: 'ابنِ بيتك على أساس متين',
            titleEn: 'Build Your Home on a Solid Foundation',
            subtitleAr: 'حديد، إسمنت، طوب وكافة مواد البناء بأعلى جودة',
            subtitleEn:
              'Steel, cement, bricks & building materials at best prices',
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
            subtitleAr:
              'شقق، فيلات، وأراضٍ للبيع والإيجار من مطورين وملاك معتمدين',
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
    }
  }
}
