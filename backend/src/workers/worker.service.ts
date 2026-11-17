import {
  Injectable,
  Logger,
  Optional,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Queue, Worker } from 'bullmq';
import { RedisService } from '../core/redis/redis.service';
import { ListingExpiryProcessor } from './listing-expiry.processor';
import { MediaCleanupProcessor } from './media-cleanup.processor';
import { PaymentReconciliationProcessor } from './payment-reconciliation.processor';
import { OutboxPublisherProcessor } from './outbox-publisher.processor';
import {
  NotificationProcessor,
  PushNotificationJobData,
} from './notification.processor';

const WORKER_QUEUE_NAME = 'marketspace-maintenance';

/**
 * WorkerService manages background scheduled maintenance tasks and async queues.
 *
 * Multi-replica safety:
 * - Respects ENABLE_WORKERS=false to run dedicated worker replicas separately from API pods.
 * - Uses BullMQ repeatable jobs when Redis Queue is connected (single execution across replicas).
 * - Falls back to Redis distributed locks (SET NX EX) around intervals when BullMQ is offline.
 */
@Injectable()
export class WorkerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(WorkerService.name);
  private intervals: NodeJS.Timeout[] = [];
  private maintenanceQueue: Queue | null = null;
  private maintenanceWorker: Worker | null = null;
  private active = false;

  constructor(
    private readonly listingExpiry: ListingExpiryProcessor,
    private readonly mediaCleanup: MediaCleanupProcessor,
    private readonly paymentReconciliation: PaymentReconciliationProcessor,
    private readonly notificationProcessor: NotificationProcessor,
    @Optional() private readonly outboxPublisher?: OutboxPublisherProcessor,
    @Optional() private readonly redisService?: RedisService,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  async onModuleInit() {
    const workersEnabled =
      this.configService?.get<boolean>('ENABLE_WORKERS', true) ?? true;
    if (!workersEnabled) {
      this.logger.log(
        '⏸️ Background workers disabled on this instance (ENABLE_WORKERS=false).',
      );
      return;
    }

    this.active = true;

    if (this.redisService?.isQueueClientConnected()) {
      await this.initBullMqWorkers();
      return;
    }

    this.initLockedIntervals();
  }

  private async initBullMqWorkers(): Promise<void> {
    if (!this.redisService) return;
    const connection = this.redisService.getQueueConnectionOptions();
    this.logger.log(
      '⚙️ Initializing BullMQ repeatable workers (multi-replica safe)...',
    );

    this.maintenanceQueue = new Queue(WORKER_QUEUE_NAME, { connection });
    this.maintenanceWorker = new Worker(
      WORKER_QUEUE_NAME,
      async (job) => {
        switch (job.name) {
          case 'listing-expiry':
            return this.listingExpiry.processExpiredListings();
          case 'payment-reconciliation':
            return this.paymentReconciliation.processStaleTransactions();
          case 'media-cleanup':
            return this.mediaCleanup.processAbandonedMedia();
          case 'outbox-publisher':
            return this.outboxPublisher?.publishPendingEvents();
          default:
            return null;
        }
      },
      { connection, concurrency: 2 },
    );

    await Promise.allSettled([
      this.maintenanceQueue.add(
        'listing-expiry',
        {},
        { repeat: { every: 30 * 60 * 1000 }, jobId: 'repeat:listing-expiry' },
      ),
      this.maintenanceQueue.add(
        'payment-reconciliation',
        {},
        {
          repeat: { every: 15 * 60 * 1000 },
          jobId: 'repeat:payment-reconciliation',
        },
      ),
      this.maintenanceQueue.add(
        'media-cleanup',
        {},
        {
          repeat: { every: 6 * 60 * 60 * 1000 },
          jobId: 'repeat:media-cleanup',
        },
      ),
      this.maintenanceQueue.add(
        'outbox-publisher',
        {},
        { repeat: { every: 10 * 1000 }, jobId: 'repeat:outbox-publisher' },
      ),
    ]);
  }

  private initLockedIntervals(): void {
    this.logger.log(
      '⚙️ Initializing interval workers with distributed Redis lock fallback...',
    );

    const runWithLock = async (
      lockName: string,
      ttlSeconds: number,
      fn: () => Promise<unknown>,
    ) => {
      if (this.redisService) {
        const token = await this.redisService.acquireLock(lockName, ttlSeconds);
        if (!token) return;
        try {
          await fn();
        } finally {
          await this.redisService.releaseLock(lockName, token);
        }
      } else {
        await fn();
      }
    };

    // Expiry check every 30 minutes
    this.intervals.push(
      setInterval(
        () => {
          runWithLock('worker:listing-expiry', 300, () =>
            this.listingExpiry.processExpiredListings(),
          ).catch((err) => {
            this.logger.error(
              `Error in listing expiry background job: ${err.message}`,
            );
          });
        },
        30 * 60 * 1000,
      ),
    );

    // Payment reconciliation every 15 minutes
    this.intervals.push(
      setInterval(
        () => {
          runWithLock('worker:payment-reconciliation', 300, () =>
            this.paymentReconciliation.processStaleTransactions(),
          ).catch((err) => {
            this.logger.error(
              `Error in payment reconciliation job: ${err.message}`,
            );
          });
        },
        15 * 60 * 1000,
      ),
    );

    // Media cleanup every 6 hours
    this.intervals.push(
      setInterval(
        () => {
          runWithLock('worker:media-cleanup', 600, () =>
            this.mediaCleanup.processAbandonedMedia(),
          ).catch((err) => {
            this.logger.error(`Error in media cleanup job: ${err.message}`);
          });
        },
        6 * 60 * 60 * 1000,
      ),
    );

    // Outbox publisher every 10 seconds
    this.intervals.push(
      setInterval(() => {
        runWithLock('worker:outbox-publisher', 30, () =>
          this.outboxPublisher
            ? this.outboxPublisher.publishPendingEvents()
            : Promise.resolve(),
        ).catch((err) => {
          this.logger.error(`Error in outbox publisher job: ${err.message}`);
        });
      }, 10 * 1000),
    );
  }

  async onModuleDestroy() {
    for (const interval of this.intervals) {
      clearInterval(interval);
    }
    this.intervals = [];
    this.active = false;
    await this.maintenanceWorker?.close().catch(() => undefined);
    await this.maintenanceQueue?.close().catch(() => undefined);
  }

  /**
   * Health probe verifying background workers active status.
   */
  isHealthy(): boolean {
    return (
      this.active &&
      (this.intervals.length > 0 || this.maintenanceWorker !== null)
    );
  }

  /**
   * Enqueues an async notification dispatch.
   */
  async enqueueNotification(job: PushNotificationJobData): Promise<boolean> {
    return this.notificationProcessor.processNotificationJob(job);
  }
}
