import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { StaffSessionService } from '../services/staff-session.service';
import { ADMIN_PERMISSIONS } from '../constants/admin-permissions.constant';
import { AuthenticatedStaff } from '../types/authenticated-staff.type';

@Injectable()
export class AdminJwtAuthGuard implements CanActivate {
  private readonly jwtIssuer = 'deal-one.eg';
  private readonly adminAudience = 'deal-one-admin';
  private readonly mobileAudience = 'deal-one-mobile';

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly staffSessionService: StaffSessionService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader =
      request?.headers?.authorization || request?.headers?.Authorization;

    if (!authHeader || typeof authHeader !== 'string') {
      throw new UnauthorizedException(
        'Admin authentication token is missing, invalid, or expired',
      );
    }

    const match = authHeader.match(/^Bearer\s+(.+)$/i);
    if (!match || !match[1]) {
      throw new UnauthorizedException(
        'Admin authentication token is missing, invalid, or expired',
      );
    }
    const token = match[1].trim();

    // 1. Primary path: verify dedicated Admin JWT (`audience: 'deal-one-admin'`)
    const adminSecret = this.staffSessionService.getAdminAccessSecret();
    try {
      const payload = this.jwtService.verify<{
        sub: string;
        actorType?: string;
        email?: string;
        roleId?: number;
        role?: string;
        sid?: string;
        jti?: string;
        iat?: number;
        mfa?: boolean;
      }>(token, {
        secret: adminSecret,
        issuer: this.jwtIssuer,
        audience: this.adminAudience,
        algorithms: ['HS256'],
      });

      if (!payload.sub || payload.actorType !== 'staff') {
        throw new UnauthorizedException('Invalid admin token claims');
      }

      const revoked = await this.staffSessionService.isAccessTokenRevoked(payload);
      if (revoked) {
        throw new UnauthorizedException(
          'Admin session has been revoked. Please sign in again.',
        );
      }

      const staff = await this.loadActiveStaff(payload.sub);
      if (!staff) {
        throw new UnauthorizedException(
          'Admin account no longer exists, is suspended, or has been disabled',
        );
      }

      const permissions = Array.isArray(staff.role?.permissions)
        ? (staff.role.permissions as string[])
        : [];

      const authenticatedStaff: AuthenticatedStaff = {
        id: staff.id,
        staffId: staff.id,
        actorType: 'staff',
        email: staff.email,
        fullName: staff.fullName,
        roleId: staff.roleId,
        role: staff.role.name,
        permissions,
        sessionId: payload.sid,
        mfaVerified: Boolean(payload.mfa),
      };

      request.user = authenticatedStaff;
      return true;
    } catch (err) {
      if (err instanceof UnauthorizedException) {
        throw err;
      }
      // Fall through to check whether a mobile token was sent
    }

    // 2. Mobile JWT check:
    //    - Marketplace USER tokens are authenticated as actorType='user' with permissions=[]
    //      so PermissionsGuard strictly rejects with 403 Forbidden (preserving RBAC contract).
    //    - In production, mobile tokens can NEVER elevate to admin permissions.
    const mobileSecret = this.configService.get<string>('JWT_ACCESS_SECRET', '');
    if (mobileSecret) {
      try {
        const mobilePayload = this.jwtService.verify<{
          sub: string;
          phone?: string;
          role?: string;
          sid?: string;
          jti?: string;
          iat?: number;
        }>(token, {
          secret: mobileSecret,
          issuer: this.jwtIssuer,
          audience: this.mobileAudience,
          algorithms: ['HS256'],
        });

        const mobileRevoked = await this.isMobileTokenRevoked(mobilePayload);
        if (mobileRevoked) {
          throw new UnauthorizedException('Access token has been revoked.');
        }

        const user = await this.prisma.user.findUnique({
          where: { id: mobilePayload.sub },
          select: { id: true, fullName: true, isActive: true, deletedAt: true },
        });
        if (!user || !user.isActive || user.deletedAt) {
          throw new UnauthorizedException(
            'User account no longer exists or is inactive',
          );
        }

        const nodeEnv = this.configService.get<string>('NODE_ENV', 'development');
        let permissions: string[] = [];
        if (nodeEnv !== 'production') {
          if (mobilePayload.role === 'SUPER_ADMIN') {
            permissions = [...ADMIN_PERMISSIONS];
          } else if (mobilePayload.role === 'MODERATOR') {
            permissions = [
              'listings.read',
              'listings.approve',
              'listings.reject',
              'reports.read',
              'reports.resolve',
              'verification.read',
              'verification.approve',
              'verification.reject',
            ];
          }
        }

        const fallbackActor: AuthenticatedStaff = {
          id: user.id,
          staffId: null,
          actorType: 'user',
          email: '',
          fullName: user.fullName,
          roleId: null,
          role: mobilePayload.role || 'USER',
          permissions,
          sessionId: mobilePayload.sid,
          mfaVerified: false,
        };
        request.user = fallbackActor;
        return true;
      } catch (mobileErr) {
        if (mobileErr instanceof UnauthorizedException) {
          throw mobileErr;
        }
      }
    }

    throw new UnauthorizedException(
      'Admin authentication token is missing, invalid, or expired',
    );
  }

  private async loadActiveStaff(staffId: string) {
    const cacheKey = `admin:staff:auth:${staffId}`;
    const cached = await this.redis?.get<{
      id: string;
      email: string;
      fullName: string;
      roleId: number;
      isActive: boolean;
      status: string;
      deletedAt: string | null;
      expiresAt: string | null;
      role: { id: number; name: string; permissions: string[] };
    }>(cacheKey);

    if (cached) {
      if (
        !cached.isActive ||
        cached.status !== 'active' ||
        cached.deletedAt ||
        (cached.expiresAt && new Date(cached.expiresAt) <= new Date())
      ) {
        return null;
      }
      return cached;
    }

    const staff = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      select: {
        id: true,
        email: true,
        fullName: true,
        roleId: true,
        isActive: true,
        status: true,
        deletedAt: true,
        expiresAt: true,
        role: {
          select: {
            id: true,
            name: true,
            permissions: true,
          },
        },
      },
    });

    if (
      !staff ||
      !staff.isActive ||
      staff.status !== 'active' ||
      staff.deletedAt ||
      (staff.expiresAt && staff.expiresAt <= new Date())
    ) {
      return null;
    }

    await this.redis?.set(cacheKey, staff, 60);
    return staff;
  }

  private async isMobileTokenRevoked(payload: {
    sub: string;
    sid?: string;
    jti?: string;
    iat?: number;
  }): Promise<boolean> {
    if (!this.redis) return false;
    if (payload.jti && (await this.redis.get(`auth:revoked:jti:${payload.jti}`))) {
      return true;
    }
    if (payload.sid && (await this.redis.get(`auth:revoked:sid:${payload.sid}`))) {
      return true;
    }
    if (payload.sub) {
      const revokedBefore = await this.redis.get<number>(
        `auth:revoked:user_before:${payload.sub}`,
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
}
