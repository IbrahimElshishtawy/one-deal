import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../core/database/prisma.service';

/**
 * MediaCleanupProcessor identifies and purges abandoned or orphaned media
 * uploads (e.g. presigned URLs generated but never attached or confirmed).
 */
@Injectable()
export class MediaCleanupProcessor {
  private readonly logger = new Logger(MediaCleanupProcessor.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Sweeps unattached media created over 24 hours ago in PENDING status.
   */
  async processAbandonedMedia(): Promise<{ purgedCount: number }> {
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    this.logger.log(
      `🧹 [Worker: MediaCleanup] Scanning for unattached media older than ${twentyFourHoursAgo.toISOString()}...`,
    );

    try {
      const result = await this.prisma.listingMedia.deleteMany({
        where: {
          processingStatus: 'pending',
          createdAt: { lte: twentyFourHoursAgo },
        },
      });

      this.logger.log(
        `✅ [Worker: MediaCleanup] Removed ${result.count} orphaned media records.`,
      );
      return { purgedCount: result.count };
    } catch (err: any) {
      this.logger.error(
        `❌ [Worker: MediaCleanup] Cleanup failed: ${err?.message || err}`,
      );
      return { purgedCount: 0 };
    }
  }
}
