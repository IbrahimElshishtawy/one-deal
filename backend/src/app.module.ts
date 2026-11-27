import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { validateEnv } from './core/config/env.config';
import { PrismaModule } from './core/database/prisma.module';
import { HealthController } from './core/health/health.controller';
import { RequestIdMiddleware } from './core/middleware/request-id.middleware';

import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { MediaModule } from './modules/media/media.module';
import { ListingsModule } from './modules/listings/listings.module';
import { HomeModule } from './modules/home/home.module';
import { SearchModule } from './modules/search/search.module';
import { ChatModule } from './modules/chat/chat.module';
import { VideoModule } from './modules/video/video.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { ModerationModule } from './modules/moderation/moderation.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { LocationsModule } from './modules/locations/locations.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { RfqModule } from './modules/rfq/rfq.module';
import { CartModule } from './modules/cart/cart.module';
import { ActivityHubModule } from './modules/activity-hub/activity-hub.module';
import { QuotasModule } from './modules/quotas/quotas.module';
import { PlatformSettingsModule } from './modules/platform-settings/platform-settings.module';
import { StaffModule } from './modules/staff/staff.module';
import { EmailModule } from './modules/email/email.module';
import { AdminAuthModule } from './modules/admin-auth/admin-auth.module';
import { AdminOperationsModule } from './modules/admin-operations/admin-operations.module';
import { SellerCenterModule } from './modules/seller-center/seller-center.module';

import { RedisModule } from './core/redis/redis.module';
import { MetricsModule } from './core/metrics/metrics.module';
import { WorkerModule } from './workers/worker.module';

const isPaymentsEnabled = process.env.ENABLE_V2_PAYMENTS === 'true';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    PrismaModule,
    RedisModule,
    MetricsModule,
    WorkerModule,
    AuthModule,
    EmailModule,
    UsersModule,
    AccountsModule,
    CategoriesModule,
    MediaModule,
    ListingsModule,
    HomeModule,
    SearchModule,
    ChatModule,
    VideoModule,
    ModerationModule,
    NotificationsModule,
    LocationsModule,
    FavoritesModule,
    BookingsModule,
    RfqModule,
    CartModule,
    ActivityHubModule,
    QuotasModule,
    PlatformSettingsModule,
    StaffModule,
    AdminAuthModule,
    AdminOperationsModule,
    SellerCenterModule,
    ...(isPaymentsEnabled ? [PaymentsModule] : []),
  ],
  controllers: [HealthController],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
