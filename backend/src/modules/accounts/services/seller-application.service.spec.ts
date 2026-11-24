import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SellerApplicationService } from './seller-application.service';
import { PrivateDocumentStorageService } from './private-document-storage.service';
import {
  AccountType,
  SellerApplicationStatus,
  SellerDocumentStatus,
  SellerDocumentType,
} from '../../../core/enums/domain.enums';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';

describe('SellerApplicationService (Unit & Transactional Integrity)', () => {
  let service: SellerApplicationService;
  let privateStorage: PrivateDocumentStorageService;
  let prisma: any;
  let securityAudit: { logEvent: jest.Mock };
  let redis: { del: jest.Mock };

  const staffActor: AuthenticatedStaff = {
    id: 'staff-1',
    staffId: 'staff-1',
    actorType: 'staff',
    email: 'admin@dealone.eg',
    fullName: 'Admin Reviewer',
    roleId: 1,
    role: 'super_admin',
    permissions: [
      'verification.read',
      'verification.documents.read',
      'verification.approve',
      'verification.reject',
      'users.suspend',
    ],
    mfaVerified: true,
  };

  beforeEach(() => {
    const configService = {
      get: jest.fn((key: string, def?: any) => def ?? ''),
    } as unknown as ConfigService;
    privateStorage = new PrivateDocumentStorageService(configService);
    securityAudit = { logEvent: jest.fn().mockResolvedValue(undefined) };
    redis = { del: jest.fn().mockResolvedValue(undefined) };

    prisma = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      sellerApplication: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        findUniqueOrThrow: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      sellerApplicationDocument: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        deleteMany: jest.fn(),
        updateMany: jest.fn(),
      },
      sellerApplicationHistory: {
        create: jest.fn(),
        findMany: jest.fn(),
      },
      account: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      accountMember: {
        upsert: jest.fn(),
      },
      moderationLog: { create: jest.fn() },
      auditLog: { create: jest.fn() },
      $transaction: jest.fn(async (cb: any) => cb(prisma)),
    };

    service = new SellerApplicationService(
      prisma,
      privateStorage,
      securityAudit as any,
      redis as any,
    );
  });

  it('prevents self-approval when admin matches applicant userId or email', async () => {
    prisma.sellerApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      userId: 'staff-1',
      status: SellerApplicationStatus.PENDING,
      businessType: AccountType.INDIVIDUAL,
      businessName: 'Self Shop',
      nationalIdNumber: '29501011234567',
      documents: [
        {
          documentType: SellerDocumentType.NATIONAL_ID_FRONT,
          status: SellerDocumentStatus.UPLOADED,
        },
        {
          documentType: SellerDocumentType.NATIONAL_ID_BACK,
          status: SellerDocumentStatus.UPLOADED,
        },
      ],
      user: {
        id: 'staff-1',
        fullName: 'Admin Reviewer',
        email: 'admin@dealone.eg',
        phone: '+201000000001',
        isActive: true,
        deletedAt: null,
      },
    });

    await expect(
      service.approveApplication('app-1', staffActor, {}),
    ).rejects.toThrow(ForbiddenException);
  });

  it('rejects approval of incomplete applications', async () => {
    prisma.sellerApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      userId: 'user-1',
      status: SellerApplicationStatus.PENDING,
      businessType: AccountType.INDIVIDUAL,
      businessName: 'Incomplete Shop',
      nationalIdNumber: '29501011234567',
      documents: [],
      user: {
        id: 'user-1',
        fullName: 'Buyer One',
        email: 'buyer@example.com',
        phone: '+201000000002',
        isActive: true,
        deletedAt: null,
      },
    });

    await expect(
      service.approveApplication('app-1', staffActor, {}),
    ).rejects.toThrow(BadRequestException);
  });

  it('prevents duplicate approval via optimistic concurrency lock', async () => {
    prisma.sellerApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      userId: 'user-1',
      status: SellerApplicationStatus.PENDING,
      businessType: AccountType.INDIVIDUAL,
      businessName: 'Complete Shop',
      nationalIdNumber: '29501011234567',
      documents: [
        {
          documentType: SellerDocumentType.NATIONAL_ID_FRONT,
          status: SellerDocumentStatus.UPLOADED,
        },
        {
          documentType: SellerDocumentType.NATIONAL_ID_BACK,
          status: SellerDocumentStatus.UPLOADED,
        },
      ],
      user: {
        id: 'user-1',
        fullName: 'Buyer One',
        email: 'buyer@example.com',
        phone: '+201000000002',
        isActive: true,
        deletedAt: null,
      },
    });
    prisma.sellerApplication.updateMany.mockResolvedValue({ count: 0 });

    await expect(
      service.approveApplication('app-1', staffActor, {}),
    ).rejects.toThrow(ConflictException);
  });

  it('keeps state consistent when transaction fails mid-approval', async () => {
    prisma.sellerApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      userId: 'user-1',
      status: SellerApplicationStatus.PENDING,
      businessType: AccountType.INDIVIDUAL,
      businessName: 'Atomic Shop',
      nationalIdNumber: '29501011234567',
      documents: [
        {
          documentType: SellerDocumentType.NATIONAL_ID_FRONT,
          status: SellerDocumentStatus.UPLOADED,
        },
        {
          documentType: SellerDocumentType.NATIONAL_ID_BACK,
          status: SellerDocumentStatus.UPLOADED,
        },
      ],
      user: {
        id: 'user-1',
        fullName: 'Buyer One',
        email: 'buyer@example.com',
        phone: '+201000000002',
        isActive: true,
        deletedAt: null,
      },
    });
    prisma.sellerApplication.updateMany.mockResolvedValue({ count: 1 });
    prisma.account.findFirst.mockResolvedValue(null);
    prisma.account.create.mockRejectedValue(new Error('Simulated DB failure'));

    await expect(
      service.approveApplication('app-1', staffActor, {}),
    ).rejects.toThrow('Simulated DB failure');
    expect(prisma.user.update).not.toHaveBeenCalled();
    expect(redis.del).not.toHaveBeenCalled();
  });

  it('rejects private storage keys using public listing media prefix or path traversal', () => {
    const userId = '11111111-1111-4111-8111-111111111111';
    const appId = '22222222-2222-4222-8222-222222222222';

    expect(() =>
      privateStorage.validatePrivateDocumentOwnership(
        userId,
        appId,
        `uploads/images/2026-11/${userId}/file.jpg`,
      ),
    ).toThrow(ForbiddenException);

    expect(() =>
      privateStorage.validatePrivateDocumentOwnership(
        userId,
        appId,
        `private/seller-verification/${userId}/../other/file.pdf`,
      ),
    ).toThrow(ForbiddenException);
  });
});
