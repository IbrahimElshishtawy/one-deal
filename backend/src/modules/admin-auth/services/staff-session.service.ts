import {
  Injectable,
  UnauthorizedException,
  Logger,
  Optional,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';

export interface StaffTokenResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  sessionId: string;
  mfaVerified: boolean;
}

@Injectable()
export class StaffSessionService {
  private readonly logger = new Logger(StaffSessionService.name);
  private readonly jwtIssuer = 'deal-one.eg';
  private readonly jwtAudience = 'deal-one-admin';
  private readonly accessTokenTtlSeconds = 900;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly securityAudit: SecurityAuditService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  getAdminAccessSecret(): string {
    const explicit = this.configService.get<string>('ADMIN_JWT_ACCESS_SECRET');
    if (explicit && explicit.trim().length >= 16) {
      return explicit.trim();
    }
    return this.configService.get<string>('JWT_ACCESS_SECRET', '');
  }

  getRefreshExpiryDays(): number {
    return this.configService.get<number>('ADMIN_REFRESH_EXPIRES_DAYS', 7);
  }

  async createSession(
    staff: {
      id: string;
      email: string;
      roleId: number;
      role: { name: string };
    },
    mfaVerified: boolean,
    userAgent?: string,
    ipAddress?: string,
    existingFamilyId?: string,
  ): Promise<StaffTokenResult> {
    const secret = this.getAdminAccessSecret();
    if (!secret || secret.length < 16) {
      throw new Error('Admin JWT access secret is not properly configured.');
    }

    const rawRefreshToken = crypto.randomBytes(40).toString('hex');
    const refreshTokenHash = this.hashToken(rawRefreshToken);
    const expiresAt = new Date(
      Date.now() + this.getRefreshExpiryDays() * 24 * 60 * 60 * 1000,
    );
    const familyId = existingFamilyId || crypto.randomUUID();

    const session = await this.prisma.staffSession.create({
      data: {
        staffId: staff.id,
        familyId,
        refreshTokenHash,
        mfaVerified,
        ipAddress: (ipAddress || '127.0.0.1').slice(0, 50),
        userAgent: userAgent?.slice(0, 500) || null,
        isRevoked: false,
        expiresAt,
      },
    });

    const jti = crypto.randomUUID();
    const expiresInStr = this.configService.get<string>(
      'ADMIN_JWT_ACCESS_EXPIRES_IN',
      '15m',
    );
    const accessToken = this.jwtService.sign(
      {
        sub: staff.id,
        actorType: 'staff',
        email: staff.email,
        roleId: staff.roleId,
        role: staff.role.name,
        mfa: mfaVerified,
        sid: session.id,
        jti,
      },
      {
        secret,
        expiresIn: expiresInStr,
        issuer: this.jwtIssuer,
        audience: this.jwtAudience,
      },
    );

    await this.securityAudit.logEvent({
      action: 'ADMIN_SESSION_CREATED',
      actorType: 'staff',
      actorId: staff.id,
      targetEntity: 'staff_session',
      targetId: session.id,
      ipAddress,
      userAgent,
      metadata: { familyId, mfaVerified, expiresAt },
    });

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn: this.accessTokenTtlSeconds,
      sessionId: session.id,
      mfaVerified,
    };
  }

  async rotateRefreshToken(
    rawRefreshToken: string,
    userAgent?: string,
    ipAddress?: string,
    correlationId?: string,
  ): Promise<
    StaffTokenResult & {
      staff: {
        id: string;
        email: string;
        fullName: string;
        roleId: number;
        mfaEnabled: boolean;
        role: { id: number; name: string; permissions: unknown };
      };
    }
  > {
    if (!rawRefreshToken || typeof rawRefreshToken !== 'string') {
      throw new UnauthorizedException('Admin refresh token is required.');
    }

    const hash = this.hashToken(rawRefreshToken);
    const session = await this.prisma.staffSession.findFirst({
      where: { refreshTokenHash: hash },
      include: {
        staff: {
          include: { role: true },
        },
      },
    });

    if (!session) {
      throw new UnauthorizedException('Invalid or unrecognized admin session.');
    }

    // Reuse detection: revoke whole family & denylist active sessions
    if (session.isRevoked) {
      this.logger.error(
        `🚨 SECURITY ALERT: Admin refresh token reuse detected for session [${session.id}] (staff: ${session.staffId})`,
      );

      const familySessions = await this.prisma.staffSession.findMany({
        where: {
          staffId: session.staffId,
          familyId: session.familyId,
          isRevoked: false,
        },
        select: { id: true },
      });

      await this.prisma.staffSession.updateMany({
        where: {
          staffId: session.staffId,
          familyId: session.familyId,
          isRevoked: false,
        },
        data: { isRevoked: true },
      });

      await this.denylistSessionId(session.id);
      await Promise.all(
        familySessions.map((s) => this.denylistSessionId(s.id)),
      );

      await this.securityAudit.logEvent({
        action: 'ADMIN_REFRESH_TOKEN_REUSE_DETECTED',
        actorType: 'staff',
        actorId: session.staffId,
        targetEntity: 'staff_session',
        targetId: session.id,
        ipAddress,
        userAgent,
        correlationId,
        metadata: { familyId: session.familyId },
      });

      throw new UnauthorizedException(
        'Security alert: Refresh token reuse detected. Session family revoked.',
      );
    }

    if (session.expiresAt <= new Date()) {
      await this.prisma.staffSession.update({
        where: { id: session.id },
        data: { isRevoked: true },
      });
      throw new UnauthorizedException('Admin refresh token has expired.');
    }

    const staff = session.staff;
    if (
      !staff ||
      !staff.isActive ||
      staff.status !== 'active' ||
      staff.deletedAt ||
      (staff.expiresAt && staff.expiresAt <= new Date())
    ) {
      await this.prisma.staffSession.update({
        where: { id: session.id },
        data: { isRevoked: true },
      });
      throw new UnauthorizedException('Admin account is inactive or disabled.');
    }

    const updateResult = await this.prisma.staffSession.updateMany({
      where: { id: session.id, isRevoked: false },
      data: { isRevoked: true, lastUsedAt: new Date() },
    });

    if (updateResult.count === 0) {
      throw new UnauthorizedException(
        'Concurrent admin refresh collision. Please sign in again.',
      );
    }

    const rotated = await this.createSession(
      staff,
      session.mfaVerified,
      userAgent || session.userAgent || undefined,
      ipAddress || session.ipAddress,
      session.familyId,
    );

    return {
      ...rotated,
      staff: {
        id: staff.id,
        email: staff.email,
        fullName: staff.fullName,
        roleId: staff.roleId,
        mfaEnabled: staff.mfaEnabled,
        role: staff.role,
      },
    };
  }

  async revokeSessionByToken(
    rawRefreshToken?: string,
    rawAccessToken?: string,
    actorStaffId?: string,
  ): Promise<void> {
    if (rawAccessToken) {
      await this.denylistRawAccessToken(rawAccessToken);
    }
    if (!rawRefreshToken) return;

    const hash = this.hashToken(rawRefreshToken);
    const session = await this.prisma.staffSession.findFirst({
      where: { refreshTokenHash: hash },
    });
    if (!session) return;
    if (actorStaffId && session.staffId !== actorStaffId) return;

    await this.prisma.staffSession.update({
      where: { id: session.id },
      data: { isRevoked: true },
    });
    await this.denylistSessionId(session.id);

    await this.securityAudit.logEvent({
      action: 'ADMIN_LOGOUT',
      actorType: 'staff',
      actorId: session.staffId,
      targetEntity: 'staff_session',
      targetId: session.id,
    });
  }

  async revokeSessionById(
    staffId: string,
    sessionId: string,
    actorId: string,
  ): Promise<boolean> {
    const session = await this.prisma.staffSession.findFirst({
      where: { id: sessionId, staffId },
    });
    if (!session) return false;

    await this.prisma.staffSession.update({
      where: { id: session.id },
      data: { isRevoked: true },
    });
    await this.denylistSessionId(session.id);

    await this.securityAudit.logEvent({
      action: 'ADMIN_SESSION_REVOKED',
      actorType: 'staff',
      actorId,
      targetEntity: 'staff_session',
      targetId: session.id,
      metadata: { targetStaffId: staffId },
    });
    return true;
  }

  async revokeAllStaffSessions(
    staffId: string,
    actorId?: string,
  ): Promise<number> {
    const active = await this.prisma.staffSession.findMany({
      where: { staffId, isRevoked: false },
      select: { id: true },
    });

    const result = await this.prisma.staffSession.updateMany({
      where: { staffId, isRevoked: false },
      data: { isRevoked: true },
    });

    await Promise.all([
      ...active.map((s) => this.denylistSessionId(s.id)),
      this.denylistStaffTokensBeforeNow(staffId),
      this.invalidateStaffAuthCache(staffId),
    ]);

    await this.securityAudit.logEvent({
      action: 'ADMIN_ALL_SESSIONS_REVOKED',
      actorType: 'staff',
      actorId: actorId || staffId,
      targetEntity: 'staff_user',
      targetId: staffId,
      metadata: { revokedCount: result.count },
    });

    return result.count;
  }

  async revokeOtherStaffSessions(
    staffId: string,
    currentSessionId?: string,
  ): Promise<number> {
    const others = await this.prisma.staffSession.findMany({
      where: {
        staffId,
        isRevoked: false,
        ...(currentSessionId ? { id: { not: currentSessionId } } : {}),
      },
      select: { id: true },
    });

    const result = await this.prisma.staffSession.updateMany({
      where: {
        staffId,
        isRevoked: false,
        ...(currentSessionId ? { id: { not: currentSessionId } } : {}),
      },
      data: { isRevoked: true },
    });

    await Promise.all(others.map((s) => this.denylistSessionId(s.id)));
    return result.count;
  }

  async getStaffActiveSessions(staffId: string, currentSessionId?: string) {
    const rows = await this.prisma.staffSession.findMany({
      where: {
        staffId,
        isRevoked: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { lastUsedAt: 'desc' },
      select: {
        id: true,
        ipAddress: true,
        userAgent: true,
        mfaVerified: true,
        createdAt: true,
        lastUsedAt: true,
        expiresAt: true,
      },
    });
    return rows.map((row) => ({
      ...row,
      isCurrent: currentSessionId ? row.id === currentSessionId : false,
    }));
  }

  async denylistSessionId(
    sessionId: string,
    ttlSeconds = this.accessTokenTtlSeconds,
  ): Promise<void> {
    if (!sessionId || !this.redis) return;
    await this.redis.set(
      `admin:revoked:sid:${sessionId}`,
      '1',
      Math.max(1, ttlSeconds),
    );
  }

  async denylistJti(
    jti: string,
    ttlSeconds = this.accessTokenTtlSeconds,
  ): Promise<void> {
    if (!jti || !this.redis) return;
    await this.redis.set(
      `admin:revoked:jti:${jti}`,
      '1',
      Math.max(1, ttlSeconds),
    );
  }

  async denylistStaffTokensBeforeNow(
    staffId: string,
    ttlSeconds = this.accessTokenTtlSeconds,
  ): Promise<void> {
    if (!staffId || !this.redis) return;
    const nowEpoch = Math.floor(Date.now() / 1000);
    await this.redis.set(
      `admin:revoked:staff_before:${staffId}`,
      nowEpoch,
      Math.max(1, ttlSeconds),
    );
  }

  async invalidateStaffAuthCache(staffId: string): Promise<void> {
    if (!staffId || !this.redis) return;
    await this.redis.del(`admin:staff:auth:${staffId}`);
  }

  async denylistRawAccessToken(rawAccessToken: string): Promise<void> {
    if (!rawAccessToken || !this.redis) return;
    const secret = this.getAdminAccessSecret();
    if (!secret) return;
    try {
      const payload = this.jwtService.verify<{
        jti?: string;
        sid?: string;
        exp?: number;
      }>(rawAccessToken, {
        secret,
        issuer: this.jwtIssuer,
        audience: this.jwtAudience,
      });
      const nowEpoch = Math.floor(Date.now() / 1000);
      const remaining = payload.exp
        ? Math.max(1, payload.exp - nowEpoch)
        : this.accessTokenTtlSeconds;
      if (payload.jti) await this.denylistJti(payload.jti, remaining);
      if (payload.sid) await this.denylistSessionId(payload.sid, remaining);
    } catch {
      // Ignore expired/invalid tokens
    }
  }

  async isAccessTokenRevoked(payload: {
    sub: string;
    sid?: string;
    jti?: string;
    iat?: number;
  }): Promise<boolean> {
    if (!this.redis) return false;

    if (payload.jti) {
      const jtiRevoked = await this.redis.get(
        `admin:revoked:jti:${payload.jti}`,
      );
      if (jtiRevoked) return true;
    }

    if (payload.sid) {
      const sidRevoked = await this.redis.get(
        `admin:revoked:sid:${payload.sid}`,
      );
      if (sidRevoked) return true;
    }

    if (payload.sub) {
      const revokedBefore = await this.redis.get<number>(
        `admin:revoked:staff_before:${payload.sub}`,
      );
      if (
        typeof revokedBefore === 'number' &&
        (payload.iat ?? 0) < revokedBefore
      ) {
        return true;
      }
    }

    return false;
  }

  hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
