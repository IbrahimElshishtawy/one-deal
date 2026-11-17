import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import Redis, { RedisOptions } from 'ioredis';

/**
 * RedisService manages the Dual-Redis topology for Deal One:
 * 1. Redis Cache (Port 6379): Fast LRU cache, session tracking, rate limiting (allkeys-lru).
 * 2. Redis Queue (Port 6380): Dedicated message broker for BullMQ async jobs & Outbox (noeviction, AOF).
 *
 * Conforms to ADR-013 and Phase 02 Dual Topology requirements.
 */
@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);

  // Dual Clients
  private cacheClient: Redis | null = null;
  private queueClient: Redis | null = null;

  private isCacheHealthy = false;
  private isQueueHealthy = false;

  private readonly inMemoryFallback = new Map<
    string,
    { value: string; expiresAt?: number }
  >();

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit() {
    await Promise.all([this.initCacheClient(), this.initQueueClient()]);
  }

  private resolveCacheTarget(): {
    url?: string;
    host: string;
    port: number;
    password?: string;
  } {
    const url =
      this.configService.get<string>('REDIS_CACHE_URL') ||
      this.configService.get<string>('REDIS_URL');
    if (url) {
      return { url, host: '', port: 0 };
    }
    const host =
      this.configService.get<string>('REDIS_CACHE_HOST') ||
      this.configService.get<string>('REDISHOST') ||
      this.configService.get<string>('REDIS_HOST', 'localhost');
    const port =
      this.configService.get<number>('REDIS_CACHE_PORT') ||
      this.configService.get<number>('REDISPORT') ||
      this.configService.get<number>('REDIS_PORT', 6379);
    const password =
      this.configService.get<string>('REDIS_CACHE_PASSWORD') ||
      this.configService.get<string>('REDISPASSWORD') ||
      this.configService.get<string>('REDIS_PASSWORD', '');

    return { host, port, password: password || undefined };
  }

  private resolveQueueTarget(): {
    url?: string;
    host: string;
    port: number;
    password?: string;
  } {
    const url =
      this.configService.get<string>('REDIS_QUEUE_URL') ||
      this.configService.get<string>('REDIS_URL');
    if (url) {
      return { url, host: '', port: 0 };
    }
    const host =
      this.configService.get<string>('REDIS_QUEUE_HOST') ||
      this.configService.get<string>('REDISHOST', 'localhost');
    const port =
      this.configService.get<number>('REDIS_QUEUE_PORT') ||
      this.configService.get<number>('REDISPORT', 6380);
    const password =
      this.configService.get<string>('REDIS_QUEUE_PASSWORD') ||
      this.configService.get<string>('REDISPASSWORD', '');

    return { host, port, password: password || undefined };
  }

  private async initCacheClient(): Promise<void> {
    const target = this.resolveCacheTarget();
    const displayEndpoint = target.url
      ? 'Cloud Redis URL'
      : `${target.host}:${target.port}`;

    try {
      const options: RedisOptions = {
        lazyConnect: true,
        maxRetriesPerRequest: 2,
        retryStrategy: (times) => {
          if (times > 5) {
            this.logger.warn(
              `⚠️ Redis Cache retry limit reached (${times}) at ${displayEndpoint}`,
            );
            return null;
          }
          return Math.min(times * 200, 2000);
        },
      };

      if (target.url) {
        this.cacheClient = new Redis(target.url, options);
      } else {
        this.cacheClient = new Redis({
          host: target.host,
          port: target.port,
          password: target.password,
          ...options,
        });
      }

      this.cacheClient.on('connect', () => {
        this.isCacheHealthy = true;
        this.logger.log(`⚡ Connected to Redis Cache at ${displayEndpoint}`);
      });

      this.cacheClient.on('error', (err) => {
        this.isCacheHealthy = false;
        this.logger.warn(`Redis Cache connection notice: ${err.message}`);
      });

      this.cacheClient.on('close', () => {
        this.isCacheHealthy = false;
      });

      await this.cacheClient.connect().catch((err) => {
        this.isCacheHealthy = false;
        this.logger.warn(
          `Redis Cache not accessible at startup (${err.message}) at ${displayEndpoint}.`,
        );
      });
    } catch (err: any) {
      this.isCacheHealthy = false;
      this.logger.error(`Redis Cache initialization failed: ${err.message}`);
    }
  }

  private async initQueueClient(): Promise<void> {
    const target = this.resolveQueueTarget();
    const displayEndpoint = target.url
      ? 'Cloud Redis URL'
      : `${target.host}:${target.port}`;

    try {
      const options: RedisOptions = {
        lazyConnect: true,
        maxRetriesPerRequest: null, // BullMQ requirement
        retryStrategy: (times) => {
          if (times > 5) {
            this.logger.warn(
              `⚠️ Redis Queue retry limit reached (${times}) at ${displayEndpoint}`,
            );
            return null;
          }
          return Math.min(times * 200, 2000);
        },
      };

      if (target.url) {
        this.queueClient = new Redis(target.url, options);
      } else {
        this.queueClient = new Redis({
          host: target.host,
          port: target.port,
          password: target.password,
          ...options,
        });
      }

      this.queueClient.on('connect', () => {
        this.isQueueHealthy = true;
        this.logger.log(`📦 Connected to Redis Queue at ${displayEndpoint}`);
      });

      this.queueClient.on('error', (err) => {
        this.isQueueHealthy = false;
        this.logger.warn(`Redis Queue connection notice: ${err.message}`);
      });

      this.queueClient.on('close', () => {
        this.isQueueHealthy = false;
      });

      await this.queueClient.connect().catch((err) => {
        this.isQueueHealthy = false;
        this.logger.warn(
          `Redis Queue not accessible at startup (${err.message}) at ${displayEndpoint}.`,
        );
      });
    } catch (err: any) {
      this.isQueueHealthy = false;
      this.logger.error(`Redis Queue initialization failed: ${err.message}`);
    }
  }

  async onModuleDestroy() {
    const disconnects: Promise<any>[] = [];

    if (this.cacheClient) {
      disconnects.push(
        this.cacheClient.quit().catch(() => this.cacheClient?.disconnect()),
      );
    }
    if (this.queueClient) {
      disconnects.push(
        this.queueClient.quit().catch(() => this.queueClient?.disconnect()),
      );
    }

    await Promise.allSettled(disconnects);
    this.isCacheHealthy = false;
    this.isQueueHealthy = false;
  }

  /**
   * Returns dedicated ioredis client for Redis Cache.
   */
  getCacheClient(): Redis | null {
    return this.cacheClient;
  }

  /**
   * Returns dedicated ioredis client for Redis Queue (BullMQ broker).
   */
  getQueueClient(): Redis | null {
    return this.queueClient;
  }

  /**
   * Returns connection options formatted for BullMQ Queue and Worker constructors.
   */
  getQueueConnectionOptions(): RedisOptions {
    const target = this.resolveQueueTarget();
    if (target.url) {
      try {
        const parsed = new URL(target.url);
        return {
          host: parsed.hostname,
          port: Number(parsed.port) || 6379,
          username: parsed.username || undefined,
          password: parsed.password || undefined,
          maxRetriesPerRequest: null,
        };
      } catch {
        // Fallback to default if URL parsing fails
      }
    }

    return {
      host: target.host,
      port: target.port,
      password: target.password || undefined,
      maxRetriesPerRequest: null, // Required by BullMQ
    };
  }

  /**
   * Real ping on Redis Cache (Port 6379).
   */
  async pingCache(): Promise<boolean> {
    if (!this.cacheClient || !this.isCacheHealthy) return false;
    try {
      const pong = await this.cacheClient.ping();
      return pong === 'PONG';
    } catch {
      return false;
    }
  }

  /**
   * Real ping on Redis Queue (Port 6380).
   */
  async pingQueue(): Promise<boolean> {
    if (!this.queueClient || !this.isQueueHealthy) return false;
    try {
      const pong = await this.queueClient.ping();
      return pong === 'PONG';
    } catch {
      return false;
    }
  }

  /**
   * Legacy and standard cache helper methods.
   */
  async get<T = any>(key: string): Promise<T | null> {
    if (this.isCacheHealthy && this.cacheClient) {
      try {
        const raw = await this.cacheClient.get(key);
        if (!raw) return null;
        return JSON.parse(raw) as T;
      } catch (err) {
        this.logger.error(
          `Error reading from Redis Cache [${key}]: ${(err as Error).message}`,
        );
      }
    }

    // Controlled fallback for test mode only
    if (this.configService.get('NODE_ENV') === 'production') {
      return null;
    }

    const entry = this.inMemoryFallback.get(key);
    if (!entry) return null;
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.inMemoryFallback.delete(key);
      return null;
    }
    return JSON.parse(entry.value) as T;
  }

  async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
    const serialized = JSON.stringify(value);

    if (this.isCacheHealthy && this.cacheClient) {
      try {
        if (ttlSeconds && ttlSeconds > 0) {
          await this.cacheClient.set(key, serialized, 'EX', ttlSeconds);
        } else {
          await this.cacheClient.set(key, serialized);
        }
        return;
      } catch (err) {
        this.logger.error(
          `Error writing to Redis Cache [${key}]: ${(err as Error).message}`,
        );
      }
    }

    if (this.configService.get('NODE_ENV') === 'production') {
      return;
    }

    const expiresAt =
      ttlSeconds && ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : undefined;
    this.inMemoryFallback.set(key, { value: serialized, expiresAt });
  }

  async del(key: string): Promise<void> {
    if (this.isCacheHealthy && this.cacheClient) {
      try {
        await this.cacheClient.del(key);
      } catch (err) {
        this.logger.error(
          `Error deleting from Redis Cache [${key}]: ${(err as Error).message}`,
        );
      }
    }
    this.inMemoryFallback.delete(key);
  }

  async incr(key: string): Promise<number> {
    if (this.isCacheHealthy && this.cacheClient) {
      try {
        return await this.cacheClient.incr(key);
      } catch (err) {
        this.logger.error(
          `Error incrementing Redis Cache [${key}]: ${(err as Error).message}`,
        );
      }
    }

    const current = (await this.get<number>(key)) || 0;
    const next = current + 1;
    await this.set(key, next);
    return next;
  }

  async checkRateLimit(
    key: string,
    maxRequests: number,
    windowSeconds: number,
  ): Promise<{ allowed: boolean; remaining: number }> {
    const current = await this.incr(key);
    if (current === 1) {
      if (this.isCacheHealthy && this.cacheClient) {
        await this.cacheClient.expire(key, windowSeconds);
      }
    }

    const allowed = current <= maxRequests;
    const remaining = Math.max(0, maxRequests - current);
    return { allowed, remaining };
  }

  isRedisConnected(): boolean {
    return this.isCacheHealthy;
  }

  isCacheClientConnected(): boolean {
    return this.isCacheHealthy;
  }

  isQueueClientConnected(): boolean {
    return this.isQueueHealthy;
  }

  /**
   * Acquires a distributed lock via Redis SET NX EX.
   * Returns an ownership lock token if acquired, or null if already locked.
   */
  async acquireLock(key: string, ttlSeconds: number): Promise<string | null> {
    const token = crypto.randomUUID();
    const lockKey = `lock:${key}`;

    if (this.isCacheHealthy && this.cacheClient) {
      try {
        const result = await this.cacheClient.set(
          lockKey,
          token,
          'EX',
          ttlSeconds,
          'NX',
        );
        return result === 'OK' ? token : null;
      } catch (err) {
        this.logger.warn(
          `Error acquiring Redis lock [${lockKey}]: ${(err as Error).message}`,
        );
      }
    }

    if (this.configService.get('NODE_ENV') === 'production') {
      return null;
    }

    const existing = this.inMemoryFallback.get(lockKey);
    if (existing && (!existing.expiresAt || Date.now() < existing.expiresAt)) {
      return null;
    }

    this.inMemoryFallback.set(lockKey, {
      value: token,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
    return token;
  }

  /**
   * Releases a distributed lock only if the caller owns the matching token.
   */
  async releaseLock(key: string, token: string): Promise<void> {
    const lockKey = `lock:${key}`;

    if (this.isCacheHealthy && this.cacheClient) {
      try {
        const luaScript = `
          if redis.call("get", KEYS[1]) == ARGV[1] then
            return redis.call("del", KEYS[1])
          else
            return 0
          end
        `;
        await this.cacheClient.eval(luaScript, 1, lockKey, token);
        return;
      } catch (err) {
        this.logger.warn(
          `Error releasing Redis lock [${lockKey}]: ${(err as Error).message}`,
        );
      }
    }

    const existing = this.inMemoryFallback.get(lockKey);
    if (existing && existing.value === token) {
      this.inMemoryFallback.delete(lockKey);
    }
  }

  /**
   * Publishes a real-time event message to a Redis Pub/Sub channel.
   */
  async publish(channel: string, message: string): Promise<void> {
    if (this.isCacheHealthy && this.cacheClient) {
      try {
        await this.cacheClient.publish(channel, message);
      } catch (err) {
        this.logger.warn(
          `Error publishing to Redis channel [${channel}]: ${(err as Error).message}`,
        );
      }
    }
  }

  /**
   * Creates a dedicated subscriber ioredis client for Pub/Sub listeners (SSE / WebSocket).
   */
  createSubscriber(): Redis | null {
    if (!this.isCacheHealthy || !this.cacheClient) {
      return null;
    }
    return this.cacheClient.duplicate();
  }
}
