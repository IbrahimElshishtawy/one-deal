import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { EventEmitter } from 'events';
import { ChatService } from './chat.service';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';

describe('ChatService (Milestone 5)', () => {
  let service: ChatService;
  let prisma: PrismaService;

  const mockPrisma: any = {
    listing: { findUnique: jest.fn() },
    conversation: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    message: {
      count: jest.fn(),
      findMany: jest.fn(),
      updateMany: jest.fn(),
      create: jest.fn(),
    },
    $transaction: jest.fn((callback: (tx: any) => any) => callback(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<ChatService>(ChatService);
    prisma = module.get<PrismaService>(PrismaService);
    expect(prisma).toBeDefined();
    jest.clearAllMocks();
  });

  describe('getOrCreateConversation', () => {
    it('should prevent buyer from initiating conversation on their own listing', async () => {
      mockPrisma.listing.findUnique.mockResolvedValue({
        id: 'listing-1',
        account: { ownerUserId: 'user-self' },
        publicationStatus: 'published',
      });

      await expect(
        service.getOrCreateConversation('listing-1', 'user-self'),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('getMessages - IDOR Check', () => {
    it('should throw ForbiddenException if user is not a participant in the conversation', async () => {
      mockPrisma.conversation.findUnique.mockResolvedValue({
        id: 'conv-1',
        buyerUserId: 'user-buyer',
        sellerAccount: { ownerUserId: 'user-seller' },
      });

      await expect(
        service.getMessages('conv-1', 'intruder-user'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('subscribeToUserStream resilience', () => {
    it('absorbs Redis subscriber errors and subscribe rejection without throwing unhandled RxJS error', async () => {
      const fakeSubscriber: any = new EventEmitter();
      fakeSubscriber.subscribe = jest
        .fn()
        .mockRejectedValue(new Error('Redis down'));
      fakeSubscriber.unsubscribe = jest.fn().mockResolvedValue(1);
      fakeSubscriber.quit = jest.fn().mockResolvedValue('OK');

      const mockRedis = {
        createSubscriber: jest.fn().mockReturnValue(fakeSubscriber),
      };

      const moduleWithRedis = await Test.createTestingModule({
        providers: [
          ChatService,
          { provide: PrismaService, useValue: mockPrisma },
          { provide: RedisService, useValue: mockRedis },
        ],
      }).compile();

      const chatWithRedis = moduleWithRedis.get<ChatService>(ChatService);
      let errReceived: unknown = null;
      const sub = chatWithRedis.subscribeToUserStream('user-sse-1').subscribe({
        error: (e) => {
          errReceived = e;
        },
      });

      await new Promise((r) => setTimeout(r, 20));
      expect(() =>
        fakeSubscriber.emit('error', new Error('ECONNRESET')),
      ).not.toThrow();
      expect(errReceived).toBeNull();
      sub.unsubscribe();
    });
  });
});
