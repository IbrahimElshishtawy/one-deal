import { Module } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { SellerCenterController } from './seller-center.controller';
import { SellerCenterService } from './seller-center.service';

@Module({
  imports: [AccountsModule],
  controllers: [SellerCenterController],
  providers: [SellerCenterService],
  exports: [SellerCenterService],
})
export class SellerCenterModule {}
