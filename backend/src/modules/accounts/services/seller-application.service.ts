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
  SellerDocumentReviewDecision,
  SellerDocumentStatus,
  SellerType,
  VerificationStatus,
} from '../../../core/enums/domain.enums';
import {
  assertValidSellerStatusTransition,
  evaluateApplicationCompleteness,
  getRequiredDocumentTypes,
  resolveBusinessType,
  resolveSellerType,
} from '../seller-application-state-machine';
import { PrivateDocumentStorageService } from './private-document-storage.service';
import { SensitiveDataCryptoService } from './sensitive-data-crypto.service';
import {
  DynamicCompletenessResult,
  SellerVerificationRequirementsService,
} from './seller-verification-requirements.service';
import { NotificationsService } from '../../notifications/notifications.service';
import {
  AdminApproveSellerApplicationDto,
  AdminExpireSellerDto,
  AdminRejectSellerApplicationDto,
  AdminRequestCorrectionDto,
  AdminReviewDocumentDto,
  AdminReviewSellerApplicationDto,
  AdminSellerApplicationsQueryDto,
  AdminSuspendSellerDto,
  ConfirmVerificationDocumentDto,
  CreateSellerApplicationDto,
  GetVerificationRequirementsQueryDto,
  ReplaceVerificationDocumentDto,
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
  SellerApplicationStatus.NEEDS_CORRECTION,
  SellerApplicationStatus.APPROVED,
];

const MAX_DOCUMENTS_PER_APPLICATION = 25;
const MAX_RESUBMISSIONS_DEFAULT = 5;
const DEFAULT_VERIFICATION_VALIDITY_DAYS = 365;

@Injectable()
export class SellerApplicationService {
  private readonly logger = new Logger(SellerApplicationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly privateStorage: PrivateDocumentStorageService,
    private readonly securityAudit: SecurityAuditService,
    @Optional() private readonly redis?: RedisService,
    @Optional() private readonly cryptoService?: SensitiveDataCryptoService,
    @Optional()
    private readonly requirementsService?: SellerVerificationRequirementsService,
    @Optional() private readonly notifications?: NotificationsService,
  ) {}

  // =========================================================================
  // REQUIREMENTS ENGINE (USER-FACING)
  // =========================================================================

  async getVerificationRequirementsForUser(
    query: GetVerificationRequirementsQueryDto,
  ) {
    const sellerType = query.sellerType ?? SellerType.INDIVIDUAL;
    const sections: string[] = [];
    if (query.marketplaceSection) {
      sections.push(query.marketplaceSection);
    }
    if (query.marketplaceSections) {
      sections.push(
        ...query.marketplaceSections
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .filter(Boolean),
      );
    }

    const requirements = this.requirementsService
      ? await this.requirementsService.getApplicableRequirements(
          sellerType,
          sections,
        )
      : [];

    return {
      sellerType,
      marketplaceSections: Array.from(new Set(sections)),
      requirements,
    };
  }

  // =========================================================================
  // BUYER-TO-SELLER APPLICATION WORKFLOW (USER ENDPOINTS)
  // =========================================================================

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

    if (
      !user ||
      !user.isActive ||
      user.deletedAt ||
      user.moderationStatus !== 'active'
    ) {
      throw new ForbiddenException(
        'Active user account is required to apply as a seller',
      );
    }

    if (user.sellerStatus === SellerApplicationStatus.SUSPENDED) {
      throw new ForbiddenException(
        'Your seller privileges are currently suspended and cannot create a new application',
      );
    }

    if (user.sellerStatus === SellerApplicationStatus.APPROVED) {
      throw new ConflictException('User is already an approved seller');
    }

