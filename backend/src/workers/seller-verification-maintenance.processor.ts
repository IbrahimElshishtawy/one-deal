import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../core/database/prisma.service';
import { SecurityAuditService } from '../core/security/security-audit.service';
import {
  SellerApplicationStatus,
  SellerDocumentStatus,
} from '../core/enums/domain.enums';
import { SellerApplicationService } from '../modules/accounts/services/seller-application.service';
import { PrivateDocumentStorageService } from '../modules/accounts/services/private-document-storage.service';
import { NotificationsService } from '../modules/notifications/notifications.service';

const ACTIVE_REVIEW_STATUSES: string[] = [
  SellerApplicationStatus.PENDING,
  SellerApplicationStatus.UNDER_REVIEW,
  SellerApplicationStatus.NEEDS_CORRECTION,
];

/**
 * SellerVerificationMaintenanceProcessor runs idempotent, multi-replica-safe
 * scheduled jobs for the Seller Verification lifecycle:
 *
 * 1. Overdue verification expiration (`APPROVED -> EXPIRED`, revokes badges, invalidates caches)
 * 2. Upcoming renewal reminder notifications (configurable days before `verificationExpiresAt`)
 * 3. Configurable private R2 document retention & orphan upload cleanup
 *    (NEVER deletes documents in active review; preserves minimum audit trail)
 */
@Injectable()
export class SellerVerificationMaintenanceProcessor {
  private readonly logger = new Logger(
    SellerVerificationMaintenanceProcessor.name,
  );

