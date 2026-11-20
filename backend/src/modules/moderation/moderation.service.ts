import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { CreateReportDto } from './dto/create-report.dto';
import { AdjudicateReportDto } from './dto/adjudicate-report.dto';
import { AdjudicateListingDto } from './dto/adjudicate-listing.dto';
import { AdjudicateVerificationDto } from './dto/adjudicate-verification.dto';
import {
  AssignReportDto,
  AuditLogQueryDto,
  ModerationQueueQueryDto,
  VerificationQueueQueryDto,
} from './dto/moderation-query.dto';
import { EmailService } from '../email/email.service';
import { normalizeEmailLocale } from '../email/templates/email-layout.template';

function maskSensitiveDocNumber(num?: string | null): string | null {
  if (!num) return null;
  if (num.length <= 4) return '****';
  return `${'*'.repeat(Math.max(4, num.length - 4))}${num.slice(-4)}`;
}

function sanitizeCsvCell(val: unknown): string {
  const str = val === null || val === undefined ? '' : String(val);
  const safe = /^[=+\-@\t\r]/.test(str) ? `'${str}` : str;
  return `"${safe.replace(/"/g, '""')}"`;
}

@Injectable()
export class ModerationService {
  private readonly logger = new Logger(ModerationService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly emailService?: EmailService,
    @Optional() private readonly redis?: RedisService,
  ) {}

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

  async adjudicateListing(
    listingId: string,
    moderatorId: string,
    dto: AdjudicateListingDto,
    ipAddress?: string,
    userAgent?: string,
    staffId?: string | null,
  ) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    if (
      (dto.action === 'reject' || dto.action === 'request_changes') &&
      !dto.notes?.trim() &&
      !dto.reasonCode?.trim()
    ) {
      throw new BadRequestException(
        'A reason code or moderator notes are required when rejecting or requesting changes.',
      );
    }

    const resolvedStaffId = staffId === undefined ? moderatorId : staffId;
    const isApprove = dto.action === 'approve';
    const isRequestChanges = dto.action === 'request_changes';
    const newModerationStatus = isApprove
      ? 'approved'
      : isRequestChanges
        ? 'pending'
        : 'rejected';
    const newPublicationStatus = isApprove ? 'published' : 'unpublished';

    const updatedListing = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.listing.update({
        where: { id: listingId },
        data: {
          moderationStatus: newModerationStatus,
          publicationStatus: newPublicationStatus,
          ...(isApprove ? { approvedAt: listing.approvedAt ?? new Date() } : {}),
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
          targetType: 'listing',
          targetId: listingId,
          action: dto.action,
          reasonCode: dto.reasonCode,
          notes: dto.notes,
        },
      });

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

    await Promise.all([
      this.redis?.incr?.('listings:feed:ver').catch(() => undefined),
      this.redis?.incr?.('home:feed:ver').catch(() => undefined),
    ]);

