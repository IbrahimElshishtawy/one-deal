import { BadRequestException } from '@nestjs/common';
import {
  AccountType,
  SellerApplicationStatus,
  SellerDocumentStatus,
  SellerDocumentType,
  SellerType,
} from '../../core/enums/domain.enums';

/**
 * Authoritative Seller Application Lifecycle State Machine.
 *
 * Allowed transitions:
 *   NOT_REQUESTED    -> DRAFT
 *   DRAFT            -> PENDING
 *   PENDING          -> UNDER_REVIEW | APPROVED | REJECTED
 *   UNDER_REVIEW     -> NEEDS_CORRECTION | APPROVED | REJECTED
 *   NEEDS_CORRECTION -> PENDING
 *   REJECTED         -> DRAFT | PENDING
 *   APPROVED         -> SUSPENDED | EXPIRED
 *   SUSPENDED        -> APPROVED
 *   EXPIRED          -> DRAFT | PENDING
 *
 * Arbitrary transitions (e.g., DRAFT -> APPROVED, REJECTED -> APPROVED,
 * NOT_REQUESTED -> APPROVED, APPROVED -> DRAFT, NEEDS_CORRECTION -> APPROVED)
 * are strictly prohibited.
 */
export const SELLER_APPLICATION_TRANSITIONS: Readonly<
  Record<SellerApplicationStatus, ReadonlyArray<SellerApplicationStatus>>
> = {
  [SellerApplicationStatus.NOT_REQUESTED]: [SellerApplicationStatus.DRAFT],
  [SellerApplicationStatus.DRAFT]: [
    SellerApplicationStatus.PENDING,
    SellerApplicationStatus.WITHDRAWN,
  ],
  [SellerApplicationStatus.PENDING]: [
    SellerApplicationStatus.UNDER_REVIEW,
    SellerApplicationStatus.APPROVED,
    SellerApplicationStatus.REJECTED,
    SellerApplicationStatus.WITHDRAWN,
  ],
  [SellerApplicationStatus.UNDER_REVIEW]: [
    SellerApplicationStatus.NEEDS_CORRECTION,
    SellerApplicationStatus.APPROVED,
    SellerApplicationStatus.REJECTED,
  ],
  [SellerApplicationStatus.NEEDS_CORRECTION]: [
    SellerApplicationStatus.PENDING,
    SellerApplicationStatus.WITHDRAWN,
  ],
  [SellerApplicationStatus.REJECTED]: [
    SellerApplicationStatus.DRAFT,
    SellerApplicationStatus.PENDING,
  ],
  [SellerApplicationStatus.WITHDRAWN]: [
    SellerApplicationStatus.DRAFT,
    SellerApplicationStatus.PENDING,
  ],
  [SellerApplicationStatus.APPROVED]: [
    SellerApplicationStatus.SUSPENDED,
    SellerApplicationStatus.EXPIRED,
  ],
  [SellerApplicationStatus.SUSPENDED]: [SellerApplicationStatus.APPROVED],
  [SellerApplicationStatus.EXPIRED]: [
    SellerApplicationStatus.DRAFT,
    SellerApplicationStatus.PENDING,
  ],
};

export function resolveSellerType(
  sellerType?: SellerType | string | null,
  businessType?: AccountType | string | null,
): SellerType {
  if (sellerType) {
    const normalized = String(sellerType).toUpperCase();
    if (
      normalized === SellerType.INDIVIDUAL ||
      normalized === SellerType.BUSINESS ||
      normalized === SellerType.SERVICE_PROVIDER
    ) {
      return normalized as SellerType;
    }
  }
  if (
    businessType &&
    [
      AccountType.COMPANY,
      AccountType.FACTORY,
      AccountType.OFFICE,
      AccountType.STORE,
    ].includes(businessType as AccountType)
  ) {
    return SellerType.BUSINESS;
  }
  return SellerType.INDIVIDUAL;
}

export function resolveBusinessType(
  businessType?: AccountType | string | null,
  sellerType?: SellerType | string | null,
): AccountType {
  if (
    businessType &&
    Object.values(AccountType).includes(businessType as AccountType)
  ) {
    return businessType as AccountType;
  }
  if (sellerType === SellerType.BUSINESS) {
    return AccountType.COMPANY;
  }
  return AccountType.INDIVIDUAL;
}

export function isValidSellerStatusTransition(
  from: SellerApplicationStatus,
  to: SellerApplicationStatus,
): boolean {
  const allowed = SELLER_APPLICATION_TRANSITIONS[from];
  return Array.isArray(allowed) && allowed.includes(to);
}

export function assertValidSellerStatusTransition(
  from: SellerApplicationStatus,
  to: SellerApplicationStatus,
): void {
  if (!isValidSellerStatusTransition(from, to)) {
    throw new BadRequestException({
      code: 'INVALID_SELLER_STATUS_TRANSITION',
      message: `Invalid seller application status transition from '${from}' to '${to}'`,
      from,
      to,
      allowedTransitions: SELLER_APPLICATION_TRANSITIONS[from] ?? [],
    });
  }
}

/**
 * Returns required verification document types based on seller business type.
 */
export function getRequiredDocumentTypes(
  businessType: string,
): SellerDocumentType[] {
  switch (businessType) {
    case AccountType.COMPANY:
    case AccountType.FACTORY:
    case AccountType.OFFICE:
    case AccountType.STORE:
      return [
        SellerDocumentType.COMMERCIAL_REGISTER,
        SellerDocumentType.TAX_CARD,
      ];
    case AccountType.INDIVIDUAL:
    default:
      return [
        SellerDocumentType.NATIONAL_ID_FRONT,
        SellerDocumentType.NATIONAL_ID_BACK,
      ];
  }
}

export interface ApplicationCompletenessInput {
  businessType: string;
  businessName?: string | null;
  nationalIdNumber?: string | null;
  commercialRegisterNumber?: string | null;
  documents: Array<{
    documentType: string;
    status: string;
  }>;
}

export interface ApplicationCompletenessResult {
  isComplete: boolean;
  missingFields: string[];
  missingDocuments: SellerDocumentType[];
}

/**
 * Evaluates whether a seller application has all required profile details and
 * uploaded verification documents before submission or admin approval.
 */
export function evaluateApplicationCompleteness(
  input: ApplicationCompletenessInput,
): ApplicationCompletenessResult {
  const missingFields: string[] = [];

  if (!input.businessName || input.businessName.trim().length < 2) {
    missingFields.push('businessName');
  }

  const isCommercial = input.businessType !== AccountType.INDIVIDUAL;
  if (isCommercial) {
    if (
      !input.commercialRegisterNumber ||
      input.commercialRegisterNumber.trim().length < 3
    ) {
      missingFields.push('commercialRegisterNumber');
    }
  } else {
    if (!input.nationalIdNumber || input.nationalIdNumber.trim().length < 6) {
      missingFields.push('nationalIdNumber');
    }
  }

  const requiredDocs = getRequiredDocumentTypes(input.businessType);
  const uploadedDocTypes = new Set(
    input.documents
      .filter(
        (d) =>
          d.status === SellerDocumentStatus.UPLOADED ||
          d.status === SellerDocumentStatus.VERIFIED,
      )
      .map((d) => d.documentType),
  );

  const missingDocuments = requiredDocs.filter(
    (docType) => !uploadedDocTypes.has(docType),
  );

  return {
    isComplete: missingFields.length === 0 && missingDocuments.length === 0,
    missingFields,
    missingDocuments,
  };
}
