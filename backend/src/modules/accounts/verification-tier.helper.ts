import {
  AccountType,
  SellerApplicationStatus,
  SellerDocumentStatus,
  SellerDocumentType,
  SellerType,
  VerificationStatus,
  VerificationTier,
} from '../../core/enums/domain.enums';

export interface VerificationBadgeDto {
  code: VerificationTier.IDENTITY_VERIFIED | VerificationTier.BUSINESS_VERIFIED;
  label: string;
}

export const VERIFICATION_BADGE_LABELS: Readonly<
  Record<
    VerificationTier.IDENTITY_VERIFIED | VerificationTier.BUSINESS_VERIFIED,
    string
  >
> = {
  [VerificationTier.IDENTITY_VERIFIED]: 'هوية موثقة',
  [VerificationTier.BUSINESS_VERIFIED]: 'شركة / مكتب موثق',
};

export interface VerificationTierDerivationInput {
  sellerType?: SellerType | string | null;
  status?: SellerApplicationStatus | VerificationStatus | string | null;
  documents?: Array<{
    documentType: string;
    status: string;
    isCurrent?: boolean;
    deletedAt?: Date | null;
  }>;
}

/**
 * Single source of truth for deriving VerificationTier from approved seller classification
 * and verified/uploaded supporting documents.
 *
 * Security invariants:
 * - Never trusts client-submitted verificationTier values.
 * - Non-approved statuses (PENDING, REJECTED, NEEDS_CORRECTION, SUSPENDED, EXPIRED, DRAFT, NOT_SUBMITTED)
 *   ALWAYS resolve to VerificationTier.NONE.
 * - BUSINESS_VERIFIED requires sellerType === BUSINESS AND valid commercial_register + tax_card documents.
 * - IDENTITY_VERIFIED requires sellerType in (INDIVIDUAL, SERVICE_PROVIDER) AND valid national_id_front + national_id_back documents.
 */
export function deriveVerificationTier(
  input: VerificationTierDerivationInput,
): VerificationTier {
  const normalizedStatus = String(input.status ?? '').toUpperCase();
  if (normalizedStatus !== 'APPROVED') {
    return VerificationTier.NONE;
  }

  const normalizedSellerType = String(
    input.sellerType ?? SellerType.INDIVIDUAL,
  ).toUpperCase();

  const validDocTypes = new Set(
    (input.documents ?? [])
      .filter(
        (d) =>
          d.isCurrent !== false &&
          !d.deletedAt &&
          (d.status === SellerDocumentStatus.VERIFIED ||
            d.status === SellerDocumentStatus.UPLOADED),
      )
      .map((d) => String(d.documentType).toLowerCase()),
  );

  if (normalizedSellerType === SellerType.BUSINESS) {
    const hasBusinessProof =
      validDocTypes.has(SellerDocumentType.COMMERCIAL_REGISTER) &&
      validDocTypes.has(SellerDocumentType.TAX_CARD);
    return hasBusinessProof
      ? VerificationTier.BUSINESS_VERIFIED
      : VerificationTier.NONE;
  }

  if (
    normalizedSellerType === SellerType.INDIVIDUAL ||
    normalizedSellerType === SellerType.SERVICE_PROVIDER
  ) {
    const hasIdentityProof =
      validDocTypes.has(SellerDocumentType.NATIONAL_ID_FRONT) &&
      validDocTypes.has(SellerDocumentType.NATIONAL_ID_BACK);
    return hasIdentityProof
      ? VerificationTier.IDENTITY_VERIFIED
      : VerificationTier.NONE;
  }

  return VerificationTier.NONE;
}

/**
 * Resolves the public Arabic verification badge for an account.
 *
 * Returns null whenever the account is not actively APPROVED or has tier NONE.
 * Pending, rejected, needs_changes, suspended, or expired accounts NEVER receive a badge.
 */
