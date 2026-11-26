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

describe('Deal One — Seller Verification & Identity Review System (Full 20-Scenario E2E)', () => {
  let app: NestFastifyApplication;
  let prisma: PrismaService;
  let redis: RedisService;
  let smsAdapter: MockSmsAdapter;
  let staffSessionService: StaffSessionService;

  const suffix = String(Date.now()).slice(-6);
  const serviceProviderPhone = `0106${suffix}1`;
  const businessBuyerPhone = `0106${suffix}2`;
  const bystanderPhone = `0106${suffix}3`;
  const adminEmail = `sv-identity-admin-${suffix}@dealone.eg`;
  const limitedAdminEmail = `sv-limited-admin-${suffix}@dealone.eg`;

  let spToken = '';
  let spUserId = '';
  let spAppId = '';
  let spDocFrontId = '';
  let spDocLicenseId = '';
  let spListingId = '';

  let bizToken = '';
  let bizUserId = '';
  let bizAppId = '';

  let bystanderToken = '';
  let bystanderId = '';

  let adminToken = '';
  let adminStaffId = '';
  let adminRoleId = 0;

  let limitedAdminToken = '';
  let limitedAdminStaffId = '';
  let limitedAdminRoleId = 0;

  let testCategoryId = '';
  let testCityId = 0;
  let seedPublicListingId = '';
  let customRequirementId = '';

  const createdUserIds: string[] = [];

  const VALID_JPEG_HEADER_B64 = Buffer.from([
    0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
  ]).toString('base64');
  const VALID_PDF_HEADER_B64 = Buffer.from('%PDF-1.7\n%test').toString('base64');
  const SPOOFED_HTML_HEADER_B64 = Buffer.from('<script>alert(1)</script>').toString('base64');

  async function registerViaOtp(phone: string, ipOctet: number) {
    const normalized = `+20${phone.slice(1)}`;
    const testIp = `10.210.${Math.floor(Date.now() / 1000) % 250}.${ipOctet}`;
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

    const verifyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/verify',
      remoteAddress: testIp,
      payload: { phone, code: otpCode },
    });
    expect(verifyRes.statusCode).toBe(200);
    const data = verifyRes.json().data;
    createdUserIds.push(data.user.id);
    return data;
  }

  async function uploadDoc(
    token: string,
    documentType: string,
    opts?: {
      mimeType?: string;
      fileName?: string;
      fileSizeBytes?: number;
      fileHeaderBase64?: string;
      expiresAt?: string;
    },
  ) {
    const mimeType = opts?.mimeType ?? 'image/jpeg';
    const fileName = opts?.fileName ?? `${documentType}.jpg`;
    const fileSizeBytes = opts?.fileSizeBytes ?? 120_000;

    const urlRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${token}` },
      payload: { documentType, fileName, mimeType, fileSizeBytes },
    });
    expect(urlRes.statusCode).toBe(200);
    const target = urlRes.json().data;
    expect(target.storageKey).toMatch(/^private\/seller-verification\//);

    const confirmRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        documentType,
        storageKey: target.storageKey,
        originalFileName: fileName,
        mimeType,
        fileSizeBytes,
        fileHeaderBase64:
          opts?.fileHeaderBase64 ??
          (mimeType === 'application/pdf'
            ? VALID_PDF_HEADER_B64
            : VALID_JPEG_HEADER_B64),
        ...(opts?.expiresAt ? { expiresAt: opts.expiresAt } : {}),
      },
    });
    return { confirmRes, target };
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

    let category = await prisma.category.findFirst({
      where: { isActive: true },
      include: { fields: { where: { isActive: true, isRequired: true } } },
    });
    if (!category || category.fields.length > 0) {
      category = await prisma.category.create({
        data: {
          nameAr: `قسم تحقق ${suffix}`,
          nameEn: `Identity Test Category ${suffix}`,
          slug: `test-id-verif-${suffix}`,
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
    testCityId = city!.id;
    let area = city!.areas[0];
    if (!area) {
      area = await prisma.area.create({
        data: {
          cityId: city!.id,
          nameAr: 'منطقة',
          nameEn: 'Area',
          isActive: true,
        },
      });
    }

    const seedSeller = await prisma.user.create({
      data: {
        phone: `+20105${suffix}8`,
        fullName: 'Seed Public Seller',
        isPhoneVerified: true,
        isActive: true,
        sellerStatus: 'APPROVED',
        sellerApprovedAt: new Date(),
      },
    });
    createdUserIds.push(seedSeller.id);

    const seedAccount = await prisma.account.create({
      data: {
        ownerUserId: seedSeller.id,
        accountType: 'store',
        displayName: 'Seed Public Store',
        slug: `seed-id-store-${suffix}`,
        verificationStatus: 'approved',
        isActive: true,
      },
    });
    await prisma.accountMember.create({
      data: { accountId: seedAccount.id, userId: seedSeller.id, role: 'owner' },
    });

    const seedListing = await prisma.listing.create({
      data: {
        accountId: seedAccount.id,
        categoryId: testCategoryId,
        areaId: area.id,
        title: 'Seed Listing for Buyer Capability Check',
        description: 'Available for favorites and cart.',
        price: 2500,
        currency: 'EGP',
        listingKind: 'product',
        moderationStatus: 'approved',
        publicationStatus: 'published',
        availabilityStatus: 'available',
        expiresAt: new Date(Date.now() + 30 * 86400_000),
      },
    });
    seedPublicListingId = seedListing.id;

    // Full verification admin
    const fullRole = await prisma.staffRole.create({
      data: {
        name: `test_id_full_admin_${suffix}`,
        description: 'Full Verification Admin',
        isSystem: false,
        permissions: [...ADMIN_PERMISSIONS],
      },
    });
    adminRoleId = fullRole.id;

    const fullStaff = await prisma.staffUser.create({
      data: {
        email: adminEmail,
        passwordHash: await argon2.hash('AdminPass#12345'),
        fullName: 'Verification Officer',
        roleId: fullRole.id,
        status: 'active',
        isActive: true,
      },
    });
    adminStaffId = fullStaff.id;
    const fullSession = await staffSessionService.createSession(
      {
        id: fullStaff.id,
        email: fullStaff.email,
        roleId: fullStaff.roleId,
        role: { name: fullRole.name },
      },
      true,
      'jest-e2e',
      '127.0.0.1',
    );
    adminToken = fullSession.accessToken;

    // Limited admin (can read verification metadata, CANNOT read private docs or approve)
    const limRole = await prisma.staffRole.create({
      data: {
        name: `test_id_limited_admin_${suffix}`,
        description: 'Read-only Support Role',
        isSystem: false,
        permissions: ['verification.read'],
      },
    });
    limitedAdminRoleId = limRole.id;

    const limStaff = await prisma.staffUser.create({
      data: {
        email: limitedAdminEmail,
        passwordHash: await argon2.hash('AdminPass#12345'),
        fullName: 'Limited Support Agent',
        roleId: limRole.id,
        status: 'active',
        isActive: true,
      },
    });
    limitedAdminStaffId = limStaff.id;
    const limSession = await staffSessionService.createSession(
      {
        id: limStaff.id,
        email: limStaff.email,
        roleId: limStaff.roleId,
        role: { name: limRole.name },
      },
      true,
      'jest-e2e',
      '127.0.0.1',
    );
    limitedAdminToken = limSession.accessToken;

    // Register 3 buyers
    const r1 = await registerViaOtp(serviceProviderPhone, 21);
    spToken = r1.tokens.accessToken;
    spUserId = r1.user.id;

    const r2 = await registerViaOtp(businessBuyerPhone, 22);
    bizToken = r2.tokens.accessToken;
    bizUserId = r2.user.id;

    const r3 = await registerViaOtp(bystanderPhone, 23);
    bystanderToken = r3.tokens.accessToken;
    bystanderId = r3.user.id;
  }, 45000);

  afterAll(async () => {
    try {
      if (customRequirementId) {
        await prisma.sellerVerificationRequirement
          .deleteMany({ where: { id: customRequirementId } })
          .catch(() => undefined);
      }
      if (createdUserIds.length > 0) {
        await prisma.notification.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.cartItem.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.favorite.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.listing.deleteMany({
          where: { account: { ownerUserId: { in: createdUserIds } } },
        });
        await prisma.sellerDocumentReview.deleteMany({
          where: { application: { userId: { in: createdUserIds } } },
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
      for (const sid of [adminStaffId, limitedAdminStaffId].filter(Boolean)) {
        await prisma.staffSession.deleteMany({ where: { staffId: sid } });
        await prisma.staffUser.deleteMany({ where: { id: sid } });
      }
      for (const rid of [adminRoleId, limitedAdminRoleId].filter(Boolean)) {
        await prisma.staffRole.deleteMany({ where: { id: rid } });
      }
    } finally {
      await app.close();
    }
  }, 30000);

  // =========================================================================
  // TEST 2: Different seller types & marketplace sections receive correct requirements
  // + Admin configurable requirements CRUD & versioning
  // =========================================================================
  it('2. Different seller types and marketplace sections receive distinct configurable requirements', async () => {
    const indRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/requirements?sellerType=INDIVIDUAL&marketplaceSection=real-estate',
      headers: { authorization: `Bearer ${spToken}` },
    });
    expect(indRes.statusCode).toBe(200);
    const indReqs = indRes.json().data.requirements;
    const indDocTypes = indReqs.filter((r: any) => r.isRequired).map((r: any) => r.documentType);
    expect(indDocTypes).toContain('national_id_front');
    expect(indDocTypes).toContain('national_id_back');
    expect(indDocTypes).toContain('proof_of_address');

    const bizCarsRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/requirements?sellerType=BUSINESS&marketplaceSection=cars',
      headers: { authorization: `Bearer ${bizToken}` },
    });
    expect(bizCarsRes.statusCode).toBe(200);
    const bizDocTypes = bizCarsRes
      .json()
      .data.requirements.filter((r: any) => r.isRequired)
      .map((r: any) => r.documentType);
    expect(bizDocTypes).toContain('commercial_register');
    expect(bizDocTypes).toContain('tax_card');
    expect(bizDocTypes).toContain('business_license');

    const spServicesRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/requirements?sellerType=SERVICE_PROVIDER&marketplaceSection=services',
      headers: { authorization: `Bearer ${spToken}` },
    });
    expect(spServicesRes.statusCode).toBe(200);
    const spDocTypes = spServicesRes
      .json()
      .data.requirements.filter((r: any) => r.isRequired)
      .map((r: any) => r.documentType);
    expect(spDocTypes).toContain('qualification_certificate');
    expect(spDocTypes).toContain('professional_license');

    // Admin creates, updates (version bumps), and deactivates a custom requirement
    const createReqRes = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/seller-applications/requirements',
      headers: { authorization: `Bearer ${adminToken}` },
      payload: {
        sellerType: 'BUSINESS',
        marketplaceSection: 'home-appliances',
        documentType: 'portfolio_document',
        displayName: 'Showroom Catalog',
        isRequired: false,
        maxFileSizeBytes: 5242880,
      },
    });
    expect(createReqRes.statusCode).toBe(201);
    customRequirementId = createReqRes.json().data.id;
    expect(createReqRes.json().data.version).toBe(1);

    const updateReqRes = await app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/seller-applications/requirements/${customRequirementId}`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { displayName: 'Updated Showroom Catalog', isRequired: true },
    });
    expect(updateReqRes.statusCode).toBe(200);
    expect(updateReqRes.json().data.version).toBe(2);

    const delReqRes = await app.inject({
      method: 'DELETE',
      url: `/api/v1/admin/seller-applications/requirements/${customRequirementId}`,
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(delReqRes.statusCode).toBe(200);
    expect(delReqRes.json().data.isActive).toBe(false);
  });

  // =========================================================================
  // TEST 1 & PII ENCRYPTION: Buyer creates SERVICE_PROVIDER application
  // =========================================================================
  it('1. Buyer creates SERVICE_PROVIDER seller application with encrypted PII at rest and masked API output', async () => {
    const rawNationalId = '29405051234567';
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        sellerType: 'SERVICE_PROVIDER',
        marketplaceSections: ['services'],
        businessName: 'Delta Engineering Services',
        nationalIdNumber: rawNationalId,
        serviceCategory: 'AC Maintenance & Electrical',
        yearsOfExperience: 8,
        qualifications: 'B.Sc. Electrical Engineering, Syndicate Member #8821',
        professionalLicenseNumber: 'ENG-2026-8821',
        address: 'Maadi, Cairo',
      },
    });
    expect(res.statusCode).toBe(201);
    const data = res.json().data;
    spAppId = data.id;
    expect(data.status).toBe('DRAFT');
    expect(data.sellerType).toBe('SERVICE_PROVIDER');
    expect(data.nationalIdNumber).toBe('**********4567'); // Masked in API response
    expect(data.nationalIdNumber).not.toContain('294050');

    // Verify encrypted at rest in PostgreSQL
    const dbApp = await prisma.sellerApplication.findUnique({
      where: { id: spAppId },
    });
    expect(dbApp?.nationalIdNumber).toMatch(/^enc:v1:/);
    expect(dbApp?.nationalIdNumber).not.toContain(rawNationalId);
  });

  // =========================================================================
  // TESTS 3, 4, 5, 6: File format, magic bytes, file size, expiration & private storage
  // =========================================================================
  it('3, 4, 5, 6. Rejects invalid MIME, spoofed content, oversized files, missing expiration, and public storage paths', async () => {
    // 4a. Disallowed MIME type rejected
    const badMime = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        documentType: 'national_id_front',
        fileName: 'malware.exe',
        mimeType: 'application/x-msdownload',
        fileSizeBytes: 50_000,
      },
    });
    expect(badMime.statusCode).toBe(400);

    // 5. Oversized file (> 10 MB requirement limit) rejected
    const oversized = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        documentType: 'national_id_front',
        fileName: 'huge.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 15 * 1024 * 1024,
      },
    });
    expect(oversized.statusCode).toBe(400);

    // 4b. Spoofed file content (HTML masquerading as JPEG) rejected via magic-byte check
    const spoofed = await uploadDoc(spToken, 'national_id_front', {
      mimeType: 'image/jpeg',
      fileHeaderBase64: SPOOFED_HTML_HEADER_B64,
    });
    expect(spoofed.confirmRes.statusCode).toBe(400);

    // 6. Attempting to attach a public listing media path is rejected
    const publicPathAttempt = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        documentType: 'national_id_front',
        storageKey: `uploads/images/2026-11/${spUserId}/leaked.jpg`,
        originalFileName: 'leaked.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 50_000,
      },
    });
    expect(publicPathAttempt.statusCode).toBe(403);

    // 3a. professional_license requires expiresAt for SERVICE_PROVIDER in 'services'
    const missingExpiry = await uploadDoc(spToken, 'professional_license', {
      mimeType: 'application/pdf',
      fileName: 'license.pdf',
    });
    expect(missingExpiry.confirmRes.statusCode).toBe(400);

    // Upload all 4 required documents cleanly
    const futureExpiry = new Date(Date.now() + 365 * 86400_000).toISOString();
    const d1 = await uploadDoc(spToken, 'national_id_front');
    expect(d1.confirmRes.statusCode).toBe(201);
    spDocFrontId = d1.confirmRes.json().data.id;
    expect(d1.confirmRes.json().data.storageKey).toBeUndefined();

    const d2 = await uploadDoc(spToken, 'national_id_back');
    expect(d2.confirmRes.statusCode).toBe(201);

    const d3 = await uploadDoc(spToken, 'qualification_certificate', {
      mimeType: 'application/pdf',
      fileName: 'degree.pdf',
    });
    expect(d3.confirmRes.statusCode).toBe(201);

    const d4 = await uploadDoc(spToken, 'professional_license', {
      mimeType: 'application/pdf',
      fileName: 'license.pdf',
      expiresAt: futureExpiry,
    });
    expect(d4.confirmRes.statusCode).toBe(201);
    spDocLicenseId = d4.confirmRes.json().data.id;

    // Submit application -> PENDING
    const submitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${spToken}` },
    });
    expect(submitRes.statusCode).toBe(200);
    expect(submitRes.json().data.status).toBe('PENDING');
  });

  // =========================================================================
  // TESTS 7, 16, 19: Pending seller blocked, Buyer cannot approve, Unauthorized doc access blocked
  // =========================================================================
  it('7, 16, 19. Pending seller cannot publish listings; buyer cannot approve; unauthorized document access rejected', async () => {
    // 16. Pending seller cannot publish listing
    const createListing = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Pending Service Listing',
        description: 'Must be blocked until approved.',
        price: 500,
        mediaKeys: [`uploads/images/2026-11/${spUserId}/img.jpg`],
      },
    });
    expect(createListing.statusCode).toBe(403);

    // 7. Buyer cannot approve application
    const buyerApprove = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/approve`,
      headers: { authorization: `Bearer ${bystanderToken}` },
      payload: {},
    });
    expect(buyerApprove.statusCode).toBe(403);

    // 19a. Another buyer cannot access private document
    const otherBuyerDoc = await app.inject({
      method: 'GET',
      url: `/api/v1/seller-applications/me/documents/${spDocFrontId}/access`,
      headers: { authorization: `Bearer ${bystanderToken}` },
    });
    expect(otherBuyerDoc.statusCode).toBe(403);

    // 19b. Admin without verification.documents.read cannot access private document
    const limitedAdminDoc = await app.inject({
      method: 'GET',
      url: `/api/v1/admin/seller-applications/${spAppId}/documents/${spDocFrontId}`,
      headers: { authorization: `Bearer ${limitedAdminToken}` },
    });
    expect(limitedAdminDoc.statusCode).toBe(403);
  });

  // =========================================================================
  // TESTS 8, 9, 10, 11, 12: Admin review, incomplete approval blocked,
  // correction request, document replacement with version history, resubmission
  // =========================================================================
  it('8, 9, 10, 11, 12. Admin reviews, requests corrections, blocks incomplete approval; user replaces rejected doc (versioned) and resubmits', async () => {
    // 8. Admin filters by sellerType and marketplaceSection
    const listRes = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/seller-applications?status=PENDING&sellerType=SERVICE_PROVIDER&marketplaceSection=services',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(listRes.statusCode).toBe(200);
    expect(listRes.json().data.items.some((a: any) => a.id === spAppId)).toBe(true);

    // Start review: PENDING -> UNDER_REVIEW
    const startReviewRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/review`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Inspecting engineering credentials' },
    });
    expect(startReviewRes.statusCode).toBe(200);
    expect(startReviewRes.json().data.status).toBe('UNDER_REVIEW');

    // Individual document review: accept license, reject national_id_front
    const approveLicDoc = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/documents/${spDocLicenseId}/review`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { decision: 'APPROVED', notes: 'License verified' },
    });
    expect(approveLicDoc.statusCode).toBe(200);
    expect(approveLicDoc.json().data.document.status).toBe('VERIFIED');

    const rejectFrontDoc = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/documents/${spDocFrontId}/review`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: {
        decision: 'REJECTED',
        reason: 'Front ID image glare obscures birth date',
      },
    });
    expect(rejectFrontDoc.statusCode).toBe(200);
    expect(rejectFrontDoc.json().data.document.status).toBe('REJECTED');

    // 9. Incomplete application (has rejected required doc) CANNOT be approved
    const blockedApprove = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: {},
    });
    expect(blockedApprove.statusCode).toBe(400);

    // 10. Admin requests correction: UNDER_REVIEW -> NEEDS_CORRECTION
    const corrRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/request-correction`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: {
        reason: 'Please re-upload a clear National ID front photo and confirm address',
        affectedFields: ['address'],
        rejectedDocumentIds: [spDocFrontId],
      },
    });
    expect(corrRes.statusCode).toBe(200);
    expect(corrRes.json().data.status).toBe('NEEDS_CORRECTION');

    // User views correction requests
    const myCorrRes = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/me/corrections',
      headers: { authorization: `Bearer ${spToken}` },
    });
    expect(myCorrRes.statusCode).toBe(200);
    expect(myCorrRes.json().data.hasPendingCorrections).toBe(true);
    expect(myCorrRes.json().data.affectedFields).toEqual(['address']);
    expect(myCorrRes.json().data.rejectedDocuments.length).toBe(1);

    // Editing an UNAFFECTED field during NEEDS_CORRECTION is forbidden
    const forbiddenFieldEdit = await app.inject({
      method: 'PATCH',
      url: '/api/v1/seller-applications/me',
      headers: { authorization: `Bearer ${spToken}` },
      payload: { businessName: 'Unauthorized Name Change' },
    });
    expect(forbiddenFieldEdit.statusCode).toBe(403);

    // Editing the AFFECTED field ('address') succeeds
    const validFieldEdit = await app.inject({
      method: 'PATCH',
      url: '/api/v1/seller-applications/me',
      headers: { authorization: `Bearer ${spToken}` },
      payload: { address: 'Building 12, Road 9, Maadi, Cairo' },
    });
    expect(validFieldEdit.statusCode).toBe(200);

    // Replacing an ACCEPTED (non-rejected) document during NEEDS_CORRECTION is forbidden
    const newUrlForLic = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        documentType: 'professional_license',
        fileName: 'new-lic.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 50_000,
      },
    });
    const forbiddenDocReplace = await app.inject({
      method: 'PUT',
      url: `/api/v1/seller-applications/me/documents/${spDocLicenseId}/replace`,
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        storageKey: newUrlForLic.json().data.storageKey,
        originalFileName: 'new-lic.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 50_000,
        fileHeaderBase64: VALID_PDF_HEADER_B64,
      },
    });
    expect(forbiddenDocReplace.statusCode).toBe(403);

    // 11. Replace the REJECTED document (increments version & preserves v1 in DB)
    const newUrlForFront = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        documentType: 'national_id_front',
        fileName: 'id-front-clear.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 150_000,
      },
    });
    expect(newUrlForFront.statusCode).toBe(200);

    const replaceRes = await app.inject({
      method: 'PUT',
      url: `/api/v1/seller-applications/me/documents/${spDocFrontId}/replace`,
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        storageKey: newUrlForFront.json().data.storageKey,
        originalFileName: 'id-front-clear.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 150_000,
        fileHeaderBase64: VALID_JPEG_HEADER_B64,
      },
    });
    expect(replaceRes.statusCode).toBe(200);
    const replacedDoc = replaceRes.json().data;
    expect(replacedDoc.version).toBe(2);
    expect(replacedDoc.isCurrent).toBe(true);

    // Verify v1 is preserved in DB with isCurrent=false and replacedByDocumentId=v2.id
    const prevDocRow = await prisma.sellerApplicationDocument.findUnique({
      where: { id: spDocFrontId },
    });
    expect(prevDocRow).toBeTruthy();
    expect(prevDocRow?.isCurrent).toBe(false);
    expect(prevDocRow?.replacedByDocumentId).toBe(replacedDoc.id);

    // 12. User resubmits corrected application: NEEDS_CORRECTION -> PENDING
    const resubmitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/resubmit',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {},
    });
    expect(resubmitRes.statusCode).toBe(200);
    expect(resubmitRes.json().data.status).toBe('PENDING');
  });

  // =========================================================================
  // TESTS 13, 14, 15: Approval grants seller permissions & preserves buyer permissions
  // =========================================================================
  it('13, 14, 15. Admin approves corrected application; seller permissions granted and buyer permissions remain active', async () => {
    const reviewAgain = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/review`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Re-reviewing corrected document' },
    });
    expect(reviewAgain.statusCode).toBe(200);

    const approveRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Verified after correction' },
    });
    expect(approveRes.statusCode).toBe(200);
    expect(approveRes.json().data.application.status).toBe('APPROVED');

    // 14. Seller permissions granted: create listing + access dashboard
    const createListing = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Verified Engineering Maintenance Service',
        description: 'Published by approved service provider.',
        price: 800,
        mediaKeys: [`uploads/images/2026-11/${spUserId}/work1.jpg`],
      },
    });
    expect(createListing.statusCode).toBe(201);
    spListingId = createListing.json().data.id;

    // 15. Buyer permissions remain active (favorite + cart)
    const favRes = await app.inject({
      method: 'POST',
      url: '/api/v1/favorites',
      headers: { authorization: `Bearer ${spToken}` },
      payload: { listingId: seedPublicListingId },
    });
    expect([200, 201]).toContain(favRes.statusCode);

    const cartRes = await app.inject({
      method: 'POST',
      url: '/api/v1/cart/items',
      headers: { authorization: `Bearer ${spToken}` },
      payload: { listingId: seedPublicListingId, quantity: 1 },
    });
    expect([200, 201]).toContain(cartRes.statusCode);
  });

  // =========================================================================
  // TESTS 17, 18, 20: Suspension, Expiration policy, Notifications & Audit History
  // =========================================================================
  it('17, 18, 20. Suspension and expiration revoke seller privileges while preserving buyer permissions, listings, notifications, and audit history', async () => {
    // 17. Suspend -> blocks seller ops, keeps buyer ops -> Reinstate
    const suspendRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/suspend`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { reason: 'Temporary compliance review hold' },
    });
    expect(suspendRes.statusCode).toBe(200);
    expect(suspendRes.json().data.status).toBe('SUSPENDED');

    const blockedWhenSuspended = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Blocked Suspended Listing',
        description: 'Must fail.',
        price: 400,
        mediaKeys: [`uploads/images/2026-11/${spUserId}/x.jpg`],
      },
    });
    expect(blockedWhenSuspended.statusCode).toBe(403);

    const reinstateRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/reinstate`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Compliance hold cleared' },
    });
    expect(reinstateRes.statusCode).toBe(200);
    expect(reinstateRes.json().data.status).toBe('APPROVED');

    // 18. Expire verification: APPROVED -> EXPIRED
    const expireRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${spAppId}/expire`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { reason: 'Annual license verification expired' },
    });
    expect(expireRes.statusCode).toBe(200);
    expect(expireRes.json().data.status).toBe('EXPIRED');

    // Expired seller cannot create listings or access dashboard
    const blockedWhenExpired = await app.inject({
      method: 'POST',
      url: '/api/v1/listings',
      headers: { authorization: `Bearer ${spToken}` },
      payload: {
        categoryId: testCategoryId,
        cityId: testCityId,
        title: 'Blocked Expired Listing',
        description: 'Must fail.',
        price: 400,
        mediaKeys: [`uploads/images/2026-11/${spUserId}/y.jpg`],
      },
    });
    expect(blockedWhenExpired.statusCode).toBe(403);

    const dashExpired = await app.inject({
      method: 'GET',
      url: '/api/v1/seller-applications/dashboard',
      headers: { authorization: `Bearer ${spToken}` },
    });
    expect(dashExpired.statusCode).toBe(403);

    // Expired seller retains buyer permissions & existing listing history
    const favRead = await app.inject({
      method: 'GET',
      url: '/api/v1/favorites',
      headers: { authorization: `Bearer ${spToken}` },
    });
    expect(favRead.statusCode).toBe(200);

    const existingListing = await prisma.listing.findUnique({
      where: { id: spListingId },
    });
    expect(existingListing).toBeTruthy();
    expect(existingListing?.deletedAt).toBeNull();

    // 20. Verify complete audit history, document reviews, and in-app notifications
    const [historyRows, reviewRows, notifRows, auditRows] = await Promise.all([
      prisma.sellerApplicationHistory.findMany({
        where: { applicationId: spAppId },
      }),
      prisma.sellerDocumentReview.findMany({
        where: { applicationId: spAppId },
      }),
      prisma.notification.findMany({
        where: { userId: spUserId },
      }),
      prisma.auditLog.findMany({
        where: { targetId: spAppId },
      }),
    ]);

    const statusTrail = historyRows.map((h) => h.newStatus);
    expect(statusTrail).toEqual(
      expect.arrayContaining([
        'DRAFT',
        'PENDING',
        'UNDER_REVIEW',
        'NEEDS_CORRECTION',
        'APPROVED',
        'SUSPENDED',
        'EXPIRED',
      ]),
    );
    expect(reviewRows.length).toBeGreaterThanOrEqual(3);

    const notifTypes = notifRows.map((n) => n.type);
    expect(notifTypes).toEqual(
      expect.arrayContaining([
        'SELLER_APPLICATION_SUBMITTED',
        'SELLER_APPLICATION_UNDER_REVIEW',
        'SELLER_APPLICATION_CORRECTION_REQUESTED',
        'SELLER_APPLICATION_APPROVED',
        'SELLER_VERIFICATION_SUSPENDED',
        'SELLER_VERIFICATION_EXPIRED',
      ]),
    );

    // Confirm zero sensitive data leaked into notifications or audit logs
    const serializedNotifs = JSON.stringify(notifRows);
    expect(serializedNotifs).not.toContain('29405051234567');
    expect(serializedNotifs).not.toContain('private/seller-verification/');

    const serializedAudits = JSON.stringify(auditRows);
    expect(serializedAudits).not.toContain('29405051234567');
  });

  // =========================================================================
  // BUSINESS seller incomplete approval test (extra validation)
  // =========================================================================
  it('BUSINESS seller missing mandatory commercial_register cannot submit', async () => {
    const createBiz = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${bizToken}` },
      payload: {
        sellerType: 'BUSINESS',
        businessType: 'company',
        marketplaceSections: ['building-materials'],
        businessName: 'Nile Steel Trading Co.',
        commercialRegisterNumber: 'CR-991122',
        authorizedRepresentativeName: 'Mohamed Ali',
        authorizedRepresentativeId: '28801011234567',
      },
    });
    expect(createBiz.statusCode).toBe(201);
    bizAppId = createBiz.json().data.id;
    expect(createBiz.json().data.authorizedRepresentativeId).toBe('**********4567');

    // Attempt to submit without required BUSINESS documents
    const submitIncomplete = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${bizToken}` },
    });
    expect(submitIncomplete.statusCode).toBe(400);
    expect(submitIncomplete.json().error?.message).toMatch(/incomplete/i);
  });
});
