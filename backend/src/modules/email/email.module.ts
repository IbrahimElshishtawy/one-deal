import { Global, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { EmailService } from './email.service';
import { EmailVerificationService } from './email-verification.service';
import { EmailVerificationController } from './email-verification.controller';
import { RateLimitGuard } from '../../core/guards/rate-limit.guard';

@Global()
@Module({
  imports: [AuthModule],
  controllers: [EmailVerificationController],
  providers: [EmailService, EmailVerificationService, RateLimitGuard],
  exports: [EmailService, EmailVerificationService],
})
export class EmailModule {}
