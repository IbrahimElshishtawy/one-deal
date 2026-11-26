import { BadRequestException, ConflictException, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AccountType,
  MarketplaceSection,
  SellerApplicationStatus,
  SellerApplicationType,
  SellerDocumentStatus,
  SellerDocumentType,
  SellerType,
  VerificationStatus,
  VerificationTier,
} from '../../core/enums/domain.enums';
import {
  buildVerificationBadge,
  deriveVerificationTier,
  formatPublicSellerVerification,
  resolveEffectiveVerificationTier,
} from './verification-tier.helper';
import {
  DEFAULT_VERIFICATION_REQUIREMENTS,
  SellerVerificationRequirementsService,
} from './services/seller-verification-requirements.service';
import { PrivateDocumentStorageService } from './services/private-document-storage.service';
import { SensitiveDataCryptoService } from './services/sensitive-data-crypto.service';
import { SellerApplicationService } from './services/seller-application.service';
import { AuthenticatedStaff } from '../admin-auth/types/authenticated-staff.type';

describe('Seller Verification Tiers, Requirements & Business Upgrade (Unit)', () => {
  const mockConfig = {
    get: (key: string, def?: any) => {
      const map: Record<string, any> = {
        SELLER_PII_ENCRYPTION_KEY: 'unit_test_seller_pii_key_32_bytes_minimum!!',
        R2_BUCKET_NAME: 'marketspace-media',
        NODE_ENV: 'test',
        JWT_ACCESS_SECRET: 'unit_test_jwt_secret_key_for_signing_123456',
      };
      return map[key] ?? def ?? '';
    },
  } as unknown as ConfigService;

  const cryptoSvc = new SensitiveDataCryptoService(mockConfig);
  const storageSvc = new PrivateDocumentStorageService(mockConfig);

  // =========================================================================
  // 1. VERIFICATION TIER DERIVATION & BADGE SERIALIZATION
  // =========================================================================
  describe('Verification Tier Derivation & Arabic Badges', () => {
    it('derives IDENTITY_VERIFIED for approved INDIVIDUAL with national_id_front + national_id_back', () => {
      const tier = deriveVerificationTier({
        sellerType: SellerType.INDIVIDUAL,
        status: SellerApplicationStatus.APPROVED,
        documents: [
          { documentType: SellerDocumentType.NATIONAL_ID_FRONT, status: SellerDocumentStatus.VERIFIED },
          { documentType: SellerDocumentType.NATIONAL_ID_BACK, status: SellerDocumentStatus.UPLOADED },
        ],
      });
      expect(tier).toBe(VerificationTier.IDENTITY_VERIFIED);

      const badge = buildVerificationBadge(VerificationStatus.APPROVED, tier, true);
      expect(badge).toEqual({
        code: VerificationTier.IDENTITY_VERIFIED,
        label: 'هوية موثقة',
      });
    });

    it('derives IDENTITY_VERIFIED for approved SERVICE_PROVIDER following individual identity docs', () => {
      const tier = deriveVerificationTier({
        sellerType: SellerType.SERVICE_PROVIDER,
        status: SellerApplicationStatus.APPROVED,
        documents: [
          { documentType: SellerDocumentType.NATIONAL_ID_FRONT, status: SellerDocumentStatus.VERIFIED },
          { documentType: SellerDocumentType.NATIONAL_ID_BACK, status: SellerDocumentStatus.VERIFIED },
        ],
      });
      expect(tier).toBe(VerificationTier.IDENTITY_VERIFIED);
    });

    it('derives BUSINESS_VERIFIED for approved BUSINESS with commercial_register + tax_card', () => {
      const tier = deriveVerificationTier({
        sellerType: SellerType.BUSINESS,
        status: SellerApplicationStatus.APPROVED,
        documents: [
          { documentType: SellerDocumentType.COMMERCIAL_REGISTER, status: SellerDocumentStatus.VERIFIED },
          { documentType: SellerDocumentType.TAX_CARD, status: SellerDocumentStatus.VERIFIED },
        ],
      });
      expect(tier).toBe(VerificationTier.BUSINESS_VERIFIED);

      const badge = buildVerificationBadge(VerificationStatus.APPROVED, tier, true);
      expect(badge).toEqual({
        code: VerificationTier.BUSINESS_VERIFIED,
        label: 'شركة / مكتب موثق',
      });
    });

    it('returns NONE if BUSINESS documents are incomplete (e.g. missing tax_card)', () => {
      const tier = deriveVerificationTier({
        sellerType: SellerType.BUSINESS,
        status: SellerApplicationStatus.APPROVED,
        documents: [
          { documentType: SellerDocumentType.COMMERCIAL_REGISTER, status: SellerDocumentStatus.VERIFIED },
        ],
      });
      expect(tier).toBe(VerificationTier.NONE);
    });

    it('NEVER grants a verified tier or badge for PENDING, REJECTED, NEEDS_CORRECTION, SUSPENDED, or EXPIRED', () => {
      const nonApprovedStatuses = [
        SellerApplicationStatus.DRAFT,
        SellerApplicationStatus.PENDING,
        SellerApplicationStatus.UNDER_REVIEW,
        SellerApplicationStatus.NEEDS_CORRECTION,
        SellerApplicationStatus.REJECTED,
        SellerApplicationStatus.SUSPENDED,
        SellerApplicationStatus.EXPIRED,
        VerificationStatus.PENDING,
        VerificationStatus.REJECTED,
        VerificationStatus.SUSPENDED,
      ];

      for (const status of nonApprovedStatuses) {
        expect(
          deriveVerificationTier({
            sellerType: SellerType.BUSINESS,
            status,
            documents: [
              { documentType: SellerDocumentType.COMMERCIAL_REGISTER, status: SellerDocumentStatus.VERIFIED },
              { documentType: SellerDocumentType.TAX_CARD, status: SellerDocumentStatus.VERIFIED },
            ],
          }),
        ).toBe(VerificationTier.NONE);

        expect(
          buildVerificationBadge(status, VerificationTier.BUSINESS_VERIFIED, true),
        ).toBeNull();

        expect(
          resolveEffectiveVerificationTier(status, VerificationTier.IDENTITY_VERIFIED, true),
        ).toBe(VerificationTier.NONE);
      }
    });

    it('returns null badge when account is inactive even if status was approved', () => {
      expect(
        buildVerificationBadge(
          VerificationStatus.APPROVED,
          VerificationTier.BUSINESS_VERIFIED,
          false,
        ),
      ).toBeNull();
    });

    it('formats safe public seller verification summary without sensitive fields', () => {
      const summary = formatPublicSellerVerification({
        id: 'acc-1',
        displayName: 'Al-Nile Office',
        slug: 'al-nile-office',
        accountType: AccountType.OFFICE,
        sellerType: SellerType.BUSINESS,
        verificationStatus: VerificationStatus.APPROVED,
        verificationTier: VerificationTier.BUSINESS_VERIFIED,
        logoUrl: null,
        isActive: true,
      });

      expect(summary).toEqual({
        id: 'acc-1',
        name: 'Al-Nile Office',
        slug: 'al-nile-office',
        accountType: AccountType.OFFICE,
        sellerType: SellerType.BUSINESS,
        verificationStatus: 'APPROVED',
        verificationTier: VerificationTier.BUSINESS_VERIFIED,
        verificationBadge: {
          code: VerificationTier.BUSINESS_VERIFIED,
          label: 'شركة / مكتب موثق',
        },
        logoUrl: null,
      });
    });
  });

  // =========================================================================
  // 2. CONFIGURABLE REQUIREMENTS RESOLUTION & OPTIONAL DOCUMENTS
  // =========================================================================
  describe('Configurable Verification Requirements & Idempotent Seeding', () => {
    let reqService: SellerVerificationRequirementsService;
    let prismaMock: any;
    let storedRows: any[];

    beforeEach(() => {
      storedRows = DEFAULT_VERIFICATION_REQUIREMENTS.map((spec, idx) => ({
        id: `req-${idx + 1}`,
        ...spec,
        isActive: true,
        version: 1,
        deletedAt: null,
        createdAt: new Date(),
      }));

      prismaMock = {
        sellerVerificationRequirement: {
          findMany: jest.fn(async ({ where }: any = {}) => {
            if (!where) return storedRows;
            return storedRows.filter((r) => {
              if (where.deletedAt === null && r.deletedAt !== null) return false;
              if (where.isActive === true && !r.isActive) return false;
              if (where.sellerType?.in && !where.sellerType.in.includes(r.sellerType)) {
                return false;
              }
              if (where.OR) {
                const matchesOr = where.OR.some((clause: any) => {
                  if (clause.marketplaceSection === null) return r.marketplaceSection === null;
                  if (clause.marketplaceSection?.in) {
                    return clause.marketplaceSection.in.includes(r.marketplaceSection);
                  }
                  return false;
                });
                if (!matchesOr) return false;
              }
              return true;
            });
          }),
          createMany: jest.fn(async ({ data }: any) => {
            for (const row of data) {
              storedRows.push({ id: `req-new-${storedRows.length + 1}`, ...row, deletedAt: null });
            }
            return { count: data.length };
          }),
        },
      };

      reqService = new SellerVerificationRequirementsService(
        prismaMock,
        cryptoSvc,
        { logEvent: jest.fn() } as any,
      );
    });

    it('resolves INDIVIDUAL baseline requirements: National ID Front + Back required; Proof of Address & Additional optional', async () => {
      const reqs = await reqService.getApplicableRequirements(SellerType.INDIVIDUAL, []);
      const required = reqs.filter((r) => r.isRequired).map((r) => r.documentType);
      const optional = reqs.filter((r) => !r.isRequired).map((r) => r.documentType);

      expect(required).toEqual([
        SellerDocumentType.NATIONAL_ID_FRONT,
        SellerDocumentType.NATIONAL_ID_BACK,
      ]);
      expect(optional).toContain(SellerDocumentType.PROOF_OF_ADDRESS);
      expect(optional).toContain(SellerDocumentType.ADDITIONAL_DOCUMENT);
      expect(required).not.toContain(SellerDocumentType.COMMERCIAL_REGISTER);
      expect(required).not.toContain(SellerDocumentType.TAX_CARD);
    });

    it('resolves BUSINESS baseline requirements: Commercial Register + Tax Card required; Legal Rep ID optional by default', async () => {
      const reqs = await reqService.getApplicableRequirements(SellerType.BUSINESS, []);
      const required = reqs.filter((r) => r.isRequired).map((r) => r.documentType);
      const optional = reqs.filter((r) => !r.isRequired).map((r) => r.documentType);

      expect(required).toEqual([
        SellerDocumentType.COMMERCIAL_REGISTER,
        SellerDocumentType.TAX_CARD,
      ]);
      expect(optional).toContain(SellerDocumentType.NATIONAL_ID_FRONT);
      expect(optional).toContain(SellerDocumentType.PROOF_OF_ADDRESS);
      expect(optional).toContain(SellerDocumentType.BUSINESS_LICENSE);
      expect(optional).toContain(SellerDocumentType.ADDITIONAL_DOCUMENT);
    });

    it('resolves SERVICE_PROVIDER baseline requirements following INDIVIDUAL defaults, extensible per section', async () => {
      const baseline = await reqService.getApplicableRequirements(SellerType.SERVICE_PROVIDER, []);
      const baselineRequired = baseline.filter((r) => r.isRequired).map((r) => r.documentType);
      expect(baselineRequired).toEqual([
        SellerDocumentType.NATIONAL_ID_FRONT,
        SellerDocumentType.NATIONAL_ID_BACK,
      ]);

      const servicesSection = await reqService.getApplicableRequirements(
        SellerType.SERVICE_PROVIDER,
        [MarketplaceSection.SERVICES],
      );
      const servicesRequired = servicesSection.filter((r) => r.isRequired).map((r) => r.documentType);
      expect(servicesRequired).toContain(SellerDocumentType.NATIONAL_ID_FRONT);
      expect(servicesRequired).toContain(SellerDocumentType.NATIONAL_ID_BACK);
      expect(servicesRequired).toContain(SellerDocumentType.QUALIFICATION_CERTIFICATE);
      expect(servicesRequired).toContain(SellerDocumentType.PROFESSIONAL_LICENSE);
    });

    it('ensures optional documents NEVER block completeness evaluation', async () => {
      const result = await reqService.evaluateCompleteness(
        {
          sellerType: SellerType.BUSINESS,
          businessType: AccountType.COMPANY,
          businessName: 'Delta Real Estate',
          commercialRegisterNumber: 'CR-445566',
          marketplaceSections: [],
        },
        [
          { documentType: SellerDocumentType.COMMERCIAL_REGISTER, status: SellerDocumentStatus.UPLOADED, isCurrent: true },
          { documentType: SellerDocumentType.TAX_CARD, status: SellerDocumentStatus.UPLOADED, isCurrent: true },
        ],
      );

      expect(result.isComplete).toBe(true);
      expect(result.missingDocuments).toEqual([]);
    });

    it('does NOT overwrite customized admin requirements during idempotent reseeding', async () => {
      // Simulate admin customized BUSINESS national_id_front to be required
      const bizRepRow = storedRows.find(
        (r) =>
          r.sellerType === SellerType.BUSINESS &&
          r.marketplaceSection === null &&
          r.documentType === SellerDocumentType.NATIONAL_ID_FRONT,
      );
      bizRepRow.isRequired = true;
      bizRepRow.displayName = 'Custom Admin Legal Rep ID';

      await reqService.ensureDefaultRequirementsSeeded();

      // createMany should NOT have been called since all default keys already exist
      expect(prismaMock.sellerVerificationRequirement.createMany).not.toHaveBeenCalled();
      expect(bizRepRow.isRequired).toBe(true);
      expect(bizRepRow.displayName).toBe('Custom Admin Legal Rep ID');
    });
  });

  // =========================================================================
  // 3. FILE EXTENSION VALIDATION
  // =========================================================================
  describe('File Extension & MIME Validation', () => {
    it('accepts matching extensions for PDF, JPEG, PNG, WEBP', () => {
      expect(() => storageSvc.validateFileExtension('id-front.jpg', 'image/jpeg')).not.toThrow();
      expect(() => storageSvc.validateFileExtension('id-front.JPEG', 'image/jpeg')).not.toThrow();
      expect(() => storageSvc.validateFileExtension('tax-card.pdf', 'application/pdf')).not.toThrow();
      expect(() => storageSvc.validateFileExtension('doc.png', 'image/png')).not.toThrow();
      expect(() => storageSvc.validateFileExtension('doc.webp', 'image/webp')).not.toThrow();
    });

    it('rejects mismatched or executable extensions', () => {
      expect(() => storageSvc.validateFileExtension('malware.exe', 'application/pdf')).toThrow(
        BadRequestException,
      );
      expect(() => storageSvc.validateFileExtension('fake.pdf', 'image/jpeg')).toThrow(
        BadRequestException,
      );
      expect(() => storageSvc.validateFileExtension('noextension', 'image/jpeg')).toThrow(
        BadRequestException,
      );
    });
  });

  // =========================================================================
  // 4. INDIVIDUAL-TO-BUSINESS UPGRADE ELIGIBILITY & APPROVAL
  // =========================================================================
  describe('Individual-to-Business Upgrade Workflow (Unit)', () => {
    let service: SellerApplicationService;
    let prisma: any;
    let securityAudit: { logEvent: jest.Mock };
    let redis: { del: jest.Mock; delByPattern: jest.Mock };

    const staffActor: AuthenticatedStaff = {
      id: 'staff-1',
      staffId: 'staff-1',
      actorType: 'staff',
      email: 'reviewer@dealone.eg',
      fullName: 'Verification Officer',
      roleId: 2,
      role: 'verification_officer',
      permissions: [
        'verification.read',
        'verification.review',
        'verification.approve',
        'verification.reject',
        'verification.require_changes',
        'verification.suspend',
        'verification.documents.read',
      ],
      mfaVerified: true,
    };

    beforeEach(() => {
      securityAudit = { logEvent: jest.fn().mockResolvedValue(undefined) };
      redis = {
        del: jest.fn().mockResolvedValue(undefined),
        delByPattern: jest.fn().mockResolvedValue(undefined),
      };
      prisma = {
        user: { findUnique: jest.fn(), update: jest.fn() },
        account: {
          findFirst: jest.fn(),
          findUnique: jest.fn(),
          findMany: jest.fn().mockResolvedValue([]),
          create: jest.fn(),
          update: jest.fn(),
          updateMany: jest.fn(),
        },
        accountMember: { upsert: jest.fn() },
        sellerApplication: {
          findFirst: jest.fn(),
          findUnique: jest.fn(),
          findUniqueOrThrow: jest.fn(),
          create: jest.fn(),
          update: jest.fn(),
          updateMany: jest.fn(),
        },
        sellerApplicationDocument: { updateMany: jest.fn() },
        sellerApplicationHistory: { create: jest.fn() },
        moderationLog: { create: jest.fn() },
        auditLog: { create: jest.fn() },
        $transaction: jest.fn(async (cb: any) => cb(prisma)),
      };

      service = new SellerApplicationService(
        prisma,
        storageSvc,
        securityAudit as any,
        redis as any,
        cryptoSvc,
      );
    });

    it('rejects business upgrade for non-approved buyers', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'buyer-1',
        fullName: 'Buyer',
        phone: '+201000000001',
        email: 'buyer@test.com',
        isActive: true,
        deletedAt: null,
        moderationStatus: 'active',
        sellerStatus: SellerApplicationStatus.NOT_REQUESTED,
      });

      await expect(
        service.requestBusinessUpgrade('buyer-1', {
          businessName: 'My Office',
          commercialRegisterNumber: 'CR-12345',
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('rejects business upgrade if account is already BUSINESS_VERIFIED', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'biz-1',
        fullName: 'Owner',
        phone: '+201000000002',
        email: 'owner@test.com',
        isActive: true,
        deletedAt: null,
        moderationStatus: 'active',
        sellerStatus: SellerApplicationStatus.APPROVED,
      });
      prisma.account.findFirst.mockResolvedValue({
        id: 'acc-biz-1',
        ownerUserId: 'biz-1',
        accountType: AccountType.COMPANY,
        sellerType: SellerType.BUSINESS,
        verificationStatus: VerificationStatus.APPROVED,
        verificationTier: VerificationTier.BUSINESS_VERIFIED,
        isActive: true,
      });

      await expect(
        service.requestBusinessUpgrade('biz-1', {
          businessName: 'Already Biz',
          commercialRegisterNumber: 'CR-99999',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('upgrades existing Account in-place from IDENTITY_VERIFIED to BUSINESS_VERIFIED without creating a second account', async () => {
      const existingAccount = {
        id: 'acc-ind-1',
        ownerUserId: 'seller-1',
        displayName: 'Independent Broker',
        accountType: AccountType.INDIVIDUAL,
        sellerType: SellerType.INDIVIDUAL,
        verificationStatus: VerificationStatus.APPROVED,
        verificationTier: VerificationTier.IDENTITY_VERIFIED,
        isActive: true,
        bio: 'Independent real estate broker',
      };

      prisma.sellerApplication.findUnique.mockResolvedValue({
        id: 'upgrade-app-1',
        userId: 'seller-1',
        accountId: existingAccount.id,
        applicationType: SellerApplicationType.BUSINESS_UPGRADE,
        status: SellerApplicationStatus.PENDING,
        sellerType: SellerType.BUSINESS,
        businessType: AccountType.OFFICE,
        businessName: 'Brokerage Office LLC',
        businessDescription: 'Licensed real estate office',
        commercialRegisterNumber: 'CR-555111',
        documents: [
          {
            documentType: SellerDocumentType.COMMERCIAL_REGISTER,
            status: SellerDocumentStatus.UPLOADED,
            isCurrent: true,
          },
          {
            documentType: SellerDocumentType.TAX_CARD,
            status: SellerDocumentStatus.UPLOADED,
            isCurrent: true,
          },
        ],
        user: {
          id: 'seller-1',
          fullName: 'Independent Broker',
          email: 'broker@example.com',
          phone: '+201000000003',
          isActive: true,
          deletedAt: null,
        },
      });

      prisma.sellerApplication.updateMany.mockResolvedValue({ count: 1 });
      prisma.account.findUnique.mockResolvedValue(existingAccount);
      prisma.account.update.mockImplementation(async ({ data }: any) => ({
        ...existingAccount,
        ...data,
      }));
      prisma.sellerApplication.update.mockResolvedValue({
        id: 'upgrade-app-1',
        accountId: existingAccount.id,
        status: SellerApplicationStatus.APPROVED,
        derivedVerificationTier: VerificationTier.BUSINESS_VERIFIED,
        documents: [],
      });

      const res = await service.approveApplication('upgrade-app-1', staffActor, {
        notes: 'Verified commercial register and tax card',
      });

      // Must update existing account, NEVER create a new one
      expect(prisma.account.create).not.toHaveBeenCalled();
      expect(prisma.account.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: existingAccount.id },
          data: expect.objectContaining({
            sellerType: SellerType.BUSINESS,
            accountType: AccountType.OFFICE,
            verificationStatus: VerificationStatus.APPROVED,
            verificationTier: VerificationTier.BUSINESS_VERIFIED,
            verificationReviewedByStaffId: staffActor.staffId,
          }),
        }),
      );
      expect(res.account.id).toBe(existingAccount.id);
      expect(res.account.verificationTier).toBe(VerificationTier.BUSINESS_VERIFIED);
      expect(res.account.verificationBadge).toEqual({
        code: VerificationTier.BUSINESS_VERIFIED,
        label: 'شركة / مكتب موثق',
      });

      // Verify audit trail recorded previousTier -> newTier
      expect(prisma.sellerApplicationHistory.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            accountId: existingAccount.id,
            previousTier: VerificationTier.IDENTITY_VERIFIED,
            newTier: VerificationTier.BUSINESS_VERIFIED,
          }),
        }),
      );
      expect(redis.delByPattern).toHaveBeenCalledWith('listings:feed:*');
    });
  });
});
