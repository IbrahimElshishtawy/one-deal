import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';
import * as crypto from 'crypto';

const BASE_URL = process.env.E2E_BASE_URL || 'http://localhost:3000/api/v1';
const TEST_RUN_ID = `run-${Date.now()}-${crypto.randomBytes(3).toString('hex')}`;

async function api(
  method: string,
  path: string,
  opts: { token?: string; body?: unknown } = {},
) {
  const headers: Record<string, string> = {};
  if (opts.body !== undefined) headers['Content-Type'] = 'application/json';
  if (opts.token) headers['Authorization'] = `Bearer ${opts.token}`;
  const start = performance.now();
  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
  const elapsedMs = performance.now() - start;
  const text = await res.text();
  let json: any = null;
  try {
    json = JSON.parse(text);
  } catch {
    json = text;
  }
  return { status: res.status, json, elapsedMs };
}

describe(`Deal One End-to-End Data Flow, Cache & Security Suite [${TEST_RUN_ID}]`, () => {
  const prisma = new PrismaClient();
  const redis = new Redis({ host: 'localhost', port: 6379, lazyConnect: true });

  let devGuestToken = '';
  let devGuestUserId = '';
  let devGuestAccountId = '';
  let otherUserToken = '';
  let createdCategoryId: string | null = null;
  let createdSubcategoryId: string | null = null;
  let createdListingId: string | null = null;
  let otherUserId: string | null = null;
  let otherAccountId: string | null = null;

  beforeAll(async () => {
    // Safety Guard: strictly refuse to run write tests against any non-local DB
    const dbUrl = new URL(process.env.DATABASE_URL || 'postgresql://localhost/test');
    if (
      process.env.NODE_ENV === 'production' ||
      !['localhost', '127.0.0.1'].includes(dbUrl.hostname)
    ) {
      throw new Error(
        `Refusing to run E2E write tests against non-local host: ${dbUrl.hostname}`,
      );
    }

    await prisma.$connect();
    await redis.connect();

    // Authenticate Development Guest via live API
    const authRes = await api('POST', '/auth/dev-guest', { body: {} });
    expect(authRes.status).toBe(200);
    devGuestToken = authRes.json.data.tokens.accessToken;
    devGuestUserId = authRes.json.data.user.id;
    devGuestAccountId = authRes.json.data.activeAccount.id;
  }, 30000);

  afterAll(async () => {
    // Clean ONLY records created during this TEST_RUN_ID
    if (createdListingId) {
      await prisma.favorite.deleteMany({ where: { listingId: createdListingId } });
      await prisma.listingMedia.deleteMany({ where: { listingId: createdListingId } });
      await prisma.listing.deleteMany({ where: { id: createdListingId } });
    }
    if (createdSubcategoryId) {
      await prisma.category.deleteMany({ where: { id: createdSubcategoryId } });
    }
    if (createdCategoryId) {
      await prisma.category.deleteMany({ where: { id: createdCategoryId } });
    }
    if (otherAccountId) {
      await prisma.accountMember.deleteMany({ where: { accountId: otherAccountId } });
      await prisma.account.deleteMany({ where: { id: otherAccountId } });
    }
    if (otherUserId) {
      await prisma.userSession.deleteMany({ where: { userId: otherUserId } });
      await prisma.user.deleteMany({ where: { id: otherUserId } });
    }
    await redis.quit();
    await prisma.$disconnect();
  });

  // =========================================================================
  // TEST 1: Category Data Flow
  // =========================================================================
  it('TEST 1 — Category & Subcategory Data Flow (DB -> Categories API -> Home Hub)', async () => {
    const rootSlug = `test-cat-${TEST_RUN_ID}`;
    const subSlug = `test-sub-${TEST_RUN_ID}`;

    const rootCat = await prisma.category.create({
      data: {
        slug: rootSlug,
        nameAr: `قسم اختبار ${TEST_RUN_ID}`,
        nameEn: `Test Category ${TEST_RUN_ID}`,
        sortOrder: 99,
        isActive: true,
      },
    });
    createdCategoryId = rootCat.id;

    const subCat = await prisma.category.create({
      data: {
        slug: subSlug,
        parentId: rootCat.id,
        nameAr: `قسم فرعي ${TEST_RUN_ID}`,
        nameEn: `Test Subcategory ${TEST_RUN_ID}`,
        sortOrder: 1,
        isActive: true,
      },
    });
    createdSubcategoryId = subCat.id;

    // Invalidate category tree & home cache to verify fresh DB read
    await redis.del('categories:tree');
    await redis.incr('home:feed:ver');

    const treeRes = await api('GET', '/categories');
    expect(treeRes.status).toBe(200);
    const foundRoot = treeRes.json.data.find((c: any) => c.slug === rootSlug);
    expect(foundRoot).toBeDefined();
    expect(foundRoot.children.some((s: any) => s.slug === subSlug)).toBe(true);

    const homeCatsRes = await api('GET', '/home/categories');
    expect(homeCatsRes.status).toBe(200);
    expect(homeCatsRes.json.data.some((c: any) => c.slug === rootSlug)).toBe(true);
  });

  // =========================================================================
  // TEST 2: Product Creation & Details Integrity Flow
  // =========================================================================
  it('TEST 2 — Product Creation Flow (DB -> Product Details API field-by-field parity)', async () => {
    const subCat = await prisma.category.findUnique({
      where: { slug: 'apartments-for-sale' },
    });
    const area = await prisma.area.findFirst({
      include: { city: { include: { governorate: true } } },
    });
    expect(subCat).toBeTruthy();
    expect(area).toBeTruthy();

    const title = `شقة اختبار تكامل ${TEST_RUN_ID}`;
    const listing = await prisma.listing.create({
      data: {
        accountId: devGuestAccountId,
        categoryId: subCat!.id,
        areaId: area!.id,
        title,
        description: `وصف كامل لاختبار دورة البيانات ${TEST_RUN_ID}`,
        searchNormalizedText: `شقة اختبار تكامل ${TEST_RUN_ID}`,
        price: 3750000,
        currency: 'EGP',
        listingKind: 'sale',
        moderationStatus: 'approved',
        publicationStatus: 'published',
        availabilityStatus: 'available',
        isDemo: true,
        promotedUntil: new Date(Date.now() + 7 * 86400000),
        attributes: {
          rooms: 3,
          baths: 2,
          area_sqm: 170,
          finishing: 'سوبر لوكس',
          condition: 'NEW',
          testRunId: TEST_RUN_ID,
        },
        expiresAt: new Date(Date.now() + 30 * 86400000),
      },
    });
    createdListingId = listing.id;

    await prisma.listingMedia.createMany({
      data: [0, 1, 2].map((i) => ({
        listingId: listing.id,
        mediaType: 'image',
        storageKey: `test/${TEST_RUN_ID}_${i}.jpg`,
        publicUrl: `https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80&v=${i}`,
        thumbnailUrl: `https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80&v=${i}`,
        sortOrder: i,
        isPrimary: i === 0,
        processingStatus: 'ready',
      })),
    });
    await redis.incr('listings:feed:ver');
    await redis.incr('home:feed:ver');

    const detailRes = await api('GET', `/listings/${listing.id}`);
    expect(detailRes.status).toBe(200);
    const d = detailRes.json.data;
    expect(d.id).toBe(listing.id);
    expect(d.title).toBe(title);
    expect(Number(d.price)).toBe(3750000);
    expect(d.category.slug).toBe('apartments-for-sale');
    expect(d.attributes.rooms).toBe(3);
    expect(d.attributes.area_sqm).toBe(170);
    expect(d.media).toHaveLength(3);
    expect(d.isFeatured).toBe(true);
    expect(d.sellerName).toBeTruthy();
  });

  // =========================================================================
  // TEST 3: Home Feed & 6-Section Isolation Flow
  // =========================================================================
  it('TEST 3 — Home Feed & Section Feeds (Zero cross-section leakage)', async () => {
    const mainHome = await api('GET', '/home?limit=6');
    expect(mainHome.status).toBe(200);
    expect(mainHome.json.data.categories.length).toBeGreaterThanOrEqual(6);
    expect(mainHome.json.data.featured.length).toBeGreaterThan(0);
    expect(mainHome.json.data.featured.every((x: any) => x.isFeatured === true)).toBe(true);
    expect(mainHome.json.data.latest.length).toBeGreaterThan(0);

    const sections = [
      'real-estate',
      'home-appliances',
      'services',
      'building-materials',
      'cars',
      'fashion',
    ];

    for (const slug of sections) {
      const rootCat = await prisma.category.findUnique({
        where: { slug },
        include: { children: { select: { id: true } } },
      });
      const validIds = new Set([rootCat!.id, ...rootCat!.children.map((c) => c.id)]);

      const feedRes = await api('GET', `/listings?categorySlug=${slug}&limit=10`);
      expect(feedRes.status).toBe(200);
      expect(feedRes.json.data.length).toBeGreaterThan(0);
      for (const item of feedRes.json.data) {
        expect(validIds.has(item.categoryId)).toBe(true);
      }
    }
  });

  // =========================================================================
  // TEST 4: Search Flow (Arabic, English, Partial, Special Chars, No Results)
  // =========================================================================
  it('TEST 4 — Search Flow (Arabic, English, Partial, Empty, Special chars, No results)', async () => {
    const arRes = await api('GET', `/search?q=${encodeURIComponent('شقة')}&limit=10`);
    expect(arRes.status).toBe(200);
    expect(arRes.json.data.length).toBeGreaterThan(0);

    const enRes = await api('GET', `/search?q=${encodeURIComponent('Casio')}&limit=10`);
    expect(enRes.status).toBe(200);
    expect(enRes.json.data.length).toBeGreaterThan(0);

    const partialRes = await api('GET', `/search?q=${encodeURIComponent('تويو')}&limit=10`);
    expect(partialRes.status).toBe(200);
    expect(partialRes.json.data.length).toBeGreaterThan(0);

    const emptyRes = await api('GET', '/search?limit=5');
    expect(emptyRes.status).toBe(200);
    expect(emptyRes.json.data.length).toBe(5);

    const noRes = await api('GET', `/search?q=${encodeURIComponent('xyz_nonexistent_999999')}`);
    expect(noRes.status).toBe(200);
    expect(noRes.json.data).toHaveLength(0);

    const sqliRes = await api('GET', `/search?q=${encodeURIComponent("'; DROP TABLE listings; --")}`);
    expect(sqliRes.status).toBe(200);
    expect(sqliRes.json.data).toHaveLength(0);
  });

  // =========================================================================
  // TEST 5: Multi-Category Dynamic Filter Flow
  // =========================================================================
  it('TEST 5 — Dynamic Filter Flow across Real Estate, Cars, Appliances & Fashion', async () => {
    // Real Estate: rooms=3 + listingKind=sale + price range
    const reRes = await api(
      'GET',
      '/search?categorySlug=real-estate&rooms=3&listingKind=sale&minPrice=1000000&maxPrice=8000000&limit=10',
    );
    expect(reRes.status).toBe(200);
    expect(reRes.json.data.length).toBeGreaterThan(0);
    for (const item of reRes.json.data) {
      expect(Number(item.price)).toBeGreaterThanOrEqual(1000000);
      expect(Number(item.price)).toBeLessThanOrEqual(8000000);
      expect(item.listingKind).toBe('sale');
      expect(item.attributes.rooms).toBe(3);
    }

    // Cars: transmission + price filter
    const carsRes = await api(
      'GET',
      `/search?categorySlug=cars&transmission=${encodeURIComponent('أوتوماتيك')}&minPrice=100000&limit=10`,
    );
    expect(carsRes.status).toBe(200);
    for (const item of carsRes.json.data) {
      expect(item.attributes.transmission).toBe('أوتوماتيك');
      expect(Number(item.price)).toBeGreaterThanOrEqual(100000);
    }

    // Appliances: condition=NEW
    const appRes = await api('GET', '/search?categorySlug=home-appliances&condition=NEW&limit=10');
    expect(appRes.status).toBe(200);
    expect(appRes.json.data.length).toBeGreaterThan(0);
    for (const item of appRes.json.data) {
      expect(item.attributes.condition).toBe('NEW');
    }
  });

  // =========================================================================
  // TEST 6: Sorting Flow
  // =========================================================================
  it('TEST 6 — Sorting Flow (price_asc, price_desc, newest, oldest, most_viewed, featured_first)', async () => {
    const asc = await api('GET', '/search?categorySlug=real-estate&sort=price_asc&limit=10');
    expect(asc.status).toBe(200);
    for (let i = 1; i < asc.json.data.length; i++) {
      expect(Number(asc.json.data[i].price)).toBeGreaterThanOrEqual(
        Number(asc.json.data[i - 1].price),
      );
    }

    const desc = await api('GET', '/search?categorySlug=real-estate&sort=price_desc&limit=10');
    expect(desc.status).toBe(200);
    for (let i = 1; i < desc.json.data.length; i++) {
      expect(Number(desc.json.data[i].price)).toBeLessThanOrEqual(
        Number(desc.json.data[i - 1].price),
      );
    }

    const viewed = await api('GET', '/search?sort=most_viewed&limit=10');
    expect(viewed.status).toBe(200);
    for (let i = 1; i < viewed.json.data.length; i++) {
      expect(viewed.json.data[i].viewsCount).toBeLessThanOrEqual(
        viewed.json.data[i - 1].viewsCount,
      );
    }

    const oldest = await api('GET', '/search?sort=oldest&limit=5');
    expect(oldest.status).toBe(200);
    expect(oldest.json.data.length).toBe(5);

    const featuredFirst = await api('GET', '/listings?sort=featured_first&limit=10');
    expect(featuredFirst.status).toBe(200);
    expect(featuredFirst.json.data[0].isFeatured).toBe(true);
  });

  // =========================================================================
  // TEST 7: Pagination Flow (No duplicates, empty page, invalid page)
  // =========================================================================
  it('TEST 7 — Pagination Flow (No duplicates across pages, empty page, invalid page)', async () => {
    const p1 = await api('GET', '/search?categorySlug=cars&sort=newest&page=1&limit=10');
    const p2 = await api('GET', '/search?categorySlug=cars&sort=newest&page=2&limit=10');
    expect(p1.status).toBe(200);
    expect(p2.status).toBe(200);

    const ids1 = new Set(p1.json.data.map((i: any) => i.id));
    const ids2 = new Set(p2.json.data.map((i: any) => i.id));
    for (const id of ids2) {
      expect(ids1.has(id)).toBe(false);
    }

    const emptyPage = await api('GET', '/search?categorySlug=cars&page=999&limit=10');
    expect(emptyPage.status).toBe(200);
    expect(emptyPage.json.data).toHaveLength(0);

    const invalidPage = await api('GET', '/search?page=-1&limit=10');
    expect(invalidPage.status).toBe(400);

    const abusiveLimit = await api('GET', '/search?limit=99999');
    expect(abusiveLimit.status).toBe(400);
  });

  // =========================================================================
  // TEST 8 & PHASE 5: Product Update Flow + Redis Cache Hit/Miss/Invalidation
  // =========================================================================
  it('TEST 8 & CACHE — Product Update Flow & Redis Cache Invalidation', async () => {
    expect(createdListingId).toBeTruthy();

    // 1. Warm Home & Feed caches (Cache Miss -> Cache Hit)
    const beforeVer = Number((await redis.get('home:feed:ver')) || '0');
    const missRes = await api('GET', `/home?limit=6`);
    expect(missRes.status).toBe(200);
    const hitRes = await api('GET', `/home?limit=6`);
    expect(hitRes.status).toBe(200);

    // 2. Update the test listing via authenticated PUT /listings/:id
    const updatedTitle = `شقة محدثة بالكامل ${TEST_RUN_ID}`;
    const updatedPrice = 4990000;
    const updRes = await api('PUT', `/listings/${createdListingId}`, {
      token: devGuestToken,
      body: {
        title: updatedTitle,
        price: updatedPrice,
        description: `وصف محدث بعد التعديل ${TEST_RUN_ID}`,
      },
    });
    expect(updRes.status).toBe(200);

    // 3. Verify Redis version bumped (invalidation occurred!)
    const afterVer = Number((await redis.get('home:feed:ver')) || '0');
    expect(afterVer).toBeGreaterThan(beforeVer);

    // 4. Verify Details API & Search API immediately reflect new values (NO stale cache)
    const detailAfter = await api('GET', `/listings/${createdListingId}`);
    expect(detailAfter.status).toBe(200);
    expect(detailAfter.json.data.title).toBe(updatedTitle);
    expect(Number(detailAfter.json.data.price)).toBe(updatedPrice);

    const searchAfter = await api('GET', `/search?q=${encodeURIComponent(TEST_RUN_ID)}`);
    expect(searchAfter.status).toBe(200);
    expect(searchAfter.json.data.some((x: any) => x.id === createdListingId && Number(x.price) === updatedPrice)).toBe(true);
  });

  // =========================================================================
  // PHASE 7: Security & Ownership Authorization Tests
  // =========================================================================
  it('PHASE 7 — Security (Unauthorized 401, Cross-Seller 403, Invalid ID, No Stack Trace)', async () => {
    // 1. Unauthorized create -> 401
    const unauth = await api('POST', '/listings', { body: { title: 'hack' } });
    expect(unauth.status).toBe(401);

    // 2. Invalid UUID -> clean error, no stack trace leaked
    const badId = await api('GET', '/listings/not-a-valid-uuid');
    expect(badId.status).toBeGreaterThanOrEqual(400);
    expect(JSON.stringify(badId.json)).not.toContain('PrismaClient');
    expect(JSON.stringify(badId.json)).not.toContain('at ');

    // 3. Cross-seller modification blocked (403 Forbidden)
    const otherListing = await prisma.listing.findFirst({
      where: { isDemo: true, accountId: { not: devGuestAccountId } },
    });
    expect(otherListing).toBeTruthy();

    const forbiddenUpd = await api('PUT', `/listings/${otherListing!.id}`, {
      token: devGuestToken,
      body: { title: 'Unauthorized Edit Attempt' },
    });
    expect(forbiddenUpd.status).toBe(403);

    const forbiddenDel = await api('DELETE', `/listings/${otherListing!.id}`, {
      token: devGuestToken,
    });
    expect(forbiddenDel.status).toBe(403);
  });

  // =========================================================================
  // TEST 9: Product Delete / Archive Flow + Cache Invalidation
  // =========================================================================
  it('TEST 9 — Product Archive/Delete Flow removes listing from Details, Feed & Search', async () => {
    expect(createdListingId).toBeTruthy();

    const delRes = await api('DELETE', `/listings/${createdListingId}`, {
      token: devGuestToken,
    });
    expect(delRes.status).toBe(200);

    const detailAfter = await api('GET', `/listings/${createdListingId}`);
    expect(detailAfter.status).toBe(404);

    const searchAfter = await api('GET', `/search?q=${encodeURIComponent(TEST_RUN_ID)}`);
    expect(searchAfter.status).toBe(200);
    expect(searchAfter.json.data.some((x: any) => x.id === createdListingId)).toBe(false);
  });

  // =========================================================================
  // TEST 10: Relationships Integrity Verification
  // =========================================================================
  it('TEST 10 — Database Referential Integrity (0 orphans, 0 missing images)', async () => {
    const [orphans]: any = await prisma.$queryRaw`
      SELECT
        (SELECT count(*)::int FROM listings l LEFT JOIN accounts a ON a.id = l.account_id WHERE a.id IS NULL) AS orphan_accounts,
        (SELECT count(*)::int FROM listings l LEFT JOIN categories c ON c.id = l.category_id WHERE c.id IS NULL) AS orphan_categories,
        (SELECT count(*)::int FROM listings l LEFT JOIN areas ar ON ar.id = l.area_id WHERE ar.id IS NULL) AS orphan_areas,
        (SELECT count(*)::int FROM listings l LEFT JOIN listing_media m ON m.listing_id = l.id WHERE l.is_demo = true AND l.deleted_at IS NULL AND m.id IS NULL) AS missing_media;
    `;
    expect(orphans.orphan_accounts).toBe(0);
    expect(orphans.orphan_categories).toBe(0);
    expect(orphans.orphan_areas).toBe(0);
    expect(orphans.missing_media).toBe(0);
  });
});
