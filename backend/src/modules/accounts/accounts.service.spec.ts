import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { AccountsService } from './accounts.service';
import { PrismaService } from '../../core/database/prisma.service';

describe('AccountsService', () => {
  let service: AccountsService;

  const mockPrisma: any = {
    account: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    accountMember: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    area: {
      findUnique: jest.fn(),
    },
    serviceArea: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      upsert: jest.fn(),
      delete: jest.fn(),
    },
    accountVerification: {
      findMany: jest.fn(),
      create: jest.fn(),
    },
    branch: {
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      delete: jest.fn(),
    },
    $transaction: jest.fn((cb: (tx: any) => any) => cb(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AccountsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<AccountsService>(AccountsService);
    jest.clearAllMocks();
  });

  it('should list user accounts with member role', async () => {
    mockPrisma.accountMember.findMany.mockResolvedValue([
      {
        role: 'owner',
        createdAt: new Date('2026-11-03T18:00:00Z'),
        account: {
          id: 'acc-1',
          accountType: 'individual',
          displayName: 'Personal Account',
          slug: 'personal-account',
          verificationStatus: 'approved',
          isActive: true,
        },
      },
      {
        role: 'manager',
        createdAt: new Date('2026-11-03T18:05:00Z'),
        account: {
          id: 'acc-2',
          accountType: 'company',
          displayName: 'El-Sewedy Motors',
          slug: 'el-sewedy-motors',
          verificationStatus: 'approved',
          isActive: true,
        },
      },
    ]);

    const result = await service.getMyAccounts('user-1');

    expect(result).toHaveLength(2);
    expect(result[0].id).toBe('acc-1');
    expect(result[0].role).toBe('owner');
    expect(result[1].id).toBe('acc-2');
    expect(result[1].role).toBe('manager');
  });

  describe('Branch Management RBAC Consistency', () => {
    const branchDto = {
      name: 'Nasr City Branch',
      areaId: 'area-1',
      address: 'Abbas El Akkad',
    };

    it('should allow manager role to create a branch (aligned with update/delete)', async () => {
      mockPrisma.accountMember.findUnique.mockResolvedValue({
        accountId: 'acc-1',
        userId: 'mgr-1',
        role: 'manager',
      });
      mockPrisma.branch.create.mockResolvedValue({
        id: 'branch-1',
        name: 'Nasr City Branch',
      });

      const created = await service.createBranch('acc-1', 'mgr-1', branchDto);
      expect(created.id).toBe('branch-1');
    });

    it('should reject lister or legacy admin role from creating a branch', async () => {
      mockPrisma.accountMember.findUnique.mockResolvedValueOnce({
        accountId: 'acc-1',
        userId: 'lister-1',
        role: 'lister',
      });

      await expect(
        service.createBranch('acc-1', 'lister-1', branchDto),
      ).rejects.toThrow(ForbiddenException);

      mockPrisma.accountMember.findUnique.mockResolvedValueOnce({
        accountId: 'acc-1',
        userId: 'bad-role',
        role: 'admin',
      });

      await expect(
        service.createBranch('acc-1', 'bad-role', branchDto),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('Service Areas & Account Verifications', () => {
    it('should upsert service area when caller is owner or manager and area is active', async () => {
      mockPrisma.accountMember.findUnique.mockResolvedValue({
        accountId: 'acc-1',
        userId: 'owner-1',
        role: 'owner',
      });
      mockPrisma.area.findUnique.mockResolvedValue({
        id: 'area-1',
        isActive: true,
      });
      mockPrisma.serviceArea.upsert.mockResolvedValue({
        id: 'sa-1',
        accountId: 'acc-1',
        areaId: 'area-1',
        radiusKm: 25,
      });

      const res = await service.upsertServiceArea('acc-1', 'owner-1', {
        areaId: 'area-1',
        radiusKm: 25,
      });
      expect(res.radiusKm).toBe(25);
    });

    it('should throw NotFoundException when removing non-existent service area on account', async () => {
      mockPrisma.accountMember.findUnique.mockResolvedValue({
        accountId: 'acc-1',
        userId: 'owner-1',
        role: 'owner',
      });
      mockPrisma.serviceArea.findFirst.mockResolvedValue(null);

      await expect(
        service.removeServiceArea('acc-1', 'sa-other', 'owner-1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should submit verification document and set account status to pending', async () => {
      mockPrisma.accountMember.findUnique.mockResolvedValue({
        accountId: 'acc-1',
        userId: 'owner-1',
        role: 'owner',
      });
      mockPrisma.account.findUnique.mockResolvedValue({
        id: 'acc-1',
        isActive: true,
        deletedAt: null,
      });
      mockPrisma.accountVerification.create.mockResolvedValue({
        id: 'ver-1',
        status: 'pending',
      });
      mockPrisma.account.update.mockResolvedValue({});

      const res = await service.submitVerification('acc-1', 'owner-1', {
        documentType: 'commercial_register',
        documentNumber: 'CR-999',
        fileUrl: 'https://cdn.marketspace.eg/ver/doc.pdf',
      });

      expect(res.status).toBe('pending');
      expect(mockPrisma.account.update).toHaveBeenCalledWith({
        where: { id: 'acc-1' },
        data: { verificationStatus: 'pending' },
      });
    });
  });
});
