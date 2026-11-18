import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

@Injectable()
export class MetricsAuthGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const configuredToken = (
      this.configService.get<string>('METRICS_AUTH_TOKEN', '') || ''
    ).trim();
    const nodeEnv = this.configService.get<string>('NODE_ENV', 'development');

    if (configuredToken.length > 0) {
      const providedToken = this.extractToken(request);
      if (
        !providedToken ||
        !this.constantTimeEquals(providedToken, configuredToken)
      ) {
        throw new UnauthorizedException(
          'Valid metrics authentication token is required.',
        );
      }
      return true;
    }

    // No METRICS_AUTH_TOKEN configured: fail closed for external traffic
    const ip = String(request.ip || request.socket?.remoteAddress || '').trim();

    if (nodeEnv === 'production') {
      if (this.isLoopbackIp(ip)) {
        return true;
      }
      throw new UnauthorizedException(
        'Metrics endpoint requires authentication in production.',
      );
    }

    // In development/test, permit loopback or RFC1918 private network scraping
    if (this.isLoopbackIp(ip) || this.isPrivateIp(ip)) {
      return true;
    }

    throw new UnauthorizedException(
      'Metrics endpoint is restricted to internal network or authenticated scrapers.',
    );
  }

  private extractToken(request: any): string | null {
    const authHeader = request.headers?.authorization;
    if (typeof authHeader === 'string') {
      if (authHeader.toLowerCase().startsWith('bearer ')) {
        return authHeader.slice(7).trim();
      }
    }
    const customHeader = request.headers?.['x-metrics-token'];
    if (typeof customHeader === 'string' && customHeader.trim().length > 0) {
      return customHeader.trim();
    }
    return null;
  }

  private constantTimeEquals(a: string, b: string): boolean {
    const hashA = crypto.createHash('sha256').update(a).digest();
    const hashB = crypto.createHash('sha256').update(b).digest();
    return crypto.timingSafeEqual(hashA, hashB);
  }

  private isLoopbackIp(ip: string): boolean {
    return (
      ip === '127.0.0.1' ||
      ip === '::1' ||
      ip === '::ffff:127.0.0.1' ||
      ip === 'localhost'
    );
  }

  private isPrivateIp(ip: string): boolean {
    const normalized = ip.startsWith('::ffff:') ? ip.slice(7) : ip;
    if (normalized.startsWith('10.')) return true;
    if (normalized.startsWith('192.168.')) return true;
    const match172 = /^172\.(\d+)\./.exec(normalized);
    if (match172) {
      const octet = Number(match172[1]);
      if (octet >= 16 && octet <= 31) return true;
    }
    return false;
  }
}
