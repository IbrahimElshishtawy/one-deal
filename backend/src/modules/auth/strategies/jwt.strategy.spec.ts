import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { JwtStrategy } from './jwt.strategy';
import { SessionService } from '../services/session.service';

describe('JwtStrategy & Redis Access Token Revocation', () => {
  let strategy: JwtStrategy;
  let sessionService: SessionService;
  let redisStore: Map<string, any>;

  const mockPrisma = {
    user: {
      findUnique: jest.fn(),
    },
    userSession: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      create: jest.fn(),
    },
  };

  const mockConfig = {
    get: jest.fn((key: string, defaultValue?: any) => {
      if (key === 'JWT_ACCESS_SECRET') {
        return '9f4a2c8e1b7d6035a9c8e7f2b4d16803e5a7c9f1b2d4e6a8c0f2b4d6e8a0c2f4';
      }
      return defaultValue;
    }),
  } as unknown as ConfigService;

  const mockAudit = {
    logEvent: jest.fn().mockResolvedValue(undefined),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    redisStore = new Map();
    const mockRedis = {
      get: jest.fn(async (key: string) => redisStore.get(key) ?? null),
      set: jest.fn(async (key: string, val: any) => {
        redisStore.set(key, val);
      }),
      del: jest.fn(async (key: string) => {
        redisStore.delete(key);
      }),
    };

    const jwtService = new JwtService({
      secret:
        '9f4a2c8e1b7d6035a9c8e7f2b4d16803e5a7c9f1b2d4e6a8c0f2b4d6e8a0c2f4',
    });

    sessionService = new SessionService(
      mockPrisma as any,
      jwtService,
      mockConfig,
      mockAudit as any,
      mockRedis as any,
    );

    strategy = new JwtStrategy(mockConfig, mockPrisma as any, sessionService);

    mockPrisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      phone: '+201012345678',
      fullName: 'Test User',
      isActive: true,
      deletedAt: null,
    });
  });

  it('should allow valid non-revoked access token', async () => {
    const result = await strategy.validate({
      sub: 'user-1',
      phone: '+201012345678',
      role: 'USER',
      sid: 'session-device-a',
      jti: 'jti-1',
      iat: Math.floor(Date.now() / 1000),
    });

    expect(result.id).toBe('user-1');
    expect(result.sessionId).toBe('session-device-a');
  });

  it('should immediately reject access token after logout revokes its session', async () => {
    mockPrisma.userSession.findFirst.mockResolvedValue({
      id: 'session-device-a',
      userId: 'user-1',
      isRevoked: false,
    });
    mockPrisma.userSession.update.mockResolvedValue({
      id: 'session-device-a',
      isRevoked: true,
    });

    await sessionService.revokeSessionByToken('raw-refresh-token', 'user-1');

    await expect(
      strategy.validate({
        sub: 'user-1',
        phone: '+201012345678',
        role: 'USER',
        sid: 'session-device-a',
        jti: 'jti-1',
        iat: Math.floor(Date.now() / 1000),
      }),
    ).rejects.toThrow(UnauthorizedException);

    // Multi-device: Device B session must remain valid!
    const deviceB = await strategy.validate({
      sub: 'user-1',
      phone: '+201012345678',
      role: 'USER',
      sid: 'session-device-b',
      jti: 'jti-2',
      iat: Math.floor(Date.now() / 1000),
    });
    expect(deviceB.sessionId).toBe('session-device-b');
  });

  it('should reject all prior access tokens after revokeAllUserSessions while allowing newly issued tokens', async () => {
    mockPrisma.userSession.updateMany.mockResolvedValue({ count: 2 });
    const oldIat = Math.floor(Date.now() / 1000) - 10;

    await sessionService.revokeAllUserSessions('user-1');

    await expect(
      strategy.validate({
        sub: 'user-1',
        phone: '+201012345678',
        role: 'USER',
        sid: 'session-old',
        jti: 'jti-old',
        iat: oldIat,
      }),
    ).rejects.toThrow(UnauthorizedException);

    // A token issued strictly after revocation timestamp is accepted
    const newToken = await strategy.validate({
      sub: 'user-1',
      phone: '+201012345678',
      role: 'USER',
      sid: 'session-new',
      jti: 'jti-new',
      iat: Math.floor(Date.now() / 1000) + 5,
    });
    expect(newToken.sessionId).toBe('session-new');
  });

  it('should revoke other devices on revokeOtherUserSessions while preserving current device', async () => {
    mockPrisma.userSession.findMany.mockResolvedValue([
      { id: 'session-other-1' },
      { id: 'session-other-2' },
    ]);
    mockPrisma.userSession.updateMany.mockResolvedValue({ count: 2 });

    await sessionService.revokeOtherUserSessions('user-1', 'session-current');

    await expect(
      strategy.validate({
        sub: 'user-1',
        phone: '+201012345678',
        role: 'USER',
        sid: 'session-other-1',
      }),
    ).rejects.toThrow(UnauthorizedException);

    const current = await strategy.validate({
      sub: 'user-1',
      phone: '+201012345678',
      role: 'USER',
      sid: 'session-current',
    });
    expect(current.sessionId).toBe('session-current');
  });
});
