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

describe('Deal One — Seller Identity & Business Verification Tiers + Upgrade (E2E & Security)', () => {
  let app: NestFastifyApplication;
  let prisma: PrismaService;
  let redis: RedisService;
  let smsAdapter: MockSmsAdapter;
  let staffSessionService: StaffSessionService;

  const suffix = String(Date.now()).slice(-6);
  const indPhone = `0107${suffix}1`;
  const bizPhone = `0107${suffix}2`;
  const buyerPhone = `0107${suffix}3`;
  const adminEmail = `sv-tier-admin-${suffix}@dealone.eg`;
  const readOnlyAdminEmail = `sv-tier-ro-${suffix}@dealone.eg`;

  let indToken = '';
  let indUserId = '';
  let indAppId = '';
  let indAccountId = '';
  let indDocFrontId = '';
  let indListingId = '';
  let indConversationId = '';
  let upgradeAppId = '';

  let bizToken = '';
  let bizUserId = '';
  let bizAppId = '';
  let bizAccountId = '';

  let buyerToken = '';
  let buyerUserId = '';

  let adminToken = '';
  let adminStaffId = '';
  let adminRoleId = 0;

  let readOnlyAdminToken = '';
  let readOnlyAdminStaffId = '';
  let readOnlyAdminRoleId = 0;

  let testCategoryId = '';
  let testAreaId = '';

  const createdUserIds: string[] = [];

  const VALID_JPEG_HEADER_B64 = Buffer.from([
    0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
  ]).toString('base64');
  const VALID_PDF_HEADER_B64 = Buffer.from('%PDF-1.7\n%test').toString('base64');

  async function registerViaOtp(phone: string, ipOctet: number) {
    const normalized = `+20${phone.slice(1)}`;
    const testIp = `10.215.${Math.floor(Date.now() / 1000) % 250}.${ipOctet}`;
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
    opts?: { mimeType?: string; fileName?: string; fileHeaderBase64?: string },
  ) {
    const mimeType = opts?.mimeType ?? 'image/jpeg';
    const fileName = opts?.fileName ?? `${documentType}.jpg`;

    const urlRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${token}` },
      payload: { documentType, fileName, mimeType, fileSizeBytes: 120_000 },
    });
    expect(urlRes.statusCode).toBe(200);
    const target = urlRes.json().data;

    const regRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        documentType,
        storageKey: target.storageKey,
        originalFileName: fileName,
        mimeType,
        fileSizeBytes: 120_000,
        fileHeaderBase64:
          opts?.fileHeaderBase64 ??
          (mimeType === 'application/pdf'
            ? VALID_PDF_HEADER_B64
            : VALID_JPEG_HEADER_B64),
      },
    });
    expect(regRes.statusCode).toBe(201);
    return regRes.json().data;
  }

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(SMS_GATEWAY_ADAPTER)
      .useClass(MockSmsAdapter)
      .compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
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
    app.setGlobalPrefix('api/v1');

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    prisma = app.get(PrismaService);
    redis = app.get(RedisService);
    smsAdapter = app.get<ISmsGatewayAdapter>(
      SMS_GATEWAY_ADAPTER,
    ) as unknown as MockSmsAdapter;
    staffSessionService = app.get(StaffSessionService);

    const passwordHash = await argon2.hash('TierAdmin!2026');
    const fullRole = await prisma.staffRole.create({
      data: {
        name: `sv_tier_full_${suffix}`,
        description: 'Full verification reviewer',
        isSystem: false,
        permissions: [...ADMIN_PERMISSIONS],
      },
    });
    adminRoleId = fullRole.id;

    const adminStaff = await prisma.staffUser.create({
      data: {
        email: adminEmail,
        passwordHash,
        fullName: 'Tier Verification Officer',
        roleId: fullRole.id,
        status: 'active',
        isActive: true,
      },
    });
    adminStaffId = adminStaff.id;

    const adminSession = await staffSessionService.createSession(
      {
        id: adminStaff.id,
        email: adminStaff.email,
        roleId: fullRole.id,
        role: { name: fullRole.name },
      },
      true,
      'jest-tier-e2e',
      '127.0.0.1',
    );
    adminToken = adminSession.accessToken;

    const roRole = await prisma.staffRole.create({
      data: {
        name: `sv_tier_ro_${suffix}`,
        description: 'Read-only verification auditor',
        isSystem: false,
        permissions: ['verification.read'],
      },
    });
    readOnlyAdminRoleId = roRole.id;

    const roStaff = await prisma.staffUser.create({
      data: {
        email: readOnlyAdminEmail,
        passwordHash,
        fullName: 'Read-Only Auditor',
        roleId: roRole.id,
        status: 'active',
        isActive: true,
      },
    });
    readOnlyAdminStaffId = roStaff.id;

    const roSession = await staffSessionService.createSession(
      {
        id: roStaff.id,
        email: roStaff.email,
        roleId: roRole.id,
        role: { name: roRole.name },
      },
      true,
      'jest-tier-ro',
      '127.0.0.1',
    );
    readOnlyAdminToken = roSession.accessToken;

    const cat = await prisma.category.findFirst({ where: { isActive: true } });
    const area = await prisma.area.findFirst({ where: { isActive: true } });
    testCategoryId = cat!.id;
    testAreaId = area!.id;

    const indReg = await registerViaOtp(indPhone, 11);
    indToken = indReg.tokens?.accessToken ?? indReg.accessToken;
    indUserId = indReg.user.id;

    const bizReg = await registerViaOtp(bizPhone, 12);
    bizToken = bizReg.tokens?.accessToken ?? bizReg.accessToken;
    bizUserId = bizReg.user.id;

    const buyerReg = await registerViaOtp(buyerPhone, 13);
    buyerToken = buyerReg.tokens?.accessToken ?? buyerReg.accessToken;
    buyerUserId = buyerReg.user.id;
  }, 60_000);

  afterAll(async () => {
    try {
      if (indConversationId) {
        await prisma.message.deleteMany({
          where: { conversationId: indConversationId },
        });
        await prisma.conversation.deleteMany({
          where: { id: indConversationId },
        });
      }
      if (indListingId) {
        await prisma.listing.deleteMany({ where: { id: indListingId } });
      }
      if (createdUserIds.length > 0) {
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
        await prisma.notification.deleteMany({
          where: { userId: { in: createdUserIds } },
        });
        await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } });
      }
      if (adminStaffId) {
        await prisma.staffSession.deleteMany({ where: { staffId: adminStaffId } });
        await prisma.staffUser.deleteMany({ where: { id: adminStaffId } });
      }
      if (readOnlyAdminStaffId) {
        await prisma.staffSession.deleteMany({
          where: { staffId: readOnlyAdminStaffId },
        });
        await prisma.staffUser.deleteMany({ where: { id: readOnlyAdminStaffId } });
      }
      if (adminRoleId) {
        await prisma.staffRole.deleteMany({ where: { id: adminRoleId } });
      }
      if (readOnlyAdminRoleId) {
        await prisma.staffRole.deleteMany({ where: { id: readOnlyAdminRoleId } });
      }
    } finally {
      await app.close();
    }
  });

  it('1. Buyer starts unverified and cannot inject verificationTier in application payload', async () => {
    const profileRes = await app.inject({
      method: 'GET',
      url: '/api/v1/users/me',
      headers: { authorization: `Bearer ${indToken}` },
    });
    expect(profileRes.statusCode).toBe(200);
    expect(profileRes.json().data.verificationTier).toBe('NONE');
    expect(profileRes.json().data.verificationBadge).toBeNull();

    // Attempt to tamper with verificationTier in DTO -> 400 (forbidNonWhitelisted)
    const tamperRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${indToken}` },
      payload: {
        sellerType: 'INDIVIDUAL',
        businessName: 'Independent Broker',
        nationalIdNumber: '29501011234567',
        verificationTier: 'BUSINESS_VERIFIED',
      },
    });
    expect(tamperRes.statusCode).toBe(400);
  });

  it('2. Individual seller submits National ID Front + Back (rejecting invalid extension & incompatible commercial doc) and receives IDENTITY_VERIFIED ("هوية موثقة")', async () => {
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${indToken}` },
      payload: {
        sellerType: 'INDIVIDUAL',
        businessName: 'Karim Independent Broker',
        nationalIdNumber: '29501011234567',
      },
    });
    expect(createRes.statusCode).toBe(201);
    indAppId = createRes.json().data.id;

    // Invalid file extension mismatch blocked
    const badExtRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${indToken}` },
      payload: {
        documentType: 'national_id_front',
        fileName: 'payload.exe',
        mimeType: 'image/jpeg',
        fileSizeBytes: 50_000,
      },
    });
    expect(badExtRes.statusCode).toBe(400);

    // Commercial register rejected as incompatible for INDIVIDUAL
    const incompatibleDocRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/documents/upload-url',
      headers: { authorization: `Bearer ${indToken}` },
      payload: {
        documentType: 'commercial_register',
        fileName: 'cr.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 50_000,
      },
    });
    expect(incompatibleDocRes.statusCode).toBe(400);

    // Upload National ID Front & Back
    const frontDoc = await uploadDoc(indToken, 'national_id_front');
    indDocFrontId = frontDoc.id;
    await uploadDoc(indToken, 'national_id_back');

    // Submit
    const submitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${indToken}` },
    });
    expect(submitRes.statusCode).toBe(200);

    // Security: Buyer cannot access seller's private document
    const buyerAccessRes = await app.inject({
      method: 'GET',
      url: `/api/v1/seller-applications/me/documents/${indDocFrontId}/access`,
      headers: { authorization: `Bearer ${buyerToken}` },
    });
    expect(buyerAccessRes.statusCode).toBe(403);

    // Security: Read-only admin without verification.approve cannot approve
    const unauthApproveRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${indAppId}/approve`,
      headers: { authorization: `Bearer ${readOnlyAdminToken}` },
      payload: {},
    });
    expect(unauthApproveRes.statusCode).toBe(403);

    // Authorized admin approves
    const approveRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${indAppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Identity verified cleanly' },
    });
    expect(approveRes.statusCode).toBe(200);
    const approvedData = approveRes.json().data;
    indAccountId = approvedData.account.id;
    expect(approvedData.account.sellerType).toBe('INDIVIDUAL');
    expect(approvedData.account.verificationTier).toBe('IDENTITY_VERIFIED');
    expect(approvedData.account.verificationBadge).toEqual({
      code: 'IDENTITY_VERIFIED',
      label: 'هوية موثقة',
    });

    // Public account endpoint exposes badge and NO sensitive documents/notes
    const publicAccRes = await app.inject({
      method: 'GET',
      url: `/api/v1/accounts/${indAccountId}`,
    });
    expect(publicAccRes.statusCode).toBe(200);
    const publicAcc = publicAccRes.json().data;
    expect(publicAcc.verificationTier).toBe('IDENTITY_VERIFIED');
    expect(publicAcc.verificationBadge).toEqual({
      code: 'IDENTITY_VERIFIED',
      label: 'هوية موثقة',
    });
    expect(publicAcc.documents).toBeUndefined();
    expect(publicAcc.nationalIdNumber).toBeUndefined();
    expect(publicAcc.verificationReviewedByStaffId).toBeUndefined();
  });

  it('3. Individual-to-Business Upgrade preserves accountId, existing listing, and conversation while upgrading to BUSINESS_VERIFIED ("شركة / مكتب موثق")', async () => {
    // Seed a published listing and a buyer conversation on the existing individual account
    const listing = await prisma.listing.create({
      data: {
        accountId: indAccountId,
        categoryId: testCategoryId,
        areaId: testAreaId,
        title: 'Maadi Apartment Before Upgrade',
        description: 'Spacious 3BR apartment in Maadi',
        price: 2500000,
        listingKind: 'sale',
        moderationStatus: 'approved',
        publicationStatus: 'published',
        availabilityStatus: 'available',
        expiresAt: new Date(Date.now() + 30 * 86_400_000),
      },
    });
    indListingId = listing.id;

    const conv = await prisma.conversation.create({
      data: {
        listingId: indListingId,
        buyerUserId,
        sellerAccountId: indAccountId,
        lastMessageText: 'Is this apartment still available?',
      },
    });
    indConversationId = conv.id;

    await prisma.message.create({
      data: {
        conversationId: conv.id,
        senderUserId: buyerUserId,
        body: 'Is this apartment still available?',
      },
    });

    // Public listing details before upgrade shows IDENTITY_VERIFIED
    const preListingRes = await app.inject({
      method: 'GET',
      url: `/api/v1/listings/${indListingId}`,
    });
    expect(preListingRes.statusCode).toBe(200);
    expect(preListingRes.json().data.seller.verificationTier).toBe('IDENTITY_VERIFIED');
    expect(preListingRes.json().data.seller.verificationBadge).toEqual({
      code: 'IDENTITY_VERIFIED',
      label: 'هوية موثقة',
    });

    // Initiate Business Upgrade
    const upgradeInitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/business-upgrade',
      headers: { authorization: `Bearer ${indToken}` },
      payload: {
        businessType: 'office',
        businessName: 'Karim Premier Real Estate Office',
        commercialRegisterNumber: 'CR-UPG-998877',
        taxIdNumber: 'TAX-UPG-112233',
      },
    });
    expect(upgradeInitRes.statusCode).toBe(201);
    upgradeAppId = upgradeInitRes.json().data.id;
    expect(upgradeInitRes.json().data.applicationType).toBe('BUSINESS_UPGRADE');
    expect(upgradeInitRes.json().data.accountId).toBe(indAccountId);

    // While upgrade is DRAFT, account sellerType & tier MUST remain INDIVIDUAL / IDENTITY_VERIFIED
    const midAcc = await prisma.account.findUnique({ where: { id: indAccountId } });
    expect(midAcc!.sellerType).toBe('INDIVIDUAL');
    expect(midAcc!.verificationTier).toBe('IDENTITY_VERIFIED');

    // Upload Commercial Registration + Tax Card (no Legal Rep ID needed — optional by default)
    await uploadDoc(indToken, 'commercial_register', {
      mimeType: 'application/pdf',
      fileName: 'commercial-register.pdf',
    });
    await uploadDoc(indToken, 'tax_card', {
      mimeType: 'application/pdf',
      fileName: 'tax-card.pdf',
    });

    // Submit upgrade
    const submitUpgRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/business-upgrade/submit',
      headers: { authorization: `Bearer ${indToken}` },
    });
    expect(submitUpgRes.statusCode).toBe(200);
    expect(submitUpgRes.json().data.status).toBe('PENDING');

    // Still IDENTITY_VERIFIED while PENDING!
    const pendingAcc = await prisma.account.findUnique({ where: { id: indAccountId } });
    expect(pendingAcc!.sellerType).toBe('INDIVIDUAL');
    expect(pendingAcc!.verificationTier).toBe('IDENTITY_VERIFIED');

    // Admin approves upgrade
    const approveUpgRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${upgradeAppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Commercial docs verified for upgrade' },
    });
    expect(approveUpgRes.statusCode).toBe(200);
    const upgResult = approveUpgRes.json().data;
    expect(upgResult.account.id).toBe(indAccountId);
    expect(upgResult.account.sellerType).toBe('BUSINESS');
    expect(upgResult.account.verificationTier).toBe('BUSINESS_VERIFIED');
    expect(upgResult.account.verificationBadge).toEqual({
      code: 'BUSINESS_VERIFIED',
      label: 'شركة / مكتب موثق',
    });

    // Verify NO second account was created
    const accountCount = await prisma.account.count({
      where: { ownerUserId: indUserId, deletedAt: null },
    });
    expect(accountCount).toBe(1);

    // Verify listing, conversation, and message are preserved
    const preservedListing = await prisma.listing.findUnique({ where: { id: indListingId } });
    expect(preservedListing!.accountId).toBe(indAccountId);

    const preservedConv = await prisma.conversation.findUnique({
      where: { id: indConversationId },
      include: { messages: true },
    });
    expect(preservedConv!.sellerAccountId).toBe(indAccountId);
    expect(preservedConv!.messages.length).toBe(1);

    // Public listing details now reflects BUSINESS_VERIFIED ("شركة / مكتب موثق")
    const postListingRes = await app.inject({
      method: 'GET',
      url: `/api/v1/listings/${indListingId}`,
    });
    expect(postListingRes.statusCode).toBe(200);
    expect(postListingRes.json().data.seller.verificationTier).toBe('BUSINESS_VERIFIED');
    expect(postListingRes.json().data.seller.verificationBadge).toEqual({
      code: 'BUSINESS_VERIFIED',
      label: 'شركة / مكتب موثق',
    });
  });

  it('4. Business registration, rejection (no badge), resubmission, approval, and suspension (badge revoked)', async () => {
    const createBizRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications',
      headers: { authorization: `Bearer ${bizToken}` },
      payload: {
        sellerType: 'BUSINESS',
        businessType: 'company',
        businessName: 'Pyramids Trading Co.',
        commercialRegisterNumber: 'CR-778899',
        taxIdNumber: 'TAX-778899',
      },
    });
    expect(createBizRes.statusCode).toBe(201);
    bizAppId = createBizRes.json().data.id;

    // Submitting without required documents fails
    const incompleteSubmit = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${bizToken}` },
    });
    expect(incompleteSubmit.statusCode).toBe(400);

    // Upload Commercial Register + Tax Card
    await uploadDoc(bizToken, 'commercial_register', {
      mimeType: 'application/pdf',
      fileName: 'biz-cr.pdf',
    });
    await uploadDoc(bizToken, 'tax_card', {
      mimeType: 'application/pdf',
      fileName: 'biz-tax.pdf',
    });

    const submitBizRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/submit',
      headers: { authorization: `Bearer ${bizToken}` },
    });
    expect(submitBizRes.statusCode).toBe(200);

    // Admin rejects with mandatory reason
    const rejectRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${bizAppId}/reject`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { reason: 'Commercial register scan is partially cropped' },
    });
    expect(rejectRes.statusCode).toBe(200);

    // Rejected user has NO verified badge
    const rejectedProfile = await app.inject({
      method: 'GET',
      url: '/api/v1/users/me',
      headers: { authorization: `Bearer ${bizToken}` },
    });
    expect(rejectedProfile.json().data.verificationTier).toBe('NONE');
    expect(rejectedProfile.json().data.verificationBadge).toBeNull();

    // Resubmit & approve
    const resubmitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/seller-applications/me/resubmit',
      headers: { authorization: `Bearer ${bizToken}` },
      payload: { submitImmediately: true },
    });
    expect(resubmitRes.statusCode).toBe(200);

    const approveBizRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${bizAppId}/approve`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { notes: 'Clear commercial docs verified' },
    });
    expect(approveBizRes.statusCode).toBe(200);
    bizAccountId = approveBizRes.json().data.account.id;
    expect(approveBizRes.json().data.account.verificationTier).toBe('BUSINESS_VERIFIED');

    // Suspend verification -> revokes active badge and sets tier to NONE
    const suspendRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/seller-applications/${bizAppId}/suspend`,
      headers: { authorization: `Bearer ${adminToken}` },
      payload: { reason: 'Compliance investigation initiated' },
    });
    expect(suspendRes.statusCode).toBe(200);

    const suspendedAcc = await prisma.account.findUnique({ where: { id: bizAccountId } });
    expect(suspendedAcc!.verificationStatus).toBe('suspended');
    expect(suspendedAcc!.verificationTier).toBe('NONE');
    expect(suspendedAcc!.isActive).toBe(false);

    // Audit history contains previousTier -> newTier transition
    const historyRows = await prisma.sellerApplicationHistory.findMany({
      where: { applicationId: bizAppId, newStatus: 'SUSPENDED' },
    });
    expect(historyRows.length).toBeGreaterThan(0);
    expect(historyRows[0].previousTier).toBe('BUSINESS_VERIFIED');
    expect(historyRows[0].newTier).toBe('NONE');
  });
});
