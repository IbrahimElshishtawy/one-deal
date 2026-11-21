import { Module } from '@nestjs/common';
import { BookingsModule } from '../bookings/bookings.module';
import { CartModule } from '../cart/cart.module';
import { FavoritesModule } from '../favorites/favorites.module';
import { RfqModule } from '../rfq/rfq.module';
import { ActivityHubController } from './activity-hub.controller';
import { ActivityHubService } from './activity-hub.service';

@Module({
  imports: [CartModule, BookingsModule, RfqModule, FavoritesModule],
  controllers: [ActivityHubController],
  providers: [ActivityHubService],
  exports: [ActivityHubService],
})
export class ActivityHubModule {}
