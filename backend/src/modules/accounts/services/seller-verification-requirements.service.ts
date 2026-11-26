import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../core/database/prisma.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';
import {
  MarketplaceSection,
  SellerDocumentStatus,
  SellerDocumentType,
  SellerType,
} from '../../../core/enums/domain.enums';
import { SensitiveDataCryptoService } from './sensitive-data-crypto.service';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';
import {
  ALLOWED_VERIFICATION_MIME_TYPES,
  MAX_VERIFICATION_DOC_SIZE_BYTES,
} from './private-document-storage.service';

export interface RequirementSeedSpec {
  sellerType: SellerType | 'ALL';
  marketplaceSection: MarketplaceSection | null;
  documentType: SellerDocumentType;
  displayName: string;
  displayNameAr: string;
  description: string;
  isRequired: boolean;
  acceptedMimeTypes: string[];
  maxFileSizeBytes: number;
  requiresExpiration: boolean;
  verificationRules: Record<string, unknown>;
  sortOrder: number;
}

const IMAGE_AND_PDF = [...ALLOWED_VERIFICATION_MIME_TYPES];
const IMAGE_ONLY = ['image/jpeg', 'image/png', 'image/webp'];

/**
 * Default configurable verification requirements across all 3 seller types
 * and all 6 Deal One marketplace sections.
 * Stored in PostgreSQL `seller_verification_requirements` and fully editable
 * by authorized admins without code changes.
 */
