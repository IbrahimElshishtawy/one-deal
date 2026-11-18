import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  HttpException,
  HttpStatus,
  Logger,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { PhoneNormalizationService } from '../../core/identity/phone-normalization.service';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { OtpService } from './services/otp.service';
import { SessionService } from './services/session.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { ResendOtpDto } from './dto/resend-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { LoginPasswordDto } from './dto/login-password.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { SetPasswordDto } from './dto/set-password.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly phoneNormalization: PhoneNormalizationService,
    private readonly otpService: OtpService,
    private readonly sessionService: SessionService,
    private readonly securityAudit: SecurityAuditService,
    @Optional() private readonly redis?: RedisService,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  /**
   * Dispatches SMS OTP with phone normalization, rate limits, and cooldown.
   */
  async sendOtp(
    dto: SendOtpDto,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    return this.otpService.requestOtp(
      dto.phone,
      'AUTH',
      ipAddress,
      userAgent,
      correlationId,
    );
  }

  /**
   * Resends SMS OTP subject to strict cooldown and attempt constraints.
   */
  async resendOtp(
    dto: ResendOtpDto,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    return this.otpService.resendOtp(
      dto.phone,
      'AUTH',
      ipAddress,
      userAgent,
      correlationId,
    );
  }

  /**
   * Verifies OTP challenge, registers new User and default Individual Account (if new),
   * or updates verified status (if existing), issuing authoritative JWT token pair.
   */
  async verifyOtp(
    dto: VerifyOtpDto,
    userAgent?: string,
    ipAddress?: string,
    correlationId?: string,
  ) {
    // 1. Verify OTP with brute-force lockout and atomic consumption
    const { normalizedPhone } = await this.otpService.verifyOtp(
      dto.phone,
      dto.code,
      'AUTH',
      ipAddress,
      userAgent,
      correlationId,
    );

    // 2. Query user identity
    let user = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });

    let primaryAccount: {
      id: string;
      accountType: string;
      displayName: string;
      role: string;
    } | null = null;

    if (!user) {
      // 3. User Registration with automatic Individual Account creation in a single transaction
      const registration = await this.prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            phone: normalizedPhone,
            fullName: `مستخدم ${normalizedPhone.slice(-4)}`,
            isPhoneVerified: true,
            isActive: true,
          },
        });

        const slugSeed = `user-${newUser.id.substring(0, 8)}-${Math.random().toString(36).substring(2, 6)}`;
        const newAccount = await tx.account.create({
          data: {
            ownerUserId: newUser.id,
            accountType: 'individual',
            displayName: newUser.fullName,
            slug: slugSeed,
            verificationStatus: 'approved', // Individual accounts approved upon phone verification
            isActive: true,
          },
        });

        await tx.accountMember.create({
          data: {
            accountId: newAccount.id,
            userId: newUser.id,
            role: 'owner',
          },
        });

        return { user: newUser, account: newAccount };
      });

      user = registration.user;
      primaryAccount = {
        id: registration.account.id,
        accountType: registration.account.accountType,
        displayName: registration.account.displayName,
        role: 'owner',
      };

      await this.securityAudit.logEvent({
        action: 'USER_REGISTERED_VIA_OTP',
        actorType: 'user',
        actorId: user.id,
        targetEntity: 'User',
        targetId: user.id,
        ipAddress,
        userAgent,
        correlationId,
        metadata: {
          phone: normalizedPhone,
          defaultAccountId: primaryAccount.id,
        },
      });
    } else {
      // Existing User Verification
      if (!user.isActive || user.deletedAt) {
        await this.securityAudit.logEvent({
          action: 'LOGIN_REJECTED_INACTIVE_USER',
          actorType: 'user',
          actorId: user.id,
          targetEntity: 'User',
          targetId: user.id,
          ipAddress,
          userAgent,
          correlationId,
        });
        throw new UnauthorizedException(
          'Your account has been deactivated or suspended by administration.',
        );
      }

      if (!user.isPhoneVerified) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { isPhoneVerified: true },
        });
      }

      // Fetch user's primary/owned account
      const ownedMembership = await this.prisma.accountMember.findFirst({
        where: { userId: user.id, role: 'owner' },
        include: { account: true },
      });

      if (ownedMembership && ownedMembership.account) {
        primaryAccount = {
          id: ownedMembership.accountId,
          accountType: ownedMembership.account.accountType,
          displayName: ownedMembership.account.displayName,
          role: ownedMembership.role,
        };
      }
    }

    // 4. Issue authoritative session tokens
    const tokens = await this.sessionService.createSession(
      user.id,
      user.phone,
      'USER',
      userAgent,
      ipAddress,
    );

    await this.securityAudit.logEvent({
      action: 'USER_AUTHENTICATED_OTP',
      actorType: 'user',
      actorId: user.id,
      targetEntity: 'User',
      targetId: user.id,
      ipAddress,
      userAgent,
      correlationId,
      metadata: { sessionId: tokens.sessionId },
    });

    return {
      user: {
        id: user.id,
        phone: user.phone,
        fullName: user.fullName,
        role: 'USER',
        avatarUrl: user.avatarUrl,
        isPhoneVerified: user.isPhoneVerified,
      },
      activeAccount: primaryAccount,
      tokens,
    };
  }

  /**
   * Password login fallback for administrative and legacy accounts.
   * Enforces per-account distributed rate limiting and consistent error messages
   * to prevent brute-force and account enumeration.
   */
  async loginWithPassword(
    dto: LoginPasswordDto,
    userAgent?: string,
    ipAddress?: string,
    correlationId?: string,
  ) {
    const normalizedPhone = this.phoneNormalization.normalize(dto.phone);

    // Per-account distributed rate limit (complements IP-level RateLimitGuard)
    const loginMax =
      this.configService?.get<number>('RATE_LIMIT_LOGIN_MAX', 5) ?? 5;
    const loginWindowSec =
      this.configService?.get<number>('RATE_LIMIT_LOGIN_WINDOW_SEC', 900) ??
      900;
    const accountThrottleKey = `auth:ratelimit:login:account:${normalizedPhone}`;

    if (this.redis) {
      const throttle = await this.redis.checkRateLimit(
        accountThrottleKey,
        loginMax,
        loginWindowSec,
      );
      if (!throttle.allowed) {
        const retryAfter = throttle.resetSeconds ?? loginWindowSec;
        await this.securityAudit.logEvent({
          action: 'PASSWORD_LOGIN_RATE_LIMITED',
          targetEntity: 'Phone',
          targetId: normalizedPhone,
          ipAddress,
          userAgent,
          correlationId,
          metadata: { retryAfterSeconds: retryAfter },
        });
        throw new HttpException(
          {
            statusCode: HttpStatus.TOO_MANY_REQUESTS,
            error: 'Too Many Requests',
            message: `Too many login attempts. Please try again after ${retryAfter} seconds.`,
            details: { retryAfterSeconds: retryAfter },
          },
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }

    const user = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });

    if (!user || !user.passwordHash) {
      // Equalize timing with Argon2 work to prevent timing-based account enumeration
      await argon2.hash(dto.password);
      await this.securityAudit.logEvent({
        action: 'PASSWORD_LOGIN_FAILED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { reason: 'USER_NOT_FOUND_OR_NO_PASSWORD' },
      });
      throw new UnauthorizedException('Invalid phone number or password.');
    }

    const isMatch = await argon2.verify(user.passwordHash, dto.password);
    if (!isMatch || !user.isActive || user.deletedAt) {
      await this.securityAudit.logEvent({
        action: 'PASSWORD_LOGIN_FAILED',
        actorType: 'user',
        actorId: user.id,
        targetEntity: 'User',
        targetId: user.id,
        ipAddress,
        userAgent,
        correlationId,
        metadata: {
          reason: !isMatch ? 'PASSWORD_MISMATCH' : 'ACCOUNT_INACTIVE',
        },
      });
      throw new UnauthorizedException('Invalid phone number or password.');
    }

    // Clear per-account throttle counter after a valid login
    if (this.redis) {
      await this.redis.del(accountThrottleKey);
    }

    const ownedMembership = await this.prisma.accountMember.findFirst({
      where: { userId: user.id, role: 'owner' },
      include: { account: true },
    });

    const tokens = await this.sessionService.createSession(
      user.id,
      user.phone,
      'USER',
      userAgent,
      ipAddress,
    );

    await this.securityAudit.logEvent({
      action: 'USER_AUTHENTICATED_PASSWORD',
      actorType: 'user',
      actorId: user.id,
      targetEntity: 'User',
      targetId: user.id,
      ipAddress,
      userAgent,
      correlationId,
      metadata: { sessionId: tokens.sessionId },
    });

    return {
      user: {
        id: user.id,
        phone: user.phone,
        fullName: user.fullName,
        role: 'USER',
        avatarUrl: user.avatarUrl,
        isPhoneVerified: user.isPhoneVerified,
      },
      activeAccount: ownedMembership?.account
        ? {
            id: ownedMembership.accountId,
            accountType: ownedMembership.account.accountType,
            displayName: ownedMembership.account.displayName,
            role: ownedMembership.role,
          }
        : null,
      tokens,
    };
  }

  /**
   * Rotates refresh token with reuse detection.
   */
  async refreshToken(
    dto: RefreshTokenDto,
    userAgent?: string,
    ipAddress?: string,
    correlationId?: string,
  ) {
    const token = dto.refreshToken || dto.refresh_token || '';
    return this.sessionService.rotateRefreshToken(
      token,
      userAgent,
      ipAddress,
      correlationId,
    );
  }

  /**
   * Revokes active session and denylists associated access token in Redis.
   */
  async logout(
    dto: RefreshTokenDto,
    authenticatedUserId?: string,
    correlationId?: string,
    rawAccessToken?: string,
  ) {
    const token = dto.refreshToken || dto.refresh_token || '';
    if (rawAccessToken) {
      return this.sessionService.revokeSessionByToken(
        token,
        authenticatedUserId,
        correlationId,
        rawAccessToken,
      );
    }
    return this.sessionService.revokeSessionByToken(
      token,
      authenticatedUserId,
      correlationId,
    );
  }

  /**
   * Revokes all active sessions for authenticated user.
   */
  async terminateAllSessions(userId: string, correlationId?: string) {
    return this.sessionService.revokeAllUserSessions(userId, correlationId);
  }

  /**
   * Lists active sessions for authenticated user.
   */
  async getActiveSessions(userId: string) {
    return this.sessionService.getUserActiveSessions(userId);
  }

  /**
   * Sets an initial password for an OTP-registered user who does not have one yet.
   */
  async setPassword(
    userId: string,
    dto: SetPasswordDto,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, passwordHash: true, isActive: true, deletedAt: true },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedException('User account is inactive or not found.');
    }

    if (user.passwordHash) {
      throw new BadRequestException(
        'Password is already set. Use change password instead.',
      );
    }

    const passwordHash = await argon2.hash(dto.password);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    await this.securityAudit.logEvent({
      action: 'PASSWORD_SET',
      actorType: 'user',
      actorId: user.id,
      targetEntity: 'User',
      targetId: user.id,
      ipAddress,
      userAgent,
      correlationId,
    });

    return {
      success: true,
      message: 'Password set successfully.',
    };
  }

  /**
   * Changes the authenticated user's password and revokes all other active sessions.
   */
  async changePassword(
    userId: string,
    dto: ChangePasswordDto,
    currentSessionId?: string,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, passwordHash: true, isActive: true, deletedAt: true },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedException('User account is inactive or not found.');
    }

    if (!user.passwordHash) {
      throw new BadRequestException(
        'No password is set for this account. Please set a password first.',
      );
    }

    const isMatch = await argon2.verify(user.passwordHash, dto.currentPassword);
    if (!isMatch) {
      await this.securityAudit.logEvent({
        action: 'PASSWORD_CHANGE_FAILED',
        actorType: 'user',
        actorId: user.id,
        targetEntity: 'User',
        targetId: user.id,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { reason: 'CURRENT_PASSWORD_MISMATCH' },
      });
      throw new UnauthorizedException('Current password is incorrect.');
    }

    if (dto.currentPassword === dto.newPassword) {
      throw new BadRequestException(
        'New password must be different from current password.',
      );
    }

    const passwordHash = await argon2.hash(dto.newPassword);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    const revocation = await this.sessionService.revokeOtherUserSessions(
      user.id,
      currentSessionId,
      correlationId,
    );

    await this.securityAudit.logEvent({
      action: 'PASSWORD_CHANGED',
      actorType: 'user',
      actorId: user.id,
      targetEntity: 'User',
      targetId: user.id,
      ipAddress,
      userAgent,
      correlationId,
      metadata: { revokedOtherSessions: revocation.revokedCount },
    });

    return {
      success: true,
      message: 'Password changed successfully.',
      revokedSessionsCount: revocation.revokedCount,
    };
  }

  /**
   * Dispatches a PASSWORD_RESET OTP if the normalized phone belongs to an active user.
   * Always returns 200 with a generic message to prevent phone number enumeration.
   */
  async forgotPassword(
    dto: ForgotPasswordDto,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    const genericResponse = {
      success: true,
      message:
        'If an active account is registered with this phone number, a password reset code has been sent.',
    };

    const normalizedPhone = this.phoneNormalization.normalize(dto.phone);
    const user = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
      select: { id: true, isActive: true, deletedAt: true },
    });

    if (!user || !user.isActive || user.deletedAt) {
      // Perform dummy Argon2 work to equalize response timing with OTP dispatch path
      await argon2.hash(normalizedPhone);
      await this.securityAudit.logEvent({
        action: 'PASSWORD_FORGOT_IGNORED',
        targetEntity: 'Phone',
        targetId: normalizedPhone,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { reason: 'NONEXISTENT_OR_INACTIVE_USER' },
      });
      return genericResponse;
    }

    try {
      await this.otpService.requestOtp(
        normalizedPhone,
        'PASSWORD_RESET',
        ipAddress,
        userAgent,
        correlationId,
      );
    } catch (err: any) {
      // Suppress OTP-layer cooldown/delivery differences so callers cannot enumerate accounts
      this.logger.warn(
        `Suppressed forgot-password OTP dispatch exception for ${normalizedPhone}: ${err?.message}`,
      );
    }

    return genericResponse;
  }

  /**
   * Verifies PASSWORD_RESET OTP, updates password hash using Argon2, and revokes all sessions.
   */
  async resetPassword(
    dto: ResetPasswordDto,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    const { normalizedPhone } = await this.otpService.verifyOtp(
      dto.phone,
      dto.code,
      'PASSWORD_RESET',
      ipAddress,
      userAgent,
      correlationId,
    );

    const user = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
      select: { id: true, isActive: true, deletedAt: true },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedException('User account is inactive or not found.');
    }

    const passwordHash = await argon2.hash(dto.newPassword);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    const revocation = await this.sessionService.revokeAllUserSessions(
      user.id,
      correlationId,
    );

    await this.securityAudit.logEvent({
      action: 'PASSWORD_RESET',
      actorType: 'user',
      actorId: user.id,
      targetEntity: 'User',
      targetId: user.id,
      ipAddress,
      userAgent,
      correlationId,
      metadata: { revokedSessions: revocation.revokedCount },
    });

    return {
      success: true,
      message:
        'Password reset successfully. All active sessions have been signed out.',
    };
  }
}
