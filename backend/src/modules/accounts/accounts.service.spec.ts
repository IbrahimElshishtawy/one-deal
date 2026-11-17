import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException } from '@nestjs/common';
import { AccountsService } from './accounts.service';
import { PrismaService } from '../../core/database/prisma.service';

describe('AccountsService', () => {
  let service: AccountsService;

  const mockPrisma = {
    accountMember: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    branch: {
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      delete: jest.fn(),
    },
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
});