export function buildVerificationBadge(
  verificationStatus?: string | null,
  verificationTier?: string | null,
  isActive = true,
): VerificationBadgeDto | null {
  if (!isActive) {
    return null;
  }

  const normalizedStatus = String(verificationStatus ?? '').toUpperCase();
  if (normalizedStatus !== 'APPROVED') {
    return null;
  }

  const normalizedTier = String(
    verificationTier ?? VerificationTier.NONE,
  ).toUpperCase();

  if (normalizedTier === VerificationTier.BUSINESS_VERIFIED) {
    return {
      code: VerificationTier.BUSINESS_VERIFIED,
      label: VERIFICATION_BADGE_LABELS[VerificationTier.BUSINESS_VERIFIED],
    };
  }

  if (normalizedTier === VerificationTier.IDENTITY_VERIFIED) {
    return {
      code: VerificationTier.IDENTITY_VERIFIED,
      label: VERIFICATION_BADGE_LABELS[VerificationTier.IDENTITY_VERIFIED],
    };
  }

  return null;
}

/**
 * Normalizes effective public verification tier (never returns a verified tier if status != APPROVED or inactive).
 */
export function resolveEffectiveVerificationTier(
  verificationStatus?: string | null,
  verificationTier?: string | null,
  isActive = true,
): VerificationTier {
  const badge = buildVerificationBadge(
    verificationStatus,
    verificationTier,
    isActive,
  );
  return badge ? badge.code : VerificationTier.NONE;
}

/**
 * Maps an Account's sellerType safely (falls back to inferring from accountType for legacy records).
 */
export function resolveAccountSellerType(
  sellerType?: string | null,
  accountType?: string | null,
): SellerType {
  const normalized = String(sellerType ?? '').toUpperCase();
  if (
    normalized === SellerType.INDIVIDUAL ||
    normalized === SellerType.BUSINESS ||
    normalized === SellerType.SERVICE_PROVIDER
  ) {
    return normalized as SellerType;
  }
  if (
    accountType &&
    [
      AccountType.COMPANY,
      AccountType.FACTORY,
      AccountType.OFFICE,
      AccountType.STORE,
    ].includes(accountType as AccountType)
  ) {
    return SellerType.BUSINESS;
  }
  return SellerType.INDIVIDUAL;
}

/**
 * Maps SellerApplicationStatus to Account.verificationStatus (preserving lowercase convention).
 */
export function mapApplicationStatusToAccountVerificationStatus(
  status: SellerApplicationStatus,
): VerificationStatus {
  switch (status) {
    case SellerApplicationStatus.APPROVED:
      return VerificationStatus.APPROVED;
    case SellerApplicationStatus.REJECTED:
      return VerificationStatus.REJECTED;
    case SellerApplicationStatus.NEEDS_CORRECTION:
      return VerificationStatus.NEEDS_CHANGES;
    case SellerApplicationStatus.SUSPENDED:
    case SellerApplicationStatus.EXPIRED:
      return VerificationStatus.SUSPENDED;
    case SellerApplicationStatus.NOT_REQUESTED:
    case SellerApplicationStatus.DRAFT:
      return VerificationStatus.NOT_SUBMITTED;
    case SellerApplicationStatus.PENDING:
    case SellerApplicationStatus.UNDER_REVIEW:
    default:
      return VerificationStatus.PENDING;
  }
}

/**
 * Builds the safe, non-sensitive public seller verification summary embedded in
 * public seller profiles, listing details, and listing search responses.
 *
 * Never exposes verification documents, rejection reasons, internal notes, or reviewer info.
 */
export function formatPublicSellerVerification(account: {
  id: string;
  displayName: string;
  slug?: string | null;
  accountType: string;
  sellerType?: string | null;
  verificationStatus: string;
  verificationTier?: string | null;
  logoUrl?: string | null;
  isActive?: boolean;
}) {
  const isActive = account.isActive !== false;
  const sellerType = resolveAccountSellerType(
    account.sellerType,
    account.accountType,
  );
  const effectiveTier = resolveEffectiveVerificationTier(
    account.verificationStatus,
    account.verificationTier,
    isActive,
  );
  const verificationBadge = buildVerificationBadge(
    account.verificationStatus,
    effectiveTier,
    isActive,
  );

  return {
    id: account.id,
    name: account.displayName,
    slug: account.slug ?? null,
    accountType: account.accountType,
    sellerType,
    verificationStatus: String(account.verificationStatus).toUpperCase(),
    verificationTier: effectiveTier,
    verificationBadge,
    logoUrl: account.logoUrl ?? null,
  };
}
