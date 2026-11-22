import { Injectable, Logger, Optional } from '@nestjs/common';
import { PrismaService } from '../core/database/prisma.service';
import { NotificationProcessor } from './notification.processor';
import { EmailService } from '../modules/email/email.service';
import { normalizeEmailLocale } from '../modules/email/templates/email-layout.template';

/**
 * OutboxPublisherProcessor implements the Transactional Outbox relay (Pattern F).
 * It atomically claims PENDING events from `outbox_events`, dispatches them to
 * downstream handlers (e.g., push notifications, transactional emails), and marks
 * them PUBLISHED or FAILED.
 */
@Injectable()
export class OutboxPublisherProcessor {
  private readonly logger = new Logger(OutboxPublisherProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationProcessor: NotificationProcessor,
    @Optional() private readonly emailService?: EmailService,
  ) {}

  private readonly staleProcessingMs = 5 * 60 * 1000;

  async publishPendingEvents(batchSize = 50): Promise<{
    publishedCount: number;
    failedCount: number;
  }> {
    if (!(this.prisma as any).outboxEvent?.findMany) {
      return { publishedCount: 0, failedCount: 0 };
    }

    const now = new Date();

    try {
      // Recover stale PROCESSING events left behind by crashed workers
      if ((this.prisma as any).outboxEvent?.updateMany) {
        const staleCutoff = new Date(now.getTime() - this.staleProcessingMs);
        try {
          await this.prisma.outboxEvent.updateMany({
            where: {
              status: 'PROCESSING',
              OR: [
                { lockedAt: { lte: staleCutoff } },
                { lockedAt: null, createdAt: { lte: staleCutoff } },
              ],
            },
            data: {
              status: 'PENDING',
              lockedAt: null,
            },
          });
        } catch {
          // Non-fatal recovery failure
        }
      }

      const pendingEvents = await this.prisma.outboxEvent.findMany({
        where: {
          status: 'PENDING',
          OR: [{ nextRetryAt: null }, { nextRetryAt: { lte: now } }],
        },
        orderBy: { createdAt: 'asc' },
        take: batchSize,
      });

      if (pendingEvents.length === 0) {
        return { publishedCount: 0, failedCount: 0 };
      }

      let publishedCount = 0;
      let failedCount = 0;

      for (const evt of pendingEvents) {
        // Atomic claim to prevent double delivery across concurrent workers
        const claim = await this.prisma.outboxEvent.updateMany({
          where: { id: evt.id, status: 'PENDING' },
          data: { status: 'PROCESSING', lockedAt: new Date() },
        });

        if (claim.count === 0) {
          continue;
        }

        try {
          await this.dispatchEvent(
            evt.eventType,
            evt.payload as Record<string, any>,
          );
          await this.prisma.outboxEvent.update({
            where: { id: evt.id },
            data: {
              status: 'PUBLISHED',
              processedAt: new Date(),
              lockedAt: null,
              error: null,
            },
          });
          publishedCount += 1;
        } catch (err: any) {
          failedCount += 1;
          const nextRetryCount = (evt.retryCount ?? 0) + 1;
          const maxRetries = evt.maxRetries ?? 5;
          const shouldRetry = nextRetryCount < maxRetries;
          const backoffSeconds = Math.min(
            30 * Math.pow(2, nextRetryCount - 1),
            3600,
          );
          const errorMessage = String(
            err?.message || 'Unknown outbox dispatch error',
          ).slice(0, 1000);

          try {
            await this.prisma.outboxEvent.update({
              where: { id: evt.id },
              data: shouldRetry
                ? {
                    status: 'PENDING',
                    retryCount: nextRetryCount,
                    nextRetryAt: new Date(Date.now() + backoffSeconds * 1000),
                    lockedAt: null,
                    error: errorMessage,
                  }
                : {
                    status: 'FAILED',
                    retryCount: nextRetryCount,
                    lockedAt: null,
                    error: errorMessage,
                    processedAt: new Date(),
                  },
            });
          } catch {
            // Ignore secondary update failure
          }
          this.logger.error(
            `❌ [Outbox] Failed to publish event ${evt.id} (${evt.eventType}) attempt ${nextRetryCount}/${maxRetries}: ${err?.message}`,
          );
        }
      }

      if (publishedCount > 0 || failedCount > 0) {
        this.logger.log(
          `📤 [Worker: Outbox] Published=${publishedCount}, Failed=${failedCount}`,
        );
      }

      return { publishedCount, failedCount };
    } catch (err: any) {
      this.logger.error(`[Outbox] Cycle error: ${err?.message || err}`);
      return { publishedCount: 0, failedCount: 0 };
    }
  }

  private async dispatchEvent(
    eventType: string,
    payload: Record<string, any>,
  ): Promise<void> {
    if (eventType === 'PUSH_NOTIFICATION' && payload?.targetUserId) {
      const ok = await this.notificationProcessor.processNotificationJob({
        targetUserId: String(payload.targetUserId),
        title: String(payload.title || 'Deal One'),
        body: String(payload.body || ''),
        dataPayload: (payload.dataPayload as Record<string, string>) || {},
      });
      if (!ok) {
        throw new Error('Notification processor failed to deliver push');
      }
      return;
    }

    if (
      eventType === 'PAYMENT_SUCCEEDED' &&
      payload?.paymentId &&
      this.emailService &&
      (this.prisma as any).payment?.findUnique
    ) {
      try {
        const payment = await this.prisma.payment.findUnique({
          where: { id: String(payload.paymentId) },
          include: {
            user: {
              select: { email: true, fullName: true, preferredLanguage: true },
            },
            package: { select: { nameAr: true, nameEn: true } },
            listing: { select: { title: true } },
          },
        });
        if (payment?.user?.email) {
          const locale = normalizeEmailLocale(payment.user.preferredLanguage);
          await this.emailService.sendPaymentReceiptEmail({
            to: payment.user.email,
            displayName: payment.user.fullName,
            amountEgp: String(payment.amountEgp),
            currency: 'EGP',
            packageName:
              locale === 'en'
                ? payment.package?.nameEn
                : payment.package?.nameAr,
            listingTitle: payment.listing?.title,
            transactionReference: String(
              payload.transactionId ||
                payment.gatewayTransactionId ||
                payment.id,
            ),
            paidAt: payment.updatedAt,
            locale,
            idempotencyKey: `payment-receipt-${payment.id}`,
          });
        }
      } catch (err: any) {
        this.logger.warn(
          `Non-blocking payment receipt email failed for payment ${payload.paymentId}: ${err?.message}`,
        );
      }
      return;
    }

    // Domain events (LISTING_CREATED, LISTING_SUBMITTED_FOR_MODERATION, etc.)
    this.logger.log(
      `📨 [Outbox Dispatch] Event=${eventType} Payload=${JSON.stringify(payload)}`,
    );
  }
}
