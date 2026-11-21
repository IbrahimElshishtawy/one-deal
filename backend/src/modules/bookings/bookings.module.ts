import { Module } from '@nestjs/common';
import { PrismaModule } from '../../core/database/prisma.module';
import { RedisModule } from '../../core/redis/redis.module';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';

@Module({
  imports: [PrismaModule, RedisModule],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
