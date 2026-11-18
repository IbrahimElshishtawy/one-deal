import { Test, TestingModule } from '@nestjs/testing';
import { SecurityAuditService } from './security-audit.service';
import { PrismaService } from '../database/prisma.service';

describe('SecurityAuditService', () => {
  let service: SecurityAuditService;
  const mockPrisma = {
    auditLog: {
      create: jest.fn().mockResolvedValue({ id: 'audit-log-uuid' }),
    },
  };

  const validUuid = 'a0000000-0000-0000-0000-000000000001';

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SecurityAuditService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<SecurityAuditService>(SecurityAuditService);
    jest.clearAllMocks();
  });

  it('should write audit event and redact sensitive keys', async () => {
    await service.logEvent({
      action: 'OTP_VERIFICATION_FAILED',
      actorType: 'user',
      targetEntity: 'User',
      targetId: validUuid,
      ipAddress: '127.0.0.1',
      userAgent: 'Mozilla/5.0',
      correlationId: 'req-123',
      metadata: {
        phone: '+201012345678',
        code: '123456',
        refreshToken: 'raw-secret-token',
        reason: 'INCORRECT_CODE',
      },
    });

    expect(mockPrisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        action: 'OTP_VERIFICATION_FAILED',
        actorType: 'user',
        targetEntity: 'User',
        targetId: validUuid,
        diffPayload: expect.objectContaining({
          phone: '+201012345678',
          code: '[REDACTED]',
          refreshToken: '[REDACTED]',
          reason: 'INCORRECT_CODE',
          correlationId: 'req-123',
        }),
      }),
    });
  });

  it('should preserve non-UUID targetId in metadata when column requires UUID', async () => {
    await service.logEvent({
      action: 'RATE_LIMIT_HIT',
      targetEntity: 'Phone',
      targetId: '+201012345678', // Non-UUID
    });

    expect(mockPrisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        targetEntity: 'Phone',
        targetId: null,
        diffPayload: expect.objectContaining({
          rawTargetId: '+201012345678',
        }),
      }),
    });
  });

  it('should redact nested and substring-matching sensitive metadata keys', async () => {
    await service.logEvent({
      action: 'WEBHOOK_DEBUG',
      targetEntity: 'Video',
      metadata: {
        apiKey: 'sk_live_12345',
        nested: {
          private_key: '-----BEGIN PRIVATE KEY-----',
          safeField: 'ok',
        },
      },
    });

    expect(mockPrisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        diffPayload: {
          apiKey: '[REDACTED]',
          nested: {
            private_key: '[REDACTED]',
            safeField: 'ok',
          },
        },
      }),
    });
  });

  it('should rethrow DB errors in queue worker mode (rethrow=true) so BullMQ retries', async () => {
    mockPrisma.auditLog.create.mockRejectedValueOnce(
      new Error('DB transient timeout'),
    );

    await expect(
      service.persistAuditRecord(
        {
          actorType: 'system',
          actorId: null,
          action: 'TEST_RETRY',
          targetEntity: 'User',
          targetId: null,
          ipAddress: null,
          userAgent: null,
          diffPayload: {},
        },
        true,
      ),
    ).rejects.toThrow('DB transient timeout');
  });
});
