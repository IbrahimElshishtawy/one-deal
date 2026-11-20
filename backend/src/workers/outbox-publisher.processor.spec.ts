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
      data: { status: 'PROCESSING' },
    });
    expect(mockPrisma.outboxEvent.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'evt-1' },
        data: expect.objectContaining({ status: 'PUBLISHED' }),
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
    mockPrisma.outboxEvent.findMany.mockRejectedValue(new Error('P1001 connection lost'));

    const res = await processor.publishPendingEvents();

    expect(res).toEqual({ publishedCount: 0, failedCount: 0 });
  });
});
