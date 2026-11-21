import { Module } from '@nestjs/common';
import { PrismaModule } from '../../core/database/prisma.module';
import { RedisModule } from '../../core/redis/redis.module';
import { RfqController } from './rfq.controller';
import { RfqService } from './rfq.service';

@Module({
  imports: [PrismaModule, RedisModule],
  controllers: [RfqController],
  providers: [RfqService],
  exports: [RfqService],
})
export class RfqModule {}
