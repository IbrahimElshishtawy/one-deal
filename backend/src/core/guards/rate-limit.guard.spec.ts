import { ExecutionContext, HttpException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RateLimitGuard } from './rate-limit.guard';
import { RedisService } from '../redis/redis.service';

describe('RateLimitGuard (userId vs Verified IP & Retry-After)', () => {
  let guard: RateLimitGuard;
  let reflector: jest.Mocked<Reflector>;
  let redisService: jest.Mocked<RedisService>;

  beforeEach(() => {
    reflector = {
      getAllAndOverride: jest
        .fn()
        .mockReturnValue({ limit: 10, ttlSeconds: 60 }),
    } as any;

    redisService = {
      checkRateLimit: jest
        .fn()
        .mockResolvedValue({ allowed: true, remaining: 9, resetSeconds: 58 }),
    } as any;

    guard = new RateLimitGuard(reflector, redisService);
  });

  function createMockContext(request: Record<string, any>): {
    context: ExecutionContext;
    headers: Record<string, any>;
  } {
    const headers: Record<string, any> = {};
    const reply = {
      header: jest.fn((k: string, v: any) => {
        headers[k] = v;
      }),
    };
    const context = {
      getHandler: jest.fn(),
      getClass: jest.fn(),
      switchToHttp: () => ({
        getRequest: () => request,
        getResponse: () => reply,
      }),
    } as any;
    return { context, headers };
  }

  it('should rate-limit authenticated requests by userId instead of IP', async () => {
    const { context, headers } = createMockContext({
      user: { id: 'user-uuid-42' },
      ip: '100.64.0.1',
      routeOptions: { url: '/api/v1/listings' },
      headers: {},
    });

    const allowed = await guard.canActivate(context);

    expect(allowed).toBe(true);
    expect(redisService.checkRateLimit).toHaveBeenCalledWith(
      'ratelimit:user:user-uuid-42:/api/v1/listings',
      10,
      60,
    );
    expect(headers['X-RateLimit-Scope']).toBe('user');
    expect(headers['X-RateLimit-Limit']).toBe(10);
    expect(headers['X-RateLimit-Reset']).toBe(58);
  });

  it('should rate-limit anonymous requests by verified request.ip and ignore spoofed X-Forwarded-For', async () => {
    const { context, headers } = createMockContext({
      ip: '198.51.100.10',
      routeOptions: { url: '/api/v1/search' },
      headers: {
        'x-forwarded-for': '203.0.113.99, 198.51.100.10',
      },
    });

    const allowed = await guard.canActivate(context);

    expect(allowed).toBe(true);
    expect(redisService.checkRateLimit).toHaveBeenCalledWith(
      'ratelimit:ip:198.51.100.10:/api/v1/search',
      30,
      60,
    );
    expect(headers['X-RateLimit-Scope']).toBe('ip');
    expect(headers['X-RateLimit-Limit']).toBe(30);
  });

  it('should throw HTTP 429 and set Retry-After header when rate limit is exceeded', async () => {
    redisService.checkRateLimit.mockResolvedValueOnce({
      allowed: false,
      remaining: 0,
      resetSeconds: 42,
    });
    const { context, headers } = createMockContext({
      user: { id: 'user-uuid-99' },
      routeOptions: { url: '/api/v1/listings' },
      headers: {},
    });

    await expect(guard.canActivate(context)).rejects.toThrow(HttpException);
    expect(headers['Retry-After']).toBe('42');
    expect(headers['X-RateLimit-Remaining']).toBe(0);
  });
});
