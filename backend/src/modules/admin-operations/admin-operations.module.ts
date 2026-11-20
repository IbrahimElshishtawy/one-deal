import { Module } from '@nestjs/common';
import { AdminAuthModule } from '../admin-auth/admin-auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { MetricsModule } from '../../core/metrics/metrics.module';
import { AdminDashboardAnalyticsService } from './services/admin-dashboard-analytics.service';
import { AdminMarketplaceService } from './services/admin-marketplace.service';
import { AdminGrowthPlatformService } from './services/admin-growth-platform.service';
import { AdminDashboardController } from './controllers/admin-dashboard.controller';
import { AdminUsersController } from './controllers/admin-users.controller';
import { AdminListingsController } from './controllers/admin-listings.controller';
import { AdminMessagingController } from './controllers/admin-messaging.controller';
import { AdminNotificationsController } from './controllers/admin-notifications.controller';
import {
  AdminCmsController,
  CmsPublicController,
} from './controllers/admin-cms.controller';
import { AdminAnalyticsController } from './controllers/admin-analytics.controller';
import { AdminSystemController } from './controllers/admin-system.controller';
import { AdminFeatureFlagsController } from './controllers/admin-feature-flags.controller';

@Module({
  imports: [AdminAuthModule, NotificationsModule, MetricsModule],
  controllers: [
    AdminDashboardController,
    AdminUsersController,
    AdminListingsController,
    AdminMessagingController,
    AdminNotificationsController,
    AdminCmsController,
    CmsPublicController,
    AdminAnalyticsController,
    AdminSystemController,
    AdminFeatureFlagsController,
  ],
  providers: [
    AdminDashboardAnalyticsService,
    AdminMarketplaceService,
    AdminGrowthPlatformService,
  ],
  exports: [
    AdminDashboardAnalyticsService,
    AdminMarketplaceService,
    AdminGrowthPlatformService,
  ],
})
export class AdminOperationsModule {}
