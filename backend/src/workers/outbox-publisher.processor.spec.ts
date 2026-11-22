import { Test, TestingModule } from '@nestjs/testing';
import { OutboxPublisherProcessor } from './outbox-publisher.processor';
import { PrismaService } from '../core/database/prisma.service';
import { NotificationProcessor } from './notification.processor';

describe('OutboxPublisherProcessor', () => {
  let processor: OutboxPublisherProcessor;

  const mockPrisma = {
    outboxEvent: {
      findMany: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
    },
  };

  const mockNotificationProcessor = {
    processNotificationJob: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OutboxPublisherProcessor,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationProcessor, useValue: mockNotificationProcessor },
      ],
    }).compile();

    processor = module.get<OutboxPublisherProcessor>(OutboxPublisherProcessor);
    jest.clearAllMocks();
  });

  it('should atomically claim and publish PUSH_NOTIFICATION outbox events', async () => {
    mockPrisma.outboxEvent.findMany.mockResolvedValue([
      {
        id: 'evt-1',
        eventType: 'PUSH_NOTIFICATION',
        payload: {
          targetUserId: 'user-1',
          title: 'Alert',
          body: 'Listing approved',
        },
      },
    ]);
    mockPrisma.outboxEvent.updateMany.mockResolvedValue({ count: 1 });
    mockNotificationProcessor.processNotificationJob.mockResolvedValue(true);

    const res = await processor.publishPendingEvents();

    expect(res).toEqual({ publishedCount: 1, failedCount: 0 });
    expect(mockPrisma.outboxEvent.updateMany).toHaveBeenCalledWith({
      where: { id: 'evt-1', status: 'PENDING' },
      data: expect.objectContaining({
        status: 'PROCESSING',
        lockedAt: expect.any(Date),
      }),
    });
    expect(mockPrisma.outboxEvent.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'evt-1' },
        data: expect.objectContaining({ status: 'PUBLISHED', lockedAt: null }),
      }),
    );
  });

  it('should schedule exponential backoff retry on transient failure and mark FAILED when maxRetries exhausted', async () => {
    mockPrisma.outboxEvent.updateMany.mockResolvedValue({ count: 1 });
    mockNotificationProcessor.processNotificationJob.mockResolvedValue(false);

    // First failure: retryCount 0 -> 1 (< maxRetries 5) => reschedule PENDING with nextRetryAt
    mockPrisma.outboxEvent.findMany.mockResolvedValueOnce([
      {
        id: 'evt-retry',
        eventType: 'PUSH_NOTIFICATION',
        retryCount: 0,
        maxRetries: 5,
        payload: { targetUserId: 'u-1', title: 'Hi', body: 'Test' },
      },
    ]);

    const res1 = await processor.publishPendingEvents();
    expect(res1).toEqual({ publishedCount: 0, failedCount: 1 });
    expect(mockPrisma.outboxEvent.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'evt-retry' },
        data: expect.objectContaining({
          status: 'PENDING',
          retryCount: 1,
          nextRetryAt: expect.any(Date),
          lockedAt: null,
        }),
      }),
    );

    // Final failure: retryCount 4 -> 5 (== maxRetries 5) => mark FAILED
    mockPrisma.outboxEvent.findMany.mockResolvedValueOnce([
      {
        id: 'evt-dead',
        eventType: 'PUSH_NOTIFICATION',
        retryCount: 4,
        maxRetries: 5,
        payload: { targetUserId: 'u-1', title: 'Hi', body: 'Test' },
      },
    ]);

    const res2 = await processor.publishPendingEvents();
    expect(res2).toEqual({ publishedCount: 0, failedCount: 1 });
    expect(mockPrisma.outboxEvent.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'evt-dead' },
        data: expect.objectContaining({
          status: 'FAILED',
          retryCount: 5,
          lockedAt: null,
        }),
      }),
    );
  });

  it('should recover stale PROCESSING events left behind by crashed workers', async () => {
    mockPrisma.outboxEvent.updateMany.mockResolvedValueOnce({ count: 2 });
    mockPrisma.outboxEvent.findMany.mockResolvedValueOnce([]);

    await processor.publishPendingEvents();

    expect(mockPrisma.outboxEvent.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ status: 'PROCESSING' }),
        data: { status: 'PENDING', lockedAt: null },
      }),
    );
  });

  it('should skip event if already claimed by another replica', async () => {
    mockPrisma.outboxEvent.findMany.mockResolvedValue([
      { id: 'evt-race', eventType: 'LISTING_PUBLISHED', payload: {} },
    ]);
    mockPrisma.outboxEvent.updateMany.mockResolvedValue({ count: 0 });

    const res = await processor.publishPendingEvents();

    expect(res).toEqual({ publishedCount: 0, failedCount: 0 });
    expect(mockPrisma.outboxEvent.update).not.toHaveBeenCalled();
  });

  it('should absorb transient DB errors gracefully without throwing unhandled rejections', async () => {
    mockPrisma.outboxEvent.findMany.mockRejectedValue(
      new Error('P1001 connection lost'),
    );

    const res = await processor.publishPendingEvents();

    expect(res).toEqual({ publishedCount: 0, failedCount: 0 });
  });
});