export const DEFAULT_VERIFICATION_REQUIREMENTS: RequirementSeedSpec[] = [
  // =========================================================================
  // INDIVIDUAL (Global baseline)
  // =========================================================================
  {
    sellerType: SellerType.INDIVIDUAL,
    marketplaceSection: null,
    documentType: SellerDocumentType.NATIONAL_ID_FRONT,
    displayName: 'National ID (Front)',
    displayNameAr: 'البطاقة الشخصية (الوجه الأمامي)',
    description: 'Clear photo or scan of the front side of a valid Egyptian National ID.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { mustBeReadable: true, mustMatchApplicantName: true },
    sortOrder: 10,
  },
  {
    sellerType: SellerType.INDIVIDUAL,
    marketplaceSection: null,
    documentType: SellerDocumentType.NATIONAL_ID_BACK,
    displayName: 'National ID (Back)',
    displayNameAr: 'البطاقة الشخصية (الوجه الخلفي)',
    description: 'Clear photo or scan of the back side of a valid Egyptian National ID.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { mustBeReadable: true },
    sortOrder: 20,
  },
  {
    sellerType: SellerType.INDIVIDUAL,
    marketplaceSection: null,
    documentType: SellerDocumentType.PROOF_OF_ADDRESS,
    displayName: 'Proof of Address',
    displayNameAr: 'إثبات محل الإقامة',
    description: 'Recent utility bill or lease agreement (optional unless required by section).',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { maxAgeDays: 90 },
    sortOrder: 30,
  },
  {
    sellerType: SellerType.INDIVIDUAL,
    marketplaceSection: null,
    documentType: SellerDocumentType.ADDITIONAL_DOCUMENT,
    displayName: 'Additional Supporting Documents',
    displayNameAr: 'مستندات إضافية داعمة',
    description: 'Optional supporting identity or activity documents.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: {},
    sortOrder: 40,
  },

  // =========================================================================
  // BUSINESS (Global baseline)
  // =========================================================================
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: null,
    documentType: SellerDocumentType.COMMERCIAL_REGISTER,
    displayName: 'Commercial Registration Certificate',
    displayNameAr: 'السجل التجاري',
    description: 'Valid commercial registration certificate issued by the competent authority.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { requireActiveRegistration: true },
    sortOrder: 10,
  },
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: null,
    documentType: SellerDocumentType.TAX_CARD,
    displayName: 'Tax Registration Card',
    displayNameAr: 'البطاقة الضريبية',
    description: 'Valid Egyptian Tax Authority registration card.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { requireActiveTaxStatus: true },
    sortOrder: 20,
  },
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: null,
    documentType: SellerDocumentType.NATIONAL_ID_FRONT,
    displayName: 'Legal Representative National ID',
    displayNameAr: 'بطاقة الممثل القانوني',
    description: 'Valid National ID of the business owner or authorized legal representative (configurable by admin).',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { mustBeReadable: true, configurableByAdmin: true },
    sortOrder: 30,
  },
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: null,
    documentType: SellerDocumentType.LEGAL_REPRESENTATION_PROOF,
    displayName: 'Proof of Legal Representation',
    displayNameAr: 'إثبات الصفة القانونية / التفويض',
    description: 'Power of attorney or authorization letter when applicant is not the listed owner.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { requiredWhenRepresentativeDiffers: true },
    sortOrder: 40,
  },
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: null,
    documentType: SellerDocumentType.PROOF_OF_ADDRESS,
    displayName: 'Proof of Business Address',
    displayNameAr: 'إثبات عنوان المقر التجاري',
    description: 'Optional utility bill or commercial lease agreement for the business premises.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { maxAgeDays: 90 },
    sortOrder: 50,
  },
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: null,
    documentType: SellerDocumentType.BUSINESS_LICENSE,
    displayName: 'Business Operating License',
    displayNameAr: 'رخصة مزاولة النشاط التجاري',
    description: 'Optional sector-specific commercial operating license.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: {},
    sortOrder: 60,
  },
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: null,
    documentType: SellerDocumentType.ADDITIONAL_DOCUMENT,
    displayName: 'Additional Business Documents',
    displayNameAr: 'مستندات تجارية إضافية',
    description: 'Optional supporting commercial or regulatory documents.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: {},
    sortOrder: 70,
  },

  // =========================================================================
  // SERVICE_PROVIDER (Global baseline — follows INDIVIDUAL identity requirements by default)
  // =========================================================================
  {
    sellerType: SellerType.SERVICE_PROVIDER,
    marketplaceSection: null,
    documentType: SellerDocumentType.NATIONAL_ID_FRONT,
    displayName: 'National ID (Front)',
    displayNameAr: 'البطاقة الشخصية (الوجه الأمامي)',
    description: 'Valid National ID of the service provider.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { mustBeReadable: true },
    sortOrder: 10,
  },
  {
    sellerType: SellerType.SERVICE_PROVIDER,
    marketplaceSection: null,
    documentType: SellerDocumentType.NATIONAL_ID_BACK,
    displayName: 'National ID (Back)',
    displayNameAr: 'البطاقة الشخصية (الوجه الخلفي)',
    description: 'Back side of the service provider National ID.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { mustBeReadable: true },
    sortOrder: 20,
  },
  {
    sellerType: SellerType.SERVICE_PROVIDER,
    marketplaceSection: null,
    documentType: SellerDocumentType.QUALIFICATION_CERTIFICATE,
    displayName: 'Qualification / Trade Certificate',
    displayNameAr: 'شهادة المؤهل أو الخبرة المهنية',
    description: 'Optional professional degree, syndicate card, or accredited trade qualification (may be required by specific service sections).',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { requireAccreditedIssuer: false },
    sortOrder: 30,
  },
  {
    sellerType: SellerType.SERVICE_PROVIDER,
    marketplaceSection: null,
    documentType: SellerDocumentType.PORTFOLIO_DOCUMENT,
    displayName: 'Portfolio / Previous Work Samples',
    displayNameAr: 'سابقة الأعمال / معرض الأعمال',
    description: 'PDF or images showcasing completed work samples.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: {},
    sortOrder: 40,
  },
  {
    sellerType: SellerType.SERVICE_PROVIDER,
    marketplaceSection: null,
    documentType: SellerDocumentType.ADDITIONAL_DOCUMENT,
    displayName: 'Additional Supporting Documents',
    displayNameAr: 'مستندات إضافية داعمة',
    description: 'Optional supporting identity or service accreditation documents.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: {},
    sortOrder: 50,
  },

  // =========================================================================
  // SECTION-SPECIFIC REQUIREMENTS (6 Deal One Marketplace Categories)
  // =========================================================================
  // 1. Real Estate
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: MarketplaceSection.REAL_ESTATE,
    documentType: SellerDocumentType.BUSINESS_LICENSE,
    displayName: 'Real Estate Brokerage / Developer License',
    displayNameAr: 'ترخيص مزاولة نشاط عقاري',
    description: 'Brokerage or real estate development activity license.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: true,
    verificationRules: { minDaysUntilExpiry: 30 },
    sortOrder: 50,
  },
  {
    sellerType: SellerType.INDIVIDUAL,
    marketplaceSection: MarketplaceSection.REAL_ESTATE,
    documentType: SellerDocumentType.PROOF_OF_ADDRESS,
    displayName: 'Proof of Address (Real Estate)',
    displayNameAr: 'إثبات العنوان (قسم العقارات)',
    description: 'Mandatory address verification for individual real estate sellers.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { maxAgeDays: 90 },
    sortOrder: 35,
  },

  // 2. Building Materials & Electricity
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: MarketplaceSection.BUILDING_MATERIALS,
    documentType: SellerDocumentType.PROOF_OF_ADDRESS,
    displayName: 'Warehouse / Storefront Address Proof',
    displayNameAr: 'إثبات عنوان المخزن أو المعرض',
    description: 'Utility bill or lease contract for building materials supply location.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { maxAgeDays: 90 },
    sortOrder: 50,
  },

  // 3. Home & Engineering Services
  {
    sellerType: SellerType.SERVICE_PROVIDER,
    marketplaceSection: MarketplaceSection.SERVICES,
    documentType: SellerDocumentType.QUALIFICATION_CERTIFICATE,
    displayName: 'Qualification / Trade Certificate (Services)',
    displayNameAr: 'شهادة المؤهل أو الخبرة المهنية (قسم الخدمات)',
    description: 'Professional degree, syndicate card, or accredited trade qualification for Home & Engineering Services.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: { requireAccreditedIssuer: false },
    sortOrder: 30,
  },
  {
    sellerType: SellerType.SERVICE_PROVIDER,
    marketplaceSection: MarketplaceSection.SERVICES,
    documentType: SellerDocumentType.PROFESSIONAL_LICENSE,
    displayName: 'Engineering / Professional Practice License',
    displayNameAr: 'ترخيص مزاولة المهنة / كارنيه النقابة',
    description: 'Valid professional syndicate card or licensed contractor permit.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: true,
    verificationRules: { minDaysUntilExpiry: 15 },
    sortOrder: 35,
  },

  // 4. Appliances & Home Decor
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: MarketplaceSection.HOME_APPLIANCES,
    documentType: SellerDocumentType.BUSINESS_LICENSE,
    displayName: 'Authorized Dealer / Store Permit',
    displayNameAr: 'تصريح معرض أو وكيل معتمد',
    description: 'Optional dealer authorization or showroom operating permit.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: false,
    verificationRules: {},
    sortOrder: 50,
  },

  // 5. Cars
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: MarketplaceSection.CARS,
    documentType: SellerDocumentType.BUSINESS_LICENSE,
    displayName: 'Automotive Dealership License',
    displayNameAr: 'ترخيص معرض سيارات',
    description: 'Valid showroom or dealership operating license for Cars section.',
    isRequired: true,
    acceptedMimeTypes: IMAGE_AND_PDF,
    maxFileSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    requiresExpiration: true,
    verificationRules: { minDaysUntilExpiry: 30 },
    sortOrder: 50,
  },

  // 6. Clothes & Accessories (fashion)
  {
    sellerType: SellerType.BUSINESS,
    marketplaceSection: MarketplaceSection.FASHION,
    documentType: SellerDocumentType.PORTFOLIO_DOCUMENT,
    displayName: 'Brand / Store Catalog Sample',
    displayNameAr: 'نموذج كتالوج العلامة التجارية',
    description: 'Optional brand lookbook or store product sample.',
    isRequired: false,
    acceptedMimeTypes: IMAGE_ONLY,
    maxFileSizeBytes: 5 * 1024 * 1024,
    requiresExpiration: false,
    verificationRules: {},
    sortOrder: 50,
  },
];

