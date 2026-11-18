import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { StaffService } from './staff.service';
import { PrismaService } from '../../core/database/prisma.service';

describe('StaffService', () => {
  let service: StaffService;

  const mockPrisma: any = {
    staffRole: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    staffUser: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    $transaction: jest.fn((cb: (tx: any) => any) => cb(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StaffService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<StaffService>(StaffService);
    jest.clearAllMocks();
  });

  it('should create staff user with argon2 password hash and exclude passwordHash from select', async () => {
    mockPrisma.staffUser.findUnique.mockResolvedValue(null);
    mockPrisma.staffRole.findUnique.mockResolvedValue({
      id: 1,
      name: 'moderator',
    });
    mockPrisma.staffUser.create.mockResolvedValue({
      id: 'staff-1',
      email: 'mod@dealone.eg',
      fullName: 'Moderator One',
      roleId: 1,
      isActive: true,
    });
    mockPrisma.auditLog.create.mockResolvedValue({});

    const res = await service.createStaffUser(
      {
        email: 'MOD@dealone.eg',
        password: 'StrongPassword!2026',
        fullName: 'Moderator One',
        roleId: 1,
      },
      'super-admin-1',
    );

    expect(res.email).toBe('mod@dealone.eg');
    expect(mockPrisma.staffUser.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          email: 'mod@dealone.eg',
          passwordHash: expect.stringContaining('$argon2'),
        }),
      }),
    );
  });

  it('should reject duplicate staff role names', async () => {
    mockPrisma.staffRole.findUnique.mockResolvedValue({ id: 1, name: 'admin' });
    await expect(
      service.createRole({ name: 'admin' }, 'super-admin-1'),
    ).rejects.toThrow(ConflictException);
  });

  it('should throw NotFoundException when updating unknown staff user', async () => {
    mockPrisma.staffUser.findUnique.mockResolvedValue(null);
    await expect(
      service.updateStaffUser('missing-id', { isActive: false }, 'admin-1'),
    ).rejects.toThrow(NotFoundException);
  });
});
