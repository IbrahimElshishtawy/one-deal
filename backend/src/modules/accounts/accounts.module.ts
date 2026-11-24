import { Module } from '@nestjs/common';
import { AccountsController } from './accounts.controller';
import { AccountsService } from './accounts.service';
import { SellerApplicationController } from './controllers/seller-application.controller';
import { AdminSellerApplicationsController } from './controllers/admin-seller-applications.controller';
import { SellerApplicationService } from './services/seller-application.service';
import { PrivateDocumentStorageService } from './services/private-document-storage.service';
import { SellerAuthorizationGuard } from './guards/seller-authorization.guard';
import { AuthModule } from '../auth/auth.module';
import { AdminAuthModule } from '../admin-auth/admin-auth.module';

@Module({
  imports: [AuthModule, AdminAuthModule],
  controllers: [
    AccountsController,
    SellerApplicationController,
    AdminSellerApplicationsController,
  ],
  providers: [
    AccountsService,
    SellerApplicationService,
    PrivateDocumentStorageService,
    SellerAuthorizationGuard,
  ],
  exports: [
    AccountsService,
    SellerApplicationService,
    PrivateDocumentStorageService,
    SellerAuthorizationGuard,
  ],
})
export class AccountsModule {}
