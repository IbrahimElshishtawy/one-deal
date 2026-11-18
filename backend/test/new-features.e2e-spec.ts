import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/core/filters/http-exception.filter';
import { TransformInterceptor } from '../src/core/interceptors/transform.interceptor';
import { LoggingInterceptor } from '../src/core/interceptors/logging.interceptor';
import { PrismaService } from '../src/core/database/prisma.service';
import { RedisService } from '../src/core/redis/redis.service';
import { SMS_GATEWAY_ADAPTER } from '../src/modules/auth/adapters/sms-gateway.interface';
import { MockSmsAdapter } from '../src/modules/auth/adapters/mock-sms.adapter';
import { SessionService } from '../src/modules/auth/services/session.service';

describe('Password Management, Notifications Inbox & Admin/Account Endpoints E2E', () => {
  let app: NestFastifyApplication;
  let prisma: PrismaService;
  let redis: RedisService;
  let smsAdapter: MockSmsAdapter;
  let sessionService: SessionService;

  const testPhone = `+20106666${Math.floor(1000 + Math.random() * 9000)}`;
  const otherPhone = `+20105555${Math.floor(1000 + Math.random() * 9000)}`;
  const adminSettingKey = `e2e_test_setting_${Date.now()}`;
  const staffRoleName = `e2e_role_${Date.now()}`;
  const staffEmail = `e2e-staff-${Date.now()}@dealone.eg`;

  let userId: string;
  let otherUserId: string;
  let accountId: string;
  let accessToken: string;
  let secondRefreshToken: string;
  let adminAccessToken: string;

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
    sessionService = app.get<SessionService>(SessionService);

    await redis.del(`otp:cooldown:${testPhone}`);
    await redis.del(`otp:ratelimit:phone:${testPhone}`);
    await redis.del('ratelimit:ip:127.0.0.1:/api/v1/auth/password/forgot');
    await redis.del('ratelimit:ip:127.0.0.1:/api/v1/auth/password/reset');

    // Register primary user via OTP
    await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/send',
      payload: { phone: testPhone },
    });
    const code = smsAdapter.getLastSentCode(testPhone);
    const verifyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/verify',
      payload: { phone: testPhone, code },
    });
    const verifyBody = JSON.parse(verifyRes.body);
    userId = verifyBody.data.user.id;
    accountId = verifyBody.data.activeAccount.id;
    accessToken = verifyBody.data.tokens.accessToken;

    // Create a second user for IDOR notification check
    const otherUser = await prisma.user.create({
      data: {
        phone: otherPhone,
        fullName: 'Other User E2E',
        isPhoneVerified: true,
        isActive: true,
      },
    });
    otherUserId = otherUser.id;

    // Mint a SUPER_ADMIN session token for admin endpoints
    const adminSession = await sessionService.createSession(
      userId,
      testPhone,
      'SUPER_ADMIN',
      'E2E-Admin',
      '127.0.0.1',
    );
    adminAccessToken = adminSession.accessToken;
  });

  afterAll(async () => {
    await prisma.notification.deleteMany({
      where: { userId: { in: [userId, otherUserId] } },
    });
    await prisma.userDevice.deleteMany({
      where: { userId: { in: [userId, otherUserId] } },
    });
    await prisma.accountVerification.deleteMany({ where: { accountId } });
    await prisma.serviceArea.deleteMany({ where: { accountId } });
    await prisma.staffUser.deleteMany({ where: { email: staffEmail } });
    await prisma.staffRole.deleteMany({ where: { name: staffRoleName } });
    await prisma.platformSetting.deleteMany({
      where: { key: adminSettingKey },
    });
    await prisma.userSession.deleteMany({
      where: { userId: { in: [userId, otherUserId] } },
    });
    await prisma.accountMember.deleteMany({ where: { userId } });
    await prisma.account.deleteMany({ where: { ownerUserId: userId } });
    await prisma.otp.deleteMany({ where: { phone: testPhone } });
    await prisma.user.deleteMany({
      where: { id: { in: [userId, otherUserId] } },
    });
    await redis.del(`otp:cooldown:${testPhone}`);
    await redis.del(`otp:ratelimit:phone:${testPhone}`);
    await redis.del('ratelimit:ip:127.0.0.1:/api/v1/auth/password/forgot');
    await redis.del('ratelimit:ip:127.0.0.1:/api/v1/auth/password/reset');
    await app.close();
  });

  describe('Password Management Flow', () => {
    it('should allow setting initial password, logging in, changing password (revoking other sessions), and resetting via forgot/reset', async () => {
      // 1. Set password
      const setRes = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/password/set',
        headers: { authorization: `Bearer ${accessToken}` },
        payload: { password: 'InitialPassword!2026' },
      });
      expect(setRes.statusCode).toBe(200);

      // 2. Login with password (creates second session)
      const loginRes = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/login',
        payload: { phone: testPhone, password: 'InitialPassword!2026' },
      });
      expect(loginRes.statusCode).toBe(200);
      const loginBody = JSON.parse(loginRes.body);
      secondRefreshToken = loginBody.data.tokens.refreshToken;

      // 3. Change password using first session (should revoke second session)
      const changeRes = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/password/change',
        headers: { authorization: `Bearer ${accessToken}` },
        payload: {
          currentPassword: 'InitialPassword!2026',
          newPassword: 'ChangedPassword!2026',
        },
      });
      expect(changeRes.statusCode).toBe(200);
      expect(
        JSON.parse(changeRes.body).data.revokedSessionsCount,
      ).toBeGreaterThanOrEqual(1);

      // Second session refresh token should now be rejected
      const refreshAfterChange = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/refresh',
        payload: { refreshToken: secondRefreshToken },
      });
      expect(refreshAfterChange.statusCode).toBe(401);

      // 4. Forgot password for unregistered phone MUST return 200 & comparable timing
      const tUnknownStart = process.hrtime.bigint();
      const forgotUnknown = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/password/forgot',
        payload: { phone: '+201099998888' },
      });
      const tUnknownMs = Number(process.hrtime.bigint() - tUnknownStart) / 1e6;
      expect(forgotUnknown.statusCode).toBe(200);

      // Clear cooldown so OTP dispatch succeeds for registered test phone
      await redis.del(`otp:cooldown:${testPhone}`);
      const tKnownStart = process.hrtime.bigint();
      const forgotKnown = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/password/forgot',
        payload: { phone: testPhone },
      });
      const tKnownMs = Number(process.hrtime.bigint() - tKnownStart) / 1e6;
      expect(forgotKnown.statusCode).toBe(200);
      expect(JSON.parse(forgotUnknown.body).data).toEqual(
        JSON.parse(forgotKnown.body).data,
      );
      expect(Math.abs(tKnownMs - tUnknownMs)).toBeLessThan(500);

      const resetCode = smsAdapter.getLastSentCode(testPhone);
      expect(resetCode).toBeDefined();

      // 5. Reset password with OTP
      const resetRes = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/password/reset',
        payload: {
          phone: testPhone,
          code: resetCode,
          newPassword: 'ResetPassword!2026',
        },
      });
      expect(resetRes.statusCode).toBe(200);

      // 6. Login with reset password succeeds
      const loginAfterReset = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/login',
        payload: { phone: testPhone, password: 'ResetPassword!2026' },
      });
      expect(loginAfterReset.statusCode).toBe(200);
      const refreshedTokens = JSON.parse(loginAfterReset.body).data.tokens;
      accessToken = refreshedTokens.accessToken;

      // Re-mint admin token because resetPassword revoked all sessions
      const adminSession = await sessionService.createSession(
        userId,
        testPhone,
        'SUPER_ADMIN',
        'E2E-Admin',
        '127.0.0.1',
      );
      adminAccessToken = adminSession.accessToken;
    });
  });

  describe('Notifications Inbox E2E', () => {
    it('should list unread notifications, block cross-user read, and mark single/all as read', async () => {
      const ownNotif1 = await prisma.notification.create({
        data: {
          userId,
          type: 'GENERAL',
          title: 'Welcome',
          body: 'Hello 1',
          isRead: false,
        },
      });
      await prisma.notification.create({
        data: {
          userId,
          type: 'GENERAL',
          title: 'Second',
          body: 'Hello 2',
          isRead: false,
        },
      });
      const otherNotif = await prisma.notification.create({
        data: {
          userId: otherUserId,
          type: 'GENERAL',
          title: 'Private',
          body: 'Other user notification',
          isRead: false,
        },
      });

      const listRes = await app.inject({
        method: 'GET',
        url: '/api/v1/notifications?unread=true&page=1&limit=10',
        headers: { authorization: `Bearer ${accessToken}` },
      });
      expect(listRes.statusCode).toBe(200);
      const listBody = JSON.parse(listRes.body);
      expect(listBody.data.unreadCount).toBe(2);
      expect(listBody.data.items.length).toBe(2);

      // Cross-user IDOR attempt must return 404
      const idorRes = await app.inject({
        method: 'PATCH',
        url: `/api/v1/notifications/${otherNotif.id}/read`,
        headers: { authorization: `Bearer ${accessToken}` },
      });
      expect(idorRes.statusCode).toBe(404);

      // Mark one as read
      const markOneRes = await app.inject({
        method: 'PATCH',
        url: `/api/v1/notifications/${ownNotif1.id}/read`,
        headers: { authorization: `Bearer ${accessToken}` },
      });
      expect(markOneRes.statusCode).toBe(200);
      expect(JSON.parse(markOneRes.body).data.isRead).toBe(true);

      // Mark all remaining as read
      const markAllRes = await app.inject({
        method: 'PATCH',
        url: '/api/v1/notifications/read-all',
        headers: { authorization: `Bearer ${accessToken}` },
      });
      expect(markAllRes.statusCode).toBe(200);
      expect(JSON.parse(markAllRes.body).data.updatedCount).toBe(1);

      // Device token DTO validation
      const validDeviceRes = await app.inject({
        method: 'POST',
        url: '/api/v1/notifications/device-token',
        headers: { authorization: `Bearer ${accessToken}` },
        payload: { token: 'fcm-e2e-token-valid-123', platform: 'android' },
      });
      expect(validDeviceRes.statusCode).toBe(200);

      const emptyTokenRes = await app.inject({
        method: 'POST',
        url: '/api/v1/notifications/device-token',
        headers: { authorization: `Bearer ${accessToken}` },
        payload: { token: '', platform: 'android' },
      });
      expect(emptyTokenRes.statusCode).toBe(400);

      const badPlatformRes = await app.inject({
        method: 'POST',
        url: '/api/v1/notifications/device-token',
        headers: { authorization: `Bearer ${accessToken}` },
        payload: { token: 'fcm-e2e-token-valid-123', platform: 'windows' },
      });
      expect(badPlatformRes.statusCode).toBe(400);
    });
  });

  describe('Service Areas, Account Verification, Platform Settings & Staff E2E', () => {
    it('should manage service areas, submit & moderate account verification, and enforce admin RBAC on settings & staff', async () => {
      const area = await prisma.area.findFirst({ where: { isActive: true } });
      expect(area).toBeDefined();

      // 1. Service Areas CRUD
      const upsertSa = await app.inject({
        method: 'POST',
        url: `/api/v1/accounts/${accountId}/service-areas`,
        headers: { authorization: `Bearer ${accessToken}` },
        payload: { areaId: area!.id, radiusKm: 15 },
      });
      expect(upsertSa.statusCode).toBe(200);
      const saId = JSON.parse(upsertSa.body).data.id;

      const listSa = await app.inject({
        method: 'GET',
        url: `/api/v1/accounts/${accountId}/service-areas`,
      });
      expect(listSa.statusCode).toBe(200);
      expect(JSON.parse(listSa.body).data.length).toBeGreaterThanOrEqual(1);

      const delSa = await app.inject({
        method: 'DELETE',
        url: `/api/v1/accounts/${accountId}/service-areas/${saId}`,
        headers: { authorization: `Bearer ${accessToken}` },
      });
      expect(delSa.statusCode).toBe(200);

      // 2. Account Verification submit + Admin moderation decision
      const submitVer = await app.inject({
        method: 'POST',
        url: `/api/v1/accounts/${accountId}/verifications`,
        headers: { authorization: `Bearer ${accessToken}` },
        payload: {
          documentType: 'commercial_register',
          documentNumber: 'CR-E2E-001',
          fileUrl: 'https://cdn.marketspace.eg/verifications/e2e.pdf',
        },
      });
      expect(submitVer.statusCode).toBe(201);
      const verId = JSON.parse(submitVer.body).data.id;

      const userForbidden = await app.inject({
        method: 'GET',
        url: '/api/v1/admin/settings',
        headers: { authorization: `Bearer ${accessToken}` },
      });
      expect(userForbidden.statusCode).toBe(403);

      const decideVer = await app.inject({
        method: 'POST',
        url: `/api/v1/admin/moderation/verifications/${verId}/decision`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
        payload: { action: 'approve', notes: 'Verified in E2E' },
      });
      expect(decideVer.statusCode).toBe(200);
      expect(JSON.parse(decideVer.body).data.status).toBe('approved');

      // Re-adjudicating an already decided verification must return 409 without extra ModerationLog
      const decideAgain = await app.inject({
        method: 'POST',
        url: `/api/v1/admin/moderation/verifications/${verId}/decision`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
        payload: { action: 'reject', rejectionReason: 'Too late' },
      });
      expect(decideAgain.statusCode).toBe(409);

      const modLogCount = await prisma.moderationLog.count({
        where: { targetType: 'verification', targetId: verId },
      });
      expect(modLogCount).toBe(1);
      await prisma.moderationLog.deleteMany({
        where: { targetType: 'verification', targetId: verId },
      });

      // Moderation limit clamping (limit=1000 -> clamped to 100)
      const modListingsRes = await app.inject({
        method: 'GET',
        url: '/api/v1/admin/moderation/listings?limit=1000',
        headers: { authorization: `Bearer ${adminAccessToken}` },
      });
      expect(modListingsRes.statusCode).toBe(200);
      expect(JSON.parse(modListingsRes.body).data.meta.limit).toBe(100);

      // 3. Platform Settings (key validation + valid flow)
      const tooLongKey = 'a'.repeat(101);
      const putTooLong = await app.inject({
        method: 'PUT',
        url: `/api/v1/admin/settings/${tooLongKey}`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
        payload: { value: true },
      });
      expect(putTooLong.statusCode).toBe(400);

      const getTooLong = await app.inject({
        method: 'GET',
        url: `/api/v1/admin/settings/${tooLongKey}`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
      });
      expect(getTooLong.statusCode).toBe(400);

      const invalidCharsKey = encodeURIComponent('bad key عربي');
      const putInvalidChars = await app.inject({
        method: 'PUT',
        url: `/api/v1/admin/settings/${invalidCharsKey}`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
        payload: { value: true },
      });
      expect(putInvalidChars.statusCode).toBe(400);

      const getInvalidChars = await app.inject({
        method: 'GET',
        url: `/api/v1/admin/settings/${invalidCharsKey}`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
      });
      expect(getInvalidChars.statusCode).toBe(400);

      const putSetting = await app.inject({
        method: 'PUT',
        url: `/api/v1/admin/settings/${adminSettingKey}`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
        payload: { value: { maxReveals: 7 }, description: 'E2E test setting' },
      });
      expect(putSetting.statusCode).toBe(200);

      const getSetting = await app.inject({
        method: 'GET',
        url: `/api/v1/admin/settings/${adminSettingKey}`,
        headers: { authorization: `Bearer ${adminAccessToken}` },
      });
      expect(getSetting.statusCode).toBe(200);
      expect(JSON.parse(getSetting.body).data.value).toEqual({ maxReveals: 7 });

      // 4. Staff Roles & Users
      const createRole = await app.inject({
        method: 'POST',
        url: '/api/v1/admin/staff/roles',
        headers: { authorization: `Bearer ${adminAccessToken}` },
        payload: { name: staffRoleName, permissions: ['moderation:read'] },
      });
      expect(createRole.statusCode).toBe(201);
      const roleId = JSON.parse(createRole.body).data.id;

      const createStaff = await app.inject({
        method: 'POST',
        url: '/api/v1/admin/staff',
        headers: { authorization: `Bearer ${adminAccessToken}` },
        payload: {
          email: staffEmail,
          password: 'StaffPassword!2026',
          fullName: 'E2E Staff',
          roleId,
        },
      });
      expect(createStaff.statusCode).toBe(201);
      const staffData = JSON.parse(createStaff.body).data;
      expect(staffData.passwordHash).toBeUndefined();
    });
  });
});
