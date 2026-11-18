import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../../core/database/prisma.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  tokenType: string;
  sessionId: string;
}

export interface ActiveSessionDto {
  id: string;
  userAgent: string | null;
  ipAddress: string;
  createdAt: Date;
  lastUsedAt: Date;
  expiresAt: Date;
  isCurrent?: boolean;
}

@Injectable()
export class SessionService {
  private readonly logger = new Logger(SessionService.name);
  private readonly accessTokenExpiry = '15m';
  private readonly refreshTokenExpiryDays = 30;
  private readonly jwtIssuer = 'deal-one.eg';
  private readonly jwtAudience = 'deal-one-mobile';

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly securityAudit: SecurityAuditService,
  ) {}

  /**
   * Mints an authoritative JWT access token and cryptographic refresh token session.
   */
  async createSession(
    userId: string,
    phone: string,
    role: string = 'USER',
    userAgent?: string,
    ipAddress?: string,
    deviceFingerprint?: string,
    existingFamilyId?: string,
  ): Promise<TokenPair> {
    const accessSecret = this.configService.get<string>('JWT_ACCESS_SECRET');
    if (!accessSecret || accessSecret.length < 16) {
      throw new Error(
        'JWT_ACCESS_SECRET must be at least 16 characters in configuration.',
      );
    }

    // 1. Mint cryptographically secure random Refresh Token (40 bytes hex)
    const rawRefreshToken = crypto.randomBytes(40).toString('hex');
    const refreshTokenHash = this.hashRefreshToken(rawRefreshToken);
    const expiresAt = new Date(
      Date.now() + this.refreshTokenExpiryDays * 24 * 60 * 60 * 1000,
    );
    const familyId = existingFamilyId || crypto.randomUUID();

    // 2. Persist session record
    const session = await this.prisma.userSession.create({
      data: {
        userId,
        familyId,
        refreshTokenHash,
        userAgent: userAgent?.substring(0, 500) || null,
        ipAddress: (ipAddress || '127.0.0.1').substring(0, 50),
        deviceFingerprint: deviceFingerprint?.substring(0, 255) || null,
        isRevoked: false,
        expiresAt,
      },
    });

    // 3. Mint short-lived JWT Access Token bound to session ID (sid)
    const accessToken = this.jwtService.sign(
      {
        sub: userId,
        phone,
        role,
        sid: session.id,
      },
      {
        secret: accessSecret,
        expiresIn: this.accessTokenExpiry,
        issuer: this.jwtIssuer,
        audience: this.jwtAudience,
      },
    );

    await this.securityAudit.logEvent({
      action: 'SESSION_CREATED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'UserSession',
      targetId: session.id,
      ipAddress,
      userAgent,
      metadata: { familyId, expiresAt },
    });

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn: 900, // 15 minutes in seconds
      tokenType: 'Bearer',
      sessionId: session.id,
    };
  }

  /**
   * Rotates refresh token with strict reuse detection and concurrency-safe invalidation.
   */
  async rotateRefreshToken(
    rawRefreshToken: string,
    userAgent?: string,
    ipAddress?: string,
    correlationId?: string,
  ): Promise<TokenPair> {
    if (!rawRefreshToken || typeof rawRefreshToken !== 'string') {
      throw new UnauthorizedException('Refresh token must be provided.');
    }

    const incomingHash = this.hashRefreshToken(rawRefreshToken);

    const session = await this.prisma.userSession.findFirst({
      where: { refreshTokenHash: incomingHash },
      include: { user: true },
    });

    if (!session) {
      await this.securityAudit.logEvent({
        action: 'REFRESH_TOKEN_NOT_FOUND',
        targetEntity: 'UserSession',
        ipAddress,
        userAgent,
        correlationId,
        metadata: { reason: 'UNKNOWN_TOKEN_HASH' },
      });
      throw new UnauthorizedException('Invalid or unrecognized refresh token.');
    }

    // --- CRITICAL REUSE DETECTION ---
    if (session.isRevoked) {
      this.logger.error(
        `🚨 SECURITY ALERT: Refresh token reuse detected for session [${session.id}] (Family: ${session.familyId}, User: ${session.userId})!`,
      );

      // Revoke the entire compromised session family or all sessions for this user
      await this.prisma.userSession.updateMany({
        where: {
          userId: session.userId,
          isRevoked: false,
          ...(session.familyId ? { familyId: session.familyId } : {}),
        },
        data: { isRevoked: true },
      });

      await this.securityAudit.logEvent({
        action: 'REFRESH_TOKEN_REUSE_DETECTED',
        actorType: 'user',
        actorId: session.userId,
        targetEntity: 'UserSession',
        targetId: session.id,
        ipAddress,
        userAgent,
        correlationId,
        metadata: {
          severity: 'HIGH_SECURITY_ALERT',
          compromisedFamilyId: session.familyId,
          revokedSessionsCount: 'FAMILY_REVOKED',
        },
      });

      throw new UnauthorizedException(
        'Security violation: Refresh token reuse detected. All active sessions in this family have been terminated. Please log in again.',
      );
    }

    // Check expiration
    if (session.expiresAt <= new Date()) {
      await this.prisma.userSession.update({
        where: { id: session.id },
        data: { isRevoked: true },
      });

      await this.securityAudit.logEvent({
        action: 'REFRESH_TOKEN_EXPIRED',
        actorType: 'user',
        actorId: session.userId,
        targetEntity: 'UserSession',
        targetId: session.id,
        ipAddress,
        userAgent,
        correlationId,
      });

      throw new UnauthorizedException(
        'Refresh token has expired. Please log in again.',
      );
    }

    // Check user account status
    if (!session.user || !session.user.isActive || session.user.deletedAt) {
      await this.prisma.userSession.update({
        where: { id: session.id },
        data: { isRevoked: true },
      });
      throw new UnauthorizedException(
        'User account is deactivated or suspended.',
      );
    }

    // Concurrency-safe atomic invalidation of the old refresh token
    const updateResult = await this.prisma.userSession.updateMany({
      where: {
        id: session.id,
        isRevoked: false,
      },
      data: {
        isRevoked: true,
        lastUsedAt: new Date(),
      },
    });

    if (updateResult.count === 0) {
      // Another concurrent request rotated this token milliseconds ago!
      await this.securityAudit.logEvent({
        action: 'CONCURRENT_REFRESH_COLLISION',
        actorType: 'user',
        actorId: session.userId,
        targetEntity: 'UserSession',
        targetId: session.id,
        ipAddress,
        userAgent,
        correlationId,
      });
      throw new UnauthorizedException(
        'Concurrent refresh conflict. Please sign in again.',
      );
    }

    // Issue rotated token pair linked to the same session family
    const newTokens = await this.createSession(
      session.user.id,
      session.user.phone,
      'USER',
      userAgent || session.userAgent || undefined,
      ipAddress || session.ipAddress,
      session.deviceFingerprint || undefined,
      session.familyId || session.id,
    );

    await this.securityAudit.logEvent({
      action: 'REFRESH_TOKEN_ROTATED',
      actorType: 'user',
      actorId: session.userId,
      targetEntity: 'UserSession',
      targetId: newTokens.sessionId,
      ipAddress,
      userAgent,
      correlationId,
      metadata: {
        previousSessionId: session.id,
        familyId: session.familyId,
      },
    });

    return newTokens;
  }

  /**
   * Revokes an active session by refresh token or session ID.
   */
  async revokeSessionByToken(
    rawRefreshToken: string,
    authenticatedUserId?: string,
    correlationId?: string,
  ): Promise<{ success: boolean; message: string }> {
    const hash = this.hashRefreshToken(rawRefreshToken);

    const session = await this.prisma.userSession.findFirst({
      where: { refreshTokenHash: hash },
    });

    if (!session) {
      return {
        success: true,
        message: 'Session already terminated or not found.',
      };
    }

    // Strict ownership verification
    if (authenticatedUserId && session.userId !== authenticatedUserId) {
      await this.securityAudit.logEvent({
        action: 'UNAUTHORIZED_SESSION_REVOCATION_ATTEMPT',
        actorType: 'user',
        actorId: authenticatedUserId,
        targetEntity: 'UserSession',
        targetId: session.id,
        correlationId,
        metadata: { ownerUserId: session.userId },
      });
      throw new UnauthorizedException(
        'You cannot revoke a session that does not belong to you.',
      );
    }

    await this.prisma.userSession.update({
      where: { id: session.id },
      data: { isRevoked: true },
    });

    await this.securityAudit.logEvent({
      action: 'SESSION_REVOKED',
      actorType: 'user',
      actorId: session.userId,
      targetEntity: 'UserSession',
      targetId: session.id,
      correlationId,
    });

    return {
      success: true,
      message: 'Active session revoked successfully.',
    };
  }

  /**
   * Revokes all active sessions belonging to the user.
   */
  async revokeAllUserSessions(
    userId: string,
    correlationId?: string,
  ): Promise<{ success: boolean; revokedCount: number }> {
    const result = await this.prisma.userSession.updateMany({
      where: {
        userId,
        isRevoked: false,
      },
      data: { isRevoked: true },
    });

    await this.securityAudit.logEvent({
      action: 'ALL_USER_SESSIONS_REVOKED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'User',
      targetId: userId,
      correlationId,
      metadata: { revokedCount: result.count },
    });

    return {
      success: true,
      revokedCount: result.count,
    };
  }

  /**
   * Revokes all active sessions belonging to the user except the current session (if known).
   */
  async revokeOtherUserSessions(
    userId: string,
    currentSessionId?: string,
    correlationId?: string,
  ): Promise<{ success: boolean; revokedCount: number }> {
    const result = await this.prisma.userSession.updateMany({
      where: {
        userId,
        isRevoked: false,
        ...(currentSessionId ? { id: { not: currentSessionId } } : {}),
      },
      data: { isRevoked: true },
    });

    await this.securityAudit.logEvent({
      action: 'OTHER_USER_SESSIONS_REVOKED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'User',
      targetId: userId,
      correlationId,
      metadata: {
        excludedSessionId: currentSessionId ?? null,
        revokedCount: result.count,
      },
    });

    return {
      success: true,
      revokedCount: result.count,
    };
  }

  /**
   * Retrieves active, non-expired sessions for the authenticated user.
   */
  async getUserActiveSessions(userId: string): Promise<ActiveSessionDto[]> {
    const sessions = await this.prisma.userSession.findMany({
      where: {
        userId,
        isRevoked: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { lastUsedAt: 'desc' },
      select: {
        id: true,
        userAgent: true,
        ipAddress: true,
        createdAt: true,
        lastUsedAt: true,
        expiresAt: true,
      },
    });

    return sessions;
  }

  /**
   * Computes SHA-256 hash of refresh token.
   */
  hashRefreshToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
