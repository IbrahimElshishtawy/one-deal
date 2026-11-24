import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { ModulesContainer } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import fastifyCookie from '@fastify/cookie';
import helmet from '@fastify/helmet';
import cors from '@fastify/cors';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/core/filters/http-exception.filter';
import { TransformInterceptor } from '../src/core/interceptors/transform.interceptor';
import { LoggingInterceptor } from '../src/core/interceptors/logging.interceptor';
import { MetricsInterceptor } from '../src/core/metrics/metrics.interceptor';
import {
  buildCorsOptions,
  buildHelmetOptions,
} from '../src/core/security/http-security.config';
import { PrismaService } from '../src/core/database/prisma.service';

describe('Deal One Backend Routes Audit & Stabilization (E2E)', () => {
  let app: NestFastifyApplication;
  let prisma: PrismaService;
  let jwtService: JwtService;
  let configService: ConfigService;

  const fastifyRoutes: Array<{ method: string; url: string }> = [];
  let swaggerPaths: Set<string>;

  let normalUserToken = '';
  let adminToken = '';
  let approvedSellerToken = '';

  const NIL_UUID = '00000000-0000-4000-8000-000000000000';

  const inject = async (
    method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
    url: string,
    opts: { token?: string; body?: unknown } = {},
  ) => {
    const headers: Record<string, string> = {};
    if (opts.token) headers.authorization = `Bearer ${opts.token}`;
    if (opts.body !== undefined) headers['content-type'] = 'application/json';
    const res = await app.inject({
      method,
      url,
      headers,
      payload: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
    });
    let json: any = null;
    try {
      json = JSON.parse(res.payload);
    } catch {
      json = res.payload;
    }
    return { status: res.statusCode, headers: res.headers, body: json };
  };

  beforeAll(async () => {
    const fastifyAdapter = new FastifyAdapter({
      logger: false,
      maxParamLength: 200,
    });
    const fastifyInstance = fastifyAdapter.getInstance();
    fastifyInstance.addHook('onRoute', (routeOptions) => {
      const methods = Array.isArray(routeOptions.method)
        ? routeOptions.method
        : [routeOptions.method];
      for (const m of methods) {
        if (m !== 'HEAD' && m !== 'OPTIONS') {
          fastifyRoutes.push({ method: m, url: routeOptions.url });
        }
      }
    });

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      fastifyAdapter,
      { rawBody: true },
    );

    await app.register(fastifyCookie);
    await app.register(helmet, buildHelmetOptions(true));
    await app.register(cors, buildCorsOptions('', 'development'));

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
      app.get(MetricsInterceptor),
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

    const swaggerConfig = new DocumentBuilder()
      .setTitle('Deal One API')
      .setVersion('1.0.0')
      .addBearerAuth(
        { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
        'BearerAuth',
      )
      .build();
    const swaggerDoc = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, swaggerDoc);

    swaggerPaths = new Set<string>();
    for (const [pathKey, pathItem] of Object.entries(swaggerDoc.paths || {})) {
      const normalized = pathKey.replace(/\{([^}]+)\}/g, ':$1');
      for (const method of Object.keys(pathItem as Record<string, unknown>)) {
        if (['get', 'post', 'put', 'patch', 'delete'].includes(method)) {
          swaggerPaths.add(`${method.toUpperCase()} ${normalized}`);
        }
      }
    }

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);
    configService = app.get(ConfigService);

    // Acquire normal user token via dev-guest
    const guestRes = await inject('POST', '/api/v1/auth/dev-guest', {
      body: {},
    });
    expect(guestRes.status).toBe(200);
    normalUserToken = guestRes.body.data.tokens.accessToken;

    // Acquire admin token from an active seeded staff user
    const staff = await prisma.staffUser.findFirst({
      where: { isActive: true, status: 'active', deletedAt: null },
      include: { role: true },
    });
    if (staff) {
      const adminSecret =
        configService.get<string>('ADMIN_JWT_ACCESS_SECRET') ||
        configService.get<string>('JWT_ACCESS_SECRET');
      adminToken = jwtService.sign(
        {
          sub: staff.id,
          actorType: 'staff',
          email: staff.email,
          roleId: staff.roleId,
          role: staff.role.name,
        },
        {
          secret: adminSecret,
          issuer: 'deal-one.eg',
          audience: 'deal-one-admin',
          expiresIn: '10m',
        },
      );
    }

    // Acquire an approved seller token if one exists in DB
    const approvedSeller = await prisma.user.findFirst({
      where: {
        isActive: true,
        deletedAt: null,
        moderationStatus: 'active',
        sellerStatus: 'APPROVED',
      },
      select: { id: true, phone: true },
    });
    if (approvedSeller) {
      const mobileSecret = configService.get<string>('JWT_ACCESS_SECRET');
      approvedSellerToken = jwtService.sign(
        {
          sub: approvedSeller.id,
          phone: approvedSeller.phone,
          role: 'USER',
        },
        {
          secret: mobileSecret,
          issuer: 'deal-one.eg',
          audience: 'deal-one-mobile',
          expiresIn: '10m',
        },
      );
    }
  });

  afterAll(async () => {
    await app.close();
  });

  it('1. Registers all controllers once with zero duplicates and consistent /api/v1 prefix', () => {
    const modulesContainer = app.get(ModulesContainer);
    const seenControllers = new Map<string, string[]>();

    for (const [, moduleRef] of modulesContainer.entries()) {
      const moduleName = moduleRef.metatype?.name || 'Unknown';
      for (const [, wrapper] of moduleRef.controllers.entries()) {
        const name = wrapper.metatype?.name;
        if (!name) continue;
        const list = seenControllers.get(name) || [];
        list.push(moduleName);
        seenControllers.set(name, list);
      }
    }

    expect(seenControllers.size).toBeGreaterThanOrEqual(38);
    for (const [ctrl, mods] of seenControllers.entries()) {
      expect({ ctrl, count: mods.length }).toEqual({ ctrl, count: 1 });
    }

    const apiRoutes = fastifyRoutes.filter(
      (r) => !r.url.startsWith('/api/docs'),
    );
    const seenRoutes = new Set<string>();
    for (const r of apiRoutes) {
      const key = `${r.method} ${r.url}`;
      expect(seenRoutes.has(key)).toBe(false);
      seenRoutes.add(key);

      expect(r.url).not.toContain('//');
      expect(r.url).not.toContain('/api/v1/api/v1');
      const validPrefix =
        r.url.startsWith('/api/v1/') ||
        r.url === '/api/v1' ||
        r.url.startsWith('/health/') ||
        r.url === '/metrics';
      expect({ route: key, validPrefix }).toEqual({
        route: key,
        validPrefix: true,
      });
    }
  });

  it('2. Swagger OpenAPI paths match actual registered Fastify routes (100% parity excluding /metrics)', () => {
    const apiFastifySet = new Set(
      fastifyRoutes
        .filter((r) => !r.url.startsWith('/api/docs') && r.url !== '/metrics')
        .map((r) => `${r.method} ${r.url}`),
    );

    const missingInSwagger = [...apiFastifySet].filter(
      (k) => !swaggerPaths.has(k),
    );
    const missingInFastify = [...swaggerPaths].filter(
      (k) => !apiFastifySet.has(k),
    );

    expect(missingInSwagger).toEqual([]);
    expect(missingInFastify).toEqual([]);
  });

  it('3. Public endpoints succeed without authentication and return standard envelope + trace headers', async () => {
    const publicEndpoints = [
      '/health/live',
      '/health/ready',
      '/api/v1/home',
      '/api/v1/home/featured',
      '/api/v1/home/latest',
      '/api/v1/home/recommended',
      '/api/v1/home/categories',
      '/api/v1/categories',
      '/api/v1/listings',
      '/api/v1/search?q=test',
      '/api/v1/search/suggestions?q=a',
      '/api/v1/locations/governorates',
      '/api/v1/video-feed',
      '/api/v1/cms/public',
    ];

    for (const url of publicEndpoints) {
      const res = await inject('GET', url);
      expect({ url, status: res.status }).toEqual({ url, status: 200 });
      expect(res.body.success).toBe(true);
      expect(res.headers['x-request-id']).toBeTruthy();
      expect(res.headers['x-trace-id']).toBeTruthy();
    }
  });

  it('4. Protected endpoints reject unauthenticated requests with 401 and accurate error messages', async () => {
    const userProtected = [
      '/api/v1/users/me',
      '/api/v1/auth/me',
      '/api/v1/favorites',
      '/api/v1/listings/favorites',
      '/api/v1/cart',
      '/api/v1/bookings',
      `/api/v1/bookings/${NIL_UUID}`,
      '/api/v1/rfqs',
      `/api/v1/rfqs/${NIL_UUID}`,
      '/api/v1/activity-hub',
      '/api/v1/quotas/my-usage',
      '/api/v1/notifications',
    ];

    for (const url of userProtected) {
      const res = await inject('GET', url);
      expect({ url, status: res.status }).toEqual({ url, status: 401 });
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
      expect(res.body.error.message).not.toContain('Admin authentication');
    }
  });

  it('5. Normal marketplace users are strictly rejected (403) on ALL admin endpoints including /admin/auth/me & sessions', async () => {
    const adminEndpoints: Array<['GET' | 'DELETE', string]> = [
      ['GET', '/api/v1/admin/auth/me'],
      ['GET', '/api/v1/admin/auth/sessions'],
      ['DELETE', `/api/v1/admin/auth/sessions/${NIL_UUID}`],
      ['GET', '/api/v1/admin/users'],
      ['GET', '/api/v1/admin/accounts'],
      ['GET', '/api/v1/admin/listings'],
      ['GET', '/api/v1/admin/seller-applications'],
      ['GET', '/api/v1/admin/categories'],
      ['GET', '/api/v1/admin/settings'],
      ['GET', '/api/v1/admin/staff'],
      ['GET', '/api/v1/admin/dashboard/overview'],
      ['GET', '/api/v1/admin/system/health'],
    ];

    for (const [method, url] of adminEndpoints) {
      const res = await inject(method, url, { token: normalUserToken });
      expect({ method, url, status: res.status }).toEqual({
        method,
        url,
        status: 403,
      });
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('FORBIDDEN');
    }
  });

  it('6. Seller-only endpoints block non-approved buyers/pending sellers with 403 and allow approved sellers', async () => {
    const createListingRes = await inject('POST', '/api/v1/listings', {
      token: normalUserToken,
      body: {},
    });
    expect(createListingRes.status).toBe(403);

    const dashboardRes = await inject(
      'GET',
      '/api/v1/seller-applications/dashboard',
      { token: normalUserToken },
    );
    expect(dashboardRes.status).toBe(403);

    if (approvedSellerToken) {
      const approvedDashboard = await inject(
        'GET',
        '/api/v1/seller-applications/dashboard',
        { token: approvedSellerToken },
      );
      expect(approvedDashboard.status).toBe(200);
      expect(approvedDashboard.body.success).toBe(true);
    }
  });

  it('7. REST PATCH aliases (/users/me, /listings/:id) and static-vs-param route priority (/listings/favorites) work', async () => {
    // Static route /listings/favorites must NOT be shadowed by /listings/:id
    const favRes = await inject('GET', '/api/v1/listings/favorites', {
      token: normalUserToken,
    });
    expect(favRes.status).toBe(200);
    expect(favRes.body.success).toBe(true);

    // PATCH /api/v1/users/me works identically to PUT /api/v1/users/me
    const patchMe = await inject('PATCH', '/api/v1/users/me', {
      token: normalUserToken,
      body: {},
    });
    expect(patchMe.status).toBe(200);
    expect(patchMe.body.success).toBe(true);

    // PATCH /api/v1/listings/:id is registered and protected by SellerAuthorizationGuard
    const patchListing = await inject('PATCH', `/api/v1/listings/${NIL_UUID}`, {
      token: normalUserToken,
      body: {},
    });
    expect(patchListing.status).toBe(403);
  });

  it('8. Invalid HTTP methods, invalid UUID params, and missing resources return proper 400/404 envelopes', async () => {
    // Invalid HTTP method
    const badMethod = await inject('DELETE', '/api/v1/home');
    expect(badMethod.status).toBe(404);
    expect(badMethod.body.success).toBe(false);
    expect(badMethod.body.error.code).toBe('NOT_FOUND');

    // Invalid UUIDs fail fast at ParseUUIDPipe (400 Bad Request, not DB error)
    const invalidUuidUrls = [
      '/api/v1/listings/not-a-uuid',
      '/api/v1/accounts/not-a-uuid',
      '/api/v1/accounts/not-a-uuid/branches',
    ];
    for (const url of invalidUuidUrls) {
      const res = await inject('GET', url);
      expect({ url, status: res.status }).toEqual({ url, status: 400 });
      expect(res.body.success).toBe(false);
    }

    const invalidChatUuid = await inject(
      'GET',
      '/api/v1/conversations/not-a-uuid/messages',
      { token: normalUserToken },
    );
    expect(invalidChatUuid.status).toBe(400);
    expect(invalidChatUuid.body.success).toBe(false);

    // Missing resources return 404 (including newly fixed GET /accounts/:id)
    const missingUrls = [
      `/api/v1/listings/${NIL_UUID}`,
      `/api/v1/accounts/${NIL_UUID}`,
      '/api/v1/categories/non-existent-category-slug-xyz',
      '/api/v1/cms/public/non-existent-cms-slug-xyz',
    ];
    for (const url of missingUrls) {
      const res = await inject('GET', url);
      expect({ url, status: res.status }).toEqual({ url, status: 404 });
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('NOT_FOUND');
    }
  });

  it('9. Admin endpoints validate DTOs properly and allow authorized admin staff', async () => {
    if (!adminToken) return;

    const adminMe = await inject('GET', '/api/v1/admin/auth/me', {
      token: adminToken,
    });
    expect(adminMe.status).toBe(200);
    expect(adminMe.body.success).toBe(true);

    const adminAccounts = await inject(
      'GET',
      '/api/v1/admin/accounts?verificationStatus=PENDING&accountType=BUSINESS&page=1&limit=10',
      { token: adminToken },
    );
    expect(adminAccounts.status).toBe(200);
    expect(adminAccounts.body.success).toBe(true);

    // Invalid pagination query rejected by AdminAccountsQueryDto + ValidationPipe
    const badAdminAccounts = await inject(
      'GET',
      '/api/v1/admin/accounts?page=-5',
      { token: adminToken },
    );
    expect(badAdminAccounts.status).toBe(400);
    expect(badAdminAccounts.body.error.code).toBe('VALIDATION_FAILED');
  });
});
