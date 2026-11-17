import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { SessionService } from './session.service';
import { PrismaService } from '../../../core/database/prisma.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';

describe('SessionService', () => {
  let service: SessionService;

  const mockPrisma = {
    userSession: {
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      findMany: jest.fn(),
    },
  };

  const mockJwtService = {
    sign: jest.fn().mockReturnValue('mock.jwt.signed.access.token'),
  };

  const mockConfigService = {
    get: jest.fn((key: string, defaultValue?: string) => {
      if (key === 'JWT_ACCESS_SECRET')
        return 'test_super_secret_access_jwt_key_12345';
      return defaultValue;
    }),
  };

  const mockSecurityAudit = {
    logEvent: jest.fn().mockResolvedValue(undefined),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SessionService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: SecurityAuditService, useValue: mockSecurityAudit },
      ],
    }).compile();

    service = module.get<SessionService>(SessionService);
    jest.clearAllMocks();
  });

  describe('createSession', () => {
    it('should mint signed JWT with issuer/audience and persist session with familyId', async () => {
      mockPrisma.userSession.create.mockResolvedValue({
        id: 'session-uuid-1',
        userId: 'user-uuid-1',
      });

      const result = await service.createSession(
        'user-uuid-1',
        '+201012345678',
        'USER',
        'Mozilla/5.0',
        '127.0.0.1',
      );

      expect(result.accessToken).toBe('mock.jwt.signed.access.token');
      expect(result.refreshToken).toBeDefined();
      expect(result.expiresIn).toBe(900);
      expect(result.sessionId).toBe('session-uuid-1');

      expect(mockJwtService.sign).toHaveBeenCalledWith(
        expect.objectContaining({
          sub: 'user-uuid-1',
          phone: '+201012345678',
          role: 'USER',
        }),
        expect.objectContaining({
          issuer: 'deal-one.eg',
          audience: 'deal-one-mobile',
          expiresIn: '15m',
        }),
      );

      expect(mockPrisma.userSession.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            userId: 'user-uuid-1',
            familyId: expect.any(String),
            isRevoked: false,
          }),
        }),
      );
    });
  });

  describe('rotateRefreshToken & Reuse Detection', () => {
    it('should rotate valid refresh token, revoke old session, and mint new session in same family', async () => {
      const rawToken = 'my_raw_refresh_token_12345';
      const hash = service.hashRefreshToken(rawToken);

      mockPrisma.userSession.findFirst.mockResolvedValue({
        id: 'old-session-id',
        familyId: 'family-100',
        userId: 'user-uuid-1',
        refreshTokenHash: hash,
        isRevoked: false,
        expiresAt: new Date(Date.now() + 1000000),
        userAgent: 'MobileApp',
        ipAddress: '10.0.0.1',
        user: {
          id: 'user-uuid-1',
          phone: '+201012345678',
          isActive: true,
          deletedAt: null,
        },
      });

      // Atomic revocation of old session
      mockPrisma.userSession.updateMany.mockResolvedValue({ count: 1 });
      mockPrisma.userSession.create.mockResolvedValue({
        id: 'new-session-id',
        userId: 'user-uuid-1',
      });

      const rotated = await service.rotateRefreshToken(rawToken);

      expect(rotated.sessionId).toBe('new-session-id');
      expect(mockPrisma.userSession.updateMany).toHaveBeenCalledWith({
        where: { id: 'old-session-id', isRevoked: false },
        data: expect.objectContaining({ isRevoked: true }),
      });
      // Ensure family lineage was preserved
      expect(mockPrisma.userSession.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            familyId: 'family-100',
          }),
        }),
      );
    });

    it('should DETECT REUSE and revoke all sessions in family when already-revoked token is submitted', async () => {
      const stolenToken = 'stolen_and_already_rotated_token';
      const hash = service.hashRefreshToken(stolenToken);

      mockPrisma.userSession.findFirst.mockResolvedValue({
        id: 'revoked-session-id',
        familyId: 'compromised-family-999',
        userId: 'user-uuid-victim',
        refreshTokenHash: hash,
        isRevoked: true, // ALREADY REVOKED!
        expiresAt: new Date(Date.now() + 1000000),
        user: { id: 'user-uuid-victim', isActive: true },
      });

      mockPrisma.userSession.updateMany.mockResolvedValue({ count: 3 });

      await expect(service.rotateRefreshToken(stolenToken)).rejects.toThrow(
        UnauthorizedException,
      );

      // Verify all sessions in that family were revoked
      expect(mockPrisma.userSession.updateMany).toHaveBeenCalledWith({
        where: {
          userId: 'user-uuid-victim',
          isRevoked: false,
          familyId: 'compromised-family-999',
        },
        data: { isRevoked: true },
      });

      // Verify security alert was logged
      expect(mockSecurityAudit.logEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'REFRESH_TOKEN_REUSE_DETECTED',
          metadata: expect.objectContaining({
            severity: 'HIGH_SECURITY_ALERT',
            compromisedFamilyId: 'compromised-family-999',
          }),
        }),
      );
    });

    it('should reject when concurrent race occurs (updateMany returns count 0)', async () => {
      const rawToken = 'concurrent_refresh_token';
      const hash = service.hashRefreshToken(rawToken);

      mockPrisma.userSession.findFirst.mockResolvedValue({
        id: 'session-id',
        familyId: 'family-1',
        userId: 'user-1',
        refreshTokenHash: hash,
        isRevoked: false,
        expiresAt: new Date(Date.now() + 100000),
        user: { id: 'user-1', isActive: true },
      });

      // Another request won the race
      mockPrisma.userSession.updateMany.mockResolvedValue({ count: 0 });

      await expect(service.rotateRefreshToken(rawToken)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should allow only ONE concurrent refresh token rotation under Promise.all race', async () => {
      const rawToken = 'parallel_refresh_token_race';
      const hash = service.hashRefreshToken(rawToken);
      let revoked = false;

      mockPrisma.userSession.findFirst.mockResolvedValue({
        id: 'session-race-1',
        familyId: 'family-race-1',
        userId: 'user-race-1',
        refreshTokenHash: hash,
        isRevoked: false,
        expiresAt: new Date(Date.now() + 100000),
        user: { id: 'user-race-1', phone: '+201012345678', isActive: true },
      });

      mockPrisma.userSession.updateMany.mockImplementation(async () => {
        if (!revoked) {
          revoked = true;
          return { count: 1 };
        }
        return { count: 0 };
      });
      mockPrisma.userSession.create.mockResolvedValue({
        id: 'new-rotated-session',
        userId: 'user-race-1',
      });

      const results = await Promise.allSettled(
        Array.from({ length: 5 }, () => service.rotateRefreshToken(rawToken)),
      );

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(4);
    });
  });

  describe('revokeSessionByToken', () => {
    it('should revoke session when caller is authorized owner', async () => {
      const token = 'token-to-revoke';

      mockPrisma.userSession.findFirst.mockResolvedValue({
        id: 'session-to-revoke',
        userId: 'caller-user-id',
      });
      mockPrisma.userSession.update.mockResolvedValue({});

      const result = await service.revokeSessionByToken(
        token,
        'caller-user-id',
      );
      expect(result.success).toBe(true);
      expect(mockPrisma.userSession.update).toHaveBeenCalledWith({
        where: { id: 'session-to-revoke' },
        data: { isRevoked: true },
      });
    });

    it('should reject revocation when session belongs to a different user', async () => {
      const token = 'token-to-revoke';

      mockPrisma.userSession.findFirst.mockResolvedValue({
        id: 'session-belonging-to-other',
        userId: 'different-user-id',
      });

      await expect(
        service.revokeSessionByToken(token, 'malicious-caller-id'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('revokeAllUserSessions', () => {
    it('should revoke all active sessions for user', async () => {
      mockPrisma.userSession.updateMany.mockResolvedValue({ count: 4 });

      const result = await service.revokeAllUserSessions('user-uuid-1');
      expect(result.success).toBe(true);
      expect(result.revokedCount).toBe(4);
      expect(mockPrisma.userSession.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-uuid-1', isRevoked: false },
        data: { isRevoked: true },
      });
    });
  });
});
