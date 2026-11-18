import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException, BadRequestException } from '@nestjs/common';
import * as argon2 from 'argon2';
import { AuthService } from './auth.service';
import { PrismaService } from '../../core/database/prisma.service';
import { PhoneNormalizationService } from '../../core/identity/phone-normalization.service';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { OtpService } from './services/otp.service';
import { SessionService } from './services/session.service';

describe('AuthService (Phase 03 Modular Architecture)', () => {
  let service: AuthService;

  const mockPrisma = {
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    account: {
      create: jest.fn(),
    },
    accountMember: {
      create: jest.fn(),
      findFirst: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const mockPhoneNormalization = {
    normalize: jest.fn((phone: string) => {
      if (phone.includes('01012345678')) return '+201012345678';
      return phone;
    }),
  };

  const mockOtpService = {
    requestOtp: jest.fn(),
    resendOtp: jest.fn(),
    verifyOtp: jest.fn(),
  };

  const mockSessionService = {
    createSession: jest.fn(),
    rotateRefreshToken: jest.fn(),
    revokeSessionByToken: jest.fn(),
    revokeAllUserSessions: jest.fn(),
    revokeOtherUserSessions: jest.fn(),
    getUserActiveSessions: jest.fn(),
  };

  const mockSecurityAudit = {
    logEvent: jest.fn().mockResolvedValue(undefined),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrisma },
        {
          provide: PhoneNormalizationService,
          useValue: mockPhoneNormalization,
        },
        { provide: OtpService, useValue: mockOtpService },
        { provide: SessionService, useValue: mockSessionService },
        { provide: SecurityAuditService, useValue: mockSecurityAudit },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    jest.clearAllMocks();
  });

  describe('sendOtp & resendOtp', () => {
    it('should delegate to OtpService.requestOtp with normalized parameters', async () => {
      mockOtpService.requestOtp.mockResolvedValue({
        success: true,
        message: 'dispatched',
        cooldownSeconds: 60,
      });

      const res = await service.sendOtp({ phone: '01012345678' });
      expect(res.success).toBe(true);
      expect(mockOtpService.requestOtp).toHaveBeenCalledWith(
        '01012345678',
        'AUTH',
        undefined,
        undefined,
        undefined,
      );
    });

    it('should delegate to OtpService.resendOtp', async () => {
      mockOtpService.resendOtp.mockResolvedValue({
        success: true,
        message: 'resent',
        cooldownSeconds: 60,
      });

      const res = await service.resendOtp({ phone: '01012345678' });
      expect(res.success).toBe(true);
      expect(mockOtpService.resendOtp).toHaveBeenCalled();
    });
  });

  describe('verifyOtp', () => {
    it('should verify OTP and register User + default Individual Account when user is new', async () => {
      mockOtpService.verifyOtp.mockResolvedValue({
        normalizedPhone: '+201012345678',
      });
      mockPrisma.user.findUnique.mockResolvedValue(null); // New user

      const mockNewUser = {
        id: 'new-user-uuid',
        phone: '+201012345678',
        fullName: 'مستخدم 5678',
        isPhoneVerified: true,
        isActive: true,
      };

      const mockNewAccount = {
        id: 'new-account-uuid',
        accountType: 'individual',
        displayName: 'مستخدم 5678',
        slug: 'user-new-slug',
        verificationStatus: 'approved',
      };

      // Mock transaction
      mockPrisma.$transaction.mockImplementation(async (callback: any) => {
        const tx = {
          user: { create: jest.fn().mockResolvedValue(mockNewUser) },
          account: { create: jest.fn().mockResolvedValue(mockNewAccount) },
          accountMember: { create: jest.fn().mockResolvedValue({}) },
        };
        return callback(tx);
      });

      mockSessionService.createSession.mockResolvedValue({
        accessToken: 'signed.access.token',
        refreshToken: 'raw.refresh.token',
        expiresIn: 900,
        sessionId: 'session-123',
      });

      const result = await service.verifyOtp({
        phone: '01012345678',
        code: '123456',
      });

      expect(result.user.id).toBe('new-user-uuid');
      expect(result.activeAccount).toEqual({
        id: 'new-account-uuid',
        accountType: 'individual',
        displayName: 'مستخدم 5678',
        role: 'owner',
      });
      expect(result.tokens.accessToken).toBe('signed.access.token');
    });

    it('should verify OTP and return tokens for existing active user', async () => {
      mockOtpService.verifyOtp.mockResolvedValue({
        normalizedPhone: '+201012345678',
      });

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'existing-user-uuid',
        phone: '+201012345678',
        fullName: 'Existing User',
        isPhoneVerified: true,
        isActive: true,
        deletedAt: null,
      });

      mockPrisma.accountMember.findFirst.mockResolvedValue({
        accountId: 'existing-account-uuid',
        role: 'owner',
        account: {
          id: 'existing-account-uuid',
          accountType: 'individual',
          displayName: 'Existing User',
        },
      });

      mockSessionService.createSession.mockResolvedValue({
        accessToken: 'existing.access.token',
        refreshToken: 'existing.refresh.token',
        expiresIn: 900,
        sessionId: 'session-existing',
      });

      const result = await service.verifyOtp({
        phone: '01012345678',
        code: '123456',
      });

      expect(result.user.id).toBe('existing-user-uuid');
      expect(result.activeAccount?.id).toBe('existing-account-uuid');
      expect(result.tokens.accessToken).toBe('existing.access.token');
    });

    it('should throw UnauthorizedException if existing user is deactivated', async () => {
      mockOtpService.verifyOtp.mockResolvedValue({
        normalizedPhone: '+201012345678',
      });

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'inactive-user',
        isActive: false,
      });

      await expect(
        service.verifyOtp({ phone: '01012345678', code: '123456' }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('loginWithPassword', () => {
    it('should authenticate user with valid Argon2 password hash', async () => {
      const hash = await argon2.hash('SecretPass123!');

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-pass-id',
        phone: '+201012345678',
        fullName: 'Password User',
        passwordHash: hash,
        isActive: true,
        deletedAt: null,
      });

      mockPrisma.accountMember.findFirst.mockResolvedValue(null);

      mockSessionService.createSession.mockResolvedValue({
        accessToken: 'pass.access.token',
        refreshToken: 'pass.refresh.token',
        expiresIn: 900,
        sessionId: 'session-pass',
      });

      const result = await service.loginWithPassword({
        phone: '01012345678',
        password: 'SecretPass123!',
      });

      expect(result.user.id).toBe('user-pass-id');
      expect(result.tokens.accessToken).toBe('pass.access.token');
    });

    it('should throw UnauthorizedException on invalid password', async () => {
      const hash = await argon2.hash('RealPassword123!');

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-pass-id',
        phone: '+201012345678',
        passwordHash: hash,
        isActive: true,
        deletedAt: null,
      });

      await expect(
        service.loginWithPassword({
          phone: '01012345678',
          password: 'WrongPassword999!',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should return identical generic error for suspended account to prevent status enumeration', async () => {
      const hash = await argon2.hash('RealPassword123!');

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-suspended-id',
        phone: '+201012345678',
        passwordHash: hash,
        isActive: false,
        deletedAt: null,
      });

      await expect(
        service.loginWithPassword({
          phone: '01012345678',
          password: 'RealPassword123!',
        }),
      ).rejects.toThrow('Invalid phone number or password.');
    });

    it('should enforce per-account distributed rate limit when RedisService rejects repeated login attempts', async () => {
      const mockRedis = {
        checkRateLimit: jest.fn().mockResolvedValue({
          allowed: false,
          remaining: 0,
          resetSeconds: 120,
        }),
        del: jest.fn(),
      };
      const rateLimitedService = new AuthService(
        mockPrisma as any,
        mockPhoneNormalization as any,
        mockOtpService as any,
        mockSessionService as any,
        mockSecurityAudit as any,
        mockRedis as any,
      );

      await expect(
        rateLimitedService.loginWithPassword({
          phone: '01012345678',
          password: 'WrongPassword999!',
        }),
      ).rejects.toThrow(/Too many login attempts/);
    });
  });

  describe('Session Management & Rotation Delegation', () => {
    it('should delegate refreshToken to SessionService', async () => {
      mockSessionService.rotateRefreshToken.mockResolvedValue({
        accessToken: 'new.access',
        refreshToken: 'new.refresh',
      });

      const res = await service.refreshToken({ refreshToken: 'old.refresh' });
      expect(res.accessToken).toBe('new.access');
      expect(mockSessionService.rotateRefreshToken).toHaveBeenCalledWith(
        'old.refresh',
        undefined,
        undefined,
        undefined,
      );
    });

    it('should delegate logout to SessionService', async () => {
      mockSessionService.revokeSessionByToken.mockResolvedValue({
        success: true,
        message: 'revoked',
      });

      const res = await service.logout(
        { refreshToken: 'token.to.revoke' },
        'user-1',
      );
      expect(res.success).toBe(true);
      expect(mockSessionService.revokeSessionByToken).toHaveBeenCalledWith(
        'token.to.revoke',
        'user-1',
        undefined,
      );
    });

    it('should delegate terminateAllSessions to SessionService', async () => {
      mockSessionService.revokeAllUserSessions.mockResolvedValue({
        success: true,
        revokedCount: 2,
      });

      const res = await service.terminateAllSessions('user-1');
      expect(res.success).toBe(true);
      expect(mockSessionService.revokeAllUserSessions).toHaveBeenCalledWith(
        'user-1',
        undefined,
      );
    });

    it('should delegate getActiveSessions to SessionService', async () => {
      mockSessionService.getUserActiveSessions.mockResolvedValue([
        { id: 's1', ipAddress: '127.0.0.1' },
      ]);

      const res = await service.getActiveSessions('user-1');
      expect(res).toHaveLength(1);
      expect(mockSessionService.getUserActiveSessions).toHaveBeenCalledWith(
        'user-1',
      );
    });
  });

  describe('Password Management (set, change, forgot, reset)', () => {
    it('setPassword should hash and store password for OTP user without passwordHash', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-otp-1',
        passwordHash: null,
        isActive: true,
        deletedAt: null,
      });
      mockPrisma.user.update.mockResolvedValue({});

      const res = await service.setPassword('user-otp-1', {
        password: 'NewStrongPassword!2026',
      });

      expect(res.success).toBe(true);
      expect(mockPrisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-otp-1' },
        data: { passwordHash: expect.stringContaining('$argon2') },
      });
    });

    it('setPassword should reject if password is already set', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-otp-1',
        passwordHash: 'existing-hash',
        isActive: true,
        deletedAt: null,
      });

      await expect(
        service.setPassword('user-otp-1', {
          password: 'NewStrongPassword!2026',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('changePassword should verify current password, update hash, and revoke other sessions', async () => {
      const currentHash = await argon2.hash('OldPassword!2026');
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        passwordHash: currentHash,
        isActive: true,
        deletedAt: null,
      });
      mockPrisma.user.update.mockResolvedValue({});
      mockSessionService.revokeOtherUserSessions.mockResolvedValue({
        success: true,
        revokedCount: 2,
      });

      const res = await service.changePassword(
        'user-1',
        {
          currentPassword: 'OldPassword!2026',
          newPassword: 'NewPassword!2026',
        },
        'current-session-id',
      );

      expect(res.success).toBe(true);
      expect(res.revokedSessionsCount).toBe(2);
      expect(mockSessionService.revokeOtherUserSessions).toHaveBeenCalledWith(
        'user-1',
        'current-session-id',
        undefined,
      );
    });

    it('forgotPassword should return 200 generic response for both registered and unregistered numbers', async () => {
      mockPrisma.user.findUnique.mockResolvedValueOnce(null);
      const unregisteredRes = await service.forgotPassword({
        phone: '01012345678',
      });
      expect(unregisteredRes.success).toBe(true);
      expect(mockOtpService.requestOtp).not.toHaveBeenCalled();

      mockPrisma.user.findUnique.mockResolvedValueOnce({
        id: 'user-1',
        isActive: true,
        deletedAt: null,
      });
      mockOtpService.requestOtp.mockResolvedValueOnce({
        success: true,
        message: 'sent',
        cooldownSeconds: 60,
      });

      const registeredRes = await service.forgotPassword({
        phone: '01012345678',
      });
      expect(registeredRes).toEqual(unregisteredRes);
      expect(mockOtpService.requestOtp).toHaveBeenCalledWith(
        '+201012345678',
        'PASSWORD_RESET',
        undefined,
        undefined,
        undefined,
      );
    });

    it('resetPassword should verify PASSWORD_RESET OTP, hash new password, and revoke all sessions', async () => {
      mockOtpService.verifyOtp.mockResolvedValue({
        normalizedPhone: '+201012345678',
      });
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        isActive: true,
        deletedAt: null,
      });
      mockPrisma.user.update.mockResolvedValue({});
      mockSessionService.revokeAllUserSessions.mockResolvedValue({
        success: true,
        revokedCount: 3,
      });

      const res = await service.resetPassword({
        phone: '01012345678',
        code: '123456',
        newPassword: 'ResetStrongPassword!2026',
      });

      expect(res.success).toBe(true);
      expect(mockOtpService.verifyOtp).toHaveBeenCalledWith(
        '01012345678',
        '123456',
        'PASSWORD_RESET',
        undefined,
        undefined,
        undefined,
      );
      expect(mockPrisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { passwordHash: expect.stringContaining('$argon2') },
      });
      expect(mockSessionService.revokeAllUserSessions).toHaveBeenCalledWith(
        'user-1',
        undefined,
      );
    });
  });
});
