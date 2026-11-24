import { Module } from '@nestjs/common';
import { PrismaModule } from '../../core/database/prisma.module';
import { RedisModule } from '../../core/redis/redis.module';
import { AccountsModule } from '../accounts/accounts.module';
import { RfqController } from './rfq.controller';
import { RfqService } from './rfq.service';

@Module({
  imports: [PrismaModule, RedisModule, AccountsModule],
  controllers: [RfqController],
  providers: [RfqService],
  exports: [RfqService],
})
export class RfqModule {}
