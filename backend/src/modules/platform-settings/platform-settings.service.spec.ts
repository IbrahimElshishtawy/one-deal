import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { PlatformSettingsService } from './platform-settings.service';
import { PrismaService } from '../../core/database/prisma.service';

describe('PlatformSettingsService', () => {
  let service: PlatformSettingsService;

  const mockPrisma: any = {
    platformSetting: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    $transaction: jest.fn((cb: (tx: any) => any) => cb(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlatformSettingsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<PlatformSettingsService>(PlatformSettingsService);
    jest.clearAllMocks();
  });

  it('should throw BadRequestException for keys > 100 chars or invalid characters', async () => {
    await expect(service.getSetting('a'.repeat(101))).rejects.toThrow(
      BadRequestException,
    );
    await expect(service.getSetting('bad key عربي')).rejects.toThrow(
      BadRequestException,
    );
    await expect(
      service.upsertSetting('bad key', 'admin-1', { value: true }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should throw NotFoundException when key does not exist', async () => {
    mockPrisma.platformSetting.findUnique.mockResolvedValue(null);
    await expect(service.getSetting('missing_key')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('should upsert setting and record audit log entry', async () => {
    mockPrisma.platformSetting.findUnique.mockResolvedValue(null);
    mockPrisma.platformSetting.upsert.mockResolvedValue({
      key: 'daily_contact_limit',
      value: 5,
    });
    mockPrisma.auditLog.create.mockResolvedValue({ id: 'audit-1' });

    const res = await service.upsertSetting('daily_contact_limit', 'admin-1', {
      value: 5,
      description: 'Max reveals per day',
    });

    expect(res.key).toBe('daily_contact_limit');
    expect(mockPrisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          action: 'PLATFORM_SETTING_CREATED',
          actorId: 'admin-1',
          targetEntity: 'platform_setting',
        }),
      }),
    );
  });
});
