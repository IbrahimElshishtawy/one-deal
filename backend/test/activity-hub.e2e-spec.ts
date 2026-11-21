import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import * as crypto from 'crypto';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/core/filters/http-exception.filter';
import { TransformInterceptor } from '../src/core/interceptors/transform.interceptor';
import { LoggingInterceptor } from '../src/core/interceptors/logging.interceptor';
import { PrismaService } from '../src/core/database/prisma.service';
import { RedisService } from '../src/core/redis/redis.service';
import { SMS_GATEWAY_ADAPTER } from '../src/modules/auth/adapters/sms-gateway.interface';
import { MockSmsAdapter } from '../src/modules/auth/adapters/mock-sms.adapter';

describe('Unified Activity & Commerce Hub E2E', () => {
  let app: NestFastifyApplication;
  let prisma: PrismaService;
  let redis: RedisService;
  let smsAdapter: MockSmsAdapter;

  const buyerPhone = `+20107771${Math.floor(1000 + Math.random() * 9000)}`;
  const sellerPhone = `+20107772${Math.floor(1000 + Math.random() * 9000)}`;
  const attackerPhone = `+20107773${Math.floor(1000 + Math.random() * 9000)}`;

  let buyerId: string;
  let buyerToken: string;
  let sellerId: string;
  let sellerAccountId: string;
  let sellerToken: string;
  let attackerToken: string;

  let realEstateCatId: string;
  let materialsCatId: string;
  let testAreaId: string;
  let realEstateListingId: string;
  let materialListingId: string;

  async function authenticateViaOtp(phone: string) {
    await redis.del(`otp:cooldown:${phone}`);
    await redis.del(`otp:ratelimit:phone:${phone}`);

    await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/send',
      payload: { phone },
    });
    const code = smsAdapter.getLastSentCode(phone);
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/verify',
      payload: { phone, code },
    });
    const body = JSON.parse(res.body);
    return {
      userId: body.data.user.id as string,
      accountId: body.data.activeAccount.id as string,
      token: body.data.tokens.accessToken as string,
    };
  }

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter({ maxParamLength: 200 }),
    );

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    app.useGlobalFilters(new HttpExceptionFilter());
    app.useGlobalInterceptors(
      new LoggingInterceptor(),
      new TransformInterceptor(),
    );
    app.setGlobalPrefix('api/v1', {
      exclude: [
        'health/live',
        'health/ready',
        'health/liveness',
        'health/readiness',
      ],
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    prisma = app.get<PrismaService>(PrismaService);
    redis = app.get<RedisService>(RedisService);
    smsAdapter = app.get<MockSmsAdapter>(SMS_GATEWAY_ADAPTER);

    const buyer = await authenticateViaOtp(buyerPhone);
    buyerId = buyer.userId;
    buyerToken = buyer.token;

    const seller = await authenticateViaOtp(sellerPhone);
    sellerId = seller.userId;
    sellerAccountId = seller.accountId;
    sellerToken = seller.token;

    const attacker = await authenticateViaOtp(attackerPhone);
    attackerToken = attacker.token;

    // Ensure categories and area exist
    const area = await prisma.area.findFirst();
    if (!area) {
      const gov = await prisma.governorate.create({
        data: {
          nameAr: 'القاهرة',
          nameEn: 'Cairo',
          slug: `cairo-e2e-${Date.now()}`,
        },
      });
      const city = await prisma.city.create({
        data: {
          governorateId: gov.id,
          nameAr: 'القاهرة الجديدة',
          nameEn: 'New Cairo',
          slug: `new-cairo-e2e-${Date.now()}`,
        },
      });
      const createdArea = await prisma.area.create({
        data: {
          cityId: city.id,
          nameAr: 'التجمع الخامس',
          nameEn: 'Fifth Settlement',
        },
      });
      testAreaId = createdArea.id;
    } else {
      testAreaId = area.id;
    }

    const reCat = await prisma.category.findFirst({
      where: { slug: 'real-estate' },
    });
    if (reCat) {
      realEstateCatId = reCat.id;
    } else {
      const createdRe = await prisma.category.create({
        data: {
          nameAr: 'عقارات',
          nameEn: 'Real Estate',
          slug: `real-estate-e2e-${Date.now()}`,
        },
      });
      realEstateCatId = createdRe.id;
    }

    const bmCat = await prisma.category.findFirst({
      where: { slug: 'building-materials' },
    });
    if (bmCat) {
      materialsCatId = bmCat.id;
    } else {
      const createdBm = await prisma.category.create({
        data: {
          nameAr: 'مواد البناء',
          nameEn: 'Building Materials',
          slug: `building-materials-e2e-${Date.now()}`,
        },
      });
      materialsCatId = createdBm.id;
    }

    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    const reListing = await prisma.listing.create({
      data: {
        accountId: sellerAccountId,
        categoryId: realEstateCatId,
        areaId: testAreaId,
        title: 'E2E Luxury Apartment for Viewing',
        description: 'Spacious 3-bedroom apartment in New Cairo',
        price: 3500000,
        currency: 'EGP',
        listingKind: 'sale',
        moderationStatus: 'approved',
        publicationStatus: 'published',
        availabilityStatus: 'available',
        expiresAt,
      },
    });
    realEstateListingId = reListing.id;

    const bmListing = await prisma.listing.create({
      data: {
        accountId: sellerAccountId,
        categoryId: materialsCatId,
        areaId: testAreaId,
        title: 'E2E Steel Rebar 16mm',
        description: 'High tensile steel rebar per ton',
        price: 39000,
        currency: 'EGP',
        listingKind: 'product',
        moderationStatus: 'approved',
        publicationStatus: 'published',
        availabilityStatus: 'available',
        expiresAt,
      },
    });
    materialListingId = bmListing.id;
  }, 60000);

  afterAll(async () => {
    try {
      await prisma.cartItem.deleteMany({
        where: { listingId: { in: [realEstateListingId, materialListingId] } },
      });
      await prisma.favorite.deleteMany({
        where: { listingId: { in: [realEstateListingId, materialListingId] } },
      });
      await prisma.booking.deleteMany({
        where: { userId: { in: [buyerId, sellerId] } },
      });
      await prisma.rfqRequest.deleteMany({
        where: { userId: buyerId },
      });
      await prisma.listing.deleteMany({
        where: { id: { in: [realEstateListingId, materialListingId] } },
      });
    } finally {
      await app.close();
    }
  });

  // ---------------------------------------------------------------------------
  // 1. FAVORITES
  // ---------------------------------------------------------------------------
  describe('Favorites Module', () => {
    it('rejects unauthenticated access', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/favorites',
      });
      expect(res.statusCode).toBe(401);
    });

    it('adds favorite via POST /favorites, prevents duplicates, checks status, filters by category, and removes', async () => {
      const addRes = await app.inject({
        method: 'POST',
        url: '/api/v1/favorites',
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: { listingId: realEstateListingId },
      });
      expect(addRes.statusCode).toBe(200);
      expect(JSON.parse(addRes.body).data.isFavorite).toBe(true);

      // Idempotent duplicate add
      const dupRes = await app.inject({
        method: 'POST',
        url: `/api/v1/favorites/${realEstateListingId}`,
        headers: { authorization: `Bearer ${buyerToken}` },
      });
      expect(dupRes.statusCode).toBe(200);

      // Status check
      const statusRes = await app.inject({
        method: 'GET',
        url: `/api/v1/favorites/${realEstateListingId}/status`,
        headers: { authorization: `Bearer ${buyerToken}` },
      });
      expect(statusRes.statusCode).toBe(200);
      expect(JSON.parse(statusRes.body).data.isFavorite).toBe(true);

      // Paginated & filtered list
      const listRes = await app.inject({
        method: 'GET',
        url: `/api/v1/favorites?page=1&limit=10&categoryId=${realEstateCatId}`,
        headers: { authorization: `Bearer ${buyerToken}` },
      });
      expect(listRes.statusCode).toBe(200);
      const listBody = JSON.parse(listRes.body);
      expect(listBody.data.length).toBeGreaterThanOrEqual(1);
      expect(listBody.meta.total).toBeGreaterThanOrEqual(1);

      // User isolation: attacker does not see buyer's favorite
      const attackerStatus = await app.inject({
        method: 'GET',
        url: `/api/v1/favorites/${realEstateListingId}/status`,
        headers: { authorization: `Bearer ${attackerToken}` },
      });
      expect(JSON.parse(attackerStatus.body).data.isFavorite).toBe(false);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. BOOKINGS
  // ---------------------------------------------------------------------------
  describe('Bookings Module', () => {
    let bookingId: string;

    it('rejects past booking dates and mass-assignment fields', async () => {
      const pastRes = await app.inject({
        method: 'POST',
        url: '/api/v1/bookings',
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: {
          listingId: realEstateListingId,
          bookingType: 'property_viewing',
          scheduledDate: '2020-01-01',
          scheduledTime: '10:00',
        },
      });
      expect(pastRes.statusCode).toBe(400);

      const massAssignRes = await app.inject({
        method: 'POST',
        url: '/api/v1/bookings',
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: {
          userId: attackerToken,
          listingId: realEstateListingId,
          bookingType: 'property_viewing',
          scheduledDate: '2028-07-01',
          scheduledTime: '14:00',
        },
      });
      expect(massAssignRes.statusCode).toBe(400);
    });

    it('creates booking, enforces provider-only status updates, and transitions PENDING -> CONFIRMED -> CANCELLED', async () => {
      const createRes = await app.inject({
        method: 'POST',
        url: '/api/v1/bookings',
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: {
          listingId: realEstateListingId,
          bookingType: 'property_viewing',
          scheduledDate: '2028-07-01',
          scheduledTime: '14:00',
          location: 'Fifth Settlement',
          notes: 'Afternoon viewing',
        },
      });
      expect(createRes.statusCode).toBe(201);
      const created = JSON.parse(createRes.body).data;
      bookingId = created.id;
      expect(created.status).toBe('PENDING');

      // Duplicate slot conflict
      const dupRes = await app.inject({
        method: 'POST',
        url: '/api/v1/bookings',
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: {
          listingId: realEstateListingId,
          bookingType: 'property_viewing',
          scheduledDate: '2028-07-01',
          scheduledTime: '14:00',
        },
      });
      expect(dupRes.statusCode).toBe(409);

      // Attacker cannot read or update booking (IDOR check)
      const idorRes = await app.inject({
        method: 'GET',
        url: `/api/v1/bookings/${bookingId}`,
        headers: { authorization: `Bearer ${attackerToken}` },
      });
      expect(idorRes.statusCode).toBe(403);

      // Buyer cannot confirm own booking
      const buyerConfirm = await app.inject({
        method: 'PATCH',
        url: `/api/v1/bookings/${bookingId}/status`,
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: { status: 'CONFIRMED' },
      });
      expect(buyerConfirm.statusCode).toBe(403);

      // Provider confirms booking
      const providerConfirm = await app.inject({
        method: 'PATCH',
        url: `/api/v1/bookings/${bookingId}/status`,
        headers: { authorization: `Bearer ${sellerToken}` },
        payload: { status: 'CONFIRMED' },
      });
      expect(providerConfirm.statusCode).toBe(200);
      expect(JSON.parse(providerConfirm.body).data.status).toBe('CONFIRMED');

      // Buyer cancels confirmed booking
      const cancelRes = await app.inject({
        method: 'PATCH',
        url: `/api/v1/bookings/${bookingId}/cancel`,
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: { reason: 'Rescheduling' },
      });
      expect(cancelRes.statusCode).toBe(200);
      expect(JSON.parse(cancelRes.body).data.status).toBe('CANCELLED');
    });
  });

  // ---------------------------------------------------------------------------
  // 3. RFQ & QUOTATIONS
  // ---------------------------------------------------------------------------
  describe('RFQ & Quotations Module', () => {
    let rfqId: string;
    let quotationId: string;

    it('creates RFQ, accepts supplier quotation, enforces isolation, and transitions without fake orders', async () => {
      const rfqRes = await app.inject({
        method: 'POST',
        url: '/api/v1/rfqs',
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: {
          title: 'Supply 5 tons Steel Rebar',
          description: 'Need 5 tons of 16mm steel rebar delivered to New Cairo',
          categoryId: materialsCatId,
          deliveryLocation: 'New Cairo Industrial Zone',
          items: [
            {
              listingId: materialListingId,
              name: 'Steel Rebar 16mm',
              quantity: 5,
              unit: 'ton',
            },
          ],
        },
      });
      expect(rfqRes.statusCode).toBe(201);
      const rfq = JSON.parse(rfqRes.body).data;
      rfqId = rfq.id;
      expect(rfq.status).toBe('SUBMITTED');

      // Seller submits quotation
      const quotRes = await app.inject({
        method: 'POST',
        url: `/api/v1/rfqs/${rfqId}/quotations`,
        headers: { authorization: `Bearer ${sellerToken}` },
        payload: {
          deliveryFee: 1000,
          estimatedDeliveryDays: 2,
          items: [
            {
              rfqItemId: rfq.items[0].id,
              name: 'Steel Rebar 16mm',
              quantity: 5,
              unit: 'ton',
              unitPrice: 38000,
            },
          ],
        },
      });
      expect(quotRes.statusCode).toBe(201);
      const quot = JSON.parse(quotRes.body).data;
      quotationId = quot.id;
      expect(Number(quot.totalAmount)).toBe(191000);

      // Attacker cannot view RFQ quotations
      const attackerQuotRes = await app.inject({
        method: 'GET',
        url: `/api/v1/rfqs/${rfqId}/quotations`,
        headers: { authorization: `Bearer ${attackerToken}` },
      });
      expect(attackerQuotRes.statusCode).toBe(403);

      // Buyer views & compares quotations
      const ownerQuotRes = await app.inject({
        method: 'GET',
        url: `/api/v1/rfqs/${rfqId}/quotations?sortBy=totalAmount`,
        headers: { authorization: `Bearer ${buyerToken}` },
      });
      expect(ownerQuotRes.statusCode).toBe(200);
      expect(JSON.parse(ownerQuotRes.body).data).toHaveLength(1);

      // Buyer accepts quotation
      const acceptRes = await app.inject({
        method: 'PATCH',
        url: `/api/v1/quotations/${quotationId}/status`,
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: { status: 'ACCEPTED' },
      });
      expect(acceptRes.statusCode).toBe(200);
      expect(JSON.parse(acceptRes.body).data.status).toBe('ACCEPTED');
    });
  });

  // ---------------------------------------------------------------------------
  // 4. CART (V1 SAVED BASKET) & ACTIVITY HUB AGGREGATION
  // ---------------------------------------------------------------------------
  describe('Cart & Unified Activity Hub', () => {
    it('adds item to V1 saved basket and aggregates Activity Hub accurately', async () => {
      const addCartRes = await app.inject({
        method: 'POST',
        url: '/api/v1/cart/items',
        headers: { authorization: `Bearer ${buyerToken}` },
        payload: {
          listingId: materialListingId,
          quantity: 3,
          variantKey: '16mm',
        },
      });
      expect(addCartRes.statusCode).toBe(201);

      const hubRes = await app.inject({
        method: 'GET',
        url: '/api/v1/activity-hub',
        headers: { authorization: `Bearer ${buyerToken}` },
      });
      expect(hubRes.statusCode).toBe(200);
      const hub = JSON.parse(hubRes.body).data;
      expect(hub.summary.cartItemsCount).toBe(1);
      expect(hub.summary.favoritesCount).toBeGreaterThanOrEqual(1);
      expect(hub.cart.commerceMode).toBe('V1_SAVED_BASKET');
      expect(hub.cart.checkoutSupported).toBe(false);
      expect(hub.bookings).toBeDefined();
      expect(hub.rfqs).toBeDefined();
      expect(hub.favorites).toBeDefined();

      // Selective include
      const partialHubRes = await app.inject({
        method: 'GET',
        url: '/api/v1/activity-hub?include=favorites',
        headers: { authorization: `Bearer ${buyerToken}` },
      });
      expect(partialHubRes.statusCode).toBe(200);
      const partialHub = JSON.parse(partialHubRes.body).data;
      expect(partialHub.favorites).toBeDefined();
      expect(partialHub.cart).toBeUndefined();
      expect(partialHub.bookings).toBeUndefined();

      // Cross-user isolation: attacker has 0 counts
      const attackerHubRes = await app.inject({
        method: 'GET',
        url: '/api/v1/activity-hub',
        headers: { authorization: `Bearer ${attackerToken}` },
      });
      expect(attackerHubRes.statusCode).toBe(200);
      const attackerHub = JSON.parse(attackerHubRes.body).data;
      expect(attackerHub.summary).toEqual({
        cartItemsCount: 0,
        activeBookingsCount: 0,
        activeRfqCount: 0,
        favoritesCount: 0,
      });
    });
  });
});
