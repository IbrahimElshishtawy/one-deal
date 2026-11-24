import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AdminAuthController } from './admin-auth.controller';
import { AdminAuthService } from './admin-auth.service';
import { StaffSessionService } from './services/staff-session.service';
import { TotpService } from './services/totp.service';
import { AdminJwtAuthGuard } from './guards/admin-jwt-auth.guard';
import { UserOrAdminJwtAuthGuard } from './guards/user-or-admin-jwt-auth.guard';
import { PermissionsGuard } from './guards/permissions.guard';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { RateLimitGuard } from '../../core/guards/rate-limit.guard';

@Global()
@Module({
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret:
          configService.get<string>('ADMIN_JWT_ACCESS_SECRET') ||
          configService.get<string>('JWT_ACCESS_SECRET'),
        signOptions: {
          expiresIn: configService.get<string>(
            'ADMIN_JWT_ACCESS_EXPIRES_IN',
            '15m',
          ),
          issuer: 'deal-one.eg',
          audience: 'deal-one-admin',
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AdminAuthController],
  providers: [
    SecurityAuditService,
    RateLimitGuard,
    TotpService,
    StaffSessionService,
    AdminAuthService,
    AdminJwtAuthGuard,
    UserOrAdminJwtAuthGuard,
    PermissionsGuard,
  ],
  exports: [
    JwtModule,
    TotpService,
    StaffSessionService,
    AdminAuthService,
    AdminJwtAuthGuard,
    UserOrAdminJwtAuthGuard,
    PermissionsGuard,
  ],
})
export class AdminAuthModule {}
