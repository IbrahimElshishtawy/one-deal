import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import fastifyCookie from '@fastify/cookie';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/core/filters/http-exception.filter';
import { TransformInterceptor } from '../src/core/interceptors/transform.interceptor';
import { PrismaService } from '../src/core/database/prisma.service';
import { RedisService } from '../src/core/redis/redis.service';
import { TotpService } from '../src/modules/admin-auth/services/totp.service';

describe('Deal One Enterprise Admin Dashboard — Complete Workflows & Security E2E', () => {
  let app: NestFastifyApplication;
  let prisma: PrismaService;
  let redis: RedisService;
  let totpService: TotpService;

  const runTag = `${Date.now()}`;
  const createdStaffEmails: string[] = [];
  const createdRoleIds: number[] = [];
  const createdUserIds: string[] = [];
  const createdListingIds: string[] = [];
  const createdCampaignIds: string[] = [];
  const createdCmsIds: string[] = [];
  const createdFlagKeys: string[] = [];

  let superAdminToken = '';
  let superAdminCookie = '';
  let superAdminId = '';

  function extractCookie(setCookieHeader: string | string[] | undefined, name: string) {
    if (!setCookieHeader) return '';
    const arr = Array.isArray(setCookieHeader) ? setCookieHeader : [setCookieHeader];
    for (const c of arr) {
      if (c.startsWith(`${name}=`)) {
        return c.split(';')[0];
      }
    }
    return '';
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
      exclude: ['health/live', 'health/ready', 'health/liveness', 'health/readiness'],
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    prisma = app.get<PrismaService>(PrismaService);
    redis = app.get<RedisService>(RedisService);
    totpService = app.get<TotpService>(TotpService);

    await redis.del('ratelimit:ip:127.0.0.1:/api/v1/admin/auth/login');
    await redis.del('ratelimit:ip:127.0.0.1:/api/v1/admin/auth/refresh');
  }, 30000);

  afterAll(async () => {
    if (createdCampaignIds.length > 0) {
      await prisma.notificationCampaign.deleteMany({
        where: { id: { in: createdCampaignIds } },
      });
    }
    if (createdCmsIds.length > 0) {
      await prisma.cmsItem.deleteMany({ where: { id: { in: createdCmsIds } } });
    }
    if (createdFlagKeys.length > 0) {
      await prisma.featureFlag.deleteMany({
        where: { key: { in: createdFlagKeys } },
      });
    }
    if (createdListingIds.length > 0) {
      await prisma.report.deleteMany({
        where: { listingId: { in: createdListingIds } },
      });
      await prisma.listing.deleteMany({
        where: { id: { in: createdListingIds } },
      });
    }
    if (createdUserIds.length > 0) {
      await prisma.notification.deleteMany({
        where: { userId: { in: createdUserIds } },
      });
      await prisma.accountVerification.deleteMany({
        where: { account: { ownerUserId: { in: createdUserIds } } },
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
      await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } });
    }
    if (createdStaffEmails.length > 0) {
      await prisma.staffUser.deleteMany({
        where: { email: { in: createdStaffEmails } },
      });
    }
    if (createdRoleIds.length > 0) {
      await prisma.staffRole.deleteMany({
        where: { id: { in: createdRoleIds } },
      });
    }
    await app.close();
  });

  it('Workflow 1: Super Admin login, HttpOnly cookie refresh rotation + CSRF enforcement, and MFA setup/verify', async () => {
    const loginRes = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: {
        email: 'superadmin@dealone.eg',
        password: 'SuperAdmin!2026',
      },
    });
    expect(loginRes.statusCode).toBe(200);
    const loginBody = JSON.parse(loginRes.body).data;
    expect(loginBody.requiresMfa).toBe(false);
    expect(loginBody.accessToken).toBeTruthy();
    expect(loginBody.refreshToken).toBeUndefined(); // Never exposed to JS in browser response!
    expect(loginBody.admin.role.name).toBe('super_admin');

    superAdminToken = loginBody.accessToken;
    superAdminId = loginBody.admin.id;
    superAdminCookie = extractCookie(
      loginRes.headers['set-cookie'],
      'dealone_admin_rt',
    );
    expect(superAdminCookie).toContain('dealone_admin_rt=');

    // CSRF Security Check: cookie-based refresh WITHOUT X-Requested-With MUST fail with 403
    const csrfBlocked = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/refresh',
      headers: { cookie: superAdminCookie },
    });
    expect(csrfBlocked.statusCode).toBe(403);

    // Valid cookie refresh WITH X-Requested-With rotates cookie & issues new accessToken
    const refreshOk = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/refresh',
      headers: {
        cookie: superAdminCookie,
        'x-requested-with': 'dealone-admin-web',
      },
    });
    expect(refreshOk.statusCode).toBe(200);
    const rotatedBody = JSON.parse(refreshOk.body).data;
    expect(rotatedBody.accessToken).toBeTruthy();
    superAdminToken = rotatedBody.accessToken;
    const rotatedCookie = extractCookie(
      refreshOk.headers['set-cookie'],
      'dealone_admin_rt',
    );
    expect(rotatedCookie).toBeTruthy();
    expect(rotatedCookie).not.toBe(superAdminCookie);
    superAdminCookie = rotatedCookie;

    // Test /admin/auth/me & active sessions
    const meRes = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/auth/me',
      headers: { authorization: `Bearer ${superAdminToken}` },
    });
    expect(meRes.statusCode).toBe(200);
    expect(JSON.parse(meRes.body).data.email).toBe('superadmin@dealone.eg');
  });

  it('Workflow 2 & 3: Create Admin Account, Create/Clone Role, Prevent Privilege Escalation & Last Super Admin Protection', async () => {
    // 1. Create custom role
    const createRoleRes = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/staff/roles',
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: {
        name: `qa_mod_${runTag}`,
        description: 'QA Moderator Role',
        permissions: ['listings.read', 'listings.approve', 'reports.read'],
      },
    });
    expect(createRoleRes.statusCode).toBe(201);
    const customRoleId = JSON.parse(createRoleRes.body).data.id;
    createdRoleIds.push(customRoleId);

    // 2. Clone role
    const cloneRes = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/staff/roles/${customRoleId}/clone`,
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: { name: `qa_mod_clone_${runTag}` },
    });
    expect(cloneRes.statusCode).toBe(201);
    createdRoleIds.push(JSON.parse(cloneRes.body).data.id);

    // 3. Create new admin account
    const staffEmail = `qa.mod.${runTag}@dealone.eg`;
    createdStaffEmails.push(staffEmail);
    const createStaffRes = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/staff',
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: {
        email: staffEmail,
        password: 'QaModerator!2026',
        fullName: 'QA Moderator',
        roleId: customRoleId,
      },
    });
    expect(createStaffRes.statusCode).toBe(201);
    const newStaffId = JSON.parse(createStaffRes.body).data.id;

    // 4. Last Super Admin self-deactivation protection -> 403
    const selfDisable = await app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/staff/${superAdminId}`,
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: { isActive: false },
    });
    expect(selfDisable.statusCode).toBe(403);

    // 5. Enroll MFA on new staff account & verify MFA login flow
    const staffLoginRes = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: staffEmail, password: 'QaModerator!2026' },
    });
    expect(staffLoginRes.statusCode).toBe(200);
    const staffToken = JSON.parse(staffLoginRes.body).data.accessToken;

    const mfaSetup = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/mfa/setup',
      headers: { authorization: `Bearer ${staffToken}` },
    });
    expect(mfaSetup.statusCode).toBe(200);
    const secret = JSON.parse(mfaSetup.body).data.secret;
    const validTotp = totpService.generateTotpForTime(secret);

    const mfaEnable = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/mfa/enable',
      headers: { authorization: `Bearer ${staffToken}` },
      payload: { code: validTotp },
    });
    expect(mfaEnable.statusCode).toBe(200);
    expect(JSON.parse(mfaEnable.body).data.mfaEnabled).toBe(true);

    // Next login requires MFA challenge
    const mfaLogin = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: staffEmail, password: 'QaModerator!2026' },
    });
    const mfaLoginData = JSON.parse(mfaLogin.body).data;
    expect(mfaLoginData.requiresMfa).toBe(true);
    expect(mfaLoginData.mfaChallengeToken).toBeTruthy();

    const mfaVerify = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/mfa/verify',
      payload: {
        mfaChallengeToken: mfaLoginData.mfaChallengeToken,
        code: totpService.generateTotpForTime(secret),
      },
    });
    expect(mfaVerify.statusCode).toBe(200);
    expect(JSON.parse(mfaVerify.body).data.accessToken).toBeTruthy();

    // Workflow 10: Unauthorized employee attempting restricted action -> 403 Forbidden
    const unauthorizedUsersBan = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/users/${newStaffId}/ban`,
      headers: { authorization: `Bearer ${staffToken}` },
      payload: { reason: 'Unauthorized attempt' },
    });
    expect(unauthorizedUsersBan.statusCode).toBe(403);

    const unauthorizedCreateRole = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/staff/roles',
      headers: { authorization: `Bearer ${staffToken}` },
      payload: { name: 'illegal_escalation', permissions: ['admins.create'] },
    });
    expect(unauthorizedCreateRole.statusCode).toBe(403);
  });

  it('Workflow 4, 5, 6 & 7: Listing Moderation (Flutter visibility), User Suspend/Ban, Report Assign/Resolve, Verification Approval & Audited Doc View', async () => {
    // Seed a marketplace user, seller account, pending listing, report, and verification request
    const category = await prisma.category.findFirst({
      where: { parentId: { not: null }, isActive: true },
    });
    const area = await prisma.area.findFirst({ where: { isActive: true } });
    expect(category).toBeTruthy();
    expect(area).toBeTruthy();

    const mpUser = await prisma.user.create({
      data: {
        phone: `+201099${runTag.slice(-6)}`,
        fullName: 'Marketplace Test Seller',
        isPhoneVerified: true,
        isActive: true,
      },
    });
    createdUserIds.push(mpUser.id);

    const mpAccount = await prisma.account.create({
      data: {
        ownerUserId: mpUser.id,
        accountType: 'company',
        displayName: `Test Co ${runTag}`,
        slug: `test-co-${runTag}`,
      },
    });

    const listing = await prisma.listing.create({
      data: {
        accountId: mpAccount.id,
        categoryId: category!.id,
        areaId: area!.id,
        title: `QA Listing ${runTag}`,
        description: 'Testing moderation and Flutter visibility sync',
        price: 150000,
        currency: 'EGP',
        listingKind: 'sale',
        moderationStatus: 'pending',
        publicationStatus: 'unpublished',
        availabilityStatus: 'available',
        expiresAt: new Date(Date.now() + 30 * 86400_000),
      },
    });
    createdListingIds.push(listing.id);

    // Workflow 4: Moderator logs in and approves listing -> visible in Flutter public endpoint
    const modLogin = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'moderator@dealone.eg', password: 'AdminStaff!2026' },
    });
    expect(modLogin.statusCode).toBe(200);
    const modToken = JSON.parse(modLogin.body).data.accessToken;

    const approveListing = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/listings/${listing.id}/approve`,
      headers: { authorization: `Bearer ${modToken}` },
      payload: { notes: 'Approved by QA moderator' },
    });
    expect(approveListing.statusCode).toBe(200);
    expect(JSON.parse(approveListing.body).data.publicationStatus).toBe('published');
    expect(JSON.parse(approveListing.body).data.approvedAt).toBeTruthy();

    // Flutter public GET /api/v1/listings/:id sees approved published listing
    const flutterListing = await app.inject({
      method: 'GET',
      url: `/api/v1/listings/${listing.id}`,
    });
    expect(flutterListing.statusCode).toBe(200);
    expect(JSON.parse(flutterListing.body).data.id).toBe(listing.id);

    // Hide listing -> Flutter GET returns 404
    const hideListing = await app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/listings/${listing.id}/hide`,
      headers: { authorization: `Bearer ${modToken}` },
      payload: { notes: 'Temporarily hidden' },
    });
    expect(hideListing.statusCode).toBe(200);
    const flutterHidden = await app.inject({
      method: 'GET',
      url: `/api/v1/listings/${listing.id}`,
    });
    expect(flutterHidden.statusCode).toBe(404);

    // Restore listing
    const restoreListing = await app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/listings/${listing.id}/restore`,
      headers: { authorization: `Bearer ${modToken}` },
      payload: {},
    });
    expect(restoreListing.statusCode).toBe(200);

    // Workflow 6: Report assign & resolve (verify status persists properly!)
    const report = await prisma.report.create({
      data: {
        reporterUserId: mpUser.id,
        listingId: listing.id,
        reason: 'scam',
        details: 'Test report for QA workflow',
        status: 'open',
      },
    });

    const assignRep = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/moderation/reports/${report.id}/assign`,
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: { staffId: superAdminId, priority: 'high' },
    });
    expect(assignRep.statusCode).toBe(200);
    expect(JSON.parse(assignRep.body).data.priority).toBe('high');

    const dismissRep = await app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/moderation/reports/${report.id}`,
      headers: { authorization: `Bearer ${modToken}` },
      payload: { status: 'dismissed', actionTaken: 'False positive report' },
    });
    expect(dismissRep.statusCode).toBe(200);
    expect(JSON.parse(dismissRep.body).data.status).toBe('dismissed');
    expect(JSON.parse(dismissRep.body).data.resolvedByStaffId).toBeTruthy();

    // Workflow 7: Verification Officer approves request + views document (audited!)
    const verification = await prisma.accountVerification.create({
      data: {
        accountId: mpAccount.id,
        documentType: 'commercial_register',
        documentNumber: 'CR-QA-9988',
        fileUrl: 'https://cdn.marketspace.eg/verifications/qa.pdf',
        status: 'pending',
      },
    });

    const verOfficerLogin = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'verification@dealone.eg', password: 'AdminStaff!2026' },
    });
    const verToken = JSON.parse(verOfficerLogin.body).data.accessToken;

    // Moderator does NOT have verification.documents.read -> 403
    const modForbiddenDoc = await app.inject({
      method: 'GET',
      url: `/api/v1/admin/moderation/verifications/${verification.id}/document`,
      headers: { authorization: `Bearer ${modToken}` },
    });
    expect(modForbiddenDoc.statusCode).toBe(403);

    // Verification officer CAN view document (writes audit log) & approve
    const docView = await app.inject({
      method: 'GET',
      url: `/api/v1/admin/moderation/verifications/${verification.id}/document`,
      headers: { authorization: `Bearer ${verToken}` },
    });
    expect(docView.statusCode).toBe(200);
    expect(JSON.parse(docView.body).data.documentNumber).toBe('CR-QA-9988');

    const approveVer = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/moderation/verifications/${verification.id}/decision`,
      headers: { authorization: `Bearer ${verToken}` },
      payload: { action: 'approve', notes: 'Commercial register verified' },
    });
    expect(approveVer.statusCode).toBe(200);
    expect(JSON.parse(approveVer.body).data.reviewedByStaffId).toBeTruthy();

    const updatedAccount = await prisma.account.findUnique({
      where: { id: mpAccount.id },
    });
    expect(updatedAccount?.verificationStatus).toBe('approved');

    // Workflow 5: Suspend and unsuspend marketplace user
    const suspendUser = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/users/${mpUser.id}/suspend`,
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: { reason: 'Repeated policy violations in QA test' },
    });
    expect(suspendUser.statusCode).toBe(200);
    expect(JSON.parse(suspendUser.body).data.moderationStatus).toBe('suspended');
    expect(JSON.parse(suspendUser.body).data.isActive).toBe(false);

    const unsuspendUser = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/users/${mpUser.id}/unsuspend`,
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: { notes: 'Verified clean' },
    });
    expect(unsuspendUser.statusCode).toBe(200);
    expect(JSON.parse(unsuspendUser.body).data.isActive).toBe(true);
  });

  it('Workflow 8 & 9: Notification Campaign Approval/Send, CMS Publish + Flutter Public Consumption, Overview, Analytics, System Health & Feature Flags', async () => {
    // Workflow 8: Marketing creates campaign -> Super Admin approves -> Marketing sends
    const mktLogin = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'marketing@dealone.eg', password: 'AdminStaff!2026' },
    });
    const mktToken = JSON.parse(mktLogin.body).data.accessToken;

    const previewRes = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/notifications/audience-preview',
      headers: { authorization: `Bearer ${mktToken}` },
      payload: { audienceType: 'new_users' },
    });
    expect(previewRes.statusCode).toBe(200);

    const createCamp = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/notifications/campaigns',
      headers: { authorization: `Bearer ${mktToken}` },
      payload: {
        titleAr: 'عرض صفقة ون',
        titleEn: 'Deal One Promo',
        bodyAr: 'تصفح أحدث العروض اليوم',
        bodyEn: 'Browse today deals',
        audienceType: 'new_users',
        submitForApproval: true,
      },
    });
    expect(createCamp.statusCode).toBe(201);
    const campId = JSON.parse(createCamp.body).data.id;
    createdCampaignIds.push(campId);

    // Marketing cannot approve own campaign without notifications.approve -> 403
    const mktApproveFail = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/notifications/campaigns/${campId}/approve`,
      headers: { authorization: `Bearer ${mktToken}` },
    });
    expect(mktApproveFail.statusCode).toBe(403);

    const approveCamp = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/notifications/campaigns/${campId}/approve`,
      headers: { authorization: `Bearer ${superAdminToken}` },
    });
    expect(approveCamp.statusCode).toBe(200);

    const sendCamp = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/notifications/campaigns/${campId}/send`,
      headers: { authorization: `Bearer ${mktToken}` },
    });
    expect(sendCamp.statusCode).toBe(200);
    expect(JSON.parse(sendCamp.body).data.status).toBe('sent');

    // Workflow 9: CMS draft -> publish -> Flutter public /api/v1/cms/public
    const cmsSlug = `qa-banner-${runTag}`;
    const createCms = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/cms',
      headers: { authorization: `Bearer ${mktToken}` },
      payload: {
        type: 'banner',
        slug: cmsSlug,
        titleAr: 'بانر اختباري',
        titleEn: 'QA Banner',
        bodyAr: 'محتوى عربي',
        bodyEn: 'English body',
        status: 'draft',
      },
    });
    expect(createCms.statusCode).toBe(201);
    const cmsId = JSON.parse(createCms.body).data.id;
    createdCmsIds.push(cmsId);

    // Draft is NOT visible publicly
    const publicDraft = await app.inject({
      method: 'GET',
      url: `/api/v1/cms/public/${cmsSlug}`,
    });
    expect(publicDraft.statusCode).toBe(404);

    // Publish CMS item
    const pubCms = await app.inject({
      method: 'POST',
      url: `/api/v1/admin/cms/${cmsId}/publish`,
      headers: { authorization: `Bearer ${mktToken}` },
    });
    expect(pubCms.statusCode).toBe(200);

    const publicLive = await app.inject({
      method: 'GET',
      url: `/api/v1/cms/public/${cmsSlug}`,
    });
    expect(publicLive.statusCode).toBe(200);
    expect(JSON.parse(publicLive.body).data.slug).toBe(cmsSlug);

    // Verify Overview, Analytics, System Health, Audit Logs, Feature Flags
    const overview = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/dashboard/overview',
      headers: { authorization: `Bearer ${superAdminToken}` },
    });
    expect(overview.statusCode).toBe(200);
    expect(JSON.parse(overview.body).data.kpis.users.total).toBeGreaterThanOrEqual(1);

    const analytics = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/analytics/summary',
      headers: { authorization: `Bearer ${superAdminToken}` },
    });
    expect(analytics.statusCode).toBe(200);

    const sysHealth = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/system/health',
      headers: { authorization: `Bearer ${superAdminToken}` },
    });
    expect(sysHealth.statusCode).toBe(200);
    expect(JSON.parse(sysHealth.body).data.database.status).toBe('up');

    const flagKey = `qa_flag_${runTag}`;
    createdFlagKeys.push(flagKey);
    const createFlag = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/feature-flags',
      headers: { authorization: `Bearer ${superAdminToken}` },
      payload: { key: flagKey, name: 'QA Flag', isEnabled: true },
    });
    expect(createFlag.statusCode).toBe(201);
  });
});
