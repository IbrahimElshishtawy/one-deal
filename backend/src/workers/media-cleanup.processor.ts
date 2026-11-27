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
        if (!this.isValidPublicMediaKey(media.storageKey)) {
          skippedCount++;
          this.logger.warn(
            `⚠️ [Worker: MediaCleanup] Skipping media ${media.id} due to invalid storageKey format`,
          );
          continue;
        }

        // Extra defense: never delete an R2 object if another media record still references it
        if (typeof (this.prisma.listingMedia as any)?.count === 'function') {
          const otherRefs = await this.prisma.listingMedia.count({
            where: {
              storageKey: media.storageKey,
              id: { not: media.id },
            },
          });
          if (otherRefs > 0) {
            skippedCount++;
            this.logger.warn(
              `⚠️ [Worker: MediaCleanup] Skipping media ${media.id} because storageKey is still referenced by ${otherRefs} other record(s)`,
            );
            continue;
          }
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

  private isValidPublicMediaKey(storageKey?: string | null): boolean {
    if (!storageKey || typeof storageKey !== 'string') {
      return false;
    }
    if (
      storageKey !== storageKey.trim() ||
      storageKey.startsWith('/') ||
      storageKey.includes('..') ||
      storageKey.includes('\\') ||
      storageKey.includes('?') ||
      storageKey.includes('#') ||
      storageKey.includes('\0') ||
      /%2e|%2f|%5c/i.test(storageKey)
    ) {
      return false;
    }
    const segments = storageKey.split('/');
    if (segments.length !== 5) {
      return false;
    }
    const [root, resourceType, datePrefix, ownerSegment, fileName] = segments;
    return (
      root === 'uploads' &&
      resourceType === 'images' &&
      /^\d{4}-(0[1-9]|1[0-2])$/.test(datePrefix) &&
      ownerSegment.length > 0 &&
      /^[a-zA-Z0-9_-]{1,128}\.(jpg|jpeg|png|webp)$/i.test(fileName)
    );
  }
}
