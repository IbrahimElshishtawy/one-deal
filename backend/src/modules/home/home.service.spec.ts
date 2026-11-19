import { ConfigService } from '@nestjs/config';
import { HomeService } from './home.service';

describe('HomeService', () => {
  const createMockPrisma = () => ({
    category: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'cat-re',
          slug: 'real-estate',
          nameAr: 'عقارات',
          nameEn: 'Real Estate',
          children: [
            { id: 'sub-apt', slug: 'apartments-for-sale', nameAr: 'شقق للبيع', nameEn: 'Apartments' },
          ],
        },
      ]),
      findFirst: jest.fn().mockResolvedValue({
        id: 'cat-re',
        children: [{ id: 'sub-apt' }],
      }),
    },
    listing: {
      groupBy: jest.fn().mockResolvedValue([
        { categoryId: 'sub-apt', _count: { _all: 15 } },
      ]),
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'listing-1',
          title: 'شقة 180م التجمع الخامس',
          description: 'تشطيب الترا لوكس',
          price: 4500000,
          currency: 'EGP',
          listingKind: 'sale',
          isDemo: true,
          promotedUntil: new Date(Date.now() + 86400000),
          categoryId: 'sub-apt',
          category: { id: 'sub-apt', slug: 'apartments-for-sale', nameAr: 'شقق للبيع', nameEn: 'Apartments', parentId: 'cat-re' },
          media: [{ id: 'm1', mediaType: 'image', publicUrl: 'https://images.unsplash.com/photo-1', thumbnailUrl: 'https://images.unsplash.com/photo-1', sortOrder: 0 }],
          area: { nameAr: 'التجمع الخامس', city: { nameAr: 'القاهرة الجديدة', governorate: { nameAr: 'القاهرة' } } },
          account: { id: 'acc-1', displayName: 'الأهرام العقارية', slug: 'ahram', accountType: 'company', logoUrl: null, verificationStatus: 'approved' },
          attributes: { rooms: 3, baths: 2, area_sqm: 180 },
          viewsCount: 120,
          _count: { favorites: 4 },
          refreshedAt: new Date(),
          createdAt: new Date(),
        },
      ]),
    },
  });

  const createConfig = (overrides: Record<string, any> = {}) =>
    ({
      get: jest.fn((key: string, defaultVal?: any) =>
        key in overrides ? overrides[key] : defaultVal,
      ),
    }) as unknown as ConfigService;

  it('aggregates categories with counts, featured, latest, recommended, and promotions without N+1', async () => {
    const prisma = createMockPrisma();
    const service = new HomeService(prisma as any, createConfig({ NODE_ENV: 'development', ENABLE_DEMO_DATA: true }));

    const feed = await service.getHomeFeed({ limit: 6 });

    expect(feed.categories).toHaveLength(1);
    expect(feed.categories[0].listingsCount).toBe(15);
    expect(feed.featured).toHaveLength(1);
    expect(feed.featured[0].isFeatured).toBe(true);
    expect(feed.featured[0].favoritesCount).toBe(4);
    expect(feed.latest).toHaveLength(1);
    expect(feed.recommended).toHaveLength(1);
    expect(feed.promotions.length).toBeGreaterThanOrEqual(3);
  });

  it('enforces isDemo=false in production when ENABLE_DEMO_DATA is false', async () => {
    const prisma = createMockPrisma();
    const service = new HomeService(
      prisma as any,
      createConfig({ NODE_ENV: 'production', ENABLE_DEMO_DATA: false }),
    );

    await service.getLatestListings({ limit: 5 });

    expect(prisma.listing.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          publicationStatus: 'published',
          deletedAt: null,
          isDemo: false,
        }),
      }),
    );
  });

  it('returns server-driven section home feed with filterConfig, livePreviews, and providers', async () => {
    const prisma = createMockPrisma();
    prisma.category.findFirst = jest.fn().mockResolvedValue({
      id: 'cat-re',
      slug: 'real-estate',
      nameAr: 'عقارات',
      nameEn: 'Real Estate',
      iconUrl: 'home_work',
      sortOrder: 1,
      fields: [],
      children: [
        {
          id: 'sub-apt',
          parentId: 'cat-re',
          slug: 'apartments-for-sale',
          nameAr: 'شقق للبيع',
          nameEn: 'Apartments for Sale',
          iconUrl: 'apartment',
          sortOrder: 1,
          fields: [
            {
              fieldKey: 'rooms',
              labelAr: 'عدد الغرف',
              labelEn: 'Bedrooms',
              fieldType: 'number',
              validationRules: null,
              sortOrder: 1,
            },
          ],
        },
      ],
    });

    const service = new HomeService(
      prisma as any,
      createConfig({ NODE_ENV: 'development', ENABLE_DEMO_DATA: true }),
    );

    const section = await service.getSectionHome('real-estate', { limit: 6 });

    expect(section.schemaVersion).toBe('1.0');
    expect(section.priceFreshnessTtlSeconds).toBe(60);
    expect(section.section.canonicalSlug).toBe('real-estate');
    expect(section.section.subcategories).toHaveLength(1);
    expect(section.livePreviews).toHaveLength(1);
    expect(section.providers).toHaveLength(1);
    expect(section.filterConfig.supportsListingKind).toBe(true);
    expect(section.filterConfig.fields).toEqual(
      expect.arrayContaining([expect.objectContaining({ key: 'rooms' })]),
    );
  });
});
