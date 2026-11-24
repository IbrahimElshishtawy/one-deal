import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';
import {
  AccountType,
  SellerApplicationStatus,
  SellerDocumentStatus,
  VerificationStatus,
} from '../../../core/enums/domain.enums';
import {
  assertValidSellerStatusTransition,
  evaluateApplicationCompleteness,
  getRequiredDocumentTypes,
} from '../seller-application-state-machine';
import { PrivateDocumentStorageService } from './private-document-storage.service';
import {
  AdminApproveSellerApplicationDto,
  AdminRejectSellerApplicationDto,
  AdminReviewSellerApplicationDto,
  AdminSellerApplicationsQueryDto,
  AdminSuspendSellerDto,
  ConfirmVerificationDocumentDto,
  CreateSellerApplicationDto,
  RequestVerificationDocUploadUrlDto,
  ResubmitSellerApplicationDto,
  UpdateSellerApplicationDto,
} from '../dto/seller-application.dto';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';

export interface RequestAuditContext {
  requestId?: string;
  ipAddress?: string;
  userAgent?: string;
}

const ACTIVE_APPLICATION_STATUSES = [
  SellerApplicationStatus.DRAFT,
  SellerApplicationStatus.PENDING,
  SellerApplicationStatus.UNDER_REVIEW,
  SellerApplicationStatus.APPROVED,
];