export interface DynamicCompletenessResult {
  isComplete: boolean;
  missingFields: string[];
  missingDocuments: string[];
  rejectedDocuments: string[];
  expiredDocuments: string[];
  requiredDocuments: string[];
}

export interface CreateRequirementInput {
  sellerType: SellerType | 'ALL';
  marketplaceSection?: string | null;
  documentType: string;
  displayName: string;
  displayNameAr?: string;
  description?: string;
  isRequired?: boolean;
  acceptedMimeTypes?: string[];
  maxFileSizeBytes?: number;
  requiresExpiration?: boolean;
  verificationRules?: Record<string, unknown>;
  isActive?: boolean;
  sortOrder?: number;
}

export interface UpdateRequirementInput {
  displayName?: string;
  displayNameAr?: string;
  description?: string;
  isRequired?: boolean;
  acceptedMimeTypes?: string[];
  maxFileSizeBytes?: number;
  requiresExpiration?: boolean;
  verificationRules?: Record<string, unknown>;
  isActive?: boolean;
  sortOrder?: number;
}

@Injectable()
export class SellerVerificationRequirementsService implements OnModuleInit {
  private readonly logger = new Logger(
    SellerVerificationRequirementsService.name,
  );
  private seeded = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly cryptoService: SensitiveDataCryptoService,
    private readonly securityAudit: SecurityAuditService,
  ) {}

  async onModuleInit() {
    await this.ensureDefaultRequirementsSeeded().catch((err) => {
      this.logger.warn(
        `Deferred verification requirements seeding: ${err?.message ?? err}`,
      );
    });
  }

  /**
   * Idempotently seeds missing default verification requirements without
   * ever overwriting existing customized admin requirements.
   */
  async ensureDefaultRequirementsSeeded(): Promise<void> {
    if (this.seeded) return;
    if (!this.prisma?.sellerVerificationRequirement) return;

    const existingRows =
      await this.prisma.sellerVerificationRequirement.findMany({
        select: {
          sellerType: true,
          marketplaceSection: true,
          documentType: true,
        },
      });

    const existingKeys = new Set(
      existingRows.map(
        (r) =>
          `${String(r.sellerType).toUpperCase()}::${r.marketplaceSection ?? ''}::${String(r.documentType).toLowerCase()}`,
      ),
    );

    const missingSpecs = DEFAULT_VERIFICATION_REQUIREMENTS.filter((spec) => {
      const key = `${String(spec.sellerType).toUpperCase()}::${spec.marketplaceSection ?? ''}::${String(spec.documentType).toLowerCase()}`;
      return !existingKeys.has(key);
    });

    if (missingSpecs.length === 0) {
      this.seeded = true;
      return;
    }

    await this.prisma.sellerVerificationRequirement.createMany({
      data: missingSpecs.map((spec) => ({
        sellerType: spec.sellerType,
        marketplaceSection: spec.marketplaceSection,
        documentType: spec.documentType,
        displayName: spec.displayName,
        displayNameAr: spec.displayNameAr,
        description: spec.description,
        isRequired: spec.isRequired,
        acceptedMimeTypes: spec.acceptedMimeTypes,
        maxFileSizeBytes: spec.maxFileSizeBytes,
        requiresExpiration: spec.requiresExpiration,
        verificationRules: spec.verificationRules as Prisma.InputJsonValue,
        isActive: true,
        version: 1,
        sortOrder: spec.sortOrder,
      })),
    });

    this.seeded = true;
    this.logger.log(
      `Seeded ${missingSpecs.length} missing default seller verification requirements (existing customized rows preserved)`,
    );
  }

  /**
   * Resolves all active verification requirements for a given sellerType and
   * optional list of marketplace sections. Section-specific rules override
   * global rules for the same documentType.
   */
  async getApplicableRequirements(
    sellerType: string,
    marketplaceSections: string[] = [],
  ) {
    await this.ensureDefaultRequirementsSeeded();

    const normalizedSellerType = (sellerType || SellerType.INDIVIDUAL).toUpperCase();
    const normalizedSections = Array.from(
      new Set(
        (marketplaceSections || [])
          .map((s) => String(s).trim().toLowerCase())
          .filter(Boolean),
      ),
    );

    const rows = await this.prisma.sellerVerificationRequirement.findMany({
      where: {
        isActive: true,
        deletedAt: null,
        sellerType: { in: [normalizedSellerType, 'ALL'] },
        OR: [
          { marketplaceSection: null },
          ...(normalizedSections.length > 0
            ? [{ marketplaceSection: { in: normalizedSections } }]
            : []),
        ],
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
    });

    // Merge: section-specific requirement overrides global requirement for same documentType
    // If multiple sections specify the same documentType, required=true takes precedence
    const merged = new Map<string, (typeof rows)[number]>();
    for (const row of rows) {
      const existing = merged.get(row.documentType);
      if (!existing) {
        merged.set(row.documentType, row);
        continue;
      }
      const existingIsSectionSpecific = existing.marketplaceSection !== null;
      const incomingIsSectionSpecific = row.marketplaceSection !== null;
      if (!existingIsSectionSpecific && incomingIsSectionSpecific) {
        merged.set(row.documentType, row);
      } else if (
        existingIsSectionSpecific === incomingIsSectionSpecific &&
        !existing.isRequired &&
        row.isRequired
      ) {
        merged.set(row.documentType, row);
      }
    }

    return Array.from(merged.values()).sort(
      (a, b) => a.sortOrder - b.sortOrder,
    );
  }

  /**
   * Builds an immutable snapshot of applicable requirements at submission time
   * so mid-review admin edits to requirement rules do not invalidate in-flight applications.
   */
  async buildRequirementsSnapshot(
    sellerType: string,
    marketplaceSections: string[] = [],
  ): Promise<{
    requirementsVersion: number;
    snapshot: Array<{
      id: string;
      documentType: string;
      displayName: string;
      isRequired: boolean;
      requiresExpiration: boolean;
      acceptedMimeTypes: unknown;
      maxFileSizeBytes: number;
      version: number;
    }>;
  }> {
    const reqs = await this.getApplicableRequirements(
      sellerType,
      marketplaceSections,
    );
    const maxVersion = reqs.reduce((acc, r) => Math.max(acc, r.version ?? 1), 1);
    return {
      requirementsVersion: maxVersion,
      snapshot: reqs.map((r) => ({
        id: r.id,
        documentType: r.documentType,
        displayName: r.displayName,
        isRequired: r.isRequired,
        requiresExpiration: r.requiresExpiration,
        acceptedMimeTypes: r.acceptedMimeTypes,
        maxFileSizeBytes: r.maxFileSizeBytes,
        version: r.version ?? 1,
      })),
    };
  }

  /**
   * Evaluates full application completeness against BOTH seller-type profile rules
   * and dynamic DB-backed document requirements (or the application's locked
   * requirementsSnapshot when already submitted).
   */
  async evaluateCompleteness(
    application: {
      sellerType: string;
      businessType: string;
      marketplaceSections?: unknown;
      requirementsSnapshot?: unknown;
      businessName?: string | null;
      nationalIdNumber?: string | null;
      commercialRegisterNumber?: string | null;
      taxIdNumber?: string | null;
      authorizedRepresentativeName?: string | null;
      serviceCategory?: string | null;
      qualifications?: string | null;
      professionalLicenseNumber?: string | null;
    },
    documents: Array<{
      documentType: string;
      status: string;
      isCurrent?: boolean;
      deletedAt?: Date | null;
      expiresAt?: Date | null;
    }>,
  ): Promise<DynamicCompletenessResult> {
    const sections = Array.isArray(application.marketplaceSections)
      ? (application.marketplaceSections as string[])
      : [];

    const snapshotItems = Array.isArray(application.requirementsSnapshot)
      ? (application.requirementsSnapshot as Array<{
          documentType: string;
          isRequired: boolean;
          requiresExpiration?: boolean;
        }>)
      : null;

    const requirements =
      snapshotItems && snapshotItems.length > 0
        ? snapshotItems
        : await this.getApplicableRequirements(application.sellerType, sections);

    const missingFields: string[] = [];
    if (!application.businessName || application.businessName.trim().length < 2) {
      missingFields.push('businessName');
    }

    const sellerType = (application.sellerType || SellerType.INDIVIDUAL).toUpperCase();

    if (sellerType === SellerType.BUSINESS) {
      if (
        !this.cryptoService.hasMinimumLength(
          application.commercialRegisterNumber,
          3,
        )
      ) {
        missingFields.push('commercialRegisterNumber');
      }
    } else if (sellerType === SellerType.SERVICE_PROVIDER) {
      if (!this.cryptoService.hasMinimumLength(application.nationalIdNumber, 6)) {
        missingFields.push('nationalIdNumber');
      }
      if (!application.serviceCategory || application.serviceCategory.trim().length < 2) {
        missingFields.push('serviceCategory');
      }
    } else {
      // INDIVIDUAL
      if (!this.cryptoService.hasMinimumLength(application.nationalIdNumber, 6)) {
        missingFields.push('nationalIdNumber');
      }
    }

    // Filter to current, non-deleted documents
    const activeDocs = documents.filter(
      (d) => d.isCurrent !== false && !d.deletedAt,
    );

    const now = new Date();
    const requiredReqs = requirements.filter((r) => r.isRequired);
    const requiredDocuments = requiredReqs.map((r) => r.documentType);

    const missingDocuments: string[] = [];
    const rejectedDocuments: string[] = [];
    const expiredDocuments: string[] = [];

    for (const req of requiredReqs) {
      const matchingDocs = activeDocs.filter(
        (d) => d.documentType === req.documentType,
      );

      if (matchingDocs.length === 0) {
        missingDocuments.push(req.documentType);
        continue;
      }

      const validDoc = matchingDocs.find(
        (d) =>
          d.status === SellerDocumentStatus.UPLOADED ||
          d.status === SellerDocumentStatus.VERIFIED,
      );

      if (!validDoc) {
        if (matchingDocs.some((d) => d.status === SellerDocumentStatus.REJECTED)) {
          rejectedDocuments.push(req.documentType);
        } else {
          missingDocuments.push(req.documentType);
        }
        continue;
      }

      if (req.requiresExpiration) {
        if (!validDoc.expiresAt || validDoc.expiresAt <= now) {
          expiredDocuments.push(req.documentType);
        }
      } else if (validDoc.expiresAt && validDoc.expiresAt <= now) {
        expiredDocuments.push(req.documentType);
      }
    }

    return {
      isComplete:
        missingFields.length === 0 &&
        missingDocuments.length === 0 &&
        rejectedDocuments.length === 0 &&
        expiredDocuments.length === 0,
      missingFields,
      missingDocuments,
      rejectedDocuments,
      expiredDocuments,
      requiredDocuments,
    };
  }

  // =========================================================================
  // ADMIN REQUIREMENT MANAGEMENT (CRUD + VERSIONING)
  // =========================================================================

  async listRequirementsForAdmin(filters?: {
    sellerType?: string;
    marketplaceSection?: string;
    isActive?: boolean;
  }) {
    await this.ensureDefaultRequirementsSeeded();

    const where: Prisma.SellerVerificationRequirementWhereInput = {
      deletedAt: null,
      ...(filters?.sellerType
        ? { sellerType: filters.sellerType.toUpperCase() }
        : {}),
      ...(filters?.marketplaceSection
        ? { marketplaceSection: filters.marketplaceSection.toLowerCase() }
        : {}),
      ...(filters?.isActive !== undefined ? { isActive: filters.isActive } : {}),
    };

    const items = await this.prisma.sellerVerificationRequirement.findMany({
      where,
      orderBy: [{ sellerType: 'asc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    });

    return { items, total: items.length };
  }

  async createRequirement(
    dto: CreateRequirementInput,
    staff: AuthenticatedStaff,
    ctx: { requestId?: string; ipAddress?: string; userAgent?: string } = {},
  ) {
    const allowedSellerTypes = ['INDIVIDUAL', 'BUSINESS', 'SERVICE_PROVIDER', 'ALL'];
    const sellerType = dto.sellerType.toUpperCase();
    if (!allowedSellerTypes.includes(sellerType)) {
      throw new BadRequestException(`Invalid sellerType '${dto.sellerType}'`);
    }

    const created = await this.prisma.sellerVerificationRequirement.create({
      data: {
        sellerType,
        marketplaceSection: dto.marketplaceSection?.trim().toLowerCase() || null,
        documentType: dto.documentType.trim().toLowerCase(),
        displayName: dto.displayName.trim(),
        displayNameAr: dto.displayNameAr?.trim() || null,
        description: dto.description?.trim() || null,
        isRequired: dto.isRequired ?? true,
        acceptedMimeTypes:
          dto.acceptedMimeTypes && dto.acceptedMimeTypes.length > 0
            ? dto.acceptedMimeTypes
            : IMAGE_AND_PDF,
        maxFileSizeBytes: dto.maxFileSizeBytes ?? MAX_VERIFICATION_DOC_SIZE_BYTES,
        requiresExpiration: dto.requiresExpiration ?? false,
        verificationRules: (dto.verificationRules ?? {}) as Prisma.InputJsonValue,
        isActive: dto.isActive ?? true,
        version: 1,
        sortOrder: dto.sortOrder ?? 100,
        createdByStaffId: staff.staffId ?? null,
        updatedByStaffId: staff.staffId ?? null,
      },
    });

    await this.securityAudit.logEvent({
      action: 'VERIFICATION_REQUIREMENT_CREATED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'SellerVerificationRequirement',
      targetId: created.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        sellerType: created.sellerType,
        marketplaceSection: created.marketplaceSection,
        documentType: created.documentType,
        isRequired: created.isRequired,
        version: created.version,
      },
    });

    return created;
  }

  async updateRequirement(
    requirementId: string,
    dto: UpdateRequirementInput,
    staff: AuthenticatedStaff,
    ctx: { requestId?: string; ipAddress?: string; userAgent?: string } = {},
  ) {
    const existing = await this.prisma.sellerVerificationRequirement.findFirst({
      where: { id: requirementId, deletedAt: null },
    });
    if (!existing) {
      throw new NotFoundException('Verification requirement not found');
    }

    const updated = await this.prisma.sellerVerificationRequirement.update({
      where: { id: requirementId },
      data: {
        ...(dto.displayName !== undefined
          ? { displayName: dto.displayName.trim() }
          : {}),
        ...(dto.displayNameAr !== undefined
          ? { displayNameAr: dto.displayNameAr.trim() }
          : {}),
        ...(dto.description !== undefined
          ? { description: dto.description.trim() }
          : {}),
        ...(dto.isRequired !== undefined ? { isRequired: dto.isRequired } : {}),
        ...(dto.acceptedMimeTypes !== undefined
          ? { acceptedMimeTypes: dto.acceptedMimeTypes }
          : {}),
        ...(dto.maxFileSizeBytes !== undefined
          ? { maxFileSizeBytes: dto.maxFileSizeBytes }
          : {}),
        ...(dto.requiresExpiration !== undefined
          ? { requiresExpiration: dto.requiresExpiration }
          : {}),
        ...(dto.verificationRules !== undefined
          ? {
              verificationRules:
                dto.verificationRules as Prisma.InputJsonValue,
            }
          : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
        ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
        version: { increment: 1 },
        updatedByStaffId: staff.staffId ?? null,
      },
    });

    await this.securityAudit.logEvent({
      action: 'VERIFICATION_REQUIREMENT_UPDATED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'SellerVerificationRequirement',
      targetId: updated.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        previousVersion: existing.version,
        newVersion: updated.version,
        updatedFields: Object.keys(dto),
      },
    });

    return updated;
  }

  async deactivateRequirement(
    requirementId: string,
    staff: AuthenticatedStaff,
    ctx: { requestId?: string; ipAddress?: string; userAgent?: string } = {},
  ) {
    const existing = await this.prisma.sellerVerificationRequirement.findFirst({
      where: { id: requirementId, deletedAt: null },
    });
    if (!existing) {
      throw new NotFoundException('Verification requirement not found');
    }

    const updated = await this.prisma.sellerVerificationRequirement.update({
      where: { id: requirementId },
      data: {
        isActive: false,
        deletedAt: new Date(),
        version: { increment: 1 },
        updatedByStaffId: staff.staffId ?? null,
      },
    });

    await this.securityAudit.logEvent({
      action: 'VERIFICATION_REQUIREMENT_DEACTIVATED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'SellerVerificationRequirement',
      targetId: updated.id,
      ipAddress: ctx.ipAddress,
      userAgent: ctx.userAgent,
      correlationId: ctx.requestId,
      metadata: {
        documentType: existing.documentType,
        sellerType: existing.sellerType,
        newVersion: updated.version,
      },
    });

    return { success: true, id: updated.id, isActive: false };
  }
}
