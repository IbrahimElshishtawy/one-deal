import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../core/database/prisma.service';

/**
 * PaymentReconciliationProcessor periodically reviews unconfirmed Paymob transactions.
 * It detects orders left in pending status past their expiration window (e.g. 1 hour)
 * and marks them as failed or initiates status checks.
 */
@Injectable()
export class PaymentReconciliationProcessor {
  private readonly logger = new Logger(PaymentReconciliationProcessor.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Reconciles stale pending transactions older than 60 minutes.
   */
  async processStaleTransactions(): Promise<{ reconciledCount: number }> {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    this.logger.log(
      `💳 [Worker: PaymentReconciliation] Checking stale payments created before ${oneHourAgo.toISOString()}...`,
    );

    let count = 0;
    try {
      if ((this.prisma as any).payment?.updateMany) {
        const result = await (this.prisma as any).payment.updateMany({
          where: {
            status: 'pending',
            createdAt: { lte: oneHourAgo },
          },
          data: {
            status: 'failed',
          },
        });
        count = result.count;
      }

      this.logger.log(
        `✅ [Worker: PaymentReconciliation] Reconciled ${count} stale pending transactions to FAILED.`,
      );
      return { reconciledCount: count };
    } catch (err: any) {
      this.logger.error(
        `❌ [Worker: PaymentReconciliation] Reconciliation failed: ${err?.message || err}`,
      );
      return { reconciledCount: 0 };
    }
  }
}
