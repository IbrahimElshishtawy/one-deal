import { BadRequestException } from '@nestjs/common';
import { QuotationStatus, RfqStatus } from './rfq.enums';

const VALID_RFQ_TRANSITIONS: Record<RfqStatus, RfqStatus[]> = {
  [RfqStatus.DRAFT]: [RfqStatus.SUBMITTED, RfqStatus.CANCELLED],
  [RfqStatus.SUBMITTED]: [
    RfqStatus.UNDER_REVIEW,
    RfqStatus.QUOTATIONS_RECEIVED,
    RfqStatus.CANCELLED,
    RfqStatus.EXPIRED,
  ],
  [RfqStatus.UNDER_REVIEW]: [
    RfqStatus.QUOTATIONS_RECEIVED,
    RfqStatus.CANCELLED,
    RfqStatus.EXPIRED,
  ],
  [RfqStatus.QUOTATIONS_RECEIVED]: [
    RfqStatus.ACCEPTED,
    RfqStatus.REJECTED,
    RfqStatus.CANCELLED,
    RfqStatus.EXPIRED,
  ],
  [RfqStatus.ACCEPTED]: [],
  [RfqStatus.REJECTED]: [],
  [RfqStatus.CANCELLED]: [],
  [RfqStatus.EXPIRED]: [],
};

const VALID_QUOTATION_TRANSITIONS: Record<QuotationStatus, QuotationStatus[]> =
  {
    [QuotationStatus.SUBMITTED]: [
      QuotationStatus.SHORTLISTED,
      QuotationStatus.ACCEPTED,
      QuotationStatus.REJECTED,
      QuotationStatus.WITHDRAWN,
      QuotationStatus.EXPIRED,
    ],
    [QuotationStatus.SHORTLISTED]: [
      QuotationStatus.ACCEPTED,
      QuotationStatus.REJECTED,
      QuotationStatus.WITHDRAWN,
      QuotationStatus.EXPIRED,
    ],
    [QuotationStatus.ACCEPTED]: [],
    [QuotationStatus.REJECTED]: [],
    [QuotationStatus.WITHDRAWN]: [],
    [QuotationStatus.EXPIRED]: [],
  };

export function assertValidRfqTransition(from: string, to: RfqStatus): void {
  const current = from as RfqStatus;
  if (!(VALID_RFQ_TRANSITIONS[current]?.includes(to) ?? false)) {
    throw new BadRequestException(
      `Invalid RFQ status transition from '${from}' to '${to}'`,
    );
  }
}

export function assertValidQuotationTransition(
  from: string,
  to: QuotationStatus,
): void {
  const current = from as QuotationStatus;
  if (!(VALID_QUOTATION_TRANSITIONS[current]?.includes(to) ?? false)) {
    throw new BadRequestException(
      `Invalid quotation status transition from '${from}' to '${to}'`,
    );
  }
}