  constructor(
    private readonly prisma: PrismaService,
    private readonly sellerApplicationService: SellerApplicationService,
    private readonly privateStorage: PrivateDocumentStorageService,
    private readonly securityAudit: SecurityAuditService,
    @Optional() private readonly notifications?: NotificationsService,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  /**
   * Job 1: Expire all APPROVED verifications whose `verificationExpiresAt <= now`.
   */
  async processOverdueVerifications(): Promise<{ expiredCount: number }> {
    try {
      const result =
        await this.sellerApplicationService.expireOverdueVerifications();
      if (result.expiredCount > 0) {
        this.logger.log(
          `✅ [Worker: VerificationExpiry] Expired ${result.expiredCount} overdue seller verification(s).`,
        );
      }
      return result;
    } catch (err: any) {
      this.logger.error(
        `❌ [Worker: VerificationExpiry] Cycle failed: ${err?.message || err}`,
      );
      return { expiredCount: 0 };
    }
  }

  /**
   * Job 2: Send renewal reminders to sellers whose verification expires within
   * `VERIFICATION_RENEWAL_REMINDER_DAYS` (default 30 days). Idempotent via
   * atomic `renewalReminderSentAt` guard.
   */
  async processRenewalReminders(): Promise<{ remindedCount: number }> {
    const reminderDays = Number(
      this.configService?.get<number>('VERIFICATION_RENEWAL_REMINDER_DAYS') ??
        30,
    );
    const now = new Date();
    const horizon = new Date(
      now.getTime() +
        (Number.isFinite(reminderDays) && reminderDays > 0
          ? reminderDays
          : 30) *
          86_400_000,
    );

    try {
      const candidates = await this.prisma.sellerApplication.findMany({
        where: {
          status: SellerApplicationStatus.APPROVED,
          isActive: true,
          deletedAt: null,
          renewalReminderSentAt: null,
          verificationExpiresAt: {
            gt: now,
            lte: horizon,
          },
        },
        select: {
          id: true,
          userId: true,
          accountId: true,
          verificationExpiresAt: true,
        },
        take: 100,
      });

      let remindedCount = 0;
      for (const app of candidates) {
        const claimed = await this.prisma.sellerApplication.updateMany({
          where: {
            id: app.id,
            status: SellerApplicationStatus.APPROVED,
            renewalReminderSentAt: null,
          },
          data: { renewalReminderSentAt: now },
        });
        if (claimed.count === 0) continue;

        const daysRemaining = app.verificationExpiresAt
          ? Math.max(
              1,
              Math.ceil(
                (app.verificationExpiresAt.getTime() - now.getTime()) /
                  86_400_000,
              ),
            )
          : reminderDays;

        if (this.notifications) {
          await this.notifications
            .sendPushNotification(
              app.userId,
              'Seller Verification Expiring Soon',
              `Your seller verification will expire in ${daysRemaining} day(s). Please prepare updated documents to renew without interruption.`,
              {
                type: 'SELLER_VERIFICATION_EXPIRING_SOON',
                applicationId: app.id,
                daysRemaining: String(daysRemaining),
              },
            )
            .catch((err: any) => {
              this.logger.warn(
                `Non-fatal renewal reminder push failure for app ${app.id}: ${err?.message}`,
              );
            });
        }

        await this.securityAudit.logEvent({
          action: 'SELLER_VERIFICATION_RENEWAL_REMINDER_SENT',
          actorType: 'system',
          targetEntity: 'SellerApplication',
          targetId: app.id,
          metadata: {
            userId: app.userId,
            accountId: app.accountId ?? null,
            expiresAt: app.verificationExpiresAt?.toISOString() ?? null,
            daysRemaining,
          },
        });

        remindedCount++;
      }

      if (remindedCount > 0) {
        this.logger.log(
          `✅ [Worker: VerificationRenewalReminder] Sent ${remindedCount} renewal reminder(s).`,
        );
      }
      return { remindedCount };
    } catch (err: any) {
      this.logger.error(
        `❌ [Worker: VerificationRenewalReminder] Cycle failed: ${err?.message || err}`,
      );
      return { remindedCount: 0 };
    }
  }

  /**
   * Job 3: Purge expired verification documents and abandoned PENDING_UPLOAD
   * orphans from Cloudflare R2 while preserving minimum audit metadata.
   *
   * Safety invariants:
   * - NEVER deletes documents belonging to applications in PENDING, UNDER_REVIEW,
   *   or NEEDS_CORRECTION status.
   * - Idempotent: treats missing R2 objects (404) as already purged.
   */
  async processDocumentRetentionCleanup(): Promise<{
    purgedRetentionCount: number;
    purgedOrphanCount: number;
  }> {
    const now = new Date();
    const orphanTtlHours = Number(
      this.configService?.get<number>('VERIFICATION_ORPHAN_UPLOAD_TTL_HOURS') ??
        24,
    );
    const orphanCutoff = new Date(
      now.getTime() -
        (Number.isFinite(orphanTtlHours) && orphanTtlHours > 0
          ? orphanTtlHours
          : 24) *
          3_600_000,
    );

    let purgedRetentionCount = 0;
    let purgedOrphanCount = 0;

    try {
      // A. Retention-expired documents (never in active review)
      const expiredDocs = await this.prisma.sellerApplicationDocument.findMany({
        where: {
          purgedAt: null,
          retentionExpiresAt: { lte: now },
          application: {
            status: { notIn: ACTIVE_REVIEW_STATUSES },
          },
        },
        select: {
          id: true,
          applicationId: true,
          userId: true,
          documentType: true,
          version: true,
          storageKey: true,
        },
        take: 100,
      });

      for (const doc of expiredDocs) {
        try {
          await this.privateStorage.deleteObject(doc.storageKey);
          await this.prisma.sellerApplicationDocument.update({
            where: { id: doc.id },
            data: {
              status: SellerDocumentStatus.PURGED,
              purgedAt: now,
              originalFileName: '[REDACTED_RETENTION_PURGED]',
              checksumSha256: null,
            },
          });
          await this.securityAudit.logEvent({
            action: 'SELLER_VERIFICATION_DOCUMENT_PURGED',
            actorType: 'system',
            targetEntity: 'SellerApplicationDocument',
            targetId: doc.id,
            metadata: {
              applicationId: doc.applicationId,
              userId: doc.userId,
              documentType: doc.documentType,
              version: doc.version,
              reason: 'RETENTION_POLICY_EXPIRED',
            },
          });
          purgedRetentionCount++;
        } catch (err: any) {
          this.logger.warn(
            `Failed to purge retention-expired document ${doc.id}: ${err?.message || err}`,
          );
        }
      }

      // B. Orphaned PENDING_UPLOAD documents older than orphanCutoff
      const orphanDocs = await this.prisma.sellerApplicationDocument.findMany({
        where: {
          status: SellerDocumentStatus.PENDING_UPLOAD,
          purgedAt: null,
          createdAt: { lte: orphanCutoff },
        },
        select: {
          id: true,
          applicationId: true,
          userId: true,
          documentType: true,
          version: true,
          storageKey: true,
        },
        take: 100,
      });

      for (const doc of orphanDocs) {
        try {
          await this.privateStorage.deleteObject(doc.storageKey);
          await this.prisma.sellerApplicationDocument.update({
            where: { id: doc.id },
            data: {
              status: SellerDocumentStatus.PURGED,
              purgedAt: now,
              deletedAt: now,
              originalFileName: '[REDACTED_ORPHAN_PURGED]',
              checksumSha256: null,
            },
          });
          purgedOrphanCount++;
        } catch (err: any) {
          this.logger.warn(
            `Failed to purge orphaned verification document ${doc.id}: ${err?.message || err}`,
          );
        }
      }

      if (purgedRetentionCount > 0 || purgedOrphanCount > 0) {
        this.logger.log(
          `✅ [Worker: VerificationDocRetention] Purged ${purgedRetentionCount} retention-expired and ${purgedOrphanCount} orphaned document(s).`,
        );
      }

      return { purgedRetentionCount, purgedOrphanCount };
    } catch (err: any) {
      this.logger.error(
        `❌ [Worker: VerificationDocRetention] Cycle failed: ${err?.message || err}`,
      );
      return { purgedRetentionCount, purgedOrphanCount };
    }
  }
}
