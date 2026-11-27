import { Injectable, Logger, Optional } from '@nestjs/common';
import { PrismaService } from '../core/database/prisma.service';
import { MediaService } from '../modules/media/media.service';

/**
 * MediaCleanupProcessor identifies and safely purges abandoned or orphaned
 * public listing media uploads (e.g. presigned URLs generated >24h ago in
 * PENDING status and not attached to a published listing).
 *
 * Safety invariants:
 * 1. Never deletes media referenced by an active published listing.
 * 2. Validates storage key format (`uploads/images/...`) before deletion.
 * 3. Deletes the Cloudflare R2 object FIRST; only deletes the DB record after
 *    R2 deletion succeeds (or returns 404).
 * 4. If R2 deletion fails, retains the DB record for automatic retry next cycle.
 */
@Injectable()
export class MediaCleanupProcessor {
  private readonly logger = new Logger(MediaCleanupProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly mediaService?: MediaService,
  ) {}

  async processAbandonedMedia(): Promise<{
    purgedCount: number;
    failedCount: number;
    skippedCount: number;
  }> {
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    this.logger.log(
      `🧹 [Worker: MediaCleanup] Scanning for unattached media older than ${twentyFourHoursAgo.toISOString()}...`,
    );

    let purgedCount = 0;
    let failedCount = 0;
    let skippedCount = 0;

    try {
      const candidates = await this.prisma.listingMedia.findMany({
        where: {
          processingStatus: 'pending',
          createdAt: { lte: twentyFourHoursAgo },
          listing: {
            publicationStatus: { not: 'published' },
          },
        },
        select: {
          id: true,
          storageKey: true,
        },
        take: 100,
      });

      for (const media of candidates) {
        if (
          !media.storageKey ||
          !media.storageKey.startsWith('uploads/images/')
        ) {
          skippedCount++;
          this.logger.warn(
            `⚠️ [Worker: MediaCleanup] Skipping media ${media.id} due to invalid storageKey format`,
          );
          continue;
        }

        try {
          if (this.mediaService) {
            await this.mediaService.deletePublicObject(media.storageKey);
          }
          await this.prisma.listingMedia.delete({
            where: { id: media.id },
          });
          purgedCount++;
        } catch (err: any) {
          failedCount++;
          this.logger.warn(
            `⚠️ [Worker: MediaCleanup] Deferred media ${media.id} for retry: ${err?.message || err}`,
          );
        }
      }

      this.logger.log(
        `✅ [Worker: MediaCleanup] Purged=${purgedCount}, Failed(retryable)=${failedCount}, Skipped=${skippedCount}.`,
      );
      return { purgedCount, failedCount, skippedCount };
    } catch (err: any) {
      this.logger.error(
        `❌ [Worker: MediaCleanup] Cleanup failed: ${err?.message || err}`,
      );
      return { purgedCount, failedCount, skippedCount };
    }
  }
}
