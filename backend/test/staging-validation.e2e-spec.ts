const METRICS_TOKEN = 'staging-e2e-metrics-bearer-token-9876543210';
const WEBHOOK_SECRET = 'staging-e2e-cloudflare-stream-webhook-secret-12345';
process.env.METRICS_AUTH_TOKEN = METRICS_TOKEN;
process.env.CLOUDFLARE_STREAM_WEBHOOK_SECRET = WEBHOOK_SECRET;

import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import * as crypto from 'crypto';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { AppModule } = require('../src/app.module');
import { HttpExceptionFilter } from '../src/core/filters/http-exception.filter';
import { TransformInterceptor } from '../src/core/interceptors/transform.interceptor';
import { LoggingInterceptor } from '../src/core/interceptors/logging.interceptor';
import { RedisService } from '../src/core/redis/redis.service';
import { PrismaService } from '../src/core/database/prisma.service';
import { SMS_GATEWAY_ADAPTER } from '../src/modules/auth/adapters/sms-gateway.interface';
import { MockSmsAdapter } from '../src/modules/auth/adapters/mock-sms.adapter';

describe('Staging Validation E2E (Real PostgreSQL/PostGIS + Real Redis)', () => {
  let app: NestFastifyApplication;
  let redis: RedisService;
  let prisma: PrismaService;
  let smsAdapter: MockSmsAdapter;

  const metricsToken = METRICS_TOKEN;
  const webhookSecret = WEBHOOK_SECRET;

  beforeAll(async () => {
    const fastifyAdapter = new FastifyAdapter({
      logger: false,
      trustProxy: 1,
    });

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      fastifyAdapter,
      { rawBody: true },
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
        'metrics',
      ],
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    redis = app.get(RedisService);
    prisma = app.get(PrismaService);
    smsAdapter = app.get(SMS_GATEWAY_ADAPTER);
  });

  afterAll(async () => {
    delete process.env.METRICS_AUTH_TOKEN;
    delete process.env.CLOUDFLARE_STREAM_WEBHOOK_SECRET;
    await app.close();
  });

  async function loginNewDevice(phone: string, remoteAddress = '127.0.0.1') {
    await redis.del(`otp:cooldown:${phone}`);
    await redis.del(`otp:ratelimit:phone:${phone}`);
    await redis.del(`otp:ratelimit:ip:${remoteAddress}`);

    const sendRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/send',
      remoteAddress,
      payload: { phone },
    });
    expect(sendRes.statusCode).toBe(200);

    const code = smsAdapter.getLastSentCode(phone);
    expect(code).toBeDefined();

    const verifyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/otp/verify',
      remoteAddress,
      payload: { phone, code },
    });
    expect(verifyRes.statusCode).toBe(200);
    return JSON.parse(verifyRes.body).data;
  }

  describe('Phase 10: Health & Metrics Authentication (Real Infrastructure)', () => {
    it('GET /health/live and /health/ready return 200 with healthy PostGIS and dual Redis', async () => {
      const liveRes = await app.inject({ method: 'GET', url: '/health/live' });
      expect(liveRes.statusCode).toBe(200);
      expect(JSON.parse(liveRes.body).data.status).toBe('ok');

      const readyRes = await app.inject({
        method: 'GET',
        url: '/health/ready',
      });
      expect(readyRes.statusCode).toBe(200);
      const readyBody = JSON.parse(readyRes.body);
      expect(readyBody.success).toBe(true);
      expect(readyBody.data.checks.database).toBe('up');
      expect(readyBody.data.checks.postgis).toContain('up');
      expect(readyBody.data.checks.redis_cache).toBe('up');
      expect(readyBody.data.checks.redis_queue).toBe('up');
    });

    it('GET /metrics rejects unauthenticated callers (401) and accepts valid Bearer token (200)', async () => {
      const unauth = await app.inject({ method: 'GET', url: '/metrics' });
      expect(unauth.statusCode).toBe(401);

      const wrong = await app.inject({
        method: 'GET',
        url: '/metrics',
        headers: { authorization: 'Bearer wrong-token' },
      });
      expect(wrong.statusCode).toBe(401);

      const ok = await app.inject({
        method: 'GET',
        url: '/metrics',
        headers: { authorization: `Bearer ${metricsToken}` },
      });
      expect(ok.statusCode).toBe(200);
      expect(ok.body).toContain('process_uptime_seconds');
    });
  });

  describe('Phase 6: Logout & Immediate Redis Access-Token Revocation', () => {
    it('should immediately revoke access token & refresh token on logout while preserving Device B', async () => {
      const phone = `+2010${Math.floor(10000000 + Math.random() * 89999999)}`;
      const deviceA = await loginNewDevice(phone, '10.10.1.1');
      const deviceB = await loginNewDevice(phone, '10.10.1.2');

      // 1. Device A authenticated call succeeds
      const meBefore = await app.inject({
        method: 'GET',
        url: '/api/v1/auth/me',
        headers: { authorization: `Bearer ${deviceA.tokens.accessToken}` },
      });
      expect(meBefore.statusCode).toBe(200);

      // 2. Device A calls logout with refreshToken + Authorization Bearer
      const logoutRes = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/logout',
        headers: { authorization: `Bearer ${deviceA.tokens.accessToken}` },
        payload: { refreshToken: deviceA.tokens.refreshToken },
      });
      expect(logoutRes.statusCode).toBe(200);

      // 3. Verify Redis denylist TTL was set
      const cacheClient = redis.getCacheClient();
      expect(cacheClient).not.toBeNull();
      const ttl = await cacheClient!.ttl(
        `auth:revoked:sid:${deviceA.tokens.sessionId}`,
      );
      expect(ttl).toBeGreaterThan(0);
      expect(ttl).toBeLessThanOrEqual(900);

      // 4. Reusing Device A's original access token is immediately rejected (401)
      const meAfter = await app.inject({
        method: 'GET',
        url: '/api/v1/auth/me',
        headers: { authorization: `Bearer ${deviceA.tokens.accessToken}` },
      });
      expect(meAfter.statusCode).toBe(401);

      // 5. Reusing Device A's refresh token is rejected (401)
      const refreshAfter = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/refresh',
        payload: { refreshToken: deviceA.tokens.refreshToken },
      });
      expect(refreshAfter.statusCode).toBe(401);

      // 6. Duplicate logout is idempotent (200)
      const dupLogout = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/logout',
        payload: { refreshToken: deviceA.tokens.refreshToken },
      });
      expect(dupLogout.statusCode).toBe(200);

      // 7. Device B remains completely unaffected (200)
      const deviceBMe = await app.inject({
        method: 'GET',
        url: '/api/v1/auth/me',
        headers: { authorization: `Bearer ${deviceB.tokens.accessToken}` },
      });
      expect(deviceBMe.statusCode).toBe(200);
    });
  });

  describe('Phase 4 & 5: TRUST_PROXY Spoofing Resistance & Real Redis Atomic Rate Limiting', () => {
    it('should enforce atomic Redis Lua rate limits with preserved TTL under concurrent load', async () => {
      const key = `staging:atomic:${crypto.randomUUID()}`;
      const results = await Promise.all([
        redis.checkRateLimit(key, 3, 120),
        redis.checkRateLimit(key, 3, 120),
        redis.checkRateLimit(key, 3, 120),
        redis.checkRateLimit(key, 3, 120),
        redis.checkRateLimit(key, 3, 120),
      ]);

      const allowedCount = results.filter((r) => r.allowed).length;
      const blockedCount = results.filter((r) => !r.allowed).length;
      expect(allowedCount).toBe(3);
      expect(blockedCount).toBe(2);

      const ttl = await redis.getCacheClient()!.ttl(key);
      expect(ttl).toBeGreaterThan(0);
      expect(ttl).toBeLessThanOrEqual(120);
      await redis.del(key);
    });

    it('should ignore spoofed leftmost X-Forwarded-For under trustProxy=1 and isolate separate clients', async () => {
      const clientA = '198.51.100.41';
      const clientB = '198.51.100.42';
      const phone = `+2010${Math.floor(10000000 + Math.random() * 89999999)}`;

      // Clean any prior keys
      await redis.del(`ratelimit:ip:${clientA}:auth:login`);
      await redis.del(`ratelimit:ip:${clientB}:auth:login`);
      await redis.del(`auth:ratelimit:login:account:${phone}`);

      // Attacker sends different spoofed leftmost XFF on every request,
      // while trusted proxy (1 hop) appends real client IP clientA at the right
      let lastStatus = 0;
      let retryAfterHeader: string | undefined;
      for (let i = 0; i < 6; i++) {
        const res = await app.inject({
          method: 'POST',
          url: '/api/v1/auth/login',
          headers: {
            'x-forwarded-for': `203.0.113.${i + 1}, ${clientA}`,
          },
          payload: {
            phone: `+2010${Math.floor(10000000 + Math.random() * 89999999)}`,
            password: 'WrongPassword!123',
          },
        });
        lastStatus = res.statusCode;
        retryAfterHeader = res.headers['retry-after'] as string | undefined;
      }

      // 6th request from clientA hits IP rate limit (default anonymous limit = 5 via RATE_LIMIT_LOGIN_MAX or 10)
      // Trigger up to 11 to guarantee hitting default anonymousLimit=10 regardless of env
      for (let i = 6; i < 12 && lastStatus !== 429; i++) {
        const res = await app.inject({
          method: 'POST',
          url: '/api/v1/auth/login',
          headers: {
            'x-forwarded-for': `203.0.113.${i + 1}, ${clientA}`,
          },
          payload: {
            phone: `+2010${Math.floor(10000000 + Math.random() * 89999999)}`,
            password: 'WrongPassword!123',
          },
        });
        lastStatus = res.statusCode;
        retryAfterHeader = res.headers['retry-after'] as string | undefined;
      }

      expect(lastStatus).toBe(429);
      expect(Number(retryAfterHeader)).toBeGreaterThan(0);

      // Separate clientB is NOT blocked by clientA's rate limit
      const clientBRes = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/login',
        headers: {
          'x-forwarded-for': clientB,
        },
        payload: {
          phone: `+2010${Math.floor(10000000 + Math.random() * 89999999)}`,
          password: 'WrongPassword!123',
        },
      });
      expect(clientBRes.statusCode).toBe(401);
    });
  });

  describe('Phase 5: Real Video Webhook Replay Protection & Listings Feed Contract', () => {
    it('should verify HMAC signature, reject replay/expired timestamps, and deduplicate via real Redis', async () => {
      const payload = {
        uid: `stream_e2e_${crypto.randomBytes(6).toString('hex')}`,
        readyToStream: true,
      };
      const rawBody = JSON.stringify(payload);
      const freshTs = Math.floor(Date.now() / 1000);
      const validSig = crypto
        .createHmac('sha256', webhookSecret)
        .update(`${freshTs}.${rawBody}`)
        .digest('hex');

      // 1. Valid fresh webhook succeeds
      const first = await app.inject({
        method: 'POST',
        url: '/api/v1/media/video/webhook',
        headers: {
          'content-type': 'application/json',
          'webhook-signature': `time=${freshTs},sig1=${validSig}`,
        },
        payload: rawBody,
      });
      expect(first.statusCode).toBe(200);
      expect(JSON.parse(first.body).data).toEqual({ received: true });

      // 2. Duplicate / replay of same signed webhook is deduplicated via real Redis
      const dup = await app.inject({
        method: 'POST',
        url: '/api/v1/media/video/webhook',
        headers: {
          'content-type': 'application/json',
          'webhook-signature': `time=${freshTs},sig1=${validSig}`,
        },
        payload: rawBody,
      });
      expect(dup.statusCode).toBe(200);
      expect(JSON.parse(dup.body).data).toEqual({
        received: true,
        duplicate: true,
      });

      // 3. Expired timestamp is rejected (401)
      const oldTs = freshTs - 600;
      const oldSig = crypto
        .createHmac('sha256', webhookSecret)
        .update(`${oldTs}.${rawBody}`)
        .digest('hex');
      const expired = await app.inject({
        method: 'POST',
        url: '/api/v1/media/video/webhook',
        headers: {
          'content-type': 'application/json',
          'webhook-signature': `time=${oldTs},sig1=${oldSig}`,
        },
        payload: rawBody,
      });
      expect(expired.statusCode).toBe(401);

      // 4. Invalid signature is rejected (401)
      const invalid = await app.inject({
        method: 'POST',
        url: '/api/v1/media/video/webhook',
        headers: {
          'content-type': 'application/json',
          'webhook-signature': `time=${freshTs},sig1=${'b'.repeat(64)}`,
        },
        payload: rawBody,
      });
      expect(invalid.statusCode).toBe(401);
    });

    it('GET /api/v1/listings preserves Flutter contract { success, data, meta } without duplicate items', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/listings?limit=5',
      });
      expect(res.statusCode).toBe(200);
      const body = JSON.parse(res.body);
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data)).toBe(true);
      expect(body.items).toBeUndefined();
      expect(body.meta).toEqual(
        expect.objectContaining({
          limit: 5,
          hasMore: expect.any(Boolean),
        }),
      );
      expect('nextCursor' in body.meta).toBe(true);
      expect('next_cursor' in body.meta).toBe(true);

      // Ensure Prisma PostGIS query works
      const postgis = await prisma.checkPostgisSupport();
      expect(postgis.supported).toBe(true);
    });
  });
});
