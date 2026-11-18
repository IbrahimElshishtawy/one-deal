import { ConflictException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { ReportStatus, ReportReason } from '../../core/enums/domain.enums';
import { ModerationService } from './moderation.service';
import { PrismaService } from '../../core/database/prisma.service';

describe('ModerationService (Milestone 8)', () => {
  let service: ModerationService;
  let prisma: PrismaService;

  const mockPrisma: any = {
    report: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      update: jest.fn(),
    },
    accountVerification: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    account: {
      update: jest.fn(),
    },
    moderationLog: {
      create: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
    $transaction: jest.fn((callback: (tx: any) => any) => callback(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModerationService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<ModerationService>(ModerationService);
    prisma = module.get<PrismaService>(PrismaService);
    expect(prisma).toBeDefined();
    jest.clearAllMocks();
  });

  describe('fileReport', () => {
    it('should create an abuse report with open status', async () => {
      mockPrisma.report.create.mockResolvedValue({
        id: 'report-1',
        reason: ReportReason.SCAM,
        status: 'open',
      });

      const result = await service.fileReport('reporter-1', {
        listingId: 'listing-1',
        reason: ReportReason.SCAM,
        notes: 'إعلان سبام متكرر',
      });

      expect(result.id).toBe('report-1');
      expect(mockPrisma.report.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            reporterUserId: 'reporter-1',
            listingId: 'listing-1',
            status: 'open',
          }),
        }),
      );
    });
  });

  describe('adjudicateReport', () => {
    it('should update report status and record an immutable audit log entry', async () => {
      mockPrisma.report.findUnique.mockResolvedValue({
        id: 'report-1',
        status: 'open',
      });
      mockPrisma.report.update.mockResolvedValue({
        id: 'report-1',
        status: 'resolved',
      });
      mockPrisma.auditLog.create.mockResolvedValue({ id: 'log-1' });

      const result = await service.adjudicateReport(
        'report-1',
        'moderator-1',
        {
          status: ReportStatus.RESOLVED,
          actionTaken: 'تم حذف الإعلان',
        },
        '127.0.0.1',
      );

      expect(result.status).toBe('resolved');
      expect(mockPrisma.auditLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            actorId: 'moderator-1',
            actorType: 'staff',
            targetEntity: 'report',
            targetId: 'report-1',
          }),
        }),
      );
    });
  });

  describe('adjudicateVerification', () => {
    it('should approve account verification, update account verificationStatus, and log moderation & audit entries', async () => {
      mockPrisma.accountVerification.findUnique
        .mockResolvedValueOnce({
          id: 'ver-1',
          accountId: 'acc-1',
          status: 'pending',
        })
        .mockResolvedValueOnce({
          id: 'ver-1',
          accountId: 'acc-1',
          status: 'approved',
        });
      mockPrisma.accountVerification.updateMany.mockResolvedValue({ count: 1 });
      mockPrisma.account.update.mockResolvedValue({});
      mockPrisma.moderationLog.create.mockResolvedValue({});
      mockPrisma.auditLog.create.mockResolvedValue({});

      const res = await service.adjudicateVerification('ver-1', 'mod-1', {
        action: 'approve',
        notes: 'Valid commercial register',
      });

      expect(res?.status).toBe('approved');
      expect(mockPrisma.accountVerification.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'ver-1', status: 'pending' },
        }),
      );
      expect(mockPrisma.account.update).toHaveBeenCalledWith({
        where: { id: 'acc-1' },
        data: { verificationStatus: 'approved' },
      });
      expect(mockPrisma.moderationLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            targetType: 'verification',
            targetId: 'ver-1',
            action: 'verify',
          }),
        }),
      );
    });

    it('should throw ConflictException and skip logging if verification is already adjudicated', async () => {
      mockPrisma.accountVerification.findUnique.mockResolvedValue({
        id: 'ver-1',
        accountId: 'acc-1',
        status: 'approved',
      });
      mockPrisma.accountVerification.updateMany.mockResolvedValue({ count: 0 });

      await expect(
        service.adjudicateVerification('ver-1', 'mod-1', { action: 'approve' }),
      ).rejects.toThrow(ConflictException);

      expect(mockPrisma.moderationLog.create).not.toHaveBeenCalled();
      expect(mockPrisma.auditLog.create).not.toHaveBeenCalled();
    });

    it('should require rejectionReason when rejecting verification', async () => {
      mockPrisma.accountVerification.findUnique.mockResolvedValue({
        id: 'ver-1',
        accountId: 'acc-1',
        status: 'pending',
      });

      await expect(
        service.adjudicateVerification('ver-1', 'mod-1', { action: 'reject' }),
      ).rejects.toThrow();
    });
  });
});
