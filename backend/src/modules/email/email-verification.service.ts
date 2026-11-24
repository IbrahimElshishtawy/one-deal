import {
  Injectable,
  BadRequestException,
  HttpException,
  HttpStatus,
  UnauthorizedException,
  Logger,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { StructuredFlowLogger } from '../../core/observability/structured-flow.logger';
import { EmailService } from './email.service';
import { EMAIL_DEFAULTS, EMAIL_REDIS_KEYS } from './email.constants';
import { normalizeEmailLocale } from './templates/email-layout.template';

interface StoredVerificationTokenPayload {
  userId: string;
  email: string;
  createdAt: number;
}

@Injectable()
export class EmailVerificationService {
  private readonly logger = new Logger(EmailVerificationService.name);
  private readonly ttlMinutes: number;
  private readonly cooldownSeconds: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly emailService: EmailService,
    private readonly configService: ConfigService,
    @Optional() private readonly securityAudit?: SecurityAuditService,
  ) {
    this.ttlMinutes = this.configService.get<number>(
      'EMAIL_VERIFICATION_TTL_MINUTES',
      EMAIL_DEFAULTS.VERIFICATION_TTL_MINUTES,
    );
    this.cooldownSeconds = EMAIL_DEFAULTS.VERIFICATION_COOLDOWN_SECONDS;
  }

  /**
   * Generates a cryptographically secure single-use verification token,
   * stores only its SHA-256 hash in Redis with TTL, invalidates any prior token
   * for the user, and sends a verification email without leaking enumeration state.
   */
  async requestVerification(
    userId: string,
    requestedEmail?: string,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ): Promise<{
    success: boolean;
    message: string;
    expiresInMinutes: number;
    cooldownSeconds: number;
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        email: true,
        isEmailVerified: true,
        isActive: true,
        deletedAt: true,
        preferredLanguage: true,
      },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedException('User account is inactive or not found.');
    }

    const targetEmail = (requestedEmail ?? user.email ?? '')
      .trim()
      .toLowerCase();
    if (!targetEmail) {
      throw new BadRequestException(
        'An email address is required to send a verification email.',
      );
    }

    if (user.email === targetEmail && user.isEmailVerified) {
      return {
        success: true,
        message: 'Email address is already verified.',
        expiresInMinutes: this.ttlMinutes,
        cooldownSeconds: this.cooldownSeconds,
      };
    }

    // Enforce resend cooldown atomically via Redis SET NX
    const cooldownKey = EMAIL_REDIS_KEYS.verificationCooldown(userId);
    const cooldownSet = await this.redis.setIfNotExists(
      cooldownKey,
      '1',
      this.cooldownSeconds,
    );
    if (!cooldownSet) {
      throw new HttpException(
        `Please wait ${this.cooldownSeconds} seconds before requesting another verification email.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Prevent email enumeration: if another account already owns this email,
    // return the same generic success response without sending or leaking ownership.
    const existingOwner = await this.prisma.user.findUnique({
      where: { email: targetEmail },
      select: { id: true },
    });
    if (existingOwner && existingOwner.id !== userId) {
      await this.securityAudit?.logEvent({
        action: 'EMAIL_VERIFICATION_CONFLICT_SUPPRESSED',
        actorType: 'user',
        actorId: userId,
        targetEntity: 'User',
        targetId: userId,
        ipAddress,
        userAgent,
        correlationId,
      });
      return {
        success: true,
        message:
          'If this email address is eligible, a verification link has been sent.',
        expiresInMinutes: this.ttlMinutes,
        cooldownSeconds: this.cooldownSeconds,
      };
    }

    // Invalidate any previous active verification token for this user
    const activeUserKey = EMAIL_REDIS_KEYS.verificationUserActiveToken(userId);
    const previousHash = await this.redis.get<string>(activeUserKey);
    if (previousHash) {
      await this.redis.del(EMAIL_REDIS_KEYS.verificationToken(previousHash));
    }

    // Generate cryptographically secure 256-bit token; store ONLY SHA-256 hash
    const rawToken = crypto.randomBytes(32).toString('base64url');
    const tokenHash = this.hashToken(rawToken);
    const ttlSeconds = this.ttlMinutes * 60;
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + ttlSeconds * 1000);

    const payload: StoredVerificationTokenPayload = {
      userId,
      email: targetEmail,
      createdAt: createdAt.getTime(),
    };

    await Promise.all([
      this.redis.set(
        EMAIL_REDIS_KEYS.verificationToken(tokenHash),
        payload,
        ttlSeconds,
      ),
      this.redis.set(activeUserKey, tokenHash, ttlSeconds),
    ]);

    // Development-only token visibility in terminal logs (strictly disabled in production)
    StructuredFlowLogger.logDevEmailVerificationGenerated({
      configuredEnv: this.configService.get<string>('NODE_ENV'),
      email: targetEmail,
      token: rawToken,
      createdAt,
      expiresAt,
      requestId: correlationId,
    });
    StructuredFlowLogger.stage(
      'AUTH',
      'Email verification token generated and hashed in Redis',
      {
        email: targetEmail,
        expiresInMinutes: this.ttlMinutes,
      },
      correlationId,
    );

    const verificationUrl = `${this.emailService.getAppPublicUrl()}/verify-email?token=${encodeURIComponent(rawToken)}`;

    // Dispatch verification email safely (never log rawToken or verificationUrl)
    await this.emailService.sendEmailVerification({
      to: targetEmail,
      displayName: user.fullName,
      verificationUrl,
      expiresInMinutes: this.ttlMinutes,
      locale: normalizeEmailLocale(user.preferredLanguage),
      idempotencyKey: `email-verify-${tokenHash.slice(0, 24)}`,
    });

    await this.securityAudit?.logEvent({
      action: 'EMAIL_VERIFICATION_REQUESTED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'User',
      targetId: userId,
      ipAddress,
      userAgent,
      correlationId,
    });

    return {
      success: true,
      message:
        'If this email address is eligible, a verification link has been sent.',
      expiresInMinutes: this.ttlMinutes,
      cooldownSeconds: this.cooldownSeconds,
    };
  }

  /**
   * Verifies a single-use email verification token, consumes it immediately
   * to prevent replay, updates User.email & User.isEmailVerified, and sends
   * confirmation / security notifications.
   */
  async verifyEmailToken(
    rawToken: string,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ): Promise<{
    success: boolean;
    message: string;
    isEmailVerified: boolean;
  }> {
    const trimmed = (rawToken ?? '').trim();
    if (!trimmed || trimmed.length < 16) {
      throw new BadRequestException(
        'Invalid or expired email verification token.',
      );
    }

    const tokenHash = this.hashToken(trimmed);
    const tokenKey = EMAIL_REDIS_KEYS.verificationToken(tokenHash);
    const stored =
      await this.redis.get<StoredVerificationTokenPayload>(tokenKey);

    if (!stored || !stored.userId || !stored.email) {
      throw new BadRequestException(
        'Invalid or expired email verification token.',
      );
    }

    // Consume token immediately to prevent replay attacks
    const activeUserKey = EMAIL_REDIS_KEYS.verificationUserActiveToken(
      stored.userId,
    );
    const activeHash = await this.redis.get<string>(activeUserKey);
    await Promise.all([
      this.redis.del(tokenKey),
      activeHash === tokenHash
        ? this.redis.del(activeUserKey)
        : Promise.resolve(),
    ]);

    // Reject if token was superseded by a newer request
    if (activeHash && activeHash !== tokenHash) {
      throw new BadRequestException(
        'Invalid or expired email verification token.',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { id: stored.userId },
      select: {
        id: true,
        fullName: true,
        email: true,
        isEmailVerified: true,
        isActive: true,
        deletedAt: true,
        preferredLanguage: true,
      },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new BadRequestException(
        'Invalid or expired email verification token.',
      );
    }

    // Re-check uniqueness before updating to prevent race collisions
    const existingOwner = await this.prisma.user.findUnique({
      where: { email: stored.email },
      select: { id: true },
    });
    if (existingOwner && existingOwner.id !== user.id) {
      throw new BadRequestException(
        'This email address cannot be verified for this account.',
      );
    }

    const previousVerifiedEmail =
      user.isEmailVerified && user.email && user.email !== stored.email
        ? user.email
        : null;

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        email: stored.email,
        isEmailVerified: true,
      },
    });

    await this.securityAudit?.logEvent({
      action: 'EMAIL_VERIFIED',
      actorType: 'user',
      actorId: user.id,
      targetEntity: 'User',
      targetId: user.id,
      ipAddress,
      userAgent,
      correlationId,
    });

    const locale = normalizeEmailLocale(user.preferredLanguage);

    // Send confirmation email (non-blocking — failures never roll back verification)
    this.emailService
      .sendEmailVerifiedConfirmation({
        to: stored.email,
        displayName: user.fullName,
        locale,
        idempotencyKey: `email-verified-${tokenHash.slice(0, 24)}`,
      })
      .catch((err) =>
        this.logger.warn(
          `Non-blocking email-verified confirmation failed: ${err?.message}`,
        ),
      );

    // If user changed from a previously verified email, notify the old email address
    if (previousVerifiedEmail) {
      this.emailService
        .sendSecurityNotificationEmail({
          to: previousVerifiedEmail,
          displayName: user.fullName,
          eventKind: 'EMAIL_CHANGED',
          ipAddress,
          locale,
          idempotencyKey: `email-changed-${tokenHash.slice(0, 24)}`,
        })
        .catch((err) =>
          this.logger.warn(
            `Non-blocking email-changed security alert failed: ${err?.message}`,
          ),
        );
    }

    return {
      success: true,
      message: 'Email address verified successfully.',
      isEmailVerified: true,
    };
  }

  hashToken(rawToken: string): string {
    return crypto.createHash('sha256').update(rawToken).digest('hex');
  }
}