@Injectable()
export class SellerApplicationService {
  private readonly logger = new Logger(SellerApplicationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly privateStorage: PrivateDocumentStorageService,
    private readonly securityAudit: SecurityAuditService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  // =========================================================================
  // BUYER-TO-SELLER APPLICATION WORKFLOW (USER ENDPOINTS)
  // =========================================================================

  /**
   * Initiates a buyer-to-seller conversion request by creating a DRAFT application.
   * Enforces single active application per user.
   */
  async requestSellerConversion(
    userId: string,
    dto: CreateSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        phone: true,
        email: true,
        isActive: true,
        deletedAt: true,
        moderationStatus: true,
        sellerStatus: true,
      },
    });

    if (!user || !user.isActive || user.deletedAt || user.moderationStatus !== 'active') {
      throw new ForbiddenException('Active user account is required to apply as a seller');
    }

    if (user.sellerStatus === SellerApplicationStatus.SUSPENDED) {
      throw new ForbiddenException(
        'Your seller privileges are currently suspended and cannot create a new application',
      );
    }

    if (user.sellerStatus === SellerApplicationStatus.APPROVED) {
      throw new ConflictException('User is already an approved seller');
    }

    // Check for duplicate active application
    const existingActive = await this.prisma.sellerApplication.findFirst({
      where: {
        userId,
        isActive: true,
        status: { in: ACTIVE_APPLICATION_STATUSES },
      },
      select: { id: true, status: true },
    });

    if (existingActive) {
      throw new ConflictException({
        code: 'DUPLICATE_SELLER_APPLICATION',
        message: `You already have an active seller application in status '${existingActive.status}'`,
        applicationId: existingActive.id,
        status: existingActive.status,
      });
    }

    // If user had a previously REJECTED application, guide them to resubmit instead of duplicating
    const existingRejected = await this.prisma.sellerApplication.findFirst({
      where: {
        userId,
        isActive: true,
        status: SellerApplicationStatus.REJECTED,
      },
      select: { id: true },
    });
    if (existingRejected) {
      throw new ConflictException({
        code: 'RESUBMISSION_REQUIRED',
        message:
          'You have a rejected seller application. Please use the resubmit endpoint to update and resubmit it.',
        applicationId: existingRejected.id,
      });
    }

    const previousStatus = user.sellerStatus as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      previousStatus,
      SellerApplicationStatus.DRAFT,
    );

    const businessType = dto.businessType ?? AccountType.INDIVIDUAL;

    try {
      const created = await this.prisma.$transaction(async (tx) => {
        const application = await tx.sellerApplication.create({
          data: {
            userId,
            status: SellerApplicationStatus.DRAFT,
            businessType,
            businessName: dto.businessName?.trim() || user.fullName,
            businessDescription: dto.businessDescription?.trim() || null,
            nationalIdNumber: dto.nationalIdNumber?.trim() || null,
            taxIdNumber: dto.taxIdNumber?.trim() || null,
            commercialRegisterNumber: dto.commercialRegisterNumber?.trim() || null,
            contactPhone: dto.contactPhone?.trim() || user.phone,
            contactEmail: dto.contactEmail?.trim() || user.email || null,
            cityId: dto.cityId ?? null,
            address: dto.address?.trim() || null,
            isActive: true,
          },
          include: { documents: true },
        });

        await tx.user.update({
          where: { id: userId },
          data: { sellerStatus: SellerApplicationStatus.DRAFT },
        });

        await tx.sellerApplicationHistory.create({
          data: {
            applicationId: application.id,
            userId,
            actorType: 'user',
            previousStatus,
            newStatus: SellerApplicationStatus.DRAFT,
            reason: 'Buyer requested seller conversion',
            metadata: {
              requestId: ctx.requestId ?? null,
              businessType,
            },
          },
        });

        return application;
      });

      await this.securityAudit.logEvent({
        action: 'SELLER_APPLICATION_CREATED',
        actorType: 'user',
        actorId: userId,
        targetEntity: 'SellerApplication',
        targetId: created.id,
        ipAddress: ctx.ipAddress,
        userAgent: ctx.userAgent,
        correlationId: ctx.requestId,
        metadata: {
          requestId: ctx.requestId ?? null,
          userId,
          applicationId: created.id,
          previousStatus,
          newStatus: SellerApplicationStatus.DRAFT,
          result: 'SUCCESS',
          timestamp: new Date().toISOString(),
        },
      });

      return this.formatApplicationForUser(created);
    } catch (err: any) {
      if (err?.code === 'P2002') {
        throw new ConflictException({
          code: 'DUPLICATE_SELLER_APPLICATION',
          message: 'An active seller application already exists for this user',
        });
      }
      throw err;
    }
  }

  /**
   * Updates the current user's seller application draft.
   */
  async updateDraft(
    userId: string,
    dto: UpdateSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'desc' },
      include: { documents: true },
    });

    if (!application) {
      throw new NotFoundException(
        'No seller application found. Please request seller conversion first.',
      );
    }

    if (application.status !== SellerApplicationStatus.DRAFT) {
      throw new BadRequestException(
        `Seller application cannot be edited while in status '${application.status}'. Only DRAFT applications can be updated.`,
      );
    }

    const updated = await this.prisma.sellerApplication.update({
      where: { id: application.id },
      data: {
        ...(dto.businessType !== undefined
          ? { businessType: dto.businessType }
          : {}),
        ...(dto.businessName !== undefined
          ? { businessName: dto.businessName.trim() }
          : {}),
        ...(dto.businessDescription !== undefined
          ? { businessDescription: dto.businessDescription.trim() }
          : {}),
        ...(dto.nationalIdNumber !== undefined
          ? { nationalIdNumber: dto.nationalIdNumber.trim() }
          : {}),
        ...(dto.taxIdNumber !== undefined
          ? { taxIdNumber: dto.taxIdNumber.trim() }
          : {}),
        ...(dto.commercialRegisterNumber !== undefined
          ? { commercialRegisterNumber: dto.commercialRegisterNumber.trim() }
          : {}),
        ...(dto.contactPhone !== undefined
          ? { contactPhone: dto.contactPhone.trim() }
          : {}),
        ...(dto.contactEmail !== undefined
          ? { contactEmail: dto.contactEmail.trim() }
          : {}),
        ...(dto.cityId !== undefined ? { cityId: dto.cityId } : {}),
        ...(dto.address !== undefined ? { address: dto.address.trim() } : {}),
      },
      include: { documents: true },
    });

    await this.securityAudit.logEvent({
      action: 'SELLER_APPLICATION_DRAFT_UPDATED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerApplication',
      targetId: updated.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        userId,
        applicationId: updated.id,
        updatedFields: Object.keys(dto),
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return this.formatApplicationForUser(updated);
  }

  /**
   * Generates a private direct-to-storage presigned PUT URL for uploading a verification document.
   */
  async requestDocumentUploadUrl(
    userId: string,
    dto: RequestVerificationDocUploadUrlDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.getEditableApplicationForUser(userId);

    const target = this.privateStorage.generatePrivateUploadUrl(
      userId,
      application.id,
      dto.mimeType,
      dto.fileSizeBytes,
    );

    await this.securityAudit.logEvent({
      action: 'SELLER_DOCUMENT_UPLOAD_URL_ISSUED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerApplication',
      targetId: application.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        userId,
        applicationId: application.id,
        documentType: dto.documentType,
        mimeType: dto.mimeType,
        fileSizeBytes: dto.fileSizeBytes,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      applicationId: application.id,
      documentType: dto.documentType,
      ...target,
    };
  }

  /**
   * Confirms and registers an uploaded private verification document on the user's active application.
   */
  async registerDocument(
    userId: string,
    dto: ConfirmVerificationDocumentDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.getEditableApplicationForUser(userId);

    this.privateStorage.validateFileMetadata(dto.mimeType, dto.fileSizeBytes);
    this.privateStorage.validatePrivateDocumentOwnership(
      userId,
      application.id,
      dto.storageKey,
    );

    // Replace existing document of same type if re-uploading while in DRAFT/REJECTED
    const document = await this.prisma.$transaction(async (tx) => {
      await tx.sellerApplicationDocument.deleteMany({
        where: {
          applicationId: application.id,
          documentType: dto.documentType,
        },
      });

      return tx.sellerApplicationDocument.create({
        data: {
          applicationId: application.id,
          userId,
          documentType: dto.documentType,
          storageKey: dto.storageKey,
          originalFileName: dto.originalFileName.trim().slice(0, 255),
          mimeType: dto.mimeType,
          fileSizeBytes: dto.fileSizeBytes,
          checksumSha256: dto.checksumSha256?.trim() || null,
          status: SellerDocumentStatus.UPLOADED,
          uploadedAt: new Date(),
        },
      });
    });

    await this.securityAudit.logEvent({
      action: 'SELLER_DOCUMENT_UPLOADED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerApplicationDocument',
      targetId: document.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        userId,
        applicationId: application.id,
        documentId: document.id,
        documentType: document.documentType,
        mimeType: document.mimeType,
        fileSizeBytes: document.fileSizeBytes,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return this.sanitizeDocumentForUser(document);
  }

  /**
   * Removes an uploaded verification document while the application is editable (DRAFT or REJECTED).
   */
  async deleteDocument(
    userId: string,
    documentId: string,
    ctx: RequestAuditContext = {},
  ) {
    const doc = await this.prisma.sellerApplicationDocument.findUnique({
      where: { id: documentId },
      include: { application: true },
    });

    if (!doc) {
      throw new NotFoundException('Verification document not found');
    }

    if (doc.userId !== userId || doc.application.userId !== userId) {
      throw new ForbiddenException(
        'You do not have permission to delete this verification document',
      );
    }

    if (
      ![
        SellerApplicationStatus.DRAFT,
        SellerApplicationStatus.REJECTED,
      ].includes(doc.application.status as SellerApplicationStatus)
    ) {
      throw new BadRequestException(
        'Documents cannot be removed after application submission',
      );
    }

    await this.prisma.sellerApplicationDocument.delete({
      where: { id: documentId },
    });

    await this.securityAudit.logEvent({
      action: 'SELLER_DOCUMENT_DELETED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerApplicationDocument',
      targetId: documentId,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        userId,
        applicationId: doc.applicationId,
        documentType: doc.documentType,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return { success: true };
  }

  /**
   * Returns a short-lived private signed access URL for the applicant's own verification document.
   * Strictly enforces ownership so no user can read another user's private documents.
   */
  async getOwnDocumentAccessUrl(
    userId: string,
    documentId: string,
    ctx: RequestAuditContext = {},
  ) {
    const doc = await this.prisma.sellerApplicationDocument.findUnique({
      where: { id: documentId },
    });

    if (!doc) {
      throw new NotFoundException('Verification document not found');
    }

    if (doc.userId !== userId) {
      await this.securityAudit.logEvent({
        action: 'UNAUTHORIZED_DOCUMENT_ACCESS_ATTEMPTED',
        actorType: 'user',
        actorId: userId,
        targetEntity: 'SellerApplicationDocument',
        targetId: documentId,
        ipAddress: ctx.ipAddress,
        userAgent: ctx.userAgent,
        correlationId: ctx.requestId,
        metadata: {
          requestId: ctx.requestId ?? null,
          userId,
          applicationId: doc.applicationId,
          result: 'DENIED',
          timestamp: new Date().toISOString(),
        },
      });
      throw new ForbiddenException(
        'You do not have permission to access this verification document',
      );
    }

    const access = this.privateStorage.generatePrivateAccessUrl(
      doc.storageKey,
      300,
    );

    await this.securityAudit.logEvent({
      action: 'SELLER_DOCUMENT_ACCESSED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerApplicationDocument',
      targetId: documentId,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        userId,
        applicationId: doc.applicationId,
        documentType: doc.documentType,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      documentId: doc.id,
      documentType: doc.documentType,
      originalFileName: doc.originalFileName,
      mimeType: doc.mimeType,
      fileSizeBytes: doc.fileSizeBytes,
      ...access,
    };
  }

  /**
   * Submits a DRAFT seller application for mandatory admin verification (DRAFT -> PENDING).
   */
  async submitApplication(userId: string, ctx: RequestAuditContext = {}) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'desc' },
      include: { documents: true },
    });

    if (!application) {
      throw new NotFoundException(
        'No seller application draft found. Please create a seller application first.',
      );
    }

    const currentStatus = application.status as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.PENDING,
    );

    const completeness = evaluateApplicationCompleteness({
      businessType: application.businessType,
      businessName: application.businessName,
      nationalIdNumber: application.nationalIdNumber,
      commercialRegisterNumber: application.commercialRegisterNumber,
      documents: application.documents,
    });

    if (!completeness.isComplete) {
      throw new BadRequestException({
        code: 'INCOMPLETE_SELLER_APPLICATION',
        message:
          'Seller application is incomplete. Please provide all required fields and verification documents before submitting.',
        missingFields: completeness.missingFields,
        missingDocuments: completeness.missingDocuments,
      });
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.sellerApplication.updateMany({
        where: { id: application.id, status: currentStatus },
        data: {
          status: SellerApplicationStatus.PENDING,
          submittedAt: new Date(),
          rejectionReason: null,
        },
      });

      if (result.count === 0) {
        throw new ConflictException(
          'Seller application status changed concurrently. Please refresh and retry.',
        );
      }

      await tx.user.update({
        where: { id: userId },
        data: { sellerStatus: SellerApplicationStatus.PENDING },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId: application.id,
          userId,
          actorType: 'user',
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.PENDING,
          reason: 'Seller application submitted for admin verification',
          metadata: {
            requestId: ctx.requestId ?? null,
            documentCount: application.documents.length,
          },
        },
      });

      return tx.sellerApplication.findUniqueOrThrow({
        where: { id: application.id },
        include: { documents: true },
      });
    });

    await this.securityAudit.logEvent({
      action: 'SELLER_APPLICATION_SUBMITTED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerApplication',
      targetId: updated.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        userId,
        applicationId: updated.id,
        previousStatus: currentStatus,
        newStatus: SellerApplicationStatus.PENDING,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return this.formatApplicationForUser(updated);
  }

  /**
   * Allows a REJECTED seller to reopen their application as DRAFT or resubmit directly to PENDING.
   */
  async resubmitApplication(
    userId: string,
    dto: ResubmitSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'desc' },
      include: { documents: true },
    });

    if (!application) {
      throw new NotFoundException('No seller application found');
    }

    const currentStatus = application.status as SellerApplicationStatus;
    if (currentStatus !== SellerApplicationStatus.REJECTED) {
      throw new BadRequestException({
        code: 'INVALID_SELLER_STATUS_TRANSITION',
        message: `Only REJECTED applications can be resubmitted (current status: '${currentStatus}')`,
      });
    }

    const targetStatus = dto.submitImmediately
      ? SellerApplicationStatus.PENDING
      : SellerApplicationStatus.DRAFT;

    assertValidSellerStatusTransition(currentStatus, targetStatus);

    const mergedBusinessType = dto.businessType ?? application.businessType;
    const mergedBusinessName =
      dto.businessName !== undefined
        ? dto.businessName.trim()
        : application.businessName;
    const mergedNationalId =
      dto.nationalIdNumber !== undefined
        ? dto.nationalIdNumber.trim()
        : application.nationalIdNumber;
    const mergedCr =
      dto.commercialRegisterNumber !== undefined
        ? dto.commercialRegisterNumber.trim()
        : application.commercialRegisterNumber;

    if (targetStatus === SellerApplicationStatus.PENDING) {
      const completeness = evaluateApplicationCompleteness({
        businessType: mergedBusinessType,
        businessName: mergedBusinessName,
        nationalIdNumber: mergedNationalId,
        commercialRegisterNumber: mergedCr,
        documents: application.documents,
      });

      if (!completeness.isComplete) {
        throw new BadRequestException({
          code: 'INCOMPLETE_SELLER_APPLICATION',
          message:
            'Cannot immediately resubmit incomplete application. Reopen as DRAFT first or complete missing fields/documents.',
          missingFields: completeness.missingFields,
          missingDocuments: completeness.missingDocuments,
        });
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.sellerApplication.update({
        where: { id: application.id },
        data: {
          status: targetStatus,
          businessType: mergedBusinessType,
          businessName: mergedBusinessName,
          ...(dto.businessDescription !== undefined
            ? { businessDescription: dto.businessDescription.trim() }
            : {}),
          nationalIdNumber: mergedNationalId,
          ...(dto.taxIdNumber !== undefined
            ? { taxIdNumber: dto.taxIdNumber.trim() }
            : {}),
          commercialRegisterNumber: mergedCr,
          ...(dto.contactPhone !== undefined
            ? { contactPhone: dto.contactPhone.trim() }
            : {}),
          ...(dto.contactEmail !== undefined
            ? { contactEmail: dto.contactEmail.trim() }
            : {}),
          ...(dto.cityId !== undefined ? { cityId: dto.cityId } : {}),
          ...(dto.address !== undefined
            ? { address: dto.address.trim() }
            : {}),
          resubmissionCount: { increment: 1 },
          ...(targetStatus === SellerApplicationStatus.PENDING
            ? { submittedAt: new Date(), rejectionReason: null }
            : {}),
        },
        include: { documents: true },
      });

      await tx.user.update({
        where: { id: userId },
        data: { sellerStatus: targetStatus },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId: application.id,
          userId,
          actorType: 'user',
          previousStatus: currentStatus,
          newStatus: targetStatus,
          reason: dto.submitImmediately
            ? 'Rejected application resubmitted for verification'
            : 'Rejected application reopened as draft for edits',
          metadata: {
            requestId: ctx.requestId ?? null,
            resubmissionCount: next.resubmissionCount,
          },
        },
      });

      return next;
    });

    await this.securityAudit.logEvent({
      action:
        targetStatus === SellerApplicationStatus.PENDING
          ? 'SELLER_APPLICATION_SUBMITTED'
          : 'SELLER_APPLICATION_RESUBMISSION_DRAFT_OPENED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerApplication',
      targetId: updated.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        userId,
        applicationId: updated.id,
        previousStatus: currentStatus,
        newStatus: targetStatus,
        resubmissionCount: updated.resubmissionCount,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return this.formatApplicationForUser(updated);
  }

  /**
   * Returns current user's seller status, capabilities, and latest seller application.
   */
  async getMyApplication(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        sellerStatus: true,
        sellerApprovedAt: true,
        sellerSuspendedAt: true,
        sellerSuspensionReason: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'desc' },
      include: {
        documents: { orderBy: { createdAt: 'asc' } },
      },
    });

    const isApproved = user.sellerStatus === SellerApplicationStatus.APPROVED;

    return {
      userId: user.id,
      sellerStatus: user.sellerStatus,
      roles: isApproved ? ['BUYER', 'SELLER'] : ['BUYER'],
      capabilities: {
        canBuy: true,
        canCreateListing: isApproved,
        canManageListing: isApproved,
        canAccessSellerDashboard: isApproved,
        canSubmitSellerApplication:
          user.sellerStatus !== SellerApplicationStatus.APPROVED &&
          user.sellerStatus !== SellerApplicationStatus.SUSPENDED,
      },
      sellerApprovedAt: user.sellerApprovedAt,
      sellerSuspendedAt: user.sellerSuspendedAt,
      sellerSuspensionReason: user.sellerSuspensionReason,
      application: application
        ? this.formatApplicationForUser(application)
        : null,
    };
  }

  /**
   * Returns chronological seller application history for the authenticated user.
   */
  async getMyApplicationHistory(userId: string) {
    const entries = await this.prisma.sellerApplicationHistory.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        applicationId: true,
        actorType: true,
        previousStatus: true,
        newStatus: true,
        reason: true,
        createdAt: true,
      },
    });

    return {
      userId,
      items: entries,
    };
  }

  /**
   * Seller Dashboard summary (protected by SellerAuthorizationGuard CAN_ACCESS_SELLER_DASHBOARD).
   */
  async getSellerDashboard(userId: string) {
    const accounts = await this.prisma.account.findMany({
      where: {
        isActive: true,
        deletedAt: null,
        verificationStatus: VerificationStatus.APPROVED,
        OR: [{ ownerUserId: userId }, { members: { some: { userId } } }],
      },
      select: {
        id: true,
        displayName: true,
        slug: true,
        accountType: true,
        verificationStatus: true,
        _count: {
          select: {
            listings: { where: { deletedAt: null } },
            branches: true,
          },
        },
      },
    });

    const accountIds = accounts.map((a) => a.id);
    const [publishedCount, pendingCount, totalViews] =
      accountIds.length > 0
        ? await Promise.all([
            this.prisma.listing.count({
              where: {
                accountId: { in: accountIds },
                publicationStatus: 'published',
                deletedAt: null,
              },
            }),
            this.prisma.listing.count({
              where: {
                accountId: { in: accountIds },
                moderationStatus: 'pending',
                deletedAt: null,
              },
            }),
            this.prisma.listing.aggregate({
              where: { accountId: { in: accountIds }, deletedAt: null },
              _sum: { viewsCount: true },
            }),
          ])
        : [0, 0, { _sum: { viewsCount: 0 } }];

    return {
      sellerStatus: SellerApplicationStatus.APPROVED,
      accounts,
      metrics: {
        publishedListings: publishedCount,
        pendingModerationListings: pendingCount,
        totalViews: totalViews._sum.viewsCount ?? 0,
      },
    };
  }

  // =========================================================================
  // ADMIN APPROVAL & GOVERNANCE WORKFLOW
  // =========================================================================

  async listApplicationsForAdmin(
    query: AdminSellerApplicationsQueryDto,
    canReadDocuments: boolean,
  ) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: Prisma.SellerApplicationWhereInput = {
      ...(query.status && query.status !== 'all'
        ? { status: query.status.toUpperCase() }
        : query.status === 'all'
          ? {}
          : { status: { in: [SellerApplicationStatus.PENDING, SellerApplicationStatus.UNDER_REVIEW] } }),
      ...(query.businessType ? { businessType: query.businessType } : {}),
      ...(query.q
        ? {
            OR: [
              { businessName: { contains: query.q.trim(), mode: 'insensitive' } },
              {
                user: {
                  fullName: { contains: query.q.trim(), mode: 'insensitive' },
                },
              },
              {
                user: {
                  phone: { contains: query.q.trim(), mode: 'insensitive' },
                },
              },
            ],
          }
        : {}),
    };

    const [total, rawItems] = await Promise.all([
      this.prisma.sellerApplication.count({ where }),
      this.prisma.sellerApplication.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ submittedAt: 'asc' }, { createdAt: 'desc' }],
        include: {
          user: {
            select: {
              id: true,
              fullName: true,
              phone: true,
              email: true,
              sellerStatus: true,
              isActive: true,
            },
          },
          reviewedBy: { select: { id: true, fullName: true, email: true } },
          assignedTo: { select: { id: true, fullName: true, email: true } },
          documents: {
            select: {
              id: true,
              documentType: true,
              originalFileName: true,
              mimeType: true,
              fileSizeBytes: true,
              status: true,
              uploadedAt: true,
            },
          },
        },
      }),
    ]);

    const items = rawItems.map((app) => ({
      ...app,
      nationalIdNumber: canReadDocuments
        ? app.nationalIdNumber
        : this.maskSensitive(app.nationalIdNumber),
      taxIdNumber: canReadDocuments
        ? app.taxIdNumber
        : this.maskSensitive(app.taxIdNumber),
    }));

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

  async getApplicationDetailForAdmin(
    applicationId: string,
    canReadDocuments: boolean,
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            phone: true,
            email: true,
            sellerStatus: true,
            isActive: true,
            moderationStatus: true,
            createdAt: true,
          },
        },
        account: {
          select: {
            id: true,
            displayName: true,
            slug: true,
            accountType: true,
            verificationStatus: true,
            isActive: true,
          },
        },
        reviewedBy: { select: { id: true, fullName: true, email: true } },
        assignedTo: { select: { id: true, fullName: true, email: true } },
        documents: {
          orderBy: { createdAt: 'asc' },
          select: {
            id: true,
            documentType: true,
            originalFileName: true,
            mimeType: true,
            fileSizeBytes: true,
            status: true,
            uploadedAt: true,
            createdAt: true,
          },
        },
        history: {
          orderBy: { createdAt: 'desc' },
          include: {
            admin: { select: { id: true, fullName: true, email: true } },
          },
        },
      },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    const completeness = evaluateApplicationCompleteness({
      businessType: app.businessType,
      businessName: app.businessName,
      nationalIdNumber: app.nationalIdNumber,
      commercialRegisterNumber: app.commercialRegisterNumber,
      documents: app.documents,
    });

    return {
      application: {
        ...app,
        nationalIdNumber: canReadDocuments
          ? app.nationalIdNumber
          : this.maskSensitive(app.nationalIdNumber),
        taxIdNumber: canReadDocuments
          ? app.taxIdNumber
          : this.maskSensitive(app.taxIdNumber),
      },
      completeness,
    };
  }

  async getApplicationHistoryForAdmin(applicationId: string) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      select: { id: true, userId: true, status: true },
    });
    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    const history = await this.prisma.sellerApplicationHistory.findMany({
      where: { applicationId },
      orderBy: { createdAt: 'desc' },
      include: {
        admin: { select: { id: true, fullName: true, email: true } },
      },
    });

    return {
      applicationId: app.id,
      userId: app.userId,
      currentStatus: app.status,
      history,
    };
  }

  /**
   * Generates a short-lived private signed URL for an authorized admin to review a verification document.
   * Strictly audited.
   */
  async getDocumentAccessForAdmin(
    applicationId: string,
    documentId: string,
    staff: AuthenticatedStaff,
    ctx: RequestAuditContext = {},
  ) {
    const doc = await this.prisma.sellerApplicationDocument.findFirst({
      where: { id: documentId, applicationId },
    });

    if (!doc) {
      throw new NotFoundException(
        'Verification document not found for this application',
      );
    }

    const access = this.privateStorage.generatePrivateAccessUrl(
      doc.storageKey,
      300,
    );

    await this.securityAudit.logEvent({
      action: 'ADMIN_SELLER_DOCUMENT_ACCESSED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'SellerApplicationDocument',
      targetId: doc.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        adminId: staff.id,
        userId: doc.userId,
        applicationId: doc.applicationId,
        documentType: doc.documentType,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      documentId: doc.id,
      applicationId: doc.applicationId,
      documentType: doc.documentType,
      originalFileName: doc.originalFileName,
      mimeType: doc.mimeType,
      fileSizeBytes: doc.fileSizeBytes,
      status: doc.status,
      ...access,
      accessedBy: staff.id,
      accessedAt: new Date().toISOString(),
    };
  }

  /**
   * Marks a PENDING seller application as UNDER_REVIEW (PENDING -> UNDER_REVIEW).
   */
  async startReview(
    applicationId: string,
    staff: AuthenticatedStaff,
    dto: AdminReviewSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: { user: { select: { id: true, email: true, phone: true } } },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    this.assertNotSelfAction(app, staff);

    const currentStatus = app.status as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.UNDER_REVIEW,
    );

    const resolvedStaffId = staff.staffId ?? null;

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.sellerApplication.updateMany({
        where: { id: applicationId, status: currentStatus },
        data: {
          status: SellerApplicationStatus.UNDER_REVIEW,
          ...(resolvedStaffId ? { assignedToStaffId: resolvedStaffId } : {}),
          ...(dto.notes ? { adminNotes: dto.notes.trim() } : {}),
        },
      });

      if (res.count === 0) {
        throw new ConflictException(
          'Seller application status was modified concurrently',
        );
      }

      await tx.user.update({
        where: { id: app.userId },
        data: { sellerStatus: SellerApplicationStatus.UNDER_REVIEW },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId,
          userId: app.userId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          actorType: 'staff',
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.UNDER_REVIEW,
          reason: dto.notes?.trim() || 'Application placed under admin review',
          metadata: {
            requestId: ctx.requestId ?? null,
            actorId: staff.id,
          },
        },
      });

      return tx.sellerApplication.findUniqueOrThrow({
        where: { id: applicationId },
      });
    });

    await this.securityAudit.logEvent({
      action: 'SELLER_APPLICATION_REVIEWED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'SellerApplication',
      targetId: applicationId,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        requestId: ctx.requestId ?? null,
        adminId: staff.id,
        userId: app.userId,
        applicationId,
        previousStatus: currentStatus,
        newStatus: SellerApplicationStatus.UNDER_REVIEW,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return updated;
  }

  /**
   * Approves a complete seller application in a single atomic transaction:
   *  - Prevents self-approval, duplicate approval, and incomplete approval
   *  - Transitions application to APPROVED
   *  - Grants seller permissions (User.sellerStatus = APPROVED) while retaining all buyer permissions
   *  - Creates or activates the user's seller Account + AccountMember(owner)
   *  - Records SellerApplicationHistory, ModerationLog, and AuditLog
   */
  async approveApplication(
    applicationId: string,
    staff: AuthenticatedStaff,
    dto: AdminApproveSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: {
        documents: true,
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            isActive: true,
            deletedAt: true,
          },
        },
      },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    if (!app.user.isActive || app.user.deletedAt) {
      throw new BadRequestException(
        'Cannot approve seller application for an inactive or deleted user',
      );
    }

    this.assertNotSelfAction(app, staff);

    const currentStatus = app.status as SellerApplicationStatus;
    if (currentStatus === SellerApplicationStatus.APPROVED) {
      throw new ConflictException({
        code: 'DUPLICATE_APPROVAL',
        message: 'Seller application has already been approved',
      });
    }

    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.APPROVED,
    );

    const completeness = evaluateApplicationCompleteness({
      businessType: app.businessType,
      businessName: app.businessName,
      nationalIdNumber: app.nationalIdNumber,
      commercialRegisterNumber: app.commercialRegisterNumber,
      documents: app.documents,
    });

    if (!completeness.isComplete) {
      throw new BadRequestException({
        code: 'INCOMPLETE_SELLER_APPLICATION',
        message:
          'Cannot approve an incomplete seller application. Required fields or documents are missing.',
        missingFields: completeness.missingFields,
        missingDocuments: completeness.missingDocuments,
      });
    }

    const resolvedStaffId = staff.staffId ?? null;
    const now = new Date();

    const result = await this.prisma.$transaction(async (tx) => {
      // Optimistic concurrency check to prevent duplicate approval race conditions
      const lockResult = await tx.sellerApplication.updateMany({
        where: {
          id: applicationId,
          status: currentStatus,
        },
        data: {
          status: SellerApplicationStatus.APPROVED,
          reviewedAt: now,
          ...(resolvedStaffId ? { reviewedByStaffId: resolvedStaffId } : {}),
          rejectionReason: null,
          suspensionReason: null,
          ...(dto.notes ? { adminNotes: dto.notes.trim() } : {}),
        },
      });

      if (lockResult.count === 0) {
        throw new ConflictException({
          code: 'DUPLICATE_APPROVAL',
          message: 'Seller application has already been adjudicated',
        });
      }

      // Mark uploaded verification documents as VERIFIED
      await tx.sellerApplicationDocument.updateMany({
        where: {
          applicationId,
          status: SellerDocumentStatus.UPLOADED,
        },
        data: { status: SellerDocumentStatus.VERIFIED },
      });

      // Reuse existing owned account if present, otherwise create a new approved seller account
      let sellerAccount = app.accountId
        ? await tx.account.findUnique({ where: { id: app.accountId } })
        : await tx.account.findFirst({
            where: { ownerUserId: app.userId, deletedAt: null },
            orderBy: { createdAt: 'asc' },
          });

      if (sellerAccount) {
        sellerAccount = await tx.account.update({
          where: { id: sellerAccount.id },
          data: {
            displayName: app.businessName || sellerAccount.displayName,
            accountType: app.businessType || sellerAccount.accountType,
            bio: app.businessDescription ?? sellerAccount.bio,
            verificationStatus: VerificationStatus.APPROVED,
            isActive: true,
          },
        });
      } else {
        const baseSlug = (app.businessName || app.user.fullName || 'seller')
          .toLowerCase()
          .trim()
          .replace(/[^\w\s-]/g, '')
          .replace(/[\s_-]+/g, '-')
          .replace(/^-+|-+$/g, '')
          .substring(0, 50);
        const slug = `${baseSlug || 'seller'}-${app.userId.substring(0, 8)}-${Math.random().toString(36).substring(2, 6)}`;

        sellerAccount = await tx.account.create({
          data: {
            ownerUserId: app.userId,
            accountType: app.businessType || AccountType.INDIVIDUAL,
            displayName: app.businessName || app.user.fullName,
            slug,
            bio: app.businessDescription,
            verificationStatus: VerificationStatus.APPROVED,
            isActive: true,
          },
        });
      }

      // Ensure owner membership exists
      await tx.accountMember.upsert({
        where: {
          uq_account_user: {
            accountId: sellerAccount.id,
            userId: app.userId,
          },
        },
        update: { role: 'owner' },
        create: {
          accountId: sellerAccount.id,
          userId: app.userId,
          role: 'owner',
        },
      });

      // Link accountId to application
      const updatedApplication = await tx.sellerApplication.update({
        where: { id: applicationId },
        data: { accountId: sellerAccount.id },
        include: { documents: true },
      });

      // Grant seller privileges on the single unified User record (buyer capabilities untouched)
      await tx.user.update({
        where: { id: app.userId },
        data: {
          sellerStatus: SellerApplicationStatus.APPROVED,
          sellerApprovedAt: now,
          sellerSuspendedAt: null,
          sellerSuspensionReason: null,
        },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId,
          userId: app.userId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          actorType: 'staff',
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.APPROVED,
          reason: dto.notes?.trim() || 'Seller application approved',
          metadata: {
            requestId: ctx.requestId ?? null,
            actorId: staff.id,
            accountId: sellerAccount.id,
          },
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
          targetType: 'verification',
          targetId: applicationId,
          action: 'verify',
          notes: dto.notes?.trim() || 'Seller application approved',
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: staff.id,
          action: 'SELLER_APPLICATION_APPROVED',
          targetEntity: 'seller_application',
          targetId: applicationId,
          ipAddress: ctx.ipAddress?.slice(0, 50),
          userAgent: ctx.userAgent?.slice(0, 500),
          diffPayload: {
            requestId: ctx.requestId ?? null,
            userId: app.userId,
            adminId: staff.id,
            applicationId,
            accountId: sellerAccount.id,
            previousStatus: currentStatus,
            newStatus: SellerApplicationStatus.APPROVED,
            result: 'SUCCESS',
            timestamp: now.toISOString(),
          },
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: staff.id,
          action: 'SELLER_PERMISSIONS_GRANTED',
          targetEntity: 'user',
          targetId: app.userId,
          ipAddress: ctx.ipAddress?.slice(0, 50),
          userAgent: ctx.userAgent?.slice(0, 500),
          diffPayload: {
            requestId: ctx.requestId ?? null,
            userId: app.userId,
            adminId: staff.id,
            applicationId,
            accountId: sellerAccount.id,
            result: 'SUCCESS',
            timestamp: now.toISOString(),
          },
        },
      });

      return { application: updatedApplication, account: sellerAccount };
    });

    await this.invalidateAccountCache(app.userId, result.account.id);

    return result;
  }

  /**
   * Rejects a PENDING or UNDER_REVIEW seller application with a mandatory reason.
   */
  async rejectApplication(
    applicationId: string,
    staff: AuthenticatedStaff,
    dto: AdminRejectSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: { user: { select: { id: true, email: true, phone: true } } },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    this.assertNotSelfAction(app, staff);

    const currentStatus = app.status as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.REJECTED,
    );

    const reason = dto.reason.trim();
    if (reason.length < 5) {
      throw new BadRequestException(
        'A rejection reason of at least 5 characters is mandatory',
      );
    }

    const resolvedStaffId = staff.staffId ?? null;
    const now = new Date();

    const updated = await this.prisma.$transaction(async (tx) => {
      const lockResult = await tx.sellerApplication.updateMany({
        where: { id: applicationId, status: currentStatus },
        data: {
          status: SellerApplicationStatus.REJECTED,
          rejectionReason: reason,
          reviewedAt: now,
          ...(resolvedStaffId ? { reviewedByStaffId: resolvedStaffId } : {}),
          ...(dto.notes ? { adminNotes: dto.notes.trim() } : {}),
        },
      });

      if (lockResult.count === 0) {
        throw new ConflictException(
          'Seller application has already been adjudicated',
        );
      }

      await tx.user.update({
        where: { id: app.userId },
        data: { sellerStatus: SellerApplicationStatus.REJECTED },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId,
          userId: app.userId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          actorType: 'staff',
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.REJECTED,
          reason,
          metadata: {
            requestId: ctx.requestId ?? null,
            actorId: staff.id,
          },
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
          targetType: 'verification',
          targetId: applicationId,
          action: 'reject',
          notes: reason,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: staff.id,
          action: 'SELLER_APPLICATION_REJECTED',
          targetEntity: 'seller_application',
          targetId: applicationId,
          ipAddress: ctx.ipAddress?.slice(0, 50),
          userAgent: ctx.userAgent?.slice(0, 500),
          diffPayload: {
            requestId: ctx.requestId ?? null,
            userId: app.userId,
            adminId: staff.id,
            applicationId,
            previousStatus: currentStatus,
            newStatus: SellerApplicationStatus.REJECTED,
            reason,
            result: 'SUCCESS',
            timestamp: now.toISOString(),
          },
        },
      });

      return tx.sellerApplication.findUniqueOrThrow({
        where: { id: applicationId },
      });
    });

    return updated;
  }

  /**
   * Suspends an APPROVED seller's privileges immediately.
   *
   * CRITICAL INVARIANT:
   * - Revokes seller capabilities immediately (`User.sellerStatus = SUSPENDED`,
   *   `Account.verificationStatus = 'suspended'`, Redis membership cache invalidated).
   * - Preserves `User.isActive = true` and `User.moderationStatus = 'active'`
   *   so ALL buyer permissions (browsing, searching, favoriting, cart, bookings,
   *   RFQs, chat, purchasing) remain 100% active!
   */
  async suspendSeller(
    applicationId: string,
    staff: AuthenticatedStaff,
    dto: AdminSuspendSellerDto,
    ctx: RequestAuditContext = {},
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: { user: { select: { id: true, email: true, phone: true } } },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    this.assertNotSelfAction(app, staff);

    const currentStatus = app.status as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.SUSPENDED,
    );

    const reason = dto.reason.trim();
    if (reason.length < 5) {
      throw new BadRequestException(
        'A suspension reason of at least 5 characters is mandatory',
      );
    }

    const resolvedStaffId = staff.staffId ?? null;
    const now = new Date();

    const ownedAccounts = await this.prisma.account.findMany({
      where: { ownerUserId: app.userId, deletedAt: null },
      select: { id: true },
    });

    const updated = await this.prisma.$transaction(async (tx) => {
      const lockResult = await tx.sellerApplication.updateMany({
        where: { id: applicationId, status: currentStatus },
        data: {
          status: SellerApplicationStatus.SUSPENDED,
          suspensionReason: reason,
          reviewedAt: now,
          ...(resolvedStaffId ? { reviewedByStaffId: resolvedStaffId } : {}),
          ...(dto.notes ? { adminNotes: dto.notes.trim() } : {}),
        },
      });

      if (lockResult.count === 0) {
        throw new ConflictException(
          'Seller application status was modified concurrently',
        );
      }

      // Revoke seller privileges ONLY — preserve user.isActive and buyer permissions
      await tx.user.update({
        where: { id: app.userId },
        data: {
          sellerStatus: SellerApplicationStatus.SUSPENDED,
          sellerSuspendedAt: now,
          sellerSuspensionReason: reason,
        },
      });

      // Mark seller accounts as suspended (without deleting listings or user identity)
      await tx.account.updateMany({
        where: { ownerUserId: app.userId, deletedAt: null },
        data: { verificationStatus: VerificationStatus.SUSPENDED },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId,
          userId: app.userId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          actorType: 'staff',
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.SUSPENDED,
          reason,
          metadata: {
            requestId: ctx.requestId ?? null,
            actorId: staff.id,
          },
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
          targetType: 'verification',
          targetId: applicationId,
          action: 'suspend',
          notes: reason,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: staff.id,
          action: 'SELLER_SUSPENDED',
          targetEntity: 'seller_application',
          targetId: applicationId,
          ipAddress: ctx.ipAddress?.slice(0, 50),
          userAgent: ctx.userAgent?.slice(0, 500),
          diffPayload: {
            requestId: ctx.requestId ?? null,
            userId: app.userId,
            adminId: staff.id,
            applicationId,
            previousStatus: currentStatus,
            newStatus: SellerApplicationStatus.SUSPENDED,
            reason,
            buyerPermissionsPreserved: true,
            result: 'SUCCESS',
            timestamp: now.toISOString(),
          },
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: staff.id,
          action: 'SELLER_PERMISSIONS_REVOKED',
          targetEntity: 'user',
          targetId: app.userId,
          ipAddress: ctx.ipAddress?.slice(0, 50),
          userAgent: ctx.userAgent?.slice(0, 500),
          diffPayload: {
            requestId: ctx.requestId ?? null,
            userId: app.userId,
            adminId: staff.id,
            applicationId,
            reason,
            result: 'SUCCESS',
            timestamp: now.toISOString(),
          },
        },
      });

      return tx.sellerApplication.findUniqueOrThrow({
        where: { id: applicationId },
      });
    });

    await Promise.all(
      ownedAccounts.map((a) => this.invalidateAccountCache(app.userId, a.id)),
    );

    return updated;
  }

  /**
   * Reinstates a SUSPENDED seller back to APPROVED status.
   */
  async reinstateSeller(
    applicationId: string,
    staff: AuthenticatedStaff,
    dto: AdminApproveSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: { user: { select: { id: true, email: true, phone: true } } },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    this.assertNotSelfAction(app, staff);

    const currentStatus = app.status as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.APPROVED,
    );

    const resolvedStaffId = staff.staffId ?? null;
    const now = new Date();

    const updated = await this.prisma.$transaction(async (tx) => {
      const lockResult = await tx.sellerApplication.updateMany({
        where: { id: applicationId, status: currentStatus },
        data: {
          status: SellerApplicationStatus.APPROVED,
          suspensionReason: null,
          reviewedAt: now,
          ...(resolvedStaffId ? { reviewedByStaffId: resolvedStaffId } : {}),
          ...(dto.notes ? { adminNotes: dto.notes.trim() } : {}),
        },
      });

      if (lockResult.count === 0) {
        throw new ConflictException(
          'Seller application status was modified concurrently',
        );
      }

      await tx.user.update({
        where: { id: app.userId },
        data: {
          sellerStatus: SellerApplicationStatus.APPROVED,
          sellerSuspendedAt: null,
          sellerSuspensionReason: null,
        },
      });

      await tx.account.updateMany({
        where: { ownerUserId: app.userId, deletedAt: null },
        data: { verificationStatus: VerificationStatus.APPROVED, isActive: true },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId,
          userId: app.userId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          actorType: 'staff',
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.APPROVED,
          reason: dto.notes?.trim() || 'Seller privileges reinstated by admin',
          metadata: {
            requestId: ctx.requestId ?? null,
            actorId: staff.id,
          },
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: staff.id,
          action: 'SELLER_PERMISSIONS_GRANTED',
          targetEntity: 'user',
          targetId: app.userId,
          ipAddress: ctx.ipAddress?.slice(0, 50),
          userAgent: ctx.userAgent?.slice(0, 500),
          diffPayload: {
            requestId: ctx.requestId ?? null,
            userId: app.userId,
            adminId: staff.id,
            applicationId,
            previousStatus: currentStatus,
            newStatus: SellerApplicationStatus.APPROVED,
            result: 'SUCCESS',
            timestamp: now.toISOString(),
          },
        },
      });

      return tx.sellerApplication.findUniqueOrThrow({
        where: { id: applicationId },
      });
    });

    if (app.accountId) {
      await this.invalidateAccountCache(app.userId, app.accountId);
    }

    return updated;
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  private async getEditableApplicationForUser(userId: string) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'desc' },
    });

    if (!application) {
      throw new NotFoundException(
        'No seller application found. Please request seller conversion first.',
      );
    }

    if (
      ![
        SellerApplicationStatus.DRAFT,
        SellerApplicationStatus.REJECTED,
      ].includes(application.status as SellerApplicationStatus)
    ) {
      throw new BadRequestException(
        `Documents can only be uploaded while application is in DRAFT or REJECTED status (current: '${application.status}')`,
      );
    }

    return application;
  }

  private assertNotSelfAction(
    app: { userId: string; user?: { email?: string | null; phone?: string | null } },
    staff: AuthenticatedStaff,
  ) {
    if (
      app.userId === staff.id ||
      (app.user?.email &&
        staff.email &&
        app.user.email.toLowerCase() === staff.email.toLowerCase())
    ) {
      throw new ForbiddenException({
        code: 'SELF_APPROVAL_FORBIDDEN',
        message:
          'Administrators cannot review, approve, reject, or suspend their own seller application',
      });
    }
  }

  private sanitizeDocumentForUser(doc: {
    id: string;
    applicationId: string;
    documentType: string;
    originalFileName: string;
    mimeType: string;
    fileSizeBytes: number;
    status: string;
    uploadedAt: Date | null;
    createdAt: Date;
  }) {
    // Never expose raw private storageKey or storage credentials
    return {
      id: doc.id,
      applicationId: doc.applicationId,
      documentType: doc.documentType,
      originalFileName: doc.originalFileName,
      mimeType: doc.mimeType,
      fileSizeBytes: doc.fileSizeBytes,
      status: doc.status,
      uploadedAt: doc.uploadedAt,
      createdAt: doc.createdAt,
    };
  }

  private formatApplicationForUser(app: any) {
    const docs = Array.isArray(app.documents) ? app.documents : [];
    const completeness = evaluateApplicationCompleteness({
      businessType: app.businessType,
      businessName: app.businessName,
      nationalIdNumber: app.nationalIdNumber,
      commercialRegisterNumber: app.commercialRegisterNumber,
      documents: docs,
    });

    return {
      id: app.id,
      userId: app.userId,
      accountId: app.accountId,
      status: app.status,
      businessType: app.businessType,
      businessName: app.businessName,
      businessDescription: app.businessDescription,
      nationalIdNumber: this.maskSensitive(app.nationalIdNumber),
      taxIdNumber: this.maskSensitive(app.taxIdNumber),
      commercialRegisterNumber: app.commercialRegisterNumber,
      contactPhone: app.contactPhone,
      contactEmail: app.contactEmail,
      cityId: app.cityId,
      address: app.address,
      submittedAt: app.submittedAt,
      reviewedAt: app.reviewedAt,
      rejectionReason: app.rejectionReason,
      suspensionReason: app.suspensionReason,
      resubmissionCount: app.resubmissionCount,
      requiredDocuments: getRequiredDocumentTypes(app.businessType),
      completeness,
      documents: docs.map((d: any) => this.sanitizeDocumentForUser(d)),
      createdAt: app.createdAt,
      updatedAt: app.updatedAt,
    };
  }

  private maskSensitive(val?: string | null): string | null {
    if (!val) return null;
    if (val.length <= 4) return '****';
    return `${'*'.repeat(Math.max(4, val.length - 4))}${val.slice(-4)}`;
  }

  private async invalidateAccountCache(userId: string, accountId: string) {
    await this.redis
      ?.del?.(`account:membership:${userId}:${accountId}`)
      .catch(() => undefined);
  }
}
