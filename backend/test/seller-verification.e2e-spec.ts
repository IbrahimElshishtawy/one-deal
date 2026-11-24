import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import fastifyCookie from '@fastify/cookie';
import * as argon2 from 'argon2';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/core/filters/http-exception.filter';
import { TransformInterceptor } from '../src/core/interceptors/transform.interceptor';
import { PrismaService } from '../src/core/database/prisma.service';
import { RedisService } from '../src/core/redis/redis.service';
import {
  ISmsGatewayAdapter,
  SMS_GATEWAY_ADAPTER,
} from '../src/modules/auth/adapters/sms-gateway.interface';
import { MockSmsAdapter } from '../src/modules/auth/adapters/mock-sms.adapter';
import { ADMIN_PERMISSIONS } from '../src/modules/admin-auth/constants/admin-permissions.constant';
import { StaffSessionService } from '../src/modules/admin-auth/services/staff-session.service';

describe('Deal One — Buyer-to-Seller Account & Mandatory Verification System (E2E)', () => {
  let app: NestFastifyApplication;
  let prisma: PrismaService;
  let redis: RedisService;
  let smsAdapter: MockSmsAdapter;
  let staffSessionService: StaffSessionService;

  const suffix = String(Date.now()).slice(-6);
  const buyer1Phone = `0109${suffix}1`;
  const buyer2Phone = `0109${suffix}2`;
  const buyer3Phone = `0109${suffix}3`;
  const adminEmail = `seller-verif-admin-${suffix}@dealone.eg`;

  let buyer1Token = '';
  let buyer1Id = '';
  let buyer2Token = '';
  let buyer2Id = '';
  let buyer3Token = '';
  let buyer3Id = '';
  let adminToken = '';
  let adminStaffId = '';
  let adminRoleId = 0;

  let testCategoryId = '';
  let testCityId = 0;
  let seedPublicListingId = '';
  let seedSellerUserId = '';
  let seedSellerAccountId = '';

  let buyer1AppId = '';
  let buyer1Doc1Id = '';
  let buyer1ListingId = '';
  let buyer2AppId = '';

  const createdUserIds: string[] = [];

  async function registerViaOtp(phone: string, ipOctet = 10) {
    const normalized = `+20${phone.slice(1)}`;
    const testIp = `10.200.${Math.floor(Date.now() / 1000) % 250}.${ipOctet}`;
    await redis.del(`otp:cooldown:${normalized}`);
    await redis.del(`otp:ratelimit:phone:${normalized}`);

    const sendRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/send',
      remoteAddress: testIp,
      payload: { phone },
    });
    expect(sendRes.statusCode).toBe(200);
    const otpCode = smsAdapter.getLastSentCode(normalized);
    expect(otpCode).toBeDefined();

    const verifyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/verify',
      remoteAddress: testIp,
      payload: { phone, code: otpCode },
    });
    expect(verifyRes.statusCode).toBe(200);
    const body = verifyRes.json();
    createdUserIds.push(body.data.user.id);
    return body.data;
  }

  async function uploadRequiredIndividualDocs(token: string) {
    const docTypes = ['national_id_front', 'national_id_back'] as const;
    const docIds: string[] = [];
    for (const docType of docTypes) {
      const urlRes = await app.inject({
        method: 'POST',
        url: '/api/v1/seller-applications/me/documents/upload-url',
        headers: { authorization: `Bearer ${token}` },
        payload: {
          documentType: docType,
          fileName: `${docType}.jpg`,
          mimeType: 'image/jpeg',
          fileSizeBytes: 120000,
        },
      });
      expect(urlRes.statusCode).toBe(200);
      const target = urlRes.json().data;
      expect(target.storageKey).toMatch(/^private\/seller-verification\//);

      const confirmRes = await app.inject({
        method: 'POST',
        url: '/api/v1/seller-applications/me/documents',
        headers: { authorization: `Bearer ${token}` },
        payload: {
          documentType: docType,
          storageKey: target.storageKey,
          originalFileName: `${docType}.jpg`,
          mimeType: 'image/jpeg',
          fileSizeBytes: 120000,
        },
      });
      expect(confirmRes.statusCode).toBe(201);
      const doc = confirmRes.json().data;
      expect(doc.storageKey).toBeUndefined(); // Never expose raw private storage path
      docIds.push(doc.id);
    }
    return docIds;
  }

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter({ maxParamLength: 200 }),
    );
    await app.register(fastifyCookie);
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    app.useGlobalFilters(new HttpExceptionFilter());
    app.useGlobalInterceptors(new TransformInterceptor());
    app.setGlobalPrefix('api/v1', {
      exclude: ['health/live', 'health/ready'],
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    prisma = app.get(PrismaService);
    redis = app.get(RedisService);
    smsAdapter = app.get<ISmsGatewayAdapter>(
      SMS_GATEWAY_ADAPTER,
    ) as MockSmsAdapter;
    staffSessionService = app.get(StaffSessionService);

    // Ensure test category & city exist
    let category = await prisma.category.findFirst({
      where: { isActive: true },
      include: { fields: { where: { isActive: true, isRequired: true } } },
    });
    if (!category || category.fields.length > 0) {
      category = await prisma.category.create({
        data: {
          nameAr: `قسم اختبار ${suffix}`,
          nameEn: `Test Category ${suffix}`,
          slug: `test-seller-verif-${suffix}`,
          isActive: true,
        },
        include: { fields: { where: { isActive: true, isRequired: true } } },
      });
    }
    testCategoryId = category.id;

    const city = await prisma.city.findFirst({
      where: { isActive: true },
      include: { areas: true },
    });
    expect(city).toBeTruthy();
    testCityId = city!.id;
    let area = city!.areas[0];
    if (!area) {
      area = await prisma.area.create({
        data: {
          cityId: city!.id,
          nameAr: 'منطقة اختبار',
          nameEn: 'Test Area',
          isActive: true,
        },
      });
    }

    // Create a seed published listing owned by another approved seller (for buyer favorite/cart tests)
    const seedSeller = await prisma.user.create({
      data: {
        phone: `+20108${suffix}9`,
        fullName: 'Seed Approved Seller',
        isPhoneVerified: true,
        isActive: true,
        sellerStatus: 'APPROVED',
        sellerApprovedAt: new Date(),
      },
    });
    seedSellerUserId = seedSeller.id;
    createdUserIds.push(seedSellerUserId);

    const seedAccount = await prisma.account.create({
      data: {
        ownerUserId: seedSeller.id,
        accountType: 'store',
        displayName: 'Seed Store',
        slug: `seed-store-${suffix}`,
        verificationStatus: 'approved',
        isActive: true,
      },
    });
    seedSellerAccountId = seedAccount.id;
    await prisma.accountMember.create({
      data: { accountId: seedAccount.id, userId: seedSeller.id, role: 'owner' },
    });

    const seedListing = await prisma.listing.create({
      data: {
        accountId: seedAccount.id,
        categoryId: testCategoryId,
        areaId: area.id,
        title: 'Seed Public Listing For Buyer Tests',
        description: 'Available listing for testing buyer favorite and cart.',
        price: 1500,
        currency: 'EGP',
        listingKind: 'product',
        moderationStatus: 'approved',
        publicationStatus: 'published',
        availabilityStatus: 'available',
        expiresAt: new Date(Date.now() + 30 * 86400_000),
      },
    });
    seedPublicListingId = seedListing.id;

    // Create Admin StaffUser with verification permissions and issue dedicated Admin JWT
    const role = await prisma.staffRole.create({
      data: {
        name: `test_verif_admin_${suffix}`,
        description: 'E2E Test Verification Admin Role',
        isSystem: false,
        permissions: [...ADMIN_PERMISSIONS],
      },
    });
    adminRoleId = role.id;

    const staff = await prisma.staffUser.create({
      data: {
        email: adminEmail,
        passwordHash: await argon2.hash('AdminPass#12345'),
        fullName: 'E2E Verification Admin',
        roleId: role.id,
        status: 'active',
        isActive: true,
      },
    });
    adminStaffId = staff.id;

    const adminTokens = await staffSessionService.createSession(
      {
        id: staff.id,
        email: staff.email,
        roleId: staff.roleId,
        role: { name: role.name },
      },
      true,
      'jest-e2e',
      '127.0.0.1',
    );
    adminToken = adminTokens.accessToken;
  }, 45000);

  afterAll(async () => {
    try {
      if (createdUserIds.length > 0) {
        await prisma.cartItem.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.favorite.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.listing.deleteMany({
          where: { account: { ownerUserId: { in: createdUserIds } } },
        });
        await prisma.sellerApplicationHistory.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.sellerApplicationDocument.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.sellerApplication.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.accountMember.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.account.deleteMany({
          where: { ownerUserId: { in: createdUserIds } },
        });
        await prisma.userSession.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.user.deleteMany({
          where: { id: { in: createdUserIds } },
        });
      }
      if (adminStaffId) {
        await prisma.staffSession.deleteMany({
          where: { staffId: adminStaffId },
        });
        await prisma.staffUser.deleteMany({ where: { id: adminStaffId } });
      }
      if (adminRoleId) {
        await prisma.staffRole.deleteMany({ where: { id: adminRoleId } });
      }
    } finally {
      await app.close();
    }
  }, 30000);

  // =========================================================================
  // SCENARIO 1: New registration creates BUYER
  // =========================================================================
  it('1. New registration creates BUYER with sellerStatus=NOT_REQUESTED and no seller account', async () => {
    const reg1 = await registerViaOtp(buyer1Phone, 11);
    buyer1Token = reg1.tokens.accessToken;
    buyer1Id = reg1.user.id;

    expect(reg1.user.sellerStatus).toBe('NOT_REQUESTED');
    expect(reg1.user.roles).toEqual(['BUYER']);
    expect(reg1.user.canSell).toBe(false);
    expect(reg1.activeAccount).toBeNull();

    // Register buyer2 and buyer3 for rejection & unauthorized access tests
    const reg2 = await registerViaOtp(buyer2Phone, 12);
    buyer2Token = reg2.tokens.accessToken;
    buyer2Id = reg2.user.id;

    const reg3 = await registerViaOtp(buyer3Phone, 13);
    buyer3Token = reg3.tokens.accessToken;
    buyer3Id = reg3.user.id;
  });

  // =========================================================================
  // SCENARIO 2 & 21: Buyer requests seller conversion & duplicate prevention
  // =========================================================================
  it('2 & 21. Buyer can request seller conversion (DRAFT) and duplicate applications are prevented', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: {
        businessType: 'individual',
        businessName: 'Cairo Verified Seller',
        nationalIdNumber: '29501011234567',
        address: 'Nasr City, Cairo',
      },
    });
    expect(res.statusCode).toBe(201);
    const appData = res.json().data;
    expect(appData.status).toBe('DRAFT');
    buyer1AppId = appData.id;

    // Duplicate application must be rejected with 409
    const dupRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: { businessType: 'individual', businessName: 'Duplicate Shop' },
    });
    expect(dupRes.statusCode).toBe(409);
  });

  // =========================================================================
  // SCENARIO 20 (partial) & 3: Invalid transition (DRAFT -> APPROVED) & Submit -> PENDING
  // =========================================================================
  it('3 & 20. Cannot approve DRAFT directly; uploading required docs and submitting transitions to PENDING', async () => {
    // Admin trying to approve a DRAFT directly must fail (invalid transition)
    const badApprove = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: {},
    });
    expect(badApprove.statusCode).toBe(400);

    // Submitting without required documents must fail
    const incompleteSubmit = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(incompleteSubmit.statusCode).toBe(400);

    // Upload required documents
    const docIds = await uploadRequiredIndividualDocs(buyer1Token);
    buyer1Doc1Id = docIds[0];

    // Submit complete application -> PENDING
    const submitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(submitRes.statusCode).toBe(200);
    expect(submitRes.json().data.status).toBe('PENDING');
  });

  // =========================================================================
  // SCENARIOS 4, 5, 6, 7: Pending seller restrictions & status retrieval
  // =========================================================================
  it('4, 5, 6, 7. Pending seller cannot create/publish listings or access dashboard, but can retrieve status', async () => {
    // 4. Cannot create listing
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Unauthorized Pending Listing',
        description: 'Must be blocked because seller is PENDING.',
        price: 5000,
        mediaKeys: [`uploads/images/2026-11/${buyer1Id}/photo.jpg`],
      },
    });
    expect(createRes.statusCode).toBe(403);

    // 5. Cannot publish/submit listing
    const publishRes = await app.inject({
      method: 'PATCH',
      url: `/api/v1/listings/${seedPublicListingId}/status`,
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: { status: 'published' },
    });
    expect(publishRes.statusCode).toBe(403);

    // 6. Cannot access seller dashboard
    const dashRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/dashboard',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(dashRes.statusCode).toBe(403);

    // 7. Can retrieve own application status and history
    const statusRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/me',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(statusRes.statusCode).toBe(200);
    expect(statusRes.json().data.sellerStatus).toBe('PENDING');
    expect(statusRes.json().data.capabilities.canCreateListing).toBe(false);

    const histRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/me/history',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(histRes.statusCode).toBe(200);
    expect(histRes.json().data.items.length).toBeGreaterThanOrEqual(2);
  });

  // =========================================================================
  // SCENARIO 22: Unauthorized document access is rejected
  // =========================================================================
  it('22. Unauthorized document access by another user or non-admin is rejected', async () => {
    // Another buyer attempting to access buyer1's document
    const otherUserDocRes = await app.inject({
      method: 'GET',
      url: `/api/v1/seller-applications/me/documents/${buyer1Doc1Id}/access`,
      headers: { authorization: `Bearer ${buyer3Token}` },
    });
    expect(otherUserDocRes.statusCode).toBe(403);

    // Regular buyer attempting to call admin document endpoint
    const nonAdminDocRes = await app.inject({
      method: 'GET',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/documents/${buyer1Doc1Id}`,
      headers: { authorization: `Bearer ${buyer3Token}` },
    });
    expect(nonAdminDocRes.statusCode).toBe(403);

    // Owner CAN access own document
    const ownDocRes = await app.inject({
      method: 'GET',
      url: `/api/v1/seller-applications/me/documents/${buyer1Doc1Id}/access`,
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(ownDocRes.statusCode).toBe(200);
    expect(ownDocRes.json().data.accessUrl).toBeDefined();
  });

  // =========================================================================
  // SCENARIOS 8, 9, 10, 23: Admin review, unauthorized approval blocked,
  // complete approval + transactional consistency
  // =========================================================================
  it('8, 9, 10, 23. Admin reviews & approves application; unauthorized approval blocked; DB state is transactionally consistent', async () => {
    // 9. Unauthorized regular user cannot approve
    const unauthApprove = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/approve`,
      headers: { authorization: `Bearer ${buyer3Token}` },
      payload: {},
    });
    expect(unauthApprove.statusCode).toBe(403);

    // 8. Admin lists pending applications, inspects document, and places UNDER_REVIEW
    const listRes = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/seller-applications?status=PENDING',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(listRes.statusCode).toBe(200);
    expect(
      listRes.json().data.items.some((a: any) => a.id === buyer1AppId),
    ).toBe(true);

    const adminDocRes = await app.inject({
      method: 'GET',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/documents/${buyer1Doc1Id}`,
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(adminDocRes.statusCode).toBe(200);
    expect(adminDocRes.json().data.accessUrl).toBeDefined();

    const reviewRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/review`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Reviewing KYC documents' },
    });
    expect(reviewRes.statusCode).toBe(200);
    expect(reviewRes.json().data.status).toBe('UNDER_REVIEW');

    // 10. Admin approves complete application
    const approveRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'All documents verified' },
    });
    expect(approveRes.statusCode).toBe(200);
    expect(approveRes.json().data.application.status).toBe('APPROVED');

    // Duplicate approval must fail with 409
    const dupApprove = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: {},
    });
    expect(dupApprove.statusCode).toBe(409);

    // 23. Verify transactional consistency across User, Account, AccountMember, History, AuditLog
    const [dbUser, dbApp, dbHistory, dbAudits] = await Promise.all([
      prisma.user.findUnique({ where: { id: buyer1Id } }),
      prisma.sellerApplication.findUnique({ where: { id: buyer1AppId } }),
      prisma.sellerApplicationHistory.findMany({
        where: { applicationId: buyer1AppId },
      }),
      prisma.auditLog.findMany({
        where: {
          action: {
            in: ['SELLER_APPLICATION_APPROVED', 'SELLER_PERMISSIONS_GRANTED'],
          },
          targetId: { in: [buyer1AppId, buyer1Id] },
        },
      }),
    ]);

    expect(dbUser?.sellerStatus).toBe('APPROVED');
    expect(dbApp?.status).toBe('APPROVED');
    expect(dbApp?.accountId).toBeTruthy();
    expect(dbHistory.some((h) => h.newStatus === 'APPROVED')).toBe(true);
    expect(dbAudits.length).toBeGreaterThanOrEqual(2);
  });

  // =========================================================================
  // SCENARIOS 11, 12, 13, 14: Approved seller can create & manage listings,
  // access seller dashboard, AND still purchase & favorite as a buyer
  // =========================================================================
  it('11, 12, 13, 14. Approved seller can create/manage owned listings and retains all buyer capabilities', async () => {
    // Seller dashboard accessible
    const dashRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/dashboard',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(dashRes.statusCode).toBe(200);

    // 11. Create listing
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Approved Seller Verified Item',
        description: 'Created by an admin-approved seller.',
        price: 12000,
        mediaKeys: [`uploads/images/2026-11/${buyer1Id}/photo1.jpg`],
      },
    });
    expect(createRes.statusCode).toBe(201);
    buyer1ListingId = createRes.json().data.id;

    // 12. Manage owned listing (update + availability)
    const updateRes = await app.inject({
      method: 'PUT',
      url: `/api/v1/listings/${buyer1ListingId}`,
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: { title: 'Updated Approved Seller Item', price: 11500 },
    });
    expect(updateRes.statusCode).toBe(200);

    const availRes = await app.inject({
      method: 'PATCH',
      url: `/api/v1/listings/${buyer1ListingId}/availability`,
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: { availabilityStatus: 'reserved' },
    });
    expect(availRes.statusCode).toBe(200);

    // 13. Approved seller can still purchase (add to cart & view cart)
    const cartAddRes = await app.inject({
      method: 'POST',
      url: '/api/v1/cart/items',
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: { listingId: seedPublicListingId, quantity: 1 },
    });
    expect([200, 201]).toContain(cartAddRes.statusCode);

    // 14. Approved seller can still favorite
    const favRes = await app.inject({
      method: 'POST',
      url: '/api/v1/favorites',
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: { listingId: seedPublicListingId },
    });
    expect([200, 201]).toContain(favRes.statusCode);
  });

  // =========================================================================
  // SCENARIOS 15, 16, 20: Rejected seller cannot publish & can resubmit
  // =========================================================================
  it('15, 16, 20. Rejected seller cannot publish, cannot jump directly to APPROVED, and can resubmit', async () => {
    // Buyer2 creates draft, uploads docs, submits
    const createApp = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${buyer2Token}` },
      payload: {
        businessType: 'individual',
        businessName: 'Buyer2 Shop',
        nationalIdNumber: '29602021234567',
      },
    });
    expect(createApp.statusCode).toBe(201);
    buyer2AppId = createApp.json().data.id;

    await uploadRequiredIndividualDocs(buyer2Token);

    const submitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${buyer2Token}` },
    });
    expect(submitRes.statusCode).toBe(200);

    // Admin rejects with mandatory reason
    const rejectRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer2AppId}/reject`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { reason: 'ID photo is blurry, please upload a clear scan' },
    });
    expect(rejectRes.statusCode).toBe(200);
    expect(rejectRes.json().data.status).toBe('REJECTED');

    // 15. Rejected seller cannot create/publish listing
    const blockedListing = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${buyer2Token}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Rejected Seller Attempt',
        description: 'Must be blocked.',
        price: 500,
        mediaKeys: [`uploads/images/2026-11/${buyer2Id}/img.jpg`],
      },
    });
    expect(blockedListing.statusCode).toBe(403);

    // 20. Invalid transition: REJECTED -> APPROVED directly must be rejected
    const invalidApprove = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer2AppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: {},
    });
    expect(invalidApprove.statusCode).toBe(400);

    // 16. Rejected seller can resubmit according to policy
    const resubmitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/resubmit',
      headers: { authorization: `Bearer ${buyer2Token}` },
      payload: {
        businessName: 'Buyer2 Shop Updated',
        submitImmediately: true,
      },
    });
    expect(resubmitRes.statusCode).toBe(200);
    expect(resubmitRes.json().data.status).toBe('PENDING');
    expect(resubmitRes.json().data.resubmissionCount).toBe(1);
  });

  // =========================================================================
  // SCENARIOS 17, 18, 19: Suspended seller loses seller privileges,
  // retains buyer permissions, and existing seller/listing relationships remain valid
  // =========================================================================
  it('17, 18, 19. Suspended seller loses seller privileges, retains buyer permissions, and existing listings remain linked', async () => {
    const suspendRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${buyer1AppId}/suspend`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { reason: 'Temporary seller compliance hold' },
    });
    expect(suspendRes.statusCode).toBe(200);
    expect(suspendRes.json().data.status).toBe('SUSPENDED');

    // 17. Suspended seller loses seller privileges immediately
    const createBlocked = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Suspended Seller Attempt',
        description: 'Must be blocked.',
        price: 1000,
        mediaKeys: [`uploads/images/2026-11/${buyer1Id}/photo2.jpg`],
      },
    });
    expect(createBlocked.statusCode).toBe(403);

    const editBlocked = await app.inject({
      method: 'PUT',
      url: `/api/v1/listings/${buyer1ListingId}`,
      headers: { authorization: `Bearer ${buyer1Token}` },
      payload: { title: 'Blocked Edit' },
    });
    expect(editBlocked.statusCode).toBe(403);

    const dashBlocked = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/dashboard',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(dashBlocked.statusCode).toBe(403);

    // 18. Suspended seller retains ALL buyer permissions
    const profileRes = await app.inject({
      method: 'GET',
      url: '/api/v1/users/me',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(profileRes.statusCode).toBe(200);
    expect(profileRes.json().data.isActive).toBe(true);
    expect(profileRes.json().data.sellerStatus).toBe('SUSPENDED');
    expect(profileRes.json().data.canSell).toBe(false);

    const feedRes = await app.inject({
      method: 'GET',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(feedRes.statusCode).toBe(200);

    const favListRes = await app.inject({
      method: 'GET',
      url: '/api/v1/favorites',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(favListRes.statusCode).toBe(200);

    const cartRes = await app.inject({
      method: 'GET',
      url: '/api/v1/cart',
      headers: { authorization: `Bearer ${buyer1Token}` },
    });
    expect(cartRes.statusCode).toBe(200);

    // 19. Existing seller/listing relationships remain intact in DB
    const existingListing = await prisma.listing.findUnique({
      where: { id: buyer1ListingId },
      include: { account: true },
    });
    expect(existingListing).toBeTruthy();
    expect(existingListing?.account.ownerUserId).toBe(buyer1Id);
    expect(existingListing?.deletedAt).toBeNull();
  });
});
