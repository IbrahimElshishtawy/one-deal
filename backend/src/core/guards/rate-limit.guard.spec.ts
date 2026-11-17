import { ExecutionContext, HttpException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RateLimitGuard } from './rate-limit.guard';
import { RedisService } from '../redis/redis.service';

describe('RateLimitGuard (userId vs IP CGNAT Isolation)', () => {
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
        .mockResolvedValue({ allowed: true, remaining: 9 }),
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
      ip: '100.64.0.1', // shared CGNAT IP
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
  });

  it('should rate-limit anonymous requests by IP with CGNAT-tolerant multiplier (3x)', async () => {
    const { context, headers } = createMockContext({
      ip: '100.64.0.1',
      routeOptions: { url: '/api/v1/search' },
      headers: {},
    });

    const allowed = await guard.canActivate(context);

    expect(allowed).toBe(true);
    expect(redisService.checkRateLimit).toHaveBeenCalledWith(
      'ratelimit:ip:100.64.0.1:/api/v1/search',
      30,
      60,
    );
    expect(headers['X-RateLimit-Scope']).toBe('ip');
    expect(headers['X-RateLimit-Limit']).toBe(30);
  });

  it('should throw HTTP 429 when rate limit is exceeded', async () => {
    redisService.checkRateLimit.mockResolvedValueOnce({
      allowed: false,
      remaining: 0,
    });
    const { context } = createMockContext({
      user: { id: 'user-uuid-99' },
      routeOptions: { url: '/api/v1/listings' },
      headers: {},
    });

    await expect(guard.canActivate(context)).rejects.toThrow(HttpException);
  });
});
