import {
  Injectable,
  Inject,
  BadRequestException,
  HttpException,
  HttpStatus,
  Logger,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { PhoneNormalizationService } from '../../../core/identity/phone-normalization.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';
import {
  ISmsGatewayAdapter,
  SMS_GATEWAY_ADAPTER,
} from '../adapters/sms-gateway.interface';

export interface OtpDispatchResult {
  success: boolean;
  message: string;
  cooldownSeconds: number;
}

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  private readonly otpPepper: string;
  private readonly otpExpirySeconds = 180; // 3 minutes window
  private readonly resendCooldownSeconds = 60; // 60 seconds cooldown
  private readonly maxAttempts = 5;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly configService: ConfigService,
    private readonly phoneNormalization: PhoneNormalizationService,
    private readonly securityAudit: SecurityAuditService,
    @Inject(SMS_GATEWAY_ADAPTER)
    private readonly smsAdapter: ISmsGatewayAdapter,
  ) {
    this.otpPepper = this.configService.get<string>(
      'JWT_ACCESS_SECRET',
      'deal_one_fallback_pepper',
    );
  }

  /**
   * Dispatches a fresh 6-digit OTP code to the normalized Egyptian mobile number.
   * Enforces IP rate limiting, phone rate limiting, and Redis resend cooldown.
   */
  async requestOtp(
    rawPhone: string,
    purpose: string = 'AUTH',
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ): Promise<OtpDispatchResult> {
    const normalizedPhone = this.phoneNormalization.normalize(rawPhone);

    // 1. IP Rate Limiting (Anti-SMS Bombing): max 10 requests per 15 minutes
    if (ipAddress) {
      const ipKey = `otp:ratelimit:ip:${ipAddress}`;
      const { allowed } = await this.redis.checkRateLimit(ipKey, 10, 900);
      if (!allowed) {
        await this.securityAudit.logEvent({
          action: 'OTP_RATE_LIMIT_EXCEEDED',
          targetEntity: 'IP',
          targetId: ipAddress,
          ipAddress,
          userAgent,
          correlationId,
          metadata: { dimension: 'ip', ipAddress },
        });
        throw new HttpException(
          'Too many OTP requests from your network. Please wait 15 minutes before retrying.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }

    // 2. Phone Rate Limiting: max 3 requests per 15 minutes
    const phoneRateLimitKey = `otp:ratelimit:phone:${normalizedPhone}`;
    const { allowed: phoneAllowed } = await this.redis.checkRateLimit(
      phoneRateLimitKey,
      3,
      900,
    );
    if (!phoneAllowed) {
      await this.securityAudit.logEvent({
        action: 'OTP_RATE_LIMIT_EXCEEDED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { dimension: 'phone', phone: normalizedPhone },
      });
      throw new HttpException(
        'Too many OTP requests for this phone number. Please wait 15 minutes before requesting a new code.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 3. Strict Resend Cooldown Check (60 seconds)
    const cooldownKey = `otp:cooldown:${normalizedPhone}`;
    const activeCooldown = await this.redis.get<string>(cooldownKey);
    if (activeCooldown) {
      throw new HttpException(
        'Please wait for the cooldown timer to elapse before requesting another OTP.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 4. Invalidate all previous unconsumed OTPs for this phone & purpose
    await this.prisma.otp.updateMany({
      where: {
        phone: normalizedPhone,
        purpose,
        isConsumed: false,
      },
      data: { isConsumed: true },
    });

    // 5. Generate cryptographically secure random 6-digit OTP
    const code = crypto.randomInt(100000, 999999).toString();
    const codeHash = this.hashOtp(code);
    const expiresAt = new Date(Date.now() + this.otpExpirySeconds * 1000);

    // 6. Persist hashed OTP challenge to PostgreSQL ledger
    await this.prisma.otp.create({
      data: {
        phone: normalizedPhone,
        purpose,
        codeHash,
        attempts: 0,
        isConsumed: false,
        expiresAt,
      },
    });

    // 7. Enforce resend cooldown in Redis Cache
    await this.redis.set(cooldownKey, '1', this.resendCooldownSeconds);

    // 8. Deliver OTP via configured SMS Gateway Adapter
    const delivery = await this.smsAdapter.sendOtp(normalizedPhone, code);
    if (!delivery.success) {
      this.logger.error(
        `Failed to deliver SMS OTP to ${normalizedPhone}: ${delivery.error}`,
      );
      await this.securityAudit.logEvent({
        action: 'SMS_DELIVERY_FAILED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: {
          provider: delivery.provider,
          error: delivery.error,
        },
      });

      if (this.configService.get<string>('NODE_ENV') === 'production') {
        throw new InternalServerErrorException(
          'Failed to deliver SMS verification code. Please try again shortly.',
        );
      }
    }

    // 9. Structured Audit Trail (Zero OTP leakage)
    await this.securityAudit.logEvent({
      action: 'OTP_REQUESTED',
      targetEntity: 'Phone',
      targetId: normalizedPhone,
      ipAddress,
      userAgent,
      correlationId,
      metadata: {
        purpose,
        provider: delivery.provider,
        expiresInSeconds: this.otpExpirySeconds,
      },
    });

    const channelLabel =
      delivery.provider === 'WHATSAPP_CLOUD' ? 'WhatsApp' : 'SMS';

    return {
      success: true,
      message: `OTP verification code dispatched successfully via ${channelLabel}.`,
      cooldownSeconds: this.resendCooldownSeconds,
    };
  }

  /**
   * Resend OTP challenge under identical rate-limiting and cooldown constraints.
   */
  async resendOtp(
    rawPhone: string,
    purpose: string = 'AUTH',
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ): Promise<OtpDispatchResult> {
    return this.requestOtp(
      rawPhone,
      purpose,
      ipAddress,
      userAgent,
      correlationId,
    );
  }

  /**
   * Verifies submitted OTP code with brute-force protection, timing-attack resistance,
   * and concurrency-safe single-use consumption.
   */
  async verifyOtp(
    rawPhone: string,
    code: string,
    purpose: string = 'AUTH',
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ): Promise<{ normalizedPhone: string }> {
    const normalizedPhone = this.phoneNormalization.normalize(rawPhone);

    const activeOtp = await this.prisma.otp.findFirst({
      where: {
        phone: normalizedPhone,
        purpose,
        isConsumed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!activeOtp) {
      await this.securityAudit.logEvent({
        action: 'OTP_VERIFICATION_FAILED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { reason: 'EXPIRED_OR_NONEXISTENT_CHALLENGE', purpose },
      });
      throw new BadRequestException(
        'Invalid or expired OTP code. Please request a new code.',
      );
    }

    // Brute-force lockout enforcement (max 5 attempts per challenge)
    if (activeOtp.attempts >= this.maxAttempts) {
      await this.prisma.otp.update({
        where: { id: activeOtp.id },
        data: { isConsumed: true },
      });

      await this.securityAudit.logEvent({
        action: 'OTP_VERIFICATION_FAILED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: {
          reason: 'MAX_ATTEMPTS_EXCEEDED',
          attempts: activeOtp.attempts,
        },
      });

      throw new BadRequestException(
        'Maximum verification attempts exceeded. Please request a new OTP code.',
      );
    }

    // Verify hash with timing-safe comparison
    const candidateHash = this.hashOtp(code);
    const candidateBuffer = Buffer.from(candidateHash, 'utf8');
    const expectedBuffer = Buffer.from(activeOtp.codeHash, 'utf8');

    const isMatch =
      candidateBuffer.length === expectedBuffer.length &&
      crypto.timingSafeEqual(candidateBuffer, expectedBuffer);

    if (!isMatch) {
      await this.prisma.otp.update({
        where: { id: activeOtp.id },
        data: { attempts: { increment: 1 } },
      });

      await this.securityAudit.logEvent({
        action: 'OTP_VERIFICATION_FAILED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: {
          reason: 'INCORRECT_CODE',
          currentAttempt: activeOtp.attempts + 1,
        },
      });

      throw new BadRequestException('Incorrect OTP code.');
    }

    // Atomic consumption to prevent concurrent verification race conditions
    const updateResult = await this.prisma.otp.updateMany({
      where: {
        id: activeOtp.id,
        isConsumed: false,
      },
      data: { isConsumed: true },
    });

    if (updateResult.count === 0) {
      await this.securityAudit.logEvent({
        action: 'OTP_VERIFICATION_FAILED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { reason: 'CONCURRENT_CONSUMPTION_COLLISION' },
      });
      throw new BadRequestException('OTP code has already been consumed.');
    }

    // Clear cooldown on successful verification
    await this.redis.del(`otp:cooldown:${normalizedPhone}`);

    await this.securityAudit.logEvent({
      action: 'OTP_VERIFICATION_SUCCEEDED',
      targetEntity: 'Phone',
      targetId: normalizedPhone,
      ipAddress,
      userAgent,
      correlationId,
      metadata: { purpose },
    });

    return { normalizedPhone };
  }

  /**
   * Cryptographic hash using SHA-256 and pepper secret.
   */
  hashOtp(code: string): string {
    return crypto
      .createHash('sha256')
      .update(code + this.otpPepper)
      .digest('hex');
  }
}
