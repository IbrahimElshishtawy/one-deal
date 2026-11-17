import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RedisService } from '../redis/redis.service';

export const RATE_LIMIT_KEY = 'rate_limit';
export interface RateLimitOptions {
  limit: number;
  ttlSeconds: number;
  anonymousLimit?: number;
}

/**
 * Decorator to define custom rate limits per route handler.
 * Authenticated requests are keyed by userId; anonymous requests fall back to IP
 * with a higher CGNAT-safe limit (defaults to 3x `limit` unless `anonymousLimit` is set).
 *
 * Example: @RateLimit(10, 60) // 10 req/min per userId, 30 req/min per IP if anonymous
 */
export const RateLimit = (
  limit: number,
  ttlSeconds: number,
  options?: { anonymousLimit?: number },
) =>
  SetMetadata(RATE_LIMIT_KEY, {
    limit,
    ttlSeconds,
    anonymousLimit: options?.anonymousLimit,
  });

@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly redisService: RedisService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const rateLimit = this.reflector.getAllAndOverride<RateLimitOptions>(
      RATE_LIMIT_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!rateLimit) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const userId = request.user?.id as string | undefined;
    const rawRoute =
      request.routeOptions?.url ||
      request.raw?.url ||
      request.url ||
      'endpoint';
    const route = String(rawRoute).split('?')[0];

    let key: string;
    let effectiveLimit: number;

    if (userId) {
      // Authenticated caller: isolate quota strictly per userId so CGNAT users don't block each other
      key = `ratelimit:user:${userId}:${route}`;
      effectiveLimit = rateLimit.limit;
    } else {
      // Anonymous caller: key by client IP with CGNAT-tolerant ceiling
      const ip =
        request.headers?.['x-forwarded-for']?.toString().split(',')[0].trim() ||
        request.ip ||
        request.socket?.remoteAddress ||
        '127.0.0.1';
      key = `ratelimit:ip:${ip}:${route}`;
      effectiveLimit = rateLimit.anonymousLimit ?? rateLimit.limit * 3;
    }

    const { allowed, remaining } = await this.redisService.checkRateLimit(
      key,
      effectiveLimit,
      rateLimit.ttlSeconds,
    );

    const reply = context.switchToHttp().getResponse();
    if (reply?.header) {
      reply.header('X-RateLimit-Limit', effectiveLimit);
      reply.header('X-RateLimit-Remaining', remaining);
      reply.header('X-RateLimit-Scope', userId ? 'user' : 'ip');
    }

    if (!allowed) {
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          error: 'Too Many Requests',
          message: `Too many requests. Please try again after ${rateLimit.ttlSeconds} seconds.`,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    return true;
  }
}
