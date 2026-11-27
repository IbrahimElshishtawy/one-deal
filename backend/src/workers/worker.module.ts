import { Global, Module } from '@nestjs/common';
import { AuthModule } from '../modules/auth/auth.module';
import { NotificationsModule } from '../modules/notifications/notifications.module';
import { AccountsModule } from '../modules/accounts/accounts.module';
import { MediaModule } from '../modules/media/media.module';
import { ListingExpiryProcessor } from './listing-expiry.processor';
import { MediaCleanupProcessor } from './media-cleanup.processor';
import { PaymentReconciliationProcessor } from './payment-reconciliation.processor';
import { OutboxPublisherProcessor } from './outbox-publisher.processor';
import { RfqExpiryProcessor } from './rfq-expiry.processor';
import { SellerVerificationMaintenanceProcessor } from './seller-verification-maintenance.processor';
import { NotificationProcessor } from './notification.processor';
import { WorkerService } from './worker.service';

@Global()
@Module({
  imports: [AuthModule, NotificationsModule, AccountsModule, MediaModule],
  providers: [
    ListingExpiryProcessor,
    MediaCleanupProcessor,
    PaymentReconciliationProcessor,
    OutboxPublisherProcessor,
    RfqExpiryProcessor,
    SellerVerificationMaintenanceProcessor,
    NotificationProcessor,
    WorkerService,
  ],
  exports: [
    WorkerService,
    OutboxPublisherProcessor,
    RfqExpiryProcessor,
    SellerVerificationMaintenanceProcessor,
  ],
})
export class WorkerModule {}
