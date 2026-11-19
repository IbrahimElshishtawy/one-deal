import {
  Injectable,
  BadRequestException,
  ConflictException,
  NotFoundException,
  Logger,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { CreateReportDto } from './dto/create-report.dto';
import { AdjudicateReportDto } from './dto/adjudicate-report.dto';
import { AdjudicateListingDto } from './dto/adjudicate-listing.dto';
import { AdjudicateVerificationDto } from './dto/adjudicate-verification.dto';
import { EmailService } from '../email/email.service';
import { normalizeEmailLocale } from '../email/templates/email-layout.template';

@Injectable()
export class ModerationService {
  private readonly logger = new Logger(ModerationService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly emailService?: EmailService,
  ) {}

  /**
   * Retrieves pending listings awaiting human moderation review.
   */
  async getPendingListings(page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [total, listings] = await Promise.all([
      this.prisma.listing.count({
        where: { moderationStatus: 'pending', deletedAt: null },
      }),
      this.prisma.listing.findMany({
        where: { moderationStatus: 'pending', deletedAt: null },
        skip,
        take: limit,
        orderBy: { createdAt: 'asc' },
        include: {
          category: {
            select: { id: true, nameAr: true, nameEn: true, slug: true },
          },
          account: {
            select: {
              id: true,
              displayName: true,
              accountType: true,
              owner: { select: { phone: true, fullName: true } },
            },
          },
          media: { orderBy: { sortOrder: 'asc' } },
        },
      }),
    ]);

    return {
      listings,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Approves or rejects a pending listing, updates publication status, and writes immutable records to moderation_log.
   */
  async adjudicateListing(
    listingId: string,
    moderatorId: string,
    dto: AdjudicateListingDto,
    ipAddress?: string,
    userAgent?: string,
  ) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    const isApprove = dto.action === 'approve';
    const newModerationStatus = isApprove ? 'approved' : 'rejected';
    const newPublicationStatus = isApprove ? 'published' : 'draft';

    const updatedListing = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.listing.update({
        where: { id: listingId },
        data: {
          moderationStatus: newModerationStatus,
          publicationStatus: newPublicationStatus,
        },
      });

      // Insert into moderation_log
      await tx.moderationLog.create({
        data: {
          targetType: 'listing',
          targetId: listingId,
          action: dto.action,
          reasonCode: dto.reasonCode,
          notes: dto.notes,
        },
      });

      // Insert into auditLog
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: moderatorId,
          action: `MODERATE_LISTING_${dto.action.toUpperCase()}`,
          targetEntity: 'listing',
          targetId: listingId,
          ipAddress: ipAddress?.slice(0, 50),
          userAgent: userAgent?.slice(0, 500),
          diffPayload: {
            previousModerationStatus: listing.moderationStatus,
            newModerationStatus,
            previousPublicationStatus: listing.publicationStatus,
            newPublicationStatus,
            reasonCode: dto.reasonCode,
            notes: dto.notes,
          },
        },
      });

      return updated;
    });

    if (this.emailService && (this.prisma as any).account?.findUnique) {
      this.notifyListingModerationDecision(
        listing.accountId,
        listingId,
        listing.title,
        isApprove,
        dto.reasonCode,
        dto.notes,
      );
    }

    return updatedListing;
  }

  private notifyListingModerationDecision(
    accountId: string,
    listingId: string,
    listingTitle: string,
    isApprove: boolean,
    reasonCode?: string,
    notes?: string,
  ): void {
    this.prisma.account
      .findUnique({
        where: { id: accountId },
        select: {
          owner: {
            select: { email: true, fullName: true, preferredLanguage: true },
          },
        },
      })
      .then((account) => {
        const owner = account?.owner;
        if (!owner?.email || !this.emailService) return;
        const locale = normalizeEmailLocale(owner.preferredLanguage);
        const listingUrl = `${this.emailService.getAppPublicUrl()}/listings/${listingId}`;
        if (isApprove) {
          return this.emailService.sendListingApprovedEmail({
            to: owner.email,
            displayName: owner.fullName,
            listingTitle,
            listingUrl,
            locale,
            idempotencyKey: `listing-approved-${listingId}`,
          });
        }
        return this.emailService.sendListingRejectedEmail({
          to: owner.email,
          displayName: owner.fullName,
          listingTitle,
          reasonCode,
          reasonNotes: notes,
          listingUrl,
          locale,
          idempotencyKey: `listing-rejected-${listingId}-${Date.now()}`,
        });
      })
      .catch((err) =>
        this.logger.warn(
          `Non-blocking moderation email failed for listing ${listingId}: ${err?.message}`,
        ),
      );
  }

  /**
   * Files a user abuse report against a listing or user.
   */
  async fileReport(reporterId: string, dto: CreateReportDto) {
    return this.prisma.report.create({
      data: {
        reporterUserId: reporterId,
        listingId: dto.listingId,
        reportedAccountId: dto.reportedAccountId,
        reason: dto.reason,
        details: dto.details ?? dto.notes,
        status: 'open',
      },
    });
  }

  /**
   * Retrieves pending abuse reports for moderators.
   */
  async getModerationQueue(page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [total, reports] = await Promise.all([
      this.prisma.report.count({ where: { status: 'open' } }),
      this.prisma.report.findMany({
        where: { status: 'open' },
        skip,
        take: limit,
        orderBy: { createdAt: 'asc' },
        include: {
          reporter: { select: { id: true, fullName: true, phone: true } },
          listing: {
            select: {
              id: true,
              title: true,
              price: true,
              publicationStatus: true,
            },
          },
          reportedAccount: {
            select: { id: true, displayName: true, slug: true },
          },
        },
      }),
    ]);

    return {
      reports,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Adjudicates a report and records an immutable entry in the audit trail.
   */
  async adjudicateReport(
    reportId: string,
    moderatorId: string,
    dto: AdjudicateReportDto,
    ipAddress?: string,
    userAgent?: string,
  ) {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedReport = await tx.report.update({
        where: { id: reportId },
        data: {
          status: 'resolved',
          resolutionNotes: dto.actionTaken,
          resolvedAt: new Date(),
        },
      });

      // Immutable audit log
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: moderatorId,
          action: `ADJUDICATE_REPORT_${dto.status}`,
          targetEntity: 'report',
          targetId: reportId,
          ipAddress: ipAddress?.slice(0, 50),
          userAgent: userAgent?.slice(0, 500),
          diffPayload: {
            previousStatus: report.status,
            newStatus: dto.status,
            actionTaken: dto.actionTaken,
          },
        },
      });

      return updatedReport;
    });
  }

  /**
   * Retrieves immutable audit logs for Super Admins.
   */
  async getAuditLogs(page = 1, limit = 50) {
    const skip = (page - 1) * limit;

    const [total, logs] = await Promise.all([
      this.prisma.auditLog.count(),
      this.prisma.auditLog.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      logs,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Lists pending account verification requests for moderators.
   */
  async getPendingVerifications(page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [total, verifications] = await Promise.all([
      this.prisma.accountVerification.count({ where: { status: 'pending' } }),
      this.prisma.accountVerification.findMany({
        where: { status: 'pending' },
        skip,
        take: limit,
        orderBy: { createdAt: 'asc' },
        include: {
          account: {
            select: {
              id: true,
              displayName: true,
              accountType: true,
              slug: true,
              owner: { select: { id: true, fullName: true, phone: true } },
            },
          },
        },
      }),
    ]);

    return {
      verifications,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Approves or rejects an account verification submission and updates account trust status.
   */
  async adjudicateVerification(
    verificationId: string,
    moderatorId: string,
    dto: AdjudicateVerificationDto,
    ipAddress?: string,
    userAgent?: string,
  ) {
    const verification = await this.prisma.accountVerification.findUnique({
      where: { id: verificationId },
    });

    if (!verification) {
      throw new NotFoundException('Account verification request not found');
    }

    if (dto.action === 'reject' && !dto.rejectionReason?.trim()) {
      throw new BadRequestException(
        'Rejection reason is required when rejecting a verification request',
      );
    }

    const newStatus = dto.action === 'approve' ? 'approved' : 'rejected';

    return this.prisma.$transaction(async (tx) => {
      const updateResult = await tx.accountVerification.updateMany({
        where: { id: verificationId, status: 'pending' },
        data: {
          status: newStatus,
          rejectionReason:
            dto.action === 'reject' ? dto.rejectionReason!.trim() : null,
          reviewedAt: new Date(),
        },
      });

      if (updateResult.count === 0) {
        throw new ConflictException(
          'Account verification request has already been adjudicated',
        );
      }

      const updatedVerification = await tx.accountVerification.findUnique({
        where: { id: verificationId },
      });

      await tx.account.update({
        where: { id: verification.accountId },
        data: { verificationStatus: newStatus },
      });

      await tx.moderationLog.create({
        data: {
          targetType: 'verification',
          targetId: verificationId,
          action: dto.action === 'approve' ? 'verify' : 'reject',
          notes: dto.notes ?? dto.rejectionReason ?? null,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: moderatorId,
          action: `MODERATE_VERIFICATION_${dto.action.toUpperCase()}`,
          targetEntity: 'account_verification',
          targetId: verificationId,
          ipAddress: ipAddress?.slice(0, 50),
          userAgent: userAgent?.slice(0, 500),
          diffPayload: {
            accountId: verification.accountId,
            previousStatus: verification.status,
            newStatus,
            rejectionReason: dto.rejectionReason ?? null,
          },
        },
      });

      return updatedVerification;
    });
  }
}
