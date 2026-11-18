import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  SetMetadata,
  Optional,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../redis/redis.service';

export const RATE_LIMIT_KEY = 'rate_limit';
export interface RateLimitOptions {
  limit: number;
  ttlSeconds: number;
  anonymousLimit?: number;
  bucketKey?: string;
  limitEnvKey?: string;
  windowEnvKey?: string;
}

/**
 * Decorator to define custom rate limits per route handler.
 * Authenticated requests are keyed by userId; anonymous requests fall back to verified client IP
 * (resolved by Fastify's trusted proxy boundary, never raw spoofable X-Forwarded-For).
 *
 * Example: @RateLimit(10, 60) // 10 req/min per userId, 30 req/min per IP if anonymous
 */
export const RateLimit = (
  limit: number,
  ttlSeconds: number,
  options?: {
    anonymousLimit?: number;
    bucketKey?: string;
    limitEnvKey?: string;
    windowEnvKey?: string;
  },
) =>
  SetMetadata(RATE_LIMIT_KEY, {
    limit,
    ttlSeconds,
    anonymousLimit: options?.anonymousLimit,
    bucketKey: options?.bucketKey,
    limitEnvKey: options?.limitEnvKey,
    windowEnvKey: options?.windowEnvKey,
  });

@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly redisService: RedisService,
    @Optional() private readonly configService?: ConfigService,
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
      rateLimit.bucketKey ||
      request.routeOptions?.url ||
      request.raw?.url ||
      request.url ||
      'endpoint';
    const route = String(rawRoute).split('?')[0];

    const configuredLimit = rateLimit.limitEnvKey
      ? this.configService?.get<number>(rateLimit.limitEnvKey)
      : undefined;
    const configuredWindow = rateLimit.windowEnvKey
      ? this.configService?.get<number>(rateLimit.windowEnvKey)
      : undefined;

    const baseLimit =
      typeof configuredLimit === 'number' && configuredLimit > 0
        ? configuredLimit
        : rateLimit.limit;
    const windowSeconds =
      typeof configuredWindow === 'number' && configuredWindow > 0
        ? configuredWindow
        : rateLimit.ttlSeconds;

    let key: string;
    let effectiveLimit: number;

    if (userId) {
      // Authenticated caller: isolate quota strictly per userId so CGNAT users don't block each other
      key = `ratelimit:user:${userId}:${route}`;
      effectiveLimit = baseLimit;
    } else {
      // Anonymous caller: rely strictly on Fastify's verified request.ip (never spoofable X-Forwarded-For)
      const ip = request.ip || request.socket?.remoteAddress || '127.0.0.1';
      key = `ratelimit:ip:${ip}:${route}`;
      effectiveLimit =
        rateLimit.anonymousLimit !== undefined
          ? rateLimit.limitEnvKey && configuredLimit
            ? configuredLimit
            : rateLimit.anonymousLimit
          : baseLimit * 3;
    }

    const result = await this.redisService.checkRateLimit(
      key,
      effectiveLimit,
      windowSeconds,
    );
    const { allowed, remaining } = result;
    const retryAfterSeconds =
      typeof result.resetSeconds === 'number' && result.resetSeconds > 0
        ? result.resetSeconds
        : windowSeconds;

    const reply = context.switchToHttp().getResponse();
    if (reply?.header) {
      reply.header('X-RateLimit-Limit', effectiveLimit);
      reply.header('X-RateLimit-Remaining', remaining);
      reply.header('X-RateLimit-Reset', retryAfterSeconds);
      reply.header('X-RateLimit-Scope', userId ? 'user' : 'ip');
      if (!allowed) {
        reply.header('Retry-After', String(retryAfterSeconds));
      }
    }

    if (!allowed) {
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          error: 'Too Many Requests',
          message: `Too many requests. Please try again after ${retryAfterSeconds} seconds.`,
          details: { retryAfterSeconds },
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    return true;
  }
}
