import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { AuthModule } from '../auth/auth.module';
import { AccountsModule } from '../accounts/accounts.module';

@Module({
  imports: [AuthModule, AccountsModule],
  controllers: [PaymentsController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