    const existingActive = await this.prisma.sellerApplication.findFirst({
      where: {
        userId,
        isActive: true,
        deletedAt: null,
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

    const existingRejected = await this.prisma.sellerApplication.findFirst({
      where: {
        userId,
        isActive: true,
        deletedAt: null,
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

    const sellerType = resolveSellerType(dto.sellerType, dto.businessType);
    const businessType = resolveBusinessType(dto.businessType, sellerType);
    const marketplaceSections = Array.from(
      new Set((dto.marketplaceSections ?? []).map((s) => String(s).toLowerCase())),
    );

    try {
      const created = await this.prisma.$transaction(async (tx) => {
        const application = await tx.sellerApplication.create({
          data: {
            userId,
            status: SellerApplicationStatus.DRAFT,
            sellerType,
            businessType,
            marketplaceSections,
            businessName: dto.businessName?.trim() || user.fullName,
            businessDescription: dto.businessDescription?.trim() || null,
            nationalIdNumber: this.encryptSensitive(dto.nationalIdNumber),
            taxIdNumber: this.encryptSensitive(dto.taxIdNumber),
            commercialRegisterNumber:
              dto.commercialRegisterNumber?.trim() || null,
            authorizedRepresentativeName:
              dto.authorizedRepresentativeName?.trim() || null,
            authorizedRepresentativeId: this.encryptSensitive(
              dto.authorizedRepresentativeId,
            ),
            serviceCategory: dto.serviceCategory?.trim() || null,
            yearsOfExperience: dto.yearsOfExperience ?? null,
            qualifications: dto.qualifications?.trim() || null,
            professionalLicenseNumber:
              dto.professionalLicenseNumber?.trim() || null,
            portfolioUrl: dto.portfolioUrl?.trim() || null,
            contactPhone: dto.contactPhone?.trim() || user.phone,
            contactEmail: dto.contactEmail?.trim() || user.email || null,
            cityId: dto.cityId ?? null,
            address: dto.address?.trim() || null,
            isActive: true,
          },
          include: { documents: { where: { deletedAt: null } } },
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
              sellerType,
              businessType,
              marketplaceSections,
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
          sellerType,
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
   * When in NEEDS_CORRECTION, restricts edits strictly to the admin-specified correctionFields.
   */
  async updateDraft(
    userId: string,
    dto: UpdateSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: { documents: { where: { deletedAt: null } } },
    });

    if (!application) {
      throw new NotFoundException(
        'No seller application found. Please request seller conversion first.',
      );
    }

    const status = application.status as SellerApplicationStatus;
    if (
      status !== SellerApplicationStatus.DRAFT &&
      status !== SellerApplicationStatus.NEEDS_CORRECTION
    ) {
      throw new BadRequestException(
        `Seller application cannot be edited while in status '${application.status}'. Only DRAFT or NEEDS_CORRECTION applications can be updated.`,
      );
    }

    const requestedFields = Object.keys(dto).filter(
      (k) => (dto as Record<string, unknown>)[k] !== undefined,
    );

    if (status === SellerApplicationStatus.NEEDS_CORRECTION) {
      const allowedFields = Array.isArray(application.correctionFields)
        ? (application.correctionFields as string[])
        : [];
      if (allowedFields.length > 0) {
        const disallowed = requestedFields.filter(
          (f) => !allowedFields.includes(f),
        );
        if (disallowed.length > 0) {
          throw new ForbiddenException({
            code: 'UNAFFECTED_FIELD_EDIT_FORBIDDEN',
            message: `During correction, only requested fields (${allowedFields.join(', ')}) may be updated.`,
            disallowedFields: disallowed,
            allowedFields,
          });
        }
      }
    }

    const nextSellerType =
      dto.sellerType !== undefined || dto.businessType !== undefined
        ? resolveSellerType(
            dto.sellerType ?? application.sellerType,
            dto.businessType ?? application.businessType,
          )
        : undefined;
    const nextBusinessType =
      dto.businessType !== undefined || dto.sellerType !== undefined
        ? resolveBusinessType(
            dto.businessType ?? application.businessType,
            nextSellerType ?? application.sellerType,
          )
        : undefined;

    const updated = await this.prisma.sellerApplication.update({
      where: { id: application.id },
      data: {
        ...(nextSellerType ? { sellerType: nextSellerType } : {}),
        ...(nextBusinessType ? { businessType: nextBusinessType } : {}),
        ...(dto.marketplaceSections !== undefined
          ? {
              marketplaceSections: Array.from(
                new Set(
                  dto.marketplaceSections.map((s) => String(s).toLowerCase()),
                ),
              ),
            }
          : {}),
        ...(dto.businessName !== undefined
          ? { businessName: dto.businessName.trim() }
          : {}),
        ...(dto.businessDescription !== undefined
          ? { businessDescription: dto.businessDescription.trim() }
          : {}),
        ...(dto.nationalIdNumber !== undefined
          ? { nationalIdNumber: this.encryptSensitive(dto.nationalIdNumber) }
          : {}),
        ...(dto.taxIdNumber !== undefined
          ? { taxIdNumber: this.encryptSensitive(dto.taxIdNumber) }
          : {}),
        ...(dto.commercialRegisterNumber !== undefined
          ? { commercialRegisterNumber: dto.commercialRegisterNumber.trim() }
          : {}),
        ...(dto.authorizedRepresentativeName !== undefined
          ? {
              authorizedRepresentativeName:
                dto.authorizedRepresentativeName.trim(),
            }
          : {}),
        ...(dto.authorizedRepresentativeId !== undefined
          ? {
              authorizedRepresentativeId: this.encryptSensitive(
                dto.authorizedRepresentativeId,
              ),
            }
          : {}),
        ...(dto.serviceCategory !== undefined
          ? { serviceCategory: dto.serviceCategory.trim() }
          : {}),
        ...(dto.yearsOfExperience !== undefined
          ? { yearsOfExperience: dto.yearsOfExperience }
          : {}),
        ...(dto.qualifications !== undefined
          ? { qualifications: dto.qualifications.trim() }
          : {}),
        ...(dto.professionalLicenseNumber !== undefined
          ? { professionalLicenseNumber: dto.professionalLicenseNumber.trim() }
          : {}),
        ...(dto.portfolioUrl !== undefined
          ? { portfolioUrl: dto.portfolioUrl.trim() }
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
      include: { documents: { where: { deletedAt: null } } },
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
        updatedFields: requestedFields,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return this.formatApplicationForUser(updated);
  }

  /**
   * Generates a private direct-to-storage presigned PUT URL for uploading a verification document.
   * Enforces per-requirement MIME type and file size rules.
   */
  async requestDocumentUploadUrl(
    userId: string,
    dto: RequestVerificationDocUploadUrlDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.getEditableApplicationForUser(userId);
    const matchedRequirement = await this.findMatchingRequirement(
      application,
      dto.documentType,
    );

    const target = this.privateStorage.generatePrivateUploadUrl(
      userId,
      application.id,
      dto.mimeType,
      dto.fileSizeBytes,
      matchedRequirement
        ? {
            acceptedMimeTypes: Array.isArray(
              matchedRequirement.acceptedMimeTypes,
            )
              ? (matchedRequirement.acceptedMimeTypes as string[])
              : undefined,
            maxFileSizeBytes: matchedRequirement.maxFileSizeBytes,
          }
        : undefined,
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
      requirementId: matchedRequirement?.id ?? null,
      ...target,
    };
  }

  /**
   * Confirms and registers an uploaded private verification document with versioning,
   * MIME + magic-byte content signature validation, expiration checks, and upload limits.
   */
  async registerDocument(
    userId: string,
    dto: ConfirmVerificationDocumentDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.getEditableApplicationForUser(userId);

    // During NEEDS_CORRECTION, only allow replacing rejected/missing required document types
    if (application.status === SellerApplicationStatus.NEEDS_CORRECTION) {
      const existingCurrent =
        await this.prisma.sellerApplicationDocument.findFirst({
          where: {
            applicationId: application.id,
            documentType: dto.documentType,
            isCurrent: true,
            deletedAt: null,
          },
        });
      if (
        existingCurrent &&
        existingCurrent.status !== SellerDocumentStatus.REJECTED
      ) {
        throw new ForbiddenException({
          code: 'UNAUTHORIZED_DOCUMENT_REPLACEMENT',
          message:
            'Only rejected documents can be replaced while application is in NEEDS_CORRECTION status',
        });
      }
    }

    const totalDocsCount = await this.prisma.sellerApplicationDocument.count({
      where: { applicationId: application.id },
    });
    if (totalDocsCount >= MAX_DOCUMENTS_PER_APPLICATION) {
      throw new BadRequestException({
        code: 'DOCUMENT_UPLOAD_LIMIT_EXCEEDED',
        message: `Maximum document upload limit (${MAX_DOCUMENTS_PER_APPLICATION}) reached for this application`,
      });
    }

    const matchedRequirement = await this.findMatchingRequirement(
      application,
      dto.documentType,
    );

    this.privateStorage.validateFileMetadata(
      dto.mimeType,
      dto.fileSizeBytes,
      matchedRequirement
        ? {
            acceptedMimeTypes: Array.isArray(
              matchedRequirement.acceptedMimeTypes,
            )
              ? (matchedRequirement.acceptedMimeTypes as string[])
              : undefined,
            maxFileSizeBytes: matchedRequirement.maxFileSizeBytes,
          }
        : undefined,
    );
    this.privateStorage.validateFileContentSignature(
      dto.mimeType,
      dto.fileHeaderBase64,
    );
    this.privateStorage.validatePrivateDocumentOwnership(
      userId,
      application.id,
      dto.storageKey,
    );

    const parsedExpiresAt = this.validateDocumentExpiration(
      dto.expiresAt,
      matchedRequirement?.requiresExpiration ?? false,
    );

    // Preserve previous document versions in audit history instead of destroying them
    const document = await this.prisma.$transaction(async (tx) => {
      const existingVersions = await tx.sellerApplicationDocument.findMany({
        where: {
          applicationId: application.id,
          documentType: dto.documentType,
          deletedAt: null,
        },
        orderBy: { version: 'desc' },
      });

      const nextVersion =
        existingVersions.length > 0 ? (existingVersions[0].version ?? 1) + 1 : 1;

      const created = await tx.sellerApplicationDocument.create({
        data: {
          applicationId: application.id,
          userId,
          requirementId: dto.requirementId ?? matchedRequirement?.id ?? null,
          documentType: dto.documentType,
          storageKey: dto.storageKey,
          originalFileName: dto.originalFileName.trim().slice(0, 255),
          mimeType: dto.mimeType,
          fileSizeBytes: dto.fileSizeBytes,
          checksumSha256: dto.checksumSha256?.trim() || null,
          status: SellerDocumentStatus.UPLOADED,
          version: nextVersion,
          isCurrent: true,
          expiresAt: parsedExpiresAt,
          uploadedAt: new Date(),
        },
      });

      if (existingVersions.length > 0) {
        const previousIds = existingVersions
          .filter((v) => v.isCurrent)
          .map((v) => v.id);
        if (previousIds.length > 0) {
          await tx.sellerApplicationDocument.updateMany({
            where: { id: { in: previousIds } },
            data: {
              isCurrent: false,
              replacedByDocumentId: created.id,
            },
          });
        }
      }

      return created;
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
        version: document.version,
        mimeType: document.mimeType,
        fileSizeBytes: document.fileSizeBytes,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return this.sanitizeDocumentForUser(document);
  }

  /**
   * Explicitly replaces an existing verification document by ID, preserving the
   * previous version in audit history. During NEEDS_CORRECTION, strictly enforces
   * that only REJECTED documents can be replaced.
   */
  async replaceDocument(
    userId: string,
    documentId: string,
    dto: ReplaceVerificationDocumentDto,
    ctx: RequestAuditContext = {},
  ) {
    const existing = await this.prisma.sellerApplicationDocument.findUnique({
      where: { id: documentId },
      include: { application: true },
    });

    if (!existing || existing.deletedAt) {
      throw new NotFoundException('Verification document not found');
    }

    if (existing.userId !== userId || existing.application.userId !== userId) {
      throw new ForbiddenException(
        'You do not have permission to replace this verification document',
      );
    }

    const appStatus = existing.application.status as SellerApplicationStatus;
    if (
      ![
        SellerApplicationStatus.DRAFT,
        SellerApplicationStatus.NEEDS_CORRECTION,
        SellerApplicationStatus.REJECTED,
        SellerApplicationStatus.EXPIRED,
      ].includes(appStatus)
    ) {
      throw new BadRequestException(
        `Documents cannot be replaced while application is in '${appStatus}' status`,
      );
    }

    if (
      appStatus === SellerApplicationStatus.NEEDS_CORRECTION &&
      existing.status !== SellerDocumentStatus.REJECTED
    ) {
      throw new ForbiddenException({
        code: 'UNAUTHORIZED_DOCUMENT_REPLACEMENT',
        message:
          'Only rejected documents may be replaced during a correction request',
      });
    }

    return this.registerDocument(
      userId,
      {
        documentType: existing.documentType as any,
        storageKey: dto.storageKey,
        originalFileName: dto.originalFileName,
        mimeType: dto.mimeType,
        fileSizeBytes: dto.fileSizeBytes,
        checksumSha256: dto.checksumSha256,
        fileHeaderBase64: dto.fileHeaderBase64,
        expiresAt: dto.expiresAt,
        requirementId: existing.requirementId ?? undefined,
      },
      ctx,
    );
  }

  /**
   * Soft-deletes an uploaded verification document while the application is an editable DRAFT/REJECTED.
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

    if (!doc || doc.deletedAt) {
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

    await this.prisma.sellerApplicationDocument.update({
      where: { id: documentId },
      data: { deletedAt: new Date(), isCurrent: false },
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

  async getOwnDocumentAccessUrl(
    userId: string,
    documentId: string,
    ctx: RequestAuditContext = {},
  ) {
    const doc = await this.prisma.sellerApplicationDocument.findUnique({
      where: { id: documentId },
    });

    if (!doc || doc.deletedAt) {
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
        version: doc.version,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      documentId: doc.id,
      documentType: doc.documentType,
      version: doc.version,
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
      where: { userId, isActive: true, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: { documents: { where: { deletedAt: null } } },
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

    const completeness = await this.evaluateCompleteness(
      application,
      application.documents,
    );

    if (!completeness.isComplete) {
      throw new BadRequestException({
        code: 'INCOMPLETE_SELLER_APPLICATION',
        message:
          'Seller application is incomplete. Please provide all required fields and verification documents before submitting.',
        missingFields: completeness.missingFields,
        missingDocuments: completeness.missingDocuments,
        rejectedDocuments: completeness.rejectedDocuments,
        expiredDocuments: completeness.expiredDocuments,
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
            documentCount: application.documents.filter((d) => d.isCurrent)
              .length,
          },
        },
      });

      return tx.sellerApplication.findUniqueOrThrow({
        where: { id: application.id },
        include: { documents: { where: { deletedAt: null } } },
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

    await this.notifyUser(
      userId,
      'SELLER_APPLICATION_SUBMITTED',
      'Seller Application Submitted',
      'Your seller verification application has been submitted and is awaiting admin review.',
      { applicationId: updated.id, status: SellerApplicationStatus.PENDING },
    );

    return this.formatApplicationForUser(updated);
  }

  /**
   * Resubmits a NEEDS_CORRECTION, REJECTED, or EXPIRED seller application.
   */
  async resubmitApplication(
    userId: string,
    dto: ResubmitSellerApplicationDto,
    ctx: RequestAuditContext = {},
  ) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: { documents: { where: { deletedAt: null } } },
    });

    if (!application) {
      throw new NotFoundException('No seller application found');
    }

    const currentStatus = application.status as SellerApplicationStatus;
    if (
      ![
        SellerApplicationStatus.NEEDS_CORRECTION,
        SellerApplicationStatus.REJECTED,
        SellerApplicationStatus.EXPIRED,
      ].includes(currentStatus)
    ) {
      throw new BadRequestException({
        code: 'INVALID_SELLER_STATUS_TRANSITION',
        message: `Only NEEDS_CORRECTION, REJECTED, or EXPIRED applications can be resubmitted (current status: '${currentStatus}')`,
      });
    }

    if (
      currentStatus === SellerApplicationStatus.REJECTED &&
      application.resubmissionCount >= MAX_RESUBMISSIONS_DEFAULT
    ) {
      throw new ForbiddenException({
        code: 'MAX_RESUBMISSIONS_REACHED',
        message: `Maximum resubmission attempts (${MAX_RESUBMISSIONS_DEFAULT}) reached. Please contact support.`,
      });
    }

    const targetStatus =
      currentStatus === SellerApplicationStatus.NEEDS_CORRECTION
        ? SellerApplicationStatus.PENDING
        : dto.submitImmediately
          ? SellerApplicationStatus.PENDING
          : SellerApplicationStatus.DRAFT;

    assertValidSellerStatusTransition(currentStatus, targetStatus);

    const mergedSellerType = resolveSellerType(
      dto.sellerType ?? application.sellerType,
      dto.businessType ?? application.businessType,
    );
    const mergedBusinessType = resolveBusinessType(
      dto.businessType ?? application.businessType,
      mergedSellerType,
    );
    const mergedBusinessName =
      dto.businessName !== undefined
        ? dto.businessName.trim()
        : application.businessName;
    const mergedNationalId =
      dto.nationalIdNumber !== undefined
        ? this.encryptSensitive(dto.nationalIdNumber)
        : application.nationalIdNumber;
    const mergedCr =
      dto.commercialRegisterNumber !== undefined
        ? dto.commercialRegisterNumber.trim()
        : application.commercialRegisterNumber;
    const mergedServiceCategory =
      dto.serviceCategory !== undefined
        ? dto.serviceCategory.trim()
        : application.serviceCategory;
    const mergedSections =
      dto.marketplaceSections !== undefined
        ? Array.from(
            new Set(dto.marketplaceSections.map((s) => String(s).toLowerCase())),
          )
        : application.marketplaceSections;

    if (targetStatus === SellerApplicationStatus.PENDING) {
      const completeness = await this.evaluateCompleteness(
        {
          ...application,
          sellerType: mergedSellerType,
          businessType: mergedBusinessType,
          marketplaceSections: mergedSections,
          businessName: mergedBusinessName,
          nationalIdNumber: mergedNationalId,
          commercialRegisterNumber: mergedCr,
          serviceCategory: mergedServiceCategory,
        },
        application.documents,
      );

      if (!completeness.isComplete) {
        throw new BadRequestException({
          code: 'INCOMPLETE_SELLER_APPLICATION',
          message:
            'Cannot submit incomplete application. Please complete all required fields and replace any rejected or expired documents.',
          missingFields: completeness.missingFields,
          missingDocuments: completeness.missingDocuments,
          rejectedDocuments: completeness.rejectedDocuments,
          expiredDocuments: completeness.expiredDocuments,
        });
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.sellerApplication.update({
        where: { id: application.id },
        data: {
          status: targetStatus,
          sellerType: mergedSellerType,
          businessType: mergedBusinessType,
          marketplaceSections: mergedSections as Prisma.InputJsonValue,
          businessName: mergedBusinessName,
          ...(dto.businessDescription !== undefined
            ? { businessDescription: dto.businessDescription.trim() }
            : {}),
          nationalIdNumber: mergedNationalId,
          ...(dto.taxIdNumber !== undefined
            ? { taxIdNumber: this.encryptSensitive(dto.taxIdNumber) }
            : {}),
          commercialRegisterNumber: mergedCr,
          ...(dto.authorizedRepresentativeName !== undefined
            ? {
                authorizedRepresentativeName:
                  dto.authorizedRepresentativeName.trim(),
              }
            : {}),
          ...(dto.authorizedRepresentativeId !== undefined
            ? {
                authorizedRepresentativeId: this.encryptSensitive(
                  dto.authorizedRepresentativeId,
                ),
              }
            : {}),
          serviceCategory: mergedServiceCategory,
          ...(dto.yearsOfExperience !== undefined
            ? { yearsOfExperience: dto.yearsOfExperience }
            : {}),
          ...(dto.qualifications !== undefined
            ? { qualifications: dto.qualifications.trim() }
            : {}),
          ...(dto.professionalLicenseNumber !== undefined
            ? {
                professionalLicenseNumber:
                  dto.professionalLicenseNumber.trim(),
              }
            : {}),
          ...(dto.portfolioUrl !== undefined
            ? { portfolioUrl: dto.portfolioUrl.trim() }
            : {}),
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
            ? {
                submittedAt: new Date(),
                rejectionReason: null,
                correctionReason: null,
                correctionFields: [],
              }
            : {}),
        },
        include: { documents: { where: { deletedAt: null } } },
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
          reason:
            currentStatus === SellerApplicationStatus.NEEDS_CORRECTION
              ? 'Corrected application resubmitted for admin review'
              : targetStatus === SellerApplicationStatus.PENDING
                ? 'Application resubmitted for verification'
                : 'Application reopened as draft for edits',
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

    if (targetStatus === SellerApplicationStatus.PENDING) {
      await this.notifyUser(
        userId,
        'SELLER_APPLICATION_SUBMITTED',
        'Seller Application Resubmitted',
        'Your updated seller verification application has been resubmitted for review.',
        { applicationId: updated.id, status: SellerApplicationStatus.PENDING },
      );
    }

    return this.formatApplicationForUser(updated);
  }

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
      where: { userId, isActive: true, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: {
        documents: {
          where: { deletedAt: null },
          orderBy: [{ documentType: 'asc' }, { version: 'desc' }],
        },
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
        ? await this.formatApplicationForUser(application)
        : null,
    };
  }

  async getMyCorrections(userId: string) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: {
        documents: {
          where: {
            deletedAt: null,
            isCurrent: true,
            status: SellerDocumentStatus.REJECTED,
          },
          include: {
            reviews: {
              orderBy: { reviewedAt: 'desc' },
              take: 1,
              select: {
                id: true,
                decision: true,
                reason: true,
                reviewedAt: true,
              },
            },
          },
        },
      },
    });

    if (!application) {
      throw new NotFoundException('No seller application found');
    }

    return {
      applicationId: application.id,
      status: application.status,
      hasPendingCorrections:
        application.status === SellerApplicationStatus.NEEDS_CORRECTION,
      correctionReason: application.correctionReason,
      correctionRequestedAt: application.correctionRequestedAt,
      affectedFields: Array.isArray(application.correctionFields)
        ? application.correctionFields
        : [],
      rejectedDocuments: application.documents.map((d) => ({
        id: d.id,
        documentType: d.documentType,
        version: d.version,
        originalFileName: d.originalFileName,
        status: d.status,
        rejectionReason: d.rejectionReason ?? d.reviews[0]?.reason ?? null,
        reviewedAt: d.reviews[0]?.reviewedAt ?? null,
      })),
    };
  }

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
    _canReadDocuments: boolean,
  ) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: Prisma.SellerApplicationWhereInput = {
      deletedAt: null,
      ...(query.status && query.status !== 'all'
        ? { status: query.status.toUpperCase() }
        : query.status === 'all'
          ? {}
          : {
              status: {
                in: [
                  SellerApplicationStatus.PENDING,
                  SellerApplicationStatus.UNDER_REVIEW,
                ],
              },
            }),
      ...(query.sellerType ? { sellerType: query.sellerType } : {}),
      ...(query.businessType ? { businessType: query.businessType } : {}),
      ...(query.marketplaceSection
        ? {
            marketplaceSections: {
              array_contains: [query.marketplaceSection],
            },
          }
        : {}),
      ...(query.q
        ? {
            OR: [
              {
                businessName: {
                  contains: query.q.trim(),
                  mode: 'insensitive',
                },
              },
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
            where: { deletedAt: null, isCurrent: true },
            select: {
              id: true,
              documentType: true,
              version: true,
              originalFileName: true,
              mimeType: true,
              fileSizeBytes: true,
              status: true,
              expiresAt: true,
              uploadedAt: true,
            },
          },
        },
      }),
    ]);

    // Never expose raw national ID numbers in list responses
    const items = rawItems.map((app) => ({
      ...app,
      nationalIdNumber: this.maskSensitive(app.nationalIdNumber),
      taxIdNumber: this.maskSensitive(app.taxIdNumber),
      authorizedRepresentativeId: this.maskSensitive(
        app.authorizedRepresentativeId,
      ),
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
    _canReadDocuments: boolean,
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
          where: { deletedAt: null },
          orderBy: [{ documentType: 'asc' }, { version: 'desc' }],
          select: {
            id: true,
            requirementId: true,
            documentType: true,
            version: true,
            isCurrent: true,
            replacedByDocumentId: true,
            originalFileName: true,
            mimeType: true,
            fileSizeBytes: true,
            status: true,
            expiresAt: true,
            rejectionReason: true,
            uploadedAt: true,
            createdAt: true,
            reviews: {
              orderBy: { reviewedAt: 'desc' },
              include: {
                admin: { select: { id: true, fullName: true, email: true } },
              },
            },
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

    const completeness = await this.evaluateCompleteness(app, app.documents);
    const applicableRequirements = this.requirementsService
      ? await this.requirementsService.getApplicableRequirements(
          app.sellerType,
          Array.isArray(app.marketplaceSections)
            ? (app.marketplaceSections as string[])
            : [],
        )
      : [];

    return {
      application: {
        ...app,
        nationalIdNumber: this.maskSensitive(app.nationalIdNumber),
        taxIdNumber: this.maskSensitive(app.taxIdNumber),
        authorizedRepresentativeId: this.maskSensitive(
          app.authorizedRepresentativeId,
        ),
      },
      applicableRequirements,
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

  async getDocumentAccessForAdmin(
    applicationId: string,
    documentId: string,
    staff: AuthenticatedStaff,
    ctx: RequestAuditContext = {},
  ) {
    const doc = await this.prisma.sellerApplicationDocument.findFirst({
      where: { id: documentId, applicationId, deletedAt: null },
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
        version: doc.version,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      documentId: doc.id,
      applicationId: doc.applicationId,
      documentType: doc.documentType,
      version: doc.version,
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
   * Individual document review (accept / reject / correction_required).
   */
  async reviewDocument(
    applicationId: string,
    documentId: string,
    staff: AuthenticatedStaff,
    dto: AdminReviewDocumentDto,
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

    if (
      ![
        SellerApplicationStatus.PENDING,
        SellerApplicationStatus.UNDER_REVIEW,
      ].includes(app.status as SellerApplicationStatus)
    ) {
      throw new BadRequestException(
        `Documents can only be reviewed while application is PENDING or UNDER_REVIEW (current: '${app.status}')`,
      );
    }

    if (
      dto.decision !== SellerDocumentReviewDecision.APPROVED &&
      (!dto.reason || dto.reason.trim().length < 5)
    ) {
      throw new BadRequestException(
        'A reason of at least 5 characters is required when rejecting or requesting correction on a document',
      );
    }

    const doc = await this.prisma.sellerApplicationDocument.findFirst({
      where: { id: documentId, applicationId, deletedAt: null },
    });
    if (!doc) {
      throw new NotFoundException(
        'Verification document not found for this application',
      );
    }

    const resolvedStaffId = staff.staffId ?? null;
    const nextDocStatus =
      dto.decision === SellerDocumentReviewDecision.APPROVED
        ? SellerDocumentStatus.VERIFIED
        : SellerDocumentStatus.REJECTED;

    const result = await this.prisma.$transaction(async (tx) => {
      const review = await tx.sellerDocumentReview.create({
        data: {
          applicationId,
          documentId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          decision: dto.decision,
          reason: dto.reason?.trim() || null,
          notes: dto.notes?.trim() || null,
        },
      });

      const updatedDoc = await tx.sellerApplicationDocument.update({
        where: { id: documentId },
        data: {
          status: nextDocStatus,
          rejectionReason:
            nextDocStatus === SellerDocumentStatus.REJECTED
              ? dto.reason?.trim() || null
              : null,
        },
      });

      return { review, document: updatedDoc };
    });

    await this.securityAudit.logEvent({
      action: 'SELLER_DOCUMENT_REVIEWED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'SellerApplicationDocument',
      targetId: documentId,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        applicationId,
        documentId,
        documentType: doc.documentType,
        decision: dto.decision,
        adminId: staff.id,
        result: 'SUCCESS',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      review: result.review,
      document: this.sanitizeDocumentForUser(result.document),
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

    await this.notifyUser(
      app.userId,
      'SELLER_APPLICATION_UNDER_REVIEW',
      'Seller Application Under Review',
      'Our verification team is currently reviewing your seller application.',
      { applicationId, status: SellerApplicationStatus.UNDER_REVIEW },
    );

    return updated;
  }

  /**
   * Requests targeted corrections on an UNDER_REVIEW application (UNDER_REVIEW -> NEEDS_CORRECTION).
   */
  async requestCorrection(
    applicationId: string,
    staff: AuthenticatedStaff,
    dto: AdminRequestCorrectionDto,
    ctx: RequestAuditContext = {},
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: {
        documents: { where: { deletedAt: null, isCurrent: true } },
        user: { select: { id: true, email: true, phone: true } },
      },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    this.assertNotSelfAction(app, staff);

    const currentStatus = app.status as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.NEEDS_CORRECTION,
    );

    const reason = dto.reason.trim();
    const affectedFields = Array.from(new Set(dto.affectedFields ?? []));
    const rejectedDocIds = Array.from(new Set(dto.rejectedDocumentIds ?? []));

    if (rejectedDocIds.length > 0) {
      const validIds = new Set(app.documents.map((d) => d.id));
      const invalidIds = rejectedDocIds.filter((id) => !validIds.has(id));
      if (invalidIds.length > 0) {
        throw new BadRequestException(
          'One or more rejectedDocumentIds do not belong to this application',
        );
      }
    }

    const resolvedStaffId = staff.staffId ?? null;
    const now = new Date();

    const updated = await this.prisma.$transaction(async (tx) => {
      const lockResult = await tx.sellerApplication.updateMany({
        where: { id: applicationId, status: currentStatus },
        data: {
          status: SellerApplicationStatus.NEEDS_CORRECTION,
          correctionReason: reason,
          correctionFields: affectedFields,
          correctionRequestedAt: now,
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

      if (rejectedDocIds.length > 0) {
        await tx.sellerApplicationDocument.updateMany({
          where: { id: { in: rejectedDocIds }, applicationId },
          data: {
            status: SellerDocumentStatus.REJECTED,
            rejectionReason: reason,
          },
        });

        await tx.sellerDocumentReview.createMany({
          data: rejectedDocIds.map((docId) => ({
            applicationId,
            documentId: docId,
            ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
            decision: SellerDocumentReviewDecision.CORRECTION_REQUIRED,
            reason,
            notes: dto.notes?.trim() || null,
            reviewedAt: now,
          })),
        });
      }

      await tx.user.update({
        where: { id: app.userId },
        data: { sellerStatus: SellerApplicationStatus.NEEDS_CORRECTION },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId,
          userId: app.userId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          actorType: 'staff',
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.NEEDS_CORRECTION,
          reason,
          metadata: {
            requestId: ctx.requestId ?? null,
            actorId: staff.id,
            affectedFields,
            rejectedDocumentIds: rejectedDocIds,
          },
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(resolvedStaffId ? { staffId: resolvedStaffId } : {}),
          targetType: 'verification',
          targetId: applicationId,
          action: 'request_correction',
          notes: reason,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId: staff.id,
          action: 'SELLER_APPLICATION_CORRECTION_REQUESTED',
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
            newStatus: SellerApplicationStatus.NEEDS_CORRECTION,
            affectedFields,
            rejectedDocumentIds: rejectedDocIds,
            result: 'SUCCESS',
            timestamp: now.toISOString(),
          },
        },
      });

      return tx.sellerApplication.findUniqueOrThrow({
        where: { id: applicationId },
        include: { documents: { where: { deletedAt: null, isCurrent: true } } },
      });
    });

    await this.notifyUser(
      app.userId,
      'SELLER_APPLICATION_CORRECTION_REQUESTED',
      'Action Required: Seller Verification Corrections',
      'Please review and update the requested information or documents in your seller application.',
      { applicationId, status: SellerApplicationStatus.NEEDS_CORRECTION },
    );

    return updated;
  }

  /**
   * Approves a complete seller application in a single atomic transaction.
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
        documents: { where: { deletedAt: null } },
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

    const completeness = await this.evaluateCompleteness(app, app.documents);

    if (!completeness.isComplete) {
      throw new BadRequestException({
        code: 'INCOMPLETE_SELLER_APPLICATION',
        message:
          'Cannot approve an incomplete seller application. Required fields or documents are missing, rejected, or expired.',
        missingFields: completeness.missingFields,
        missingDocuments: completeness.missingDocuments,
        rejectedDocuments: completeness.rejectedDocuments,
        expiredDocuments: completeness.expiredDocuments,
      });
    }

    const resolvedStaffId = staff.staffId ?? null;
    const now = new Date();
    const verificationExpiresAt = dto.verificationExpiresAt
      ? new Date(dto.verificationExpiresAt)
      : new Date(
          now.getTime() + DEFAULT_VERIFICATION_VALIDITY_DAYS * 86_400_000,
        );

    const result = await this.prisma.$transaction(async (tx) => {
      const lockResult = await tx.sellerApplication.updateMany({
        where: {
          id: applicationId,
          status: currentStatus,
        },
        data: {
          status: SellerApplicationStatus.APPROVED,
          reviewedAt: now,
          verificationExpiresAt,
          expiredAt: null,
          ...(resolvedStaffId ? { reviewedByStaffId: resolvedStaffId } : {}),
          rejectionReason: null,
          suspensionReason: null,
          correctionReason: null,
          correctionFields: [],
          ...(dto.notes ? { adminNotes: dto.notes.trim() } : {}),
        },
      });

      if (lockResult.count === 0) {
        throw new ConflictException({
          code: 'DUPLICATE_APPROVAL',
          message: 'Seller application has already been adjudicated',
        });
      }

      await tx.sellerApplicationDocument.updateMany({
        where: {
          applicationId,
          isCurrent: true,
          deletedAt: null,
          status: SellerDocumentStatus.UPLOADED,
        },
        data: { status: SellerDocumentStatus.VERIFIED },
      });

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

      const updatedApplication = await tx.sellerApplication.update({
        where: { id: applicationId },
        data: { accountId: sellerAccount.id },
        include: { documents: { where: { deletedAt: null } } },
      });

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
            verificationExpiresAt: verificationExpiresAt.toISOString(),
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

    await this.notifyUser(
      app.userId,
      'SELLER_APPLICATION_APPROVED',
      'Seller Account Approved',
      'Congratulations! Your seller verification has been approved. You can now publish listings on Deal One.',
      {
        applicationId,
        accountId: result.account.id,
        status: SellerApplicationStatus.APPROVED,
      },
    );

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

    await this.notifyUser(
      app.userId,
      'SELLER_APPLICATION_REJECTED',
      'Seller Application Not Approved',
      'Your seller verification application was not approved. Please review the feedback in the app to resubmit.',
      { applicationId, status: SellerApplicationStatus.REJECTED },
    );

    return updated;
  }

  /**
   * Suspends an APPROVED seller's privileges immediately while preserving buyer permissions.
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

      await tx.user.update({
        where: { id: app.userId },
        data: {
          sellerStatus: SellerApplicationStatus.SUSPENDED,
          sellerSuspendedAt: now,
          sellerSuspensionReason: reason,
        },
      });

      await tx.account.updateMany({
        where: { ownerUserId: app.userId, deletedAt: null },
        data: { isActive: false },
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

    await this.notifyUser(
      app.userId,
      'SELLER_VERIFICATION_SUSPENDED',
      'Seller Privileges Suspended',
      'Your seller privileges have been temporarily suspended. Your buyer account remains active.',
      { applicationId, status: SellerApplicationStatus.SUSPENDED },
    );

    return updated;
  }

  /**
   * Expires an APPROVED seller verification (APPROVED -> EXPIRED).
   * Revokes seller-only permissions while preserving buyer permissions and listing history.
   */
  async expireSellerVerification(
    applicationId: string,
    staff: AuthenticatedStaff | null,
    dto: AdminExpireSellerDto = {},
    ctx: RequestAuditContext = {},
  ) {
    const app = await this.prisma.sellerApplication.findUnique({
      where: { id: applicationId },
      include: { user: { select: { id: true, email: true, phone: true } } },
    });

    if (!app) {
      throw new NotFoundException('Seller application not found');
    }

    if (staff) {
      this.assertNotSelfAction(app, staff);
    }

    const currentStatus = app.status as SellerApplicationStatus;
    assertValidSellerStatusTransition(
      currentStatus,
      SellerApplicationStatus.EXPIRED,
    );

    const reason =
      dto.reason?.trim() || 'Seller verification credentials have expired';
    const resolvedStaffId = staff?.staffId ?? null;
    const actorType = staff ? 'staff' : 'system';
    const actorId = staff?.id ?? undefined;
    const now = new Date();

    const ownedAccounts = await this.prisma.account.findMany({
      where: { ownerUserId: app.userId, deletedAt: null },
      select: { id: true },
    });

    const updated = await this.prisma.$transaction(async (tx) => {
      const lockResult = await tx.sellerApplication.updateMany({
        where: { id: applicationId, status: currentStatus },
        data: {
          status: SellerApplicationStatus.EXPIRED,
          expiredAt: now,
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
        data: { sellerStatus: SellerApplicationStatus.EXPIRED },
      });

      await tx.account.updateMany({
        where: { ownerUserId: app.userId, deletedAt: null },
        data: { isActive: false },
      });

      await tx.sellerApplicationHistory.create({
        data: {
          applicationId,
          userId: app.userId,
          ...(resolvedStaffId ? { adminId: resolvedStaffId } : {}),
          actorType,
          previousStatus: currentStatus,
          newStatus: SellerApplicationStatus.EXPIRED,
          reason,
          metadata: {
            requestId: ctx.requestId ?? null,
            actorId: actorId ?? null,
          },
        },
      });

      await tx.auditLog.create({
        data: {
          actorType,
          actorId: actorId ?? null,
          action: 'SELLER_VERIFICATION_EXPIRED',
          targetEntity: 'seller_application',
          targetId: applicationId,
          ipAddress: ctx.ipAddress?.slice(0, 50),
          userAgent: ctx.userAgent?.slice(0, 500),
          diffPayload: {
            requestId: ctx.requestId ?? null,
            userId: app.userId,
            adminId: actorId ?? null,
            applicationId,
            previousStatus: currentStatus,
            newStatus: SellerApplicationStatus.EXPIRED,
            reason,
            buyerPermissionsPreserved: true,
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

    await this.notifyUser(
      app.userId,
      'SELLER_VERIFICATION_EXPIRED',
      'Seller Verification Expired',
      'Your seller verification has expired. Please renew your documents to continue selling. Your buyer features remain active.',
      { applicationId, status: SellerApplicationStatus.EXPIRED },
    );

    return updated;
  }

  /**
   * Batch policy job: expires all APPROVED applications whose verificationExpiresAt has passed.
   */
  async expireOverdueVerifications(): Promise<{ expiredCount: number }> {
    const overdue = await this.prisma.sellerApplication.findMany({
      where: {
        status: SellerApplicationStatus.APPROVED,
        isActive: true,
        deletedAt: null,
        verificationExpiresAt: { lte: new Date() },
      },
      select: { id: true },
      take: 100,
    });

    let expiredCount = 0;
    for (const app of overdue) {
      try {
        await this.expireSellerVerification(app.id, null, {
          reason: 'Verification validity period expired',
        });
        expiredCount++;
      } catch (err: any) {
        this.logger.warn(
          `Failed to expire overdue seller application ${app.id}: ${err?.message}`,
        );
      }
    }
    return { expiredCount };
  }

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

    await this.notifyUser(
      app.userId,
      'SELLER_APPLICATION_APPROVED',
      'Seller Privileges Reinstated',
      'Your seller privileges have been reinstated. You can resume managing your listings.',
      { applicationId, status: SellerApplicationStatus.APPROVED },
    );

    return updated;
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  private async evaluateCompleteness(
    app: any,
    documents: any[],
  ): Promise<DynamicCompletenessResult> {
    if (this.requirementsService) {
      return this.requirementsService.evaluateCompleteness(app, documents);
    }

    // Fallback for lightweight unit tests instantiated without requirementsService
    const activeDocs = (documents || []).filter(
      (d) => d.isCurrent !== false && !d.deletedAt,
    );
    const legacy = evaluateApplicationCompleteness({
      businessType: app.businessType,
      businessName: app.businessName,
      nationalIdNumber:
        this.cryptoService?.decrypt(app.nationalIdNumber) ??
        app.nationalIdNumber,
      commercialRegisterNumber: app.commercialRegisterNumber,
      documents: activeDocs,
    });
    return {
      isComplete: legacy.isComplete,
      missingFields: legacy.missingFields,
      missingDocuments: legacy.missingDocuments,
      rejectedDocuments: [],
      expiredDocuments: [],
      requiredDocuments: getRequiredDocumentTypes(app.businessType),
    };
  }

  private async findMatchingRequirement(
    application: { sellerType?: string; marketplaceSections?: unknown },
    documentType: string,
  ) {
    if (!this.requirementsService) return null;
    const sections = Array.isArray(application.marketplaceSections)
      ? (application.marketplaceSections as string[])
      : [];
    const reqs = await this.requirementsService.getApplicableRequirements(
      application.sellerType || SellerType.INDIVIDUAL,
      sections,
    );
    return reqs.find((r) => r.documentType === documentType) ?? null;
  }

  private validateDocumentExpiration(
    expiresAtStr?: string,
    requiresExpiration = false,
  ): Date | null {
    if (!expiresAtStr) {
      if (requiresExpiration) {
        throw new BadRequestException({
          code: 'DOCUMENT_EXPIRATION_REQUIRED',
          message:
            'An expiration date (expiresAt) is required for this verification document type',
        });
      }
      return null;
    }

    const parsed = new Date(expiresAtStr);
    if (Number.isNaN(parsed.getTime())) {
      throw new BadRequestException('Invalid expiresAt date format');
    }
    if (parsed <= new Date()) {
      throw new BadRequestException({
        code: 'DOCUMENT_ALREADY_EXPIRED',
        message: 'Verification document expiration date must be in the future',
      });
    }
    return parsed;
  }

  private async getEditableApplicationForUser(userId: string) {
    const application = await this.prisma.sellerApplication.findFirst({
      where: { userId, isActive: true, deletedAt: null },
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
        SellerApplicationStatus.NEEDS_CORRECTION,
        SellerApplicationStatus.REJECTED,
        SellerApplicationStatus.EXPIRED,
      ].includes(application.status as SellerApplicationStatus)
    ) {
      throw new BadRequestException(
        `Documents can only be uploaded while application is in DRAFT, NEEDS_CORRECTION, REJECTED, or EXPIRED status (current: '${application.status}')`,
      );
    }

    return application;
  }

  private assertNotSelfAction(
    app: {
      userId: string;
      user?: { email?: string | null; phone?: string | null };
    },
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

  private sanitizeDocumentForUser(doc: any) {
    return {
      id: doc.id,
      applicationId: doc.applicationId,
      requirementId: doc.requirementId ?? null,
      documentType: doc.documentType,
      version: doc.version ?? 1,
      isCurrent: doc.isCurrent ?? true,
      originalFileName: doc.originalFileName,
      mimeType: doc.mimeType,
      fileSizeBytes: doc.fileSizeBytes,
      status: doc.status,
      expiresAt: doc.expiresAt ?? null,
      rejectionReason: doc.rejectionReason ?? null,
      uploadedAt: doc.uploadedAt,
      createdAt: doc.createdAt,
    };
  }

  private async formatApplicationForUser(app: any) {
    const docs = Array.isArray(app.documents)
      ? app.documents.filter((d: any) => !d.deletedAt)
      : [];
    const currentDocs = docs.filter((d: any) => d.isCurrent !== false);
    const completeness = await this.evaluateCompleteness(app, docs);

    return {
      id: app.id,
      userId: app.userId,
      accountId: app.accountId,
      status: app.status,
      sellerType: app.sellerType ?? SellerType.INDIVIDUAL,
      businessType: app.businessType,
      marketplaceSections: Array.isArray(app.marketplaceSections)
        ? app.marketplaceSections
        : [],
      businessName: app.businessName,
      businessDescription: app.businessDescription,
      nationalIdNumber: this.maskSensitive(app.nationalIdNumber),
      taxIdNumber: this.maskSensitive(app.taxIdNumber),
      commercialRegisterNumber: app.commercialRegisterNumber,
      authorizedRepresentativeName: app.authorizedRepresentativeName ?? null,
      authorizedRepresentativeId: this.maskSensitive(
        app.authorizedRepresentativeId,
      ),
      serviceCategory: app.serviceCategory ?? null,
      yearsOfExperience: app.yearsOfExperience ?? null,
      qualifications: app.qualifications ?? null,
      professionalLicenseNumber: app.professionalLicenseNumber ?? null,
      portfolioUrl: app.portfolioUrl ?? null,
      contactPhone: app.contactPhone,
      contactEmail: app.contactEmail,
      cityId: app.cityId,
      address: app.address,
      submittedAt: app.submittedAt,
      reviewedAt: app.reviewedAt,
      rejectionReason: app.rejectionReason,
      suspensionReason: app.suspensionReason,
      correctionReason: app.correctionReason ?? null,
      correctionFields: Array.isArray(app.correctionFields)
        ? app.correctionFields
        : [],
      correctionRequestedAt: app.correctionRequestedAt ?? null,
      verificationExpiresAt: app.verificationExpiresAt ?? null,
      expiredAt: app.expiredAt ?? null,
      resubmissionCount: app.resubmissionCount,
      requiredDocuments: completeness.requiredDocuments,
      completeness,
      documents: currentDocs.map((d: any) => this.sanitizeDocumentForUser(d)),
      createdAt: app.createdAt,
      updatedAt: app.updatedAt,
    };
  }

  private encryptSensitive(val?: string | null): string | null {
    if (!val) return null;
    const trimmed = val.trim();
    if (!trimmed) return null;
    return this.cryptoService ? this.cryptoService.encrypt(trimmed) : trimmed;
  }

  private maskSensitive(val?: string | null): string | null {
    if (!val) return null;
    if (this.cryptoService) {
      return this.cryptoService.mask(val);
    }
    if (val.length <= 4) return '****';
    return `${'*'.repeat(Math.max(4, val.length - 4))}${val.slice(-4)}`;
  }

  private async notifyUser(
    userId: string,
    type: string,
    title: string,
    body: string,
    payload: Record<string, string>,
  ) {
    if (!this.notifications) return;
    try {
      await this.notifications.sendPushNotification(userId, title, body, {
        type,
        ...payload,
      });
    } catch (err: any) {
      this.logger.warn(
        `Non-fatal notification dispatch failure (${type}): ${err?.message}`,
      );
    }
  }

  private async invalidateAccountCache(userId: string, accountId: string) {
    await this.redis
      ?.del?.(`account:membership:${userId}:${accountId}`)
      .catch(() => undefined);
  }
}
