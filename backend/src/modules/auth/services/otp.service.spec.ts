import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { HttpException, BadRequestException } from '@nestjs/common';
import { OtpService } from './otp.service';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { PhoneNormalizationService } from '../../../core/identity/phone-normalization.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';
import {
  ISmsGatewayAdapter,
  SMS_GATEWAY_ADAPTER,
} from '../adapters/sms-gateway.interface';

describe('OtpService', () => {
  let service: OtpService;
  let smsAdapter: ISmsGatewayAdapter;

  const mockPrisma = {
    otp: {
      updateMany: jest.fn(),
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
  };

  const mockRedis = {
    checkRateLimit: jest
      .fn()
      .mockResolvedValue({ allowed: true, remaining: 2 }),
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(undefined),
    del: jest.fn().mockResolvedValue(undefined),
  };

  const mockConfig = {
    get: jest.fn((key: string, defaultValue?: string) => {
      if (key === 'JWT_ACCESS_SECRET') return 'test_otp_secret_key_12345';
      if (key === 'NODE_ENV') return 'test';
      return defaultValue;
    }),
  };

  const mockAudit = {
    logEvent: jest.fn().mockResolvedValue(undefined),
  };

  const mockSmsAdapter: ISmsGatewayAdapter = {
    providerName: 'MOCK_TEST_GATEWAY',
    sendOtp: jest.fn().mockResolvedValue({
      success: true,
      provider: 'MOCK_TEST_GATEWAY',
      messageId: 'mock-123',
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OtpService,
        PhoneNormalizationService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedis },
        { provide: ConfigService, useValue: mockConfig },
        { provide: SecurityAuditService, useValue: mockAudit },
        { provide: SMS_GATEWAY_ADAPTER, useValue: mockSmsAdapter },
      ],
    }).compile();

    service = module.get<OtpService>(OtpService);
    smsAdapter = module.get<ISmsGatewayAdapter>(SMS_GATEWAY_ADAPTER);
    expect(smsAdapter).toBeDefined();
    jest.clearAllMocks();
  });

  describe('requestOtp', () => {
    it('should normalize phone, check rate limits, persist hash, set cooldown, and dispatch SMS', async () => {
      mockRedis.checkRateLimit.mockResolvedValue({
        allowed: true,
        remaining: 2,
      });
      mockRedis.get.mockResolvedValue(null); // No active cooldown
      mockPrisma.otp.updateMany.mockResolvedValue({ count: 0 });
      mockPrisma.otp.create.mockResolvedValue({ id: 'otp-id' });
      (mockSmsAdapter.sendOtp as jest.Mock).mockResolvedValue({
        success: true,
        provider: 'MOCK_TEST_GATEWAY',
      });

      const result = await service.requestOtp('01012345678');

      expect(result.success).toBe(true);
      expect(result.cooldownSeconds).toBe(60);
      expect(mockPrisma.otp.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            phone: '+201012345678',
            codeHash: expect.any(String),
            isConsumed: false,
          }),
        }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'otp:cooldown:+201012345678',
        '1',
        60,
      );
      expect(mockSmsAdapter.sendOtp).toHaveBeenCalledWith(
        '+201012345678',
        expect.stringMatching(/^\d{6}$/),
      );
    });

    it('should throw HTTP 429 when cooldown is active', async () => {
      mockRedis.checkRateLimit.mockResolvedValue({
        allowed: true,
        remaining: 1,
      });
      mockRedis.get.mockResolvedValue('1'); // Cooldown active

      await expect(service.requestOtp('01012345678')).rejects.toThrow(
        HttpException,
      );
      expect(mockPrisma.otp.create).not.toHaveBeenCalled();
    });

    it('should throw HTTP 429 when phone rate limit is exceeded', async () => {
      mockRedis.checkRateLimit.mockResolvedValue({
        allowed: false,
        remaining: 0,
      });

      await expect(service.requestOtp('01012345678')).rejects.toThrow(
        HttpException,
      );
    });
  });

  describe('verifyOtp', () => {
    it('should verify correct OTP code and atomically consume it', async () => {
      const code = '742918';
      const validHash = service.hashOtp(code);

      mockPrisma.otp.findFirst.mockResolvedValue({
        id: 'otp-challenge-1',
        phone: '+201012345678',
        codeHash: validHash,
        attempts: 0,
        isConsumed: false,
      });

      mockPrisma.otp.updateMany.mockResolvedValue({ count: 1 });

      const result = await service.verifyOtp('01012345678', code);

      expect(result.normalizedPhone).toBe('+201012345678');
      expect(mockPrisma.otp.updateMany).toHaveBeenCalledWith({
        where: { id: 'otp-challenge-1', isConsumed: false },
        data: { isConsumed: true },
      });
      expect(mockRedis.del).toHaveBeenCalledWith('otp:cooldown:+201012345678');
    });

    it('should increment attempt counter on incorrect code and reject', async () => {
      const correctCode = '111111';
      const validHash = service.hashOtp(correctCode);

      mockPrisma.otp.findFirst.mockResolvedValue({
        id: 'otp-challenge-1',
        phone: '+201012345678',
        codeHash: validHash,
        attempts: 1,
        isConsumed: false,
      });

      mockPrisma.otp.update.mockResolvedValue({});

      await expect(service.verifyOtp('01012345678', '999999')).rejects.toThrow(
        BadRequestException,
      );

      expect(mockPrisma.otp.update).toHaveBeenCalledWith({
        where: { id: 'otp-challenge-1' },
        data: { attempts: { increment: 1 } },
      });
    });

    it('should lockout challenge when attempts reach 5', async () => {
      mockPrisma.otp.findFirst.mockResolvedValue({
        id: 'otp-challenge-1',
        phone: '+201012345678',
        codeHash: 'some_hash',
        attempts: 5,
        isConsumed: false,
      });

      mockPrisma.otp.update.mockResolvedValue({});

      await expect(service.verifyOtp('01012345678', '123456')).rejects.toThrow(
        BadRequestException,
      );

      expect(mockPrisma.otp.update).toHaveBeenCalledWith({
        where: { id: 'otp-challenge-1' },
        data: { isConsumed: true },
      });
    });

    it('should prevent concurrent race conditions when atomic update returns count 0', async () => {
      const code = '555555';
      const validHash = service.hashOtp(code);

      mockPrisma.otp.findFirst.mockResolvedValue({
        id: 'otp-challenge-1',
        phone: '+201012345678',
        codeHash: validHash,
        attempts: 0,
        isConsumed: false,
      });

      // Another concurrent process consumed it first!
      mockPrisma.otp.updateMany.mockResolvedValue({ count: 0 });

      await expect(service.verifyOtp('01012345678', code)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should allow only ONE winner under simultaneous Promise.all OTP verification load', async () => {
      const code = '654321';
      const validHash = service.hashOtp(code);
      let consumed = false;

      mockPrisma.otp.findFirst.mockResolvedValue({
        id: 'otp-race-1',
        phone: '+201012345678',
        codeHash: validHash,
        attempts: 0,
        isConsumed: false,
      });

      mockPrisma.otp.updateMany.mockImplementation(async () => {
        if (!consumed) {
          consumed = true;
          return { count: 1 };
        }
        return { count: 0 };
      });

      const results = await Promise.allSettled(
        Array.from({ length: 5 }, () => service.verifyOtp('01012345678', code)),
      );

      const fulfilled = results.filter((r) => r.status === 'fulfilled');
      const rejected = results.filter((r) => r.status === 'rejected');

      expect(fulfilled).toHaveLength(1);
      expect(rejected).toHaveLength(4);
    });
  });
});
