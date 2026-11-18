import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../../core/database/prisma.service';

describe('NotificationsService (Inbox & Read State)', () => {
  let service: NotificationsService;

  const mockPrisma = {
    notification: {
      count: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      create: jest.fn(),
    },
    userDevice: {
      upsert: jest.fn(),
      findMany: jest.fn(),
    },
  };

  const mockConfig = {
    get: jest.fn((_k: string, def?: string) => def ?? ''),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: ConfigService, useValue: mockConfig },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
    jest.clearAllMocks();
  });

  it('should list paginated notifications with unread filter and unreadCount', async () => {
    mockPrisma.notification.count
      .mockResolvedValueOnce(1)
      .mockResolvedValueOnce(3);
    mockPrisma.notification.findMany.mockResolvedValue([
      { id: 'n-1', userId: 'user-1', isRead: false, title: 'New message' },
    ]);

    const res = await service.getUserNotifications('user-1', {
      page: 1,
      limit: 10,
      unread: true,
    });

    expect(res.items).toHaveLength(1);
    expect(res.unreadCount).toBe(3);
    expect(res.meta.total).toBe(1);
    expect(mockPrisma.notification.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'user-1', isRead: false },
        skip: 0,
        take: 10,
      }),
    );
  });

  it('should mark own notification as read and reject access to another user notification', async () => {
    mockPrisma.notification.findFirst.mockResolvedValueOnce({
      id: 'n-1',
      userId: 'user-1',
      isRead: false,
    });
    mockPrisma.notification.update.mockResolvedValueOnce({
      id: 'n-1',
      userId: 'user-1',
      isRead: true,
    });

    const updated = await service.markAsRead('user-1', 'n-1');
    expect(updated.isRead).toBe(true);
    expect(mockPrisma.notification.findFirst).toHaveBeenCalledWith({
      where: { id: 'n-1', userId: 'user-1' },
    });

    mockPrisma.notification.findFirst.mockResolvedValueOnce(null);
    await expect(service.markAsRead('user-2', 'n-1')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('should mark all unread notifications as read for user', async () => {
    mockPrisma.notification.updateMany.mockResolvedValue({ count: 4 });

    const res = await service.markAllAsRead('user-1');
    expect(res).toEqual({ success: true, updatedCount: 4 });
    expect(mockPrisma.notification.updateMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', isRead: false },
      data: { isRead: true },
    });
  });
});
