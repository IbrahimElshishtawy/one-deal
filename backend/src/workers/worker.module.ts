import { Global, Module } from '@nestjs/common';
import { NotificationsModule } from '../modules/notifications/notifications.module';
import { ListingExpiryProcessor } from './listing-expiry.processor';
import { MediaCleanupProcessor } from './media-cleanup.processor';
import { PaymentReconciliationProcessor } from './payment-reconciliation.processor';
import { OutboxPublisherProcessor } from './outbox-publisher.processor';
import { RfqExpiryProcessor } from './rfq-expiry.processor';
import { NotificationProcessor } from './notification.processor';
import { WorkerService } from './worker.service';

@Global()
@Module({
  imports: [NotificationsModule],
  providers: [
    ListingExpiryProcessor,
    MediaCleanupProcessor,
    PaymentReconciliationProcessor,
    OutboxPublisherProcessor,
    RfqExpiryProcessor,
    NotificationProcessor,
    WorkerService,
  ],
  exports: [WorkerService, OutboxPublisherProcessor, RfqExpiryProcessor],
})
export class WorkerModule {}
