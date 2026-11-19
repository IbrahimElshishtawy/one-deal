import { BadRequestException, HttpException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailVerificationService } from './email-verification.service';
import { EMAIL_REDIS_KEYS } from './email.constants';

describe('EmailVerificationService', () => {
  let service: EmailVerificationService;
  let prisma: any;
  let redisStore: Map<string, any>;
  let redis: any;
  let emailService: any;
  let securityAudit: any;

  beforeEach(() => {
    redisStore = new Map();

    redis = {
      get: jest.fn(async (key: string) =>
        redisStore.has(key) ? redisStore.get(key) : null,
      ),
      set: jest.fn(async (key: string, value: any) => {
        redisStore.set(key, value);
      }),
      del: jest.fn(async (key: string) => {
        redisStore.delete(key);
      }),
      setIfNotExists: jest.fn(async (key: string, value: any) => {
        if (redisStore.has(key)) return false;
        redisStore.set(key, value);
        return true;
      }),
    };

    prisma = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn().mockResolvedValue({}),
      },
    };

    emailService = {
      getAppPublicUrl: jest
        .fn()
        .mockReturnValue('https://one-deal-cjjt-production.up.railway.app'),
      sendEmailVerification: jest.fn().mockResolvedValue({ success: true }),
      sendEmailVerifiedConfirmation: jest
        .fn()
        .mockResolvedValue({ success: true }),
      sendSecurityNotificationEmail: jest
        .fn()
        .mockResolvedValue({ success: true }),
    };

    securityAudit = {
      logEvent: jest.fn().mockResolvedValue(undefined),
    };

    const configService = {
      get: jest.fn((key: string, fallback: any) =>
        key === 'EMAIL_VERIFICATION_TTL_MINUTES' ? 30 : fallback,
      ),
    } as unknown as ConfigService;

    service = new EmailVerificationService(
      prisma,
      redis,
      emailService,
      configService,
      securityAudit,
    );
  });

  it('stores only SHA-256 token hash in Redis and sends verification email', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        fullName: 'Ibrahim',
        email: null,
        isEmailVerified: false,
        isActive: true,
        deletedAt: null,
        preferredLanguage: 'en',
      })
      .mockResolvedValueOnce(null);

    const res = await service.requestVerification('user-1', 'User@Example.com');

    expect(res.success).toBe(true);
    expect(emailService.sendEmailVerification).toHaveBeenCalledTimes(1);

    const sentPayload = emailService.sendEmailVerification.mock.calls[0][0];
    expect(sentPayload.to).toBe('user@example.com');

    const url = new URL(sentPayload.verificationUrl);
    const rawToken = url.searchParams.get('token')!;
    expect(rawToken.length).toBeGreaterThanOrEqual(32);

    // Raw token must NOT appear as a Redis key; only its SHA-256 hash
    const expectedHash = service.hashToken(rawToken);
    expect(
      redisStore.has(EMAIL_REDIS_KEYS.verificationToken(expectedHash)),
    ).toBe(true);
    expect(redisStore.has(EMAIL_REDIS_KEYS.verificationToken(rawToken))).toBe(
      false,
    );
  });

  it('verifies token once, updates User.isEmailVerified, and blocks replay', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        fullName: 'Ibrahim',
        email: null,
        isEmailVerified: false,
        isActive: true,
        deletedAt: null,
        preferredLanguage: 'ar',
      })
      .mockResolvedValueOnce(null);

    await service.requestVerification('user-1', 'ibrahim@example.com');
    const url = new URL(
      emailService.sendEmailVerification.mock.calls[0][0].verificationUrl,
    );
    const rawToken = url.searchParams.get('token')!;

    prisma.user.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        fullName: 'Ibrahim',
        email: null,
        isEmailVerified: false,
        isActive: true,
        deletedAt: null,
        preferredLanguage: 'ar',
      })
      .mockResolvedValueOnce(null);

    const verified = await service.verifyEmailToken(rawToken);
    expect(verified.success).toBe(true);
    expect(verified.isEmailVerified).toBe(true);
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { email: 'ibrahim@example.com', isEmailVerified: true },
    });
    expect(emailService.sendEmailVerifiedConfirmation).toHaveBeenCalledTimes(1);

    // Replay with the same token MUST fail
    await expect(service.verifyEmailToken(rawToken)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('rejects invalid and expired tokens', async () => {
    await expect(service.verifyEmailToken('short')).rejects.toThrow(
      BadRequestException,
    );
    await expect(
      service.verifyEmailToken('non_existent_expired_token_1234567890'),
    ).rejects.toThrow(BadRequestException);
  });

  it('enforces 60s resend cooldown and invalidates previous token on resend', async () => {
    prisma.user.findUnique.mockImplementation(async ({ where }: any) => {
      if (where.id === 'user-1') {
        return {
          id: 'user-1',
          fullName: 'Ibrahim',
          email: null,
          isEmailVerified: false,
          isActive: true,
          deletedAt: null,
          preferredLanguage: 'ar',
        };
      }
      return null;
    });

    await service.requestVerification('user-1', 'first@example.com');
    const firstToken = new URL(
      emailService.sendEmailVerification.mock.calls[0][0].verificationUrl,
    ).searchParams.get('token')!;

    // Immediate resend hits 429 cooldown
    await expect(
      service.requestVerification('user-1', 'first@example.com'),
    ).rejects.toThrow(HttpException);

    // Simulate cooldown expiry
    redisStore.delete(EMAIL_REDIS_KEYS.verificationCooldown('user-1'));

    await service.requestVerification('user-1', 'first@example.com');
    // Old token must now be invalidated
    await expect(service.verifyEmailToken(firstToken)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('prevents email enumeration when email belongs to another account', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        fullName: 'Ibrahim',
        email: null,
        isEmailVerified: false,
        isActive: true,
        deletedAt: null,
        preferredLanguage: 'en',
      })
      .mockResolvedValueOnce({ id: 'other-user-2' });

    const res = await service.requestVerification(
      'user-1',
      'taken@example.com',
    );
    expect(res.success).toBe(true);
    expect(emailService.sendEmailVerification).not.toHaveBeenCalled();
  });

  it('notifies previous verified email address on email change', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        fullName: 'Ibrahim',
        email: 'old@example.com',
        isEmailVerified: true,
        isActive: true,
        deletedAt: null,
        preferredLanguage: 'en',
      })
      .mockResolvedValueOnce(null);

    await service.requestVerification('user-1', 'new@example.com');
    const token = new URL(
      emailService.sendEmailVerification.mock.calls[0][0].verificationUrl,
    ).searchParams.get('token')!;

    prisma.user.findUnique
      .mockResolvedValueOnce({
        id: 'user-1',
        fullName: 'Ibrahim',
        email: 'old@example.com',
        isEmailVerified: true,
        isActive: true,
        deletedAt: null,
        preferredLanguage: 'en',
      })
      .mockResolvedValueOnce(null);

    await service.verifyEmailToken(token, '1.2.3.4');
    expect(emailService.sendSecurityNotificationEmail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'old@example.com',
        eventKind: 'EMAIL_CHANGED',
      }),
    );
  });
});
