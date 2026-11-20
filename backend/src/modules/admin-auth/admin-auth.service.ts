import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { EmailService } from '../email/email.service';
import { StaffSessionService } from './services/staff-session.service';
import { TotpService } from './services/totp.service';
import {
  AdminChangePasswordDto,
  AdminForgotPasswordDto,
  AdminLoginDto,
  AdminResetPasswordDto,
  DisableMfaDto,
  EnableMfaDto,
  VerifyMfaChallengeDto,
} from './dto/admin-auth.dto';

const LOCKOUT_MAX_FAILURES = 5;
const LOCKOUT_WINDOW_MINUTES = 15;

@Injectable()
export class AdminAuthService {
  private readonly logger = new Logger(AdminAuthService.name);
  private readonly jwtIssuer = 'deal-one.eg';
  private readonly mfaAudience = 'deal-one-admin-mfa';

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly staffSessionService: StaffSessionService,
    private readonly totpService: TotpService,
    private readonly securityAudit: SecurityAuditService,
    @Optional() private readonly redis?: RedisService,
    @Optional() private readonly emailService?: EmailService,
  ) {}

  async login(
    dto: AdminLoginDto,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    const email = dto.email.trim().toLowerCase();
    const ip = (ipAddress || '127.0.0.1').slice(0, 50);
    const ua = userAgent?.slice(0, 500);

    // Check recent failed login lockout window (since last successful login or 15 mins)
    const staff = await this.prisma.staffUser.findUnique({
      where: { email },
      include: { role: true },
    });

    const windowStart = new Date(
      Date.now() - LOCKOUT_WINDOW_MINUTES * 60 * 1000,
    );
    const cutoffDate =
      staff?.lastLoginAt && staff.lastLoginAt > windowStart
        ? staff.lastLoginAt
        : windowStart;

    const recentFailures = await this.prisma.staffLoginAttempt.count({
      where: {
        email,
        isSuccess: false,
        createdAt: { gte: cutoffDate },
      },
    });

    if (recentFailures >= LOCKOUT_MAX_FAILURES) {
      await this.recordAttempt(email, staff?.id ?? null, ip, ua, false, 'ACCOUNT_LOCKED');
      await this.securityAudit.logEvent({
        action: 'ADMIN_LOGIN_LOCKED',
        actorType: 'staff',
        actorId: staff?.id,
        targetEntity: 'staff_user',
        targetId: staff?.id,
        ipAddress: ip,
        userAgent: ua,
        correlationId,
      });
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          error: 'Too Many Requests',
          message:
            'Too many failed login attempts. Account is temporarily locked for 15 minutes.',
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    if (!staff) {
      await argon2.hash(dto.password); // Timing mitigation
      await this.recordAttempt(email, null, ip, ua, false, 'UNKNOWN_EMAIL');
      throw new UnauthorizedException('Invalid email or password.');
    }

    const passwordValid = await argon2
      .verify(staff.passwordHash, dto.password)
      .catch(() => false);

    if (!passwordValid) {
      await this.recordAttempt(
        email,
        staff.id,
        ip,
        ua,
        false,
        'PASSWORD_MISMATCH',
      );
      await this.securityAudit.logEvent({
        action: 'ADMIN_LOGIN_FAILED',
        actorType: 'staff',
        actorId: staff.id,
        targetEntity: 'staff_user',
        targetId: staff.id,
        ipAddress: ip,
        userAgent: ua,
        correlationId,
        metadata: { reason: 'PASSWORD_MISMATCH' },
      });
      throw new UnauthorizedException('Invalid email or password.');
    }

    if (
      !staff.isActive ||
      staff.status !== 'active' ||
      staff.deletedAt ||
      (staff.expiresAt && staff.expiresAt <= new Date())
    ) {
      await this.recordAttempt(
        email,
        staff.id,
        ip,
        ua,
        false,
        `ACCOUNT_${staff.status.toUpperCase()}`,
      );
      throw new ForbiddenException(
        'Admin account is suspended, disabled, or expired.',
      );
    }

    // If MFA is enabled, issue a short-lived MFA challenge token
    if (staff.mfaEnabled && staff.mfaSecretEncrypted) {
      const jti = crypto.randomUUID();
      const mfaChallengeToken = this.jwtService.sign(
        { sub: staff.id, type: 'mfa_challenge', jti },
        {
          secret: this.staffSessionService.getAdminAccessSecret(),
          expiresIn: '5m',
          issuer: this.jwtIssuer,
          audience: this.mfaAudience,
        },
      );

      await this.securityAudit.logEvent({
        action: 'ADMIN_LOGIN_MFA_CHALLENGE_ISSUED',
        actorType: 'staff',
        actorId: staff.id,
        targetEntity: 'staff_user',
        targetId: staff.id,
        ipAddress: ip,
        userAgent: ua,
        correlationId,
      });

      return {
        requiresMfa: true,
        mfaChallengeToken,
        admin: this.formatSafeAdmin(staff),
      };
    }

    const sessionResult = await this.staffSessionService.createSession(
      staff,
      false,
      ua,
      ip,
    );

    await Promise.all([
      this.prisma.staffUser.update({
        where: { id: staff.id },
        data: { lastLoginAt: new Date() },
      }),
      this.recordAttempt(email, staff.id, ip, ua, true, null),
    ]);

    return {
      requiresMfa: false,
      admin: this.formatSafeAdmin(staff),
      accessToken: sessionResult.accessToken,
      refreshToken: sessionResult.refreshToken,
      expiresIn: sessionResult.expiresIn,
      sessionId: sessionResult.sessionId,
    };
  }

  async verifyMfaChallenge(
    dto: VerifyMfaChallengeDto,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    let payload: { sub: string; type?: string; jti?: string };
    try {
      payload = this.jwtService.verify(dto.mfaChallengeToken, {
        secret: this.staffSessionService.getAdminAccessSecret(),
        issuer: this.jwtIssuer,
        audience: this.mfaAudience,
        algorithms: ['HS256'],
      });
    } catch {
      throw new UnauthorizedException(
        'MFA challenge token is invalid or has expired.',
      );
    }

    if (!payload.sub || payload.type !== 'mfa_challenge') {
      throw new UnauthorizedException('Invalid MFA challenge token.');
    }

    const staff = await this.prisma.staffUser.findUnique({
      where: { id: payload.sub },
      include: { role: true },
    });

    if (
      !staff ||
      !staff.isActive ||
      staff.status !== 'active' ||
      staff.deletedAt ||
      !staff.mfaEnabled ||
      !staff.mfaSecretEncrypted
    ) {
      throw new UnauthorizedException('Admin account is not eligible for MFA.');
    }

    const secret = this.totpService.decryptSecret(staff.mfaSecretEncrypted);
    const codeValid = this.totpService.verifyTotp(secret, dto.code);
    let usedRecoveryCode = false;

    if (!codeValid) {
      const recoveryHashes = Array.isArray(staff.mfaRecoveryCodesHash)
        ? (staff.mfaRecoveryCodesHash as string[])
        : [];
      const candidateHash = this.totpService.hashRecoveryCode(dto.code);
      const matchIdx = recoveryHashes.findIndex((h) => h === candidateHash);
      if (matchIdx === -1) {
        await this.recordAttempt(
          staff.email,
          staff.id,
          ipAddress || '127.0.0.1',
          userAgent,
          false,
          'MFA_INVALID_CODE',
        );
        throw new UnauthorizedException('Invalid MFA verification code.');
      }
      usedRecoveryCode = true;
      const updatedHashes = recoveryHashes.filter((_, idx) => idx !== matchIdx);
      await this.prisma.staffUser.update({
        where: { id: staff.id },
        data: { mfaRecoveryCodesHash: updatedHashes },
      });
    }

    if (payload.jti && this.redis) {
      const firstUse = await this.redis.setIfNotExists(
        `admin:mfa:used:${payload.jti}`,
        '1',
        300,
      );
      if (!firstUse) {
        throw new UnauthorizedException('MFA challenge token was already used.');
      }
    }

    const sessionResult = await this.staffSessionService.createSession(
      staff,
      true,
      userAgent,
      ipAddress,
    );

    await Promise.all([
      this.prisma.staffUser.update({
        where: { id: staff.id },
        data: { lastLoginAt: new Date() },
      }),
      this.recordAttempt(
        staff.email,
        staff.id,
        ipAddress || '127.0.0.1',
        userAgent,
        true,
        null,
      ),
      this.securityAudit.logEvent({
        action: 'ADMIN_MFA_VERIFIED',
        actorType: 'staff',
        actorId: staff.id,
        targetEntity: 'staff_user',
        targetId: staff.id,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { usedRecoveryCode },
      }),
    ]);

    return {
      requiresMfa: false,
      admin: this.formatSafeAdmin(staff),
      accessToken: sessionResult.accessToken,
      refreshToken: sessionResult.refreshToken,
      expiresIn: sessionResult.expiresIn,
      sessionId: sessionResult.sessionId,
    };
  }

  async refresh(
    rawRefreshToken: string,
    ipAddress?: string,
    userAgent?: string,
    correlationId?: string,
  ) {
    const rotated = await this.staffSessionService.rotateRefreshToken(
      rawRefreshToken,
      userAgent,
      ipAddress,
      correlationId,
    );

    return {
      admin: this.formatSafeAdmin(rotated.staff),
      accessToken: rotated.accessToken,
      refreshToken: rotated.refreshToken,
      expiresIn: rotated.expiresIn,
      sessionId: rotated.sessionId,
    };
  }

  async logout(
    rawRefreshToken?: string,
    rawAccessToken?: string,
    staffId?: string,
  ) {
    await this.staffSessionService.revokeSessionByToken(
      rawRefreshToken,
      rawAccessToken,
      staffId,
    );
    return { success: true };
  }

  async getMe(staffId: string) {
    const staff = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      include: { role: true },
    });
    if (!staff) {
      throw new UnauthorizedException('Admin account not found');
    }
    return this.formatSafeAdmin(staff);
  }

  async setupMfa(staffId: string) {
    const staff = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      select: { id: true, email: true, mfaEnabled: true },
    });
    if (!staff) throw new UnauthorizedException('Staff account not found');

    const secret = this.totpService.generateBase32Secret();
    const encrypted = this.totpService.encryptSecret(secret);

    await this.prisma.staffUser.update({
      where: { id: staffId },
      data: { mfaSecretEncrypted: encrypted },
    });

    return {
      secret,
      otpauthUrl: this.totpService.buildOtpAuthUri(staff.email, secret),
      mfaEnabled: staff.mfaEnabled,
    };
  }

  async enableMfa(staffId: string, dto: EnableMfaDto) {
    const staff = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      select: { id: true, mfaSecretEncrypted: true },
    });
    if (!staff?.mfaSecretEncrypted) {
      throw new BadRequestException(
        'MFA setup has not been initiated. Call /mfa/setup first.',
      );
    }

    const secret = this.totpService.decryptSecret(staff.mfaSecretEncrypted);
    if (!this.totpService.verifyTotp(secret, dto.code)) {
      throw new BadRequestException('Invalid 6-digit verification code.');
    }

    const { plainCodes, hashedCodes } =
      this.totpService.generateRecoveryCodes(8);

    await this.prisma.staffUser.update({
      where: { id: staffId },
      data: {
        mfaEnabled: true,
        mfaRecoveryCodesHash: hashedCodes,
      },
    });
    await this.staffSessionService.invalidateStaffAuthCache(staffId);

    await this.securityAudit.logEvent({
      action: 'ADMIN_MFA_ENABLED',
      actorType: 'staff',
      actorId: staffId,
      targetEntity: 'staff_user',
      targetId: staffId,
    });

    return {
      mfaEnabled: true,
      recoveryCodes: plainCodes,
    };
  }

  async disableMfa(staffId: string, dto: DisableMfaDto) {
    const staff = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
    });
    if (!staff) throw new UnauthorizedException('Staff account not found');

    const pwdOk = await argon2
      .verify(staff.passwordHash, dto.currentPassword)
      .catch(() => false);
    if (!pwdOk) {
      throw new UnauthorizedException('Current password is incorrect.');
    }

    if (staff.mfaEnabled && staff.mfaSecretEncrypted) {
      const secret = this.totpService.decryptSecret(staff.mfaSecretEncrypted);
      if (!this.totpService.verifyTotp(secret, dto.code)) {
        throw new BadRequestException('Invalid MFA code.');
      }
    }

    await this.prisma.staffUser.update({
      where: { id: staffId },
      data: {
        mfaEnabled: false,
        mfaSecretEncrypted: null,
        mfaRecoveryCodesHash: [],
      },
    });
    await this.staffSessionService.invalidateStaffAuthCache(staffId);

    await this.securityAudit.logEvent({
      action: 'ADMIN_MFA_DISABLED',
      actorType: 'staff',
      actorId: staffId,
      targetEntity: 'staff_user',
      targetId: staffId,
    });

    return { mfaEnabled: false };
  }

  async changePassword(
    staffId: string,
    dto: AdminChangePasswordDto,
    currentSessionId?: string,
  ) {
    const staff = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
    });
    if (!staff) throw new UnauthorizedException('Staff account not found');

    const matches = await argon2
      .verify(staff.passwordHash, dto.currentPassword)
      .catch(() => false);
    if (!matches) {
      throw new UnauthorizedException('Current password is incorrect.');
    }

    const newHash = await argon2.hash(dto.newPassword);
    await this.prisma.staffUser.update({
      where: { id: staffId },
      data: {
        passwordHash: newHash,
        passwordChangedAt: new Date(),
      },
    });

    const revokedSessionsCount =
      await this.staffSessionService.revokeOtherStaffSessions(
        staffId,
        currentSessionId,
      );

    await this.securityAudit.logEvent({
      action: 'ADMIN_PASSWORD_CHANGED',
      actorType: 'staff',
      actorId: staffId,
      targetEntity: 'staff_user',
      targetId: staffId,
      metadata: { revokedSessionsCount },
    });

    return { success: true, revokedSessionsCount };
  }

  async forgotPassword(dto: AdminForgotPasswordDto) {
    const email = dto.email.trim().toLowerCase();
    const staff = await this.prisma.staffUser.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        fullName: true,
        isActive: true,
        status: true,
        deletedAt: true,
      },
    });

    const genericResponse = {
      success: true,
      message:
        'If an active admin account exists for this email, reset instructions have been issued.',
    };

    if (!staff || !staff.isActive || staff.status !== 'active' || staff.deletedAt) {
      return genericResponse;
    }

    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = this.staffSessionService.hashToken(rawToken);
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);

    await this.prisma.staffPasswordResetToken.create({
      data: {
        staffId: staff.id,
        tokenHash,
        expiresAt,
      },
    });

    const adminUrl = this.configService.get<string>(
      'ADMIN_PUBLIC_URL',
      'http://localhost:5173',
    );
    const resetLink = `${adminUrl.replace(/\/+$/, '')}/login?resetToken=${rawToken}`;

    if (this.emailService?.isConfigured()) {
      await this.emailService
        .sendEmail({
          to: staff.email,
          subject: 'Deal One Admin — Password Reset Request',
          html: `<p>Hello ${staff.fullName},</p><p>Use the link below within 30 minutes to reset your admin password:</p><p><a href="${resetLink}">${resetLink}</a></p>`,
          text: `Hello ${staff.fullName}, reset your admin password within 30 minutes: ${resetLink}`,
          template: 'admin-password-reset',
          locale: 'en',
        })
        .catch((err) =>
          this.logger.warn(`Failed sending admin reset email: ${err?.message}`),
        );
    }

    await this.securityAudit.logEvent({
      action: 'ADMIN_PASSWORD_RESET_REQUESTED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'staff_user',
      targetId: staff.id,
    });

    if (this.configService.get<string>('NODE_ENV') === 'test') {
      return { ...genericResponse, debugResetToken: rawToken };
    }

    return genericResponse;
  }

  async resetPassword(dto: AdminResetPasswordDto) {
    const tokenHash = this.staffSessionService.hashToken(dto.token.trim());
    const resetRecord = await this.prisma.staffPasswordResetToken.findUnique({
      where: { tokenHash },
      include: { staff: true },
    });

    if (
      !resetRecord ||
      resetRecord.usedAt ||
      resetRecord.expiresAt <= new Date() ||
      !resetRecord.staff
    ) {
      throw new BadRequestException(
        'Password reset token is invalid or has expired.',
      );
    }

    const newHash = await argon2.hash(dto.newPassword);

    await this.prisma.$transaction(async (tx) => {
      await tx.staffPasswordResetToken.update({
        where: { id: resetRecord.id },
        data: { usedAt: new Date() },
      });
      await tx.staffUser.update({
        where: { id: resetRecord.staffId },
        data: {
          passwordHash: newHash,
          passwordChangedAt: new Date(),
        },
      });
    });

    await this.staffSessionService.revokeAllStaffSessions(
      resetRecord.staffId,
      resetRecord.staffId,
    );

    await this.securityAudit.logEvent({
      action: 'ADMIN_PASSWORD_RESET_COMPLETED',
      actorType: 'staff',
      actorId: resetRecord.staffId,
      targetEntity: 'staff_user',
      targetId: resetRecord.staffId,
    });

    return { success: true };
  }

  formatSafeAdmin(staff: {
    id: string;
    email: string;
    fullName: string;
    phone?: string | null;
    department?: string | null;
    jobTitle?: string | null;
    roleId: number;
    status?: string;
    isActive?: boolean;
    mfaEnabled: boolean;
    lastLoginAt?: Date | null;
    role: { id: number; name: string; description?: string | null; permissions: unknown };
  }) {
    const permissions = Array.isArray(staff.role?.permissions)
      ? (staff.role.permissions as string[])
      : [];

    return {
      id: staff.id,
      email: staff.email,
      fullName: staff.fullName,
      phone: staff.phone ?? null,
      department: staff.department ?? null,
      jobTitle: staff.jobTitle ?? null,
      status: staff.status ?? 'active',
      isActive: staff.isActive ?? true,
      mfaEnabled: staff.mfaEnabled,
      lastLoginAt: staff.lastLoginAt ?? null,
      role: {
        id: staff.role.id,
        name: staff.role.name,
        description: staff.role.description ?? null,
      },
      permissions,
    };
  }

  private async recordAttempt(
    email: string,
    staffId: string | null,
    ipAddress: string,
    userAgent: string | undefined,
    isSuccess: boolean,
    failureReason: string | null,
  ) {
    await this.prisma.staffLoginAttempt
      .create({
        data: {
          email,
          staffId,
          ipAddress: ipAddress.slice(0, 50),
          userAgent: userAgent?.slice(0, 500) || null,
          isSuccess,
          failureReason,
        },
      })
      .catch((err) =>
        this.logger.warn(`Failed recording login attempt: ${err?.message}`),
      );
  }
}
