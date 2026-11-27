import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Optional,
  Logger,
  MessageEvent,
} from '@nestjs/common';
import { Observable, Subject, Subscription } from 'rxjs';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);
  private readonly localStreams = new Map<string, Subject<MessageEvent>>();

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  /**
   * Starts or returns an existing conversation bound to (listing, buyer, seller).
   */
  async getOrCreateConversation(listingId: string, buyerUserId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      include: { account: true },
    });

    if (!listing || listing.publicationStatus !== 'published') {
      throw new NotFoundException(
        'Listing not found or is no longer published',
      );
    }

    if (listing.account.ownerUserId === buyerUserId) {
      throw new BadRequestException(
        'You cannot start a conversation on your own listing',
      );
    }

    const existing = await this.prisma.conversation.findUnique({
      where: {
        uq_conversation_pair: {
          listingId,
          buyerUserId,
        },
      },
      include: {
        listing: { select: { id: true, title: true, price: true } },
        sellerAccount: {
          select: { id: true, displayName: true, logoUrl: true },
        },
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.conversation.create({
      data: {
        listingId,
        buyerUserId,
        sellerAccountId: listing.accountId,
      },
      include: {
        listing: { select: { id: true, title: true, price: true } },
        sellerAccount: {
          select: { id: true, displayName: true, logoUrl: true },
        },
      },
    });
  }

  /**
   * Retrieves active conversations for the authenticated user.
   */
  async getUserConversations(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        OR: [
          { buyerUserId: userId },
          { sellerAccount: { ownerUserId: userId } },
        ],
      },
      orderBy: { lastMessageAt: 'desc' },
      take: 50,
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            media: {
              take: 1,
              orderBy: { sortOrder: 'asc' },
              select: { publicUrl: true },
            },
          },
        },
        buyer: { select: { id: true, fullName: true, avatarUrl: true } },
        sellerAccount: {
          select: { id: true, displayName: true, logoUrl: true },
        },
      },
    });
  }

  /**
   * Retrieves paginated messages in a conversation, ensuring participant authorization (IDOR check).
   */
  async getMessages(
    conversationId: string,
    userId: string,
    page = 1,
    limit = 30,
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { sellerAccount: true },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (
      conversation.buyerUserId !== userId &&
      conversation.sellerAccount.ownerUserId !== userId
    ) {
      throw new ForbiddenException(
        'You are not a participant in this conversation',
      );
    }

    // Mark unread messages sent by the other party as read
    await this.prisma.message.updateMany({
      where: {
        conversationId,
        senderUserId: { not: userId },
        status: { not: 'read' },
      },
      data: {
        status: 'read',
        readAt: new Date(),
      },
    });

    const skip = (page - 1) * limit;

    const [total, messages] = await Promise.all([
      this.prisma.message.count({ where: { conversationId } }),
      this.prisma.message.findMany({
        where: { conversationId },
        skip,
        take: limit,
        orderBy: { sentAt: 'asc' },
        include: {
          sender: { select: { id: true, fullName: true, avatarUrl: true } },
        },
      }),
    ]);

    return {
      messages,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Sends a text message inside a verified conversation with optional client-generated
   * idempotency key (`clientMessageId`) and transactional outbox push notification dispatch.
   */
  async sendMessage(
    conversationId: string,
    senderId: string,
    text: string,
    clientMessageId?: string,
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { sellerAccount: true },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (
      conversation.buyerUserId !== senderId &&
      conversation.sellerAccount.ownerUserId !== senderId
    ) {
      throw new ForbiddenException(
        'You are not a participant in this conversation',
      );
    }

    const normalizedClientMessageId = clientMessageId?.trim() || undefined;

    // Fast-path idempotency check (after participant authorization)
    if (normalizedClientMessageId && this.prisma.message?.findFirst) {
      const existing = await this.prisma.message.findFirst({
        where: {
          conversationId,
          senderUserId: senderId,
          clientMessageId: normalizedClientMessageId,
        },
        include: {
          sender: { select: { id: true, fullName: true, avatarUrl: true } },
        },
      });
      if (existing) {
        return existing;
      }
    }

    const recipientUserId =
      conversation.buyerUserId === senderId
        ? conversation.sellerAccount.ownerUserId
        : conversation.buyerUserId;

    let message: any;
    try {
      message = await this.prisma.$transaction(async (tx) => {
        const created = await tx.message.create({
          data: {
            conversationId,
            senderUserId: senderId,
            ...(normalizedClientMessageId
              ? { clientMessageId: normalizedClientMessageId }
              : {}),
            body: text,
          },
          include: {
            sender: { select: { id: true, fullName: true, avatarUrl: true } },
          },
        });

        await tx.conversation.update({
          where: { id: conversationId },
          data: {
            lastMessageText: text.slice(0, 500),
            lastMessageAt: new Date(),
          },
        });

        // Enqueue asynchronous push notification via Transactional Outbox
        // (keeps message persistence independent of FCM availability & avoids blocking)
        if (
          recipientUserId &&
          recipientUserId !== senderId &&
          (tx as any).outboxEvent?.create
        ) {
          await (tx as any).outboxEvent.create({
            data: {
              aggregateType: 'Conversation',
              aggregateId: conversationId,
              eventType: 'PUSH_NOTIFICATION',
              payload: {
                targetUserId: recipientUserId,
                title: created.sender?.fullName || 'New Message',
                body: text.slice(0, 140),
                dataPayload: {
                  type: 'CHAT_MESSAGE',
                  conversationId,
                  messageId: created.id,
                },
              },
            },
          });
        }

        return created;
      });
    } catch (err: any) {
      // Handle concurrent duplicate race cleanly via DB unique constraint P2002
      if (
        normalizedClientMessageId &&
        err?.code === 'P2002' &&
        this.prisma.message?.findFirst
      ) {
        const existing = await this.prisma.message.findFirst({
          where: {
            conversationId,
            senderUserId: senderId,
            clientMessageId: normalizedClientMessageId,
          },
          include: {
            sender: { select: { id: true, fullName: true, avatarUrl: true } },
          },
        });
        if (existing) {
          return existing;
        }
      }
      throw err;
    }

    const eventPayload = JSON.stringify({
      type: 'chat.message',
      conversationId,
      message,
    });
    const recipients = new Set<string>([
      conversation.buyerUserId,
      conversation.sellerAccount.ownerUserId,
    ]);
    await Promise.allSettled(
      Array.from(recipients).map((uid) =>
        this.publishChatEvent(uid, eventPayload),
      ),
    );

    return message;
  }

  private getOrCreateLocalStream(userId: string): Subject<MessageEvent> {
    let subject = this.localStreams.get(userId);
    if (!subject) {
      subject = new Subject<MessageEvent>();
      this.localStreams.set(userId, subject);
    }
    return subject;
  }

  /**
   * Real-time Server-Sent Events (SSE) stream for incoming messages across all replicas via Redis Pub/Sub.
   */
  subscribeToUserStream(userId: string): Observable<MessageEvent> {
    const channel = `chat:user:${userId}`;
    const subscriber = this.redis?.createSubscriber?.();

    if (subscriber) {
      return new Observable<MessageEvent>((observer) => {
        let localSub: Subscription | null = null;
        const onMessage = (incomingChannel: string, rawPayload: string) => {
          if (incomingChannel === channel && !observer.closed) {
            observer.next({ data: rawPayload });
          }
        };
        const onError = (err: Error) => {
          this.logger.warn(
            `Chat SSE Redis subscriber error for user ${userId}: ${err?.message || err}`,
          );
        };
        subscriber.on('message', onMessage);
        subscriber.on('error', onError);
        subscriber.subscribe(channel).catch((err) => {
          this.logger.warn(
            `Chat SSE Redis subscribe failed for user ${userId}, falling back to local stream: ${err?.message || err}`,
          );
          if (!observer.closed) {
            localSub = this.getOrCreateLocalStream(userId).subscribe({
              next: (evt) => observer.next(evt),
            });
          }
        });

        return () => {
          localSub?.unsubscribe();
          subscriber.off('message', onMessage);
          subscriber.off('error', onError);
          subscriber.unsubscribe(channel).catch(() => undefined);
          subscriber.quit().catch(() => undefined);
        };
      });
    }

    return this.getOrCreateLocalStream(userId).asObservable();
  }

  private async publishChatEvent(
    userId: string,
    serializedPayload: string,
  ): Promise<void> {
    const channel = `chat:user:${userId}`;
    if (this.redis?.isCacheClientConnected?.()) {
      await this.redis.publish(channel, serializedPayload);
      return;
    }
    this.localStreams.get(userId)?.next({ data: serializedPayload });
  }
}
