import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../core/database/prisma.service';
import { QuotationStatus, RfqStatus } from '../modules/rfq/rfq.enums';

/**
 * RfqExpiryProcessor transitions past-due open RFQs and quotations into EXPIRED state.
 */
@Injectable()
export class RfqExpiryProcessor {
  private readonly logger = new Logger(RfqExpiryProcessor.name);

  constructor(private readonly prisma: PrismaService) {}

  async processExpiredRfqsAndQuotations(): Promise<{
    expiredRfqs: number;
    expiredQuotations: number;
  }> {
    const now = new Date();
    let expiredRfqs = 0;
    let expiredQuotations = 0;

    try {
      if ((this.prisma as any).rfqRequest?.updateMany) {
        const rfqResult = await this.prisma.rfqRequest.updateMany({
          where: {
            status: {
              in: [
                RfqStatus.SUBMITTED,
                RfqStatus.UNDER_REVIEW,
                RfqStatus.QUOTATIONS_RECEIVED,
              ],
            },
            expiresAt: { lte: now },
          },
          data: { status: RfqStatus.EXPIRED },
        });
        expiredRfqs = rfqResult.count;
      }

      if ((this.prisma as any).quotation?.updateMany) {
        const quotResult = await this.prisma.quotation.updateMany({
          where: {
            status: {
              in: [QuotationStatus.SUBMITTED, QuotationStatus.SHORTLISTED],
            },
            validUntil: { lte: now },
          },
          data: { status: QuotationStatus.EXPIRED },
        });
        expiredQuotations = quotResult.count;
      }

      if (expiredRfqs > 0 || expiredQuotations > 0) {
        this.logger.log(
          `⏳ [Worker: RfqExpiry] Expired ${expiredRfqs} RFQ(s) and ${expiredQuotations} quotation(s)`,
        );
      }

      return { expiredRfqs, expiredQuotations };
    } catch (err: any) {
      this.logger.error(`[RfqExpiry] Cycle error: ${err?.message || err}`);
      return { expiredRfqs: 0, expiredQuotations: 0 };
    }
  }
}
