import { Module } from '@nestjs/common';
import { VideoController } from './video.controller';
import { VideoService } from './video.service';
import { AuthModule } from '../auth/auth.module';
import { AccountsModule } from '../accounts/accounts.module';

@Module({
  imports: [AuthModule, AccountsModule],
  controllers: [VideoController],
  providers: [VideoService],
  exports: [VideoService],
})
export class VideoModule {}
