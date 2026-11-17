import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OtpService } from './services/otp.service';
import { SessionService } from './services/session.service';
import { PhoneNormalizationService } from '../../core/identity/phone-normalization.service';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { SMS_GATEWAY_ADAPTER } from './adapters/sms-gateway.interface';
import { SmsMisrAdapter } from './adapters/sms-misr.adapter';
import { WhatsAppCloudAdapter } from './adapters/whatsapp-cloud.adapter';
import { MockSmsAdapter } from './adapters/mock-sms.adapter';
import { JwtStrategy } from './strategies/jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { AccountTenantGuard } from './guards/account-tenant.guard';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_ACCESS_SECRET'),
        signOptions: {
          expiresIn: configService.get<string>('JWT_ACCESS_EXPIRES_IN', '15m'),
          issuer: 'deal-one.eg',
          audience: 'deal-one-mobile',
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [
    PhoneNormalizationService,
    SecurityAuditService,
    SmsMisrAdapter,
    WhatsAppCloudAdapter,
    MockSmsAdapter,
    {
      provide: SMS_GATEWAY_ADAPTER,
      useFactory: (
        configService: ConfigService,
        smsMisr: SmsMisrAdapter,
        whatsapp: WhatsAppCloudAdapter,
        mockSms: MockSmsAdapter,
      ) => {
        const provider = configService
          .get<string>('SMS_PROVIDER', 'SMS_MISR')
          .toUpperCase();
        const nodeEnv = configService.get<string>('NODE_ENV', 'development');
        const isTestEnv = process.env.NODE_ENV === 'test' || nodeEnv === 'test';

        if (isTestEnv) {
          return mockSms;
        }

        if (provider === 'WHATSAPP' || provider === 'WHATSAPP_CLOUD') {
          if (whatsapp.isConfigured() && !whatsapp.isPlaceholder()) {
            return whatsapp;
          }
          if (nodeEnv === 'production') {
            return whatsapp;
          }
        }

        if (
          provider === 'SMS_MISR' &&
          smsMisr.isConfigured() &&
          !smsMisr.isPlaceholder()
        ) {
          return smsMisr;
        }

        // If WhatsApp credentials are configured even when SMS_PROVIDER wasn't switched from default
        if (whatsapp.isConfigured() && !whatsapp.isPlaceholder()) {
          return whatsapp;
        }

        if (nodeEnv === 'production') {
          // In production, fallback to configured adapter which fails safely if unconfigured
          return smsMisr;
        }

        // In local development with placeholder or mock config, use MockSmsAdapter
        return mockSms;
      },
      inject: [
        ConfigService,
        SmsMisrAdapter,
        WhatsAppCloudAdapter,
        MockSmsAdapter,
      ],
    },
    OtpService,
    SessionService,
    AuthService,
    JwtStrategy,
    JwtAuthGuard,
    RolesGuard,
    AccountTenantGuard,
  ],
  exports: [
    AuthService,
    OtpService,
    SessionService,
    PhoneNormalizationService,
    SecurityAuditService,
    JwtAuthGuard,
    RolesGuard,
    AccountTenantGuard,
    PassportModule,
    JwtModule,
    SMS_GATEWAY_ADAPTER,
  ],
})
export class AuthModule {}
