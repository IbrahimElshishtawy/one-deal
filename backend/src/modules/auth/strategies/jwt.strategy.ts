import { Injectable, UnauthorizedException, Optional } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../core/database/prisma.service';
import { SessionService } from '../services/session.service';

export interface JwtPayload {
  sub: string;
  phone: string;
  role: string;
  sid?: string;
  jti?: string;
  iss?: string;
  aud?: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    @Optional() private readonly sessionService?: SessionService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_ACCESS_SECRET'),
      issuer: 'deal-one.eg',
      audience: 'deal-one-mobile',
      algorithms: ['HS256'],
    });
  }

  async validate(payload: JwtPayload) {
    if (!payload.sub || !payload.phone) {
      throw new UnauthorizedException('JWT token contains invalid claims.');
    }

    if (this.sessionService) {
      const revoked = await this.sessionService.isAccessTokenRevoked(payload);
      if (revoked) {
        throw new UnauthorizedException(
          'Access token has been revoked. Please sign in again.',
        );
      }
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        phone: true,
        fullName: true,
        isActive: true,
        deletedAt: true,
      },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedException(
        'User account no longer exists or is inactive',
      );
    }

    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      role: payload.role || 'USER',
      status: user.isActive ? 'ACTIVE' : 'SUSPENDED',
      sessionId: payload.sid,
    };
  }
}