    if (this.emailService && (this.prisma as any).account?.findUnique && !isRequestChanges) {
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

  async getModerationQueue(
    page = 1,
    limit = 20,
    filters?: ModerationQueueQueryDto,
  ) {
    const skip = (page - 1) * limit;
    const statusFilter = filters?.status;

    const where: any = {
      ...(statusFilter === 'all'
        ? {}
        : { status: statusFilter || 'open' }),
      ...(filters?.reason ? { reason: filters.reason } : {}),
      ...(filters?.priority ? { priority: filters.priority } : {}),
      ...(filters?.assignedToStaffId
        ? { assignedToStaffId: filters.assignedToStaffId }
        : {}),
      ...(filters?.q
        ? {
            OR: [
              { details: { contains: filters.q.trim(), mode: 'insensitive' } },
              {
                listing: {
                  title: { contains: filters.q.trim(), mode: 'insensitive' },
                },
              },
              {
                reporter: {
                  fullName: { contains: filters.q.trim(), mode: 'insensitive' },
                },
              },
            ],
          }
        : {}),
    };

    const [total, reports] = await Promise.all([
      this.prisma.report.count({ where }),
      this.prisma.report.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reporter: { select: { id: true, fullName: true, phone: true } },
          listing: {
            select: {
              id: true,
              title: true,
              price: true,
              publicationStatus: true,
              moderationStatus: true,
            },
          },
          reportedAccount: {
            select: { id: true, displayName: true, slug: true },
          },
          assignedTo: {
            select: { id: true, fullName: true, email: true },
          },
          resolvedBy: {
            select: { id: true, fullName: true, email: true },
          },
        },
      }),
    ]);

    return {
      reports,
      items: reports,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getReportDetail(reportId: string) {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      include: {
        reporter: {
          select: { id: true, fullName: true, phone: true, email: true },
        },
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            moderationStatus: true,
            publicationStatus: true,
            accountId: true,
          },
        },
        reportedAccount: {
          select: {
            id: true,
            displayName: true,
            slug: true,
            verificationStatus: true,
          },
        },
        assignedTo: { select: { id: true, fullName: true, email: true } },
        resolvedBy: { select: { id: true, fullName: true, email: true } },
      },
    });
    if (!report) {
      throw new NotFoundException('Report not found');
    }
    const history = await this.prisma.moderationLog.findMany({
      where: { targetType: 'report', targetId: reportId },
      orderBy: { createdAt: 'desc' },
      include: { staff: { select: { id: true, fullName: true, email: true } } },
    });
    return { report, history };
  }

  async assignReport(
    reportId: string,
    actorId: string,
    dto: AssignReportDto,
    staffId?: string | null,
  ) {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
    });
    if (!report) {
      throw new NotFoundException('Report not found');
    }
    if (dto.staffId) {
      const targetStaff = await this.prisma.staffUser.findUnique({
        where: { id: dto.staffId },
        select: { id: true, isActive: true },
      });
      if (!targetStaff || !targetStaff.isActive) {
        throw new NotFoundException('Assigned staff user not found or inactive');
      }
    }

    const resolvedStaffId = staffId === undefined ? actorId : staffId;

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.report.update({
        where: { id: reportId },
        data: {
          ...(dto.staffId !== undefined
            ? {
                assignedToStaffId: dto.staffId,
                assignedAt: dto.staffId ? new Date() : null,
              }
            : {}),
          ...(dto.priority !== undefined ? { priority: dto.priority } : {}),
        },
        include: {
          assignedTo: { select: { id: true, fullName: true, email: true } },
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
          targetType: 'report',
          targetId: reportId,
          action: 'assign',
          notes: dto.staffId
            ? `Assigned to ${dto.staffId}${dto.priority ? ` (priority=${dto.priority})` : ''}`
            : `Updated priority=${dto.priority ?? report.priority}`,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'REPORT_ASSIGNED',
          targetEntity: 'report',
          targetId: reportId,
          diffPayload: {
            assignedToStaffId: updated.assignedToStaffId,
            priority: updated.priority,
          },
        },
      });

      return updated;
    });
  }

  async addReportNote(
    reportId: string,
    actorId: string,
    actorName: string,
    note: string,
  ) {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
    });
    if (!report) {
      throw new NotFoundException('Report not found');
    }

    const existingNotes = Array.isArray(report.internalNotes)
      ? (report.internalNotes as Array<Record<string, unknown>>)
      : [];
    const entry = {
      id: `${Date.now()}`,
      authorId: actorId,
      authorName: actorName,
      note: note.trim(),
      createdAt: new Date().toISOString(),
    };

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.report.update({
        where: { id: reportId },
        data: { internalNotes: [...existingNotes, entry] as any },
      });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'REPORT_NOTE_ADDED',
          targetEntity: 'report',
          targetId: reportId,
          diffPayload: { noteLength: note.trim().length },
        },
      });
      return next;
    });

    return updated;
  }

  async adjudicateReport(
    reportId: string,
    moderatorId: string,
    dto: AdjudicateReportDto,
    ipAddress?: string,
    userAgent?: string,
    staffId?: string | null,
  ) {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    const resolvedStaffId = staffId === undefined ? moderatorId : staffId;
    const isTerminal = dto.status === 'resolved' || dto.status === 'dismissed';

    return this.prisma.$transaction(async (tx) => {
      const updatedReport = await tx.report.update({
        where: { id: reportId },
        data: {
          status: dto.status,
          ...(dto.priority ? { priority: dto.priority } : {}),
          ...(resolvedStaffId ? { resolvedByStaffId: resolvedStaffId } : {}),
          ...(dto.actionTaken !== undefined
            ? { resolutionNotes: dto.actionTaken }
            : {}),
          resolvedAt: isTerminal ? new Date() : null,
        },
      });

      if (tx.moderationLog?.create) {
        await tx.moderationLog.create({
          data: {
            ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
            targetType: 'report',
            targetId: reportId,
            action: dto.status,
            notes: dto.actionTaken ?? null,
          },
        });
      }

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

  async getModerationLogs(page = 1, limit = 30, targetType?: string) {
    const skip = (page - 1) * limit;
    const where: any = targetType ? { targetType } : {};

    const [total, items] = await Promise.all([
      this.prisma.moderationLog.count({ where }),
      this.prisma.moderationLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          staff: { select: { id: true, fullName: true, email: true } },
        },
      }),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getAuditLogs(page = 1, limit = 50, query?: AuditLogQueryDto) {
    const skip = (page - 1) * limit;
    const where = this.buildAuditWhere(query);

    const [total, logs] = await Promise.all([
      this.prisma.auditLog.count({ where }),
      this.prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      logs,
      items: logs,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getAuditLogById(id: string) {
    const log = await this.prisma.auditLog.findUnique({ where: { id } });
    if (!log) {
      throw new NotFoundException('Audit log entry not found');
    }
    return log;
  }

  async exportAuditLogs(
    actorId: string,
    query: AuditLogQueryDto,
    ipAddress?: string,
  ) {
    const where = this.buildAuditWhere(query);
    const logs = await this.prisma.auditLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 2000,
    });

    await this.prisma.auditLog.create({
      data: {
        actorType: 'staff',
        actorId,
        action: 'AUDIT_LOGS_EXPORTED',
        targetEntity: 'audit_log',
        ipAddress: ipAddress?.slice(0, 50),
        diffPayload: {
          exportedCount: logs.length,
          format: query.format || 'csv',
        },
      },
    });

    if (query.format === 'json') {
      return { format: 'json', count: logs.length, items: logs };
    }

    const header =
      'id,createdAt,actorType,actorId,action,targetEntity,targetId,ipAddress';
    const rows = logs.map((l) =>
      [
        l.id,
        l.createdAt.toISOString(),
        l.actorType,
        l.actorId || '',
        l.action,
        l.targetEntity,
        l.targetId || '',
        l.ipAddress || '',
      ]
        .map(sanitizeCsvCell)
        .join(','),
    );
    return {
      format: 'csv',
      count: logs.length,
      csv: [header, ...rows].join('\n'),
    };
  }

  private buildAuditWhere(query?: AuditLogQueryDto) {
    const where: any = {};
    if (query?.actorType) where.actorType = query.actorType;
    if (query?.actorId) where.actorId = query.actorId;
    if (query?.action) {
      where.action = { contains: query.action.trim(), mode: 'insensitive' };
    }
    if (query?.targetEntity) where.targetEntity = query.targetEntity;
    if (query?.targetId) where.targetId = query.targetId;
    if (query?.from || query?.to) {
      where.createdAt = {
        ...(query.from ? { gte: new Date(query.from) } : {}),
        ...(query.to ? { lte: new Date(query.to) } : {}),
      };
    }
    if (query?.q) {
      where.OR = [
        { action: { contains: query.q.trim(), mode: 'insensitive' } },
        { targetEntity: { contains: query.q.trim(), mode: 'insensitive' } },
        { ipAddress: { contains: query.q.trim(), mode: 'insensitive' } },
      ];
    }
    return where;
  }

  async getPendingVerifications(
    page = 1,
    limit = 20,
    query?: VerificationQueueQueryDto,
    canReadDocuments = true,
  ) {
    const skip = (page - 1) * limit;
    const status = query?.status;

    const where: any = {
      ...(status === 'all' ? {} : { status: status || 'pending' }),
      ...(query?.documentType ? { documentType: query.documentType } : {}),
      ...(query?.q
        ? {
            account: {
              OR: [
                {
                  displayName: {
                    contains: query.q.trim(),
                    mode: 'insensitive',
                  },
                },
                {
                  owner: {
                    fullName: {
                      contains: query.q.trim(),
                      mode: 'insensitive',
                    },
                  },
                },
              ],
            },
          }
        : {}),
    };

    const [total, rawVerifications] = await Promise.all([
      this.prisma.accountVerification.count({ where }),
      this.prisma.accountVerification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          account: {
            select: {
              id: true,
              displayName: true,
              accountType: true,
              slug: true,
              verificationStatus: true,
              owner: { select: { id: true, fullName: true, phone: true } },
            },
          },
          reviewedBy: { select: { id: true, fullName: true, email: true } },
        },
      }),
    ]);

    const verifications = rawVerifications.map((v) => ({
      ...v,
      fileUrl: canReadDocuments ? v.fileUrl : null,
      documentNumber: canReadDocuments
        ? v.documentNumber
        : maskSensitiveDocNumber(v.documentNumber),
    }));

    return {
      verifications,
      items: verifications,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getVerificationDetail(
    verificationId: string,
    canReadDocuments: boolean,
  ) {
    const verification = await this.prisma.accountVerification.findUnique({
      where: { id: verificationId },
      include: {
        account: {
          select: {
            id: true,
            displayName: true,
            accountType: true,
            slug: true,
            verificationStatus: true,
            owner: {
              select: { id: true, fullName: true, phone: true, email: true },
            },
          },
        },
        reviewedBy: { select: { id: true, fullName: true, email: true } },
      },
    });
    if (!verification) {
      throw new NotFoundException('Account verification request not found');
    }

    const history = await this.prisma.moderationLog.findMany({
      where: { targetType: 'verification', targetId: verificationId },
      orderBy: { createdAt: 'desc' },
      include: { staff: { select: { id: true, fullName: true, email: true } } },
    });

    return {
      verification: {
        ...verification,
        fileUrl: canReadDocuments ? verification.fileUrl : null,
        documentNumber: canReadDocuments
          ? verification.documentNumber
          : maskSensitiveDocNumber(verification.documentNumber),
      },
      history,
    };
  }

  async getVerificationDocument(
    verificationId: string,
    actorId: string,
    ipAddress?: string,
    userAgent?: string,
  ) {
    const verification = await this.prisma.accountVerification.findUnique({
      where: { id: verificationId },
      select: {
        id: true,
        accountId: true,
        documentType: true,
        documentNumber: true,
        fileUrl: true,
        status: true,
      },
    });
    if (!verification) {
      throw new NotFoundException('Account verification request not found');
    }

    await this.prisma.auditLog.create({
      data: {
        actorType: 'staff',
        actorId,
        action: 'VERIFICATION_DOCUMENT_VIEWED',
        targetEntity: 'account_verification',
        targetId: verificationId,
        ipAddress: ipAddress?.slice(0, 50),
        userAgent: userAgent?.slice(0, 500),
        diffPayload: {
          accountId: verification.accountId,
          documentType: verification.documentType,
        },
      },
    });

    return {
      ...verification,
      accessedAt: new Date().toISOString(),
      accessedBy: actorId,
    };
  }

  async assignVerification(
    verificationId: string,
    actorId: string,
    assignedStaffId?: string | null,
  ) {
    const verification = await this.prisma.accountVerification.findUnique({
      where: { id: verificationId },
    });
    if (!verification) {
      throw new NotFoundException('Account verification request not found');
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.accountVerification.update({
        where: { id: verificationId },
        data: { assignedToStaffId: assignedStaffId ?? null },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'VERIFICATION_ASSIGNED',
          targetEntity: 'account_verification',
          targetId: verificationId,
          diffPayload: { assignedToStaffId: assignedStaffId ?? null },
        },
      });

      return updated;
    });
  }

  async adjudicateVerification(
    verificationId: string,
    moderatorId: string,
    dto: AdjudicateVerificationDto,
    ipAddress?: string,
    userAgent?: string,
    staffId?: string | null,
  ) {
    const verification = await this.prisma.accountVerification.findUnique({
      where: { id: verificationId },
    });

    if (!verification) {
      throw new NotFoundException('Account verification request not found');
    }

    if (
      (dto.action === 'reject' || dto.action === 'request_resubmission') &&
      !dto.rejectionReason?.trim()
    ) {
      throw new BadRequestException(
        'Rejection reason is required when rejecting or requesting resubmission',
      );
    }

    const resolvedStaffId = staffId === undefined ? moderatorId : staffId;
    const newStatus =
      dto.action === 'approve'
        ? 'approved'
        : dto.action === 'request_resubmission'
          ? 'resubmission'
          : 'rejected';
    const accountVerificationStatus =
      dto.action === 'approve'
        ? 'approved'
        : dto.action === 'request_resubmission'
          ? 'pending'
          : 'rejected';

    const currentStatus = verification.status;
    if (!['pending', 'resubmission'].includes(currentStatus)) {
      throw new ConflictException(
        'Account verification request has already been adjudicated',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const updateResult = await tx.accountVerification.updateMany({
        where: {
          id: verificationId,
          status: currentStatus,
        },
        data: {
          status: newStatus,
          rejectionReason:
            dto.action === 'approve' ? null : dto.rejectionReason!.trim(),
          ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
          ...(resolvedStaffId ? { reviewedByStaffId: resolvedStaffId } : {}),
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
        data: { verificationStatus: accountVerificationStatus },
      });

      await tx.moderationLog.create({
        data: {
          ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
          targetType: 'verification',
          targetId: verificationId,
          action: dto.action === 'approve' ? 'verify' : dto.action,
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
