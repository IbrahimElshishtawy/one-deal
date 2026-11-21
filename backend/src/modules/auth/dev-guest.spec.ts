import { ForbiddenException } from '@nestjs/common';
import { validateEnv } from '../../core/config/env.config';
import { AuthService } from './auth.service';

describe('Development Guest Auth & Production Fail-Closed Safety', () => {
  const createAuthService = (envOverrides: Record<string, any>) => {
    const prisma: any = {
      user: {
        upsert: jest.fn().mockResolvedValue({
          id: 'dev-guest-user-id',
          phone: '+201000000001',
          email: 'dev.guest@dealone.local',
          fullName: 'مصطفى هيكل',
          avatarUrl: null,
          isPhoneVerified: true,
          isDemo: true,
        }),
      },
      account: {
        upsert: jest.fn().mockResolvedValue({
          id: 'dev-guest-acc-id',
          accountType: 'individual',
          displayName: 'مصطفى هيكل',
        }),
      },
      accountMember: {
        upsert: jest.fn().mockResolvedValue({}),
      },
    };
    const sessionService: any = {
      createSession: jest.fn().mockResolvedValue({
        accessToken: 'jwt-access-dev',
        refreshToken: 'jwt-refresh-dev',
        expiresIn: 900,
        sessionId: 'sess-dev-1',
      }),
    };
    const securityAudit: any = {
      logEvent: jest.fn().mockResolvedValue(undefined),
    };
    const configService: any = {
      get: jest.fn((key: string, def?: any) =>
        key in envOverrides ? envOverrides[key] : def,
      ),
    };

    return new AuthService(
      prisma,
      {} as any,
      {} as any,
      sessionService,
      securityAudit,
      undefined,
      configService,
    );
  };

  it('rejects ENABLE_DEV_AUTH_BYPASS=true in production at config validation time (fail-closed)', () => {
    expect(() =>
      validateEnv({
        NODE_ENV: 'production',
        DATABASE_URL: 'postgresql://u:p@host:5432/db',
        CORS_ORIGIN: 'https://dealone.eg',
        JWT_ACCESS_SECRET: 'a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6q7R8s9T0',
        JWT_REFRESH_SECRET: 'z9Y8x7W6v5U4t3S2r1Q0p9O8n7M6l5K4j3I2h1G0',
        ENABLE_DEV_AUTH_BYPASS: 'true',
      }),
    ).toThrow(/ENABLE_DEV_AUTH_BYPASS/);
  });

  it('blocks dev-guest login in production even if bypass flag is forced', async () => {
    const service = createAuthService({
      NODE_ENV: 'production',
      ENABLE_DEV_AUTH_BYPASS: true,
    });
    await expect(service.authenticateDevGuest()).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('blocks dev-guest login in development when ENABLE_DEV_AUTH_BYPASS is false', async () => {
    const service = createAuthService({
      NODE_ENV: 'development',
      ENABLE_DEV_AUTH_BYPASS: false,
    });
    await expect(service.authenticateDevGuest()).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('issues non-admin USER JWT session in development when ENABLE_DEV_AUTH_BYPASS is true', async () => {
    const service = createAuthService({
      NODE_ENV: 'development',
      ENABLE_DEV_AUTH_BYPASS: true,
    });
    const res = await service.authenticateDevGuest(
      'FlutterApp/1.0',
      '127.0.0.1',
    );
    expect(res.isDemoGuest).toBe(true);
    expect(res.user.role).toBe('USER');
    expect(res.user.isDemo).toBe(true);
    expect(res.tokens.accessToken).toBe('jwt-access-dev');
  });
});
