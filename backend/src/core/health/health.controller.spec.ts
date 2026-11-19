import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../redis/redis.service';

describe('HealthController', () => {
  let controller: HealthController;
  let prismaService: PrismaService;
  let redisService: RedisService;

  beforeEach(async () => {
    const mockPrisma = {
      ping: jest.fn().mockResolvedValue(true),
      checkPostgisSupport: jest
        .fn()
        .mockResolvedValue({ supported: true, version: '3.4 USE_GEOS=1' }),
    };

    const mockRedis = {
      pingCache: jest.fn().mockResolvedValue(true),
      pingQueue: jest.fn().mockResolvedValue(true),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
        {
          provide: RedisService,
          useValue: mockRedis,
        },
      ],
    }).compile();

    controller = module.get<HealthController>(HealthController);
    prismaService = module.get<PrismaService>(PrismaService);
    redisService = module.get<RedisService>(RedisService);
  });

  describe('getLiveness', () => {
    it('should return status ok with uptime and memory', () => {
      const result = controller.getLiveness();
      expect(result.status).toBe('ok');
      expect(result.uptimeSeconds).toBeGreaterThanOrEqual(0);
      expect(result.memoryRssMb).toBeGreaterThan(0);
      expect(result.timestamp).toBeDefined();
    });
  });

  describe('getReadiness', () => {
    it('should return healthy status when all dependencies are reachable', async () => {
      const mockRes = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn().mockImplementation((payload) => payload),
      };

      await controller.getReadiness(mockRes as any);

      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            status: 'healthy',
            checks: {
              database: 'up',
              postgis: 'up (3.4 USE_GEOS=1)',
              redis_cache: 'up',
              redis_queue: 'up',
              workers: 'active',
              email: 'unconfigured',
            },
          }),
        }),
      );
    });

    it('should return service unavailable when database is down', async () => {
      jest.spyOn(prismaService, 'ping').mockResolvedValueOnce(false);

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn().mockImplementation((payload) => payload),
      };

      await controller.getReadiness(mockRes as any);

      expect(mockRes.status).toHaveBeenCalledWith(503);
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          data: expect.objectContaining({
            status: 'unhealthy',
            checks: expect.objectContaining({
              database: 'down',
            }),
          }),
        }),
      );
    });

    it('should return service unavailable when Redis Queue is down', async () => {
      jest.spyOn(redisService, 'pingQueue').mockResolvedValueOnce(false);

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn().mockImplementation((payload) => payload),
      };

      await controller.getReadiness(mockRes as any);

      expect(mockRes.status).toHaveBeenCalledWith(503);
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          data: expect.objectContaining({
            status: 'unhealthy',
            checks: expect.objectContaining({
              redis_queue: 'down',
            }),
          }),
        }),
      );
    });
  });
});
