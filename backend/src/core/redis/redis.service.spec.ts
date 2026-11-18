import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { RedisService } from './redis.service';

describe('RedisService', () => {
  let service: RedisService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RedisService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string, defaultValue: any) => defaultValue),
          },
        },
      ],
    }).compile();

    service = module.get<RedisService>(RedisService);
    await service.onModuleInit();
    await service.del('test_key');
    await service.del('to_delete');
    await service.del('view_counter');
    await service.del('rate_test');
  });

  afterEach(async () => {
    await service.onModuleDestroy();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should store and retrieve data in in-memory fallback', async () => {
    await service.set('test_key', { hello: 'world' });
    const result = await service.get<{ hello: string }>('test_key');
    expect(result).toEqual({ hello: 'world' });
  });

  it('should return null for non-existent keys', async () => {
    const result = await service.get('non_existent');
    expect(result).toBeNull();
  });

  it('should delete keys from cache', async () => {
    await service.set('to_delete', 123);
    await service.del('to_delete');
    const result = await service.get('to_delete');
    expect(result).toBeNull();
  });

  it('should atomically increment counters', async () => {
    const val1 = await service.incr('view_counter');
    const val2 = await service.incr('view_counter');
    expect(val1).toBe(1);
    expect(val2).toBe(2);
  });

  it('should enforce rate limits accurately with resetSeconds in fallback mode', async () => {
    const r1 = await service.checkRateLimit('rate_test', 2, 60);
    const r2 = await service.checkRateLimit('rate_test', 2, 60);
    const r3 = await service.checkRateLimit('rate_test', 2, 60);

    expect(r1).toEqual({ allowed: true, remaining: 1, resetSeconds: 60 });
    expect(r2.allowed).toBe(true);
    expect(r2.remaining).toBe(0);
    expect(r2.resetSeconds).toBeLessThanOrEqual(60);
    expect(r3.allowed).toBe(false);
    expect(r3.remaining).toBe(0);
  });

  it('should execute atomic Lua script on connected Redis client without separate INCR/EXPIRE calls', async () => {
    let counter = 0;
    let ttl = -2;
    const mockEval = jest.fn(
      async (
        _script: string,
        _numKeys: number,
        _key: string,
        windowArg: string,
      ) => {
        counter += 1;
        if (counter === 1 || ttl === -1) {
          ttl = Number(windowArg);
        } else {
          ttl = Math.max(1, ttl - 5);
        }
        return [counter, ttl];
      },
    );
    const mockIncr = jest.fn();
    const mockExpire = jest.fn();

    (service as any).cacheClient = {
      eval: mockEval,
      incr: mockIncr,
      expire: mockExpire,
      quit: jest.fn().mockResolvedValue('OK'),
      disconnect: jest.fn(),
    };
    (service as any).isCacheHealthy = true;

    // Concurrent requests
    const results = await Promise.all([
      service.checkRateLimit('atomic:key', 3, 120),
      service.checkRateLimit('atomic:key', 3, 120),
      service.checkRateLimit('atomic:key', 3, 120),
      service.checkRateLimit('atomic:key', 3, 120),
    ]);

    expect(mockEval).toHaveBeenCalledTimes(4);
    expect(mockIncr).not.toHaveBeenCalled();
    expect(mockExpire).not.toHaveBeenCalled();

    // First initializes TTL=120; subsequent preserve/decrement existing TTL without resetting to 120
    expect(results[0]).toEqual({
      allowed: true,
      remaining: 2,
      resetSeconds: 120,
    });
    expect(results[1]).toEqual({
      allowed: true,
      remaining: 1,
      resetSeconds: 115,
    });
    expect(results[2]).toEqual({
      allowed: true,
      remaining: 0,
      resetSeconds: 110,
    });
    expect(results[3]).toEqual({
      allowed: false,
      remaining: 0,
      resetSeconds: 105,
    });
  });

  it('should fall back safely on Redis error and recover when Redis returns', async () => {
    const mockEval = jest
      .fn()
      .mockRejectedValueOnce(new Error('ECONNRESET'))
      .mockRejectedValueOnce(new Error('ECONNRESET'))
      .mockResolvedValueOnce([1, 60]);

    (service as any).cacheClient = {
      eval: mockEval,
      quit: jest.fn().mockResolvedValue('OK'),
      disconnect: jest.fn(),
    };
    (service as any).isCacheHealthy = true;

    // Redis fails -> bounded in-memory fallback still enforces limit
    const f1 = await service.checkRateLimit('recovery:key', 1, 60);
    const f2 = await service.checkRateLimit('recovery:key', 1, 60);
    expect(f1.allowed).toBe(true);
    expect(f2.allowed).toBe(false);

    // Redis recovers -> uses distributed Redis again
    const recovered = await service.checkRateLimit('recovery:key', 1, 60);
    expect(recovered).toEqual({
      allowed: true,
      remaining: 0,
      resetSeconds: 60,
    });
  });

  it('should support setIfNotExists idempotency guard', async () => {
    const first = await service.setIfNotExists('idem:event:1', '1', 60);
    const second = await service.setIfNotExists('idem:event:1', '1', 60);
    expect(first).toBe(true);
    expect(second).toBe(false);
  });
});
