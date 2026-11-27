import {
  BadRequestException,
  ForbiddenException,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrivateDocumentStorageService } from '../modules/accounts/services/private-document-storage.service';
import { RedisService } from '../core/redis/redis.service';
import { MediaCleanupProcessor } from './media-cleanup.processor';
import { ChatService } from '../modules/chat/chat.service';
import { PaymentsService } from '../modules/payments/payments.service';
import { redactSensitiveData } from '../core/observability/request-context';
import { PaymentStatus } from '../core/enums/domain.enums';

function makeConfig(values: Record<string, any>): ConfigService {
  return {
    get: jest.fn((key: string, defaultVal?: any) =>
      key in values ? values[key] : defaultVal,
    ),
  } as unknown as ConfigService;
}

describe('Phase 2 Production Hardening Suite (Workstreams A–G)', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  // =========================================================================
  // WORKSTREAM A: Server-Side R2 Ranged-GET Magic-Byte Validation (SEC-001/002)
  // =========================================================================
  describe('Workstream A: PrivateDocumentStorageService ranged-GET magic-byte verification', () => {
    const validKey =
      'private/seller-verification/11111111-1111-4111-8111-111111111111/22222222-2222-4222-8222-222222222222/id.pdf';
    const r2Config = makeConfig({
      NODE_ENV: 'production',
      R2_ACCOUNT_ID: 'acc123456',
      R2_ACCESS_KEY_ID: 'key123456',
      R2_SECRET_ACCESS_KEY: 'secret123456',
      R2_PRIVATE_BUCKET_NAME: 'dealone-kyc-private',
    });

    it('accepts valid PDF when R2 HEAD + ranged GET (bytes=0-15) return %PDF- signature', async () => {
      const storage = new PrivateDocumentStorageService(r2Config);
      const pdfBytes = Buffer.from('%PDF-1.7\n1 0 obj', 'ascii');

      const fetchSpy = jest
        .spyOn(global, 'fetch')
        .mockResolvedValueOnce({
          status: 200,
          ok: true,
          headers: new Headers({
            'content-length': '2048',
            'content-type': 'application/pdf',
            etag: '"pdf-etag"',
          }),
        } as Response)
        .mockResolvedValueOnce({
          status: 206,
          ok: true,
          arrayBuffer: async () =>
            pdfBytes.buffer.slice(
              pdfBytes.byteOffset,
              pdfBytes.byteOffset + pdfBytes.byteLength,
            ),
        } as Response);

      const res = await storage.verifyUploadedObject(
        validKey,
        'application/pdf',
        10_000,
      );
      expect(res.verified).toBe(true);
      expect(fetchSpy).toHaveBeenCalledTimes(2);
      expect(fetchSpy.mock.calls[1][1]).toEqual(
        expect.objectContaining({
          method: 'GET',
          headers: { Range: 'bytes=0-15' },
        }),
      );
    });

    it('rejects spoofed payload (MZ executable bytes) even when R2 HEAD claims application/pdf', async () => {
      const storage = new PrivateDocumentStorageService(r2Config);
      const exeBytes = Buffer.from([0x4d, 0x5a, 0x90, 0x00, 0x03, 0x00]);

      jest
        .spyOn(global, 'fetch')
        .mockResolvedValueOnce({
          status: 200,
          ok: true,
          headers: new Headers({
            'content-length': '1024',
            'content-type': 'application/pdf',
          }),
        } as Response)
        .mockResolvedValueOnce({
          status: 206,
          ok: true,
          arrayBuffer: async () =>
            exeBytes.buffer.slice(
              exeBytes.byteOffset,
              exeBytes.byteOffset + exeBytes.byteLength,
            ),
        } as Response);

      await expect(
        storage.verifyUploadedObject(validKey, 'application/pdf', 10_000),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects R2 ranged GET timeout / 500 failure and truncated 416 responses safely', async () => {
      const storage = new PrivateDocumentStorageService(r2Config);

      // Ranged GET network timeout
      jest
        .spyOn(global, 'fetch')
        .mockResolvedValueOnce({
          status: 200,
          ok: true,
          headers: new Headers({
            'content-length': '512',
            'content-type': 'application/pdf',
          }),
        } as Response)
        .mockRejectedValueOnce(
          new Error('The operation was aborted due to timeout'),
        );

      await expect(
        storage.verifyUploadedObject(validKey, 'application/pdf', 10_000),
      ).rejects.toThrow(InternalServerErrorException);

      // Empty / truncated object (HTTP 416)
      jest
        .spyOn(global, 'fetch')
        .mockResolvedValueOnce({
          status: 200,
          ok: true,
          headers: new Headers({
            'content-length': '512',
            'content-type': 'application/pdf',
          }),
        } as Response)
        .mockResolvedValueOnce({
          status: 416,
          ok: false,
        } as Response);

      await expect(
        storage.verifyUploadedObject(validKey, 'application/pdf', 10_000),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // =========================================================================
  // WORKSTREAM B: Redis Dual vs Single-Shared Topology Reporting (INF-001)
  // =========================================================================
  describe('Workstream B: RedisService topology detection', () => {
    it('reports dual_isolated when REDIS_CACHE_URL and REDIS_QUEUE_URL differ', () => {
      const svc = new RedisService(
        makeConfig({
          REDIS_CACHE_URL: 'redis://cache-host:6379',
          REDIS_QUEUE_URL: 'redis://queue-host:6380',
        }),
      );
      expect(svc.getTopologyStatus()).toEqual(
        expect.objectContaining({ mode: 'dual_isolated', separated: true }),
      );
    });

    it('reports single_shared when both fall back to the same REDIS_URL', () => {
      const svc = new RedisService(
        makeConfig({
          REDIS_URL: 'redis://shared-railway:6379',
        }),
      );
      expect(svc.getTopologyStatus()).toEqual(
        expect.objectContaining({ mode: 'single_shared', separated: false }),
      );
    });

    it('reports local_split when local host/ports differ (6379 vs 6380)', () => {
      const svc = new RedisService(
        makeConfig({
          REDIS_CACHE_HOST: 'localhost',
          REDIS_CACHE_PORT: 6379,
          REDIS_QUEUE_HOST: 'localhost',
          REDIS_QUEUE_PORT: 6380,
        }),
      );
      expect(svc.getTopologyStatus()).toEqual(
        expect.objectContaining({ mode: 'local_split', separated: true }),
      );
    });
  });

  // =========================================================================
  // WORKSTREAM C: Safe Public Media Cleanup (OPS-001)
  // =========================================================================
  describe('Workstream C: MediaCleanupProcessor R2-first deletion', () => {
    it('deletes R2 object first, skips invalid keys, and keeps DB row for retry if R2 DELETE fails', async () => {
      const mockPrisma: any = {
        listingMedia: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'media-ok',
              storageKey: 'uploads/images/2026-11/user1/file1.jpg',
            },
            {
              id: 'media-r2-fail',
              storageKey: 'uploads/images/2026-11/user1/file2.jpg',
            },
            {
              id: 'media-invalid-key',
              storageKey: 'private/seller-verification/bad/path/id.pdf',
            },
          ]),
          delete: jest.fn().mockResolvedValue({}),
        },
      };

      const mockMediaService: any = {
        deletePublicObject: jest
          .fn()
          .mockResolvedValueOnce({ deleted: true, statusCode: 204 })
          .mockRejectedValueOnce(new Error('R2 503 Unavailable')),
      };

      const processor = new MediaCleanupProcessor(mockPrisma, mockMediaService);
      const result = await processor.processAbandonedMedia();

      expect(result).toEqual({
        purgedCount: 1,
        failedCount: 1,
        skippedCount: 1,
      });
      // Only media-ok was deleted from DB; media-r2-fail kept for retry; invalid key never sent to R2
      expect(mockPrisma.listingMedia.delete).toHaveBeenCalledTimes(1);
      expect(mockPrisma.listingMedia.delete).toHaveBeenCalledWith({
        where: { id: 'media-ok' },
      });
      // Ensures active published listings are excluded from query
      expect(mockPrisma.listingMedia.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            listing: { publicationStatus: { not: 'published' } },
          }),
        }),
      );
    });
  });

  // =========================================================================
  // WORKSTREAM D: Chat Idempotency & Outbox Push Notification (MSG-001/002)
  // =========================================================================
  describe('Workstream D: ChatService idempotency & outbox push', () => {
    it('returns original message on duplicate clientMessageId without creating duplicate rows or outbox events', async () => {
      const existingMsg = {
        id: 'msg-1',
        conversationId: 'conv-1',
        senderUserId: 'buyer-1',
        clientMessageId: 'idem-key-123',
        body: 'Hello!',
      };
      const mockPrisma: any = {
        conversation: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'conv-1',
            buyerUserId: 'buyer-1',
            sellerAccount: { ownerUserId: 'seller-1' },
          }),
        },
        message: {
          findFirst: jest.fn().mockResolvedValue(existingMsg),
        },
        $transaction: jest.fn(),
      };

      const chat = new ChatService(mockPrisma);
      const res = await chat.sendMessage(
        'conv-1',
        'buyer-1',
        'Hello!',
        'idem-key-123',
      );

      expect(res).toEqual(existingMsg);
      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    });

    it('rejects unauthorized sender BEFORE checking idempotency key', async () => {
      const mockPrisma: any = {
        conversation: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'conv-1',
            buyerUserId: 'buyer-1',
            sellerAccount: { ownerUserId: 'seller-1' },
          }),
        },
        message: { findFirst: jest.fn() },
      };

      const chat = new ChatService(mockPrisma);
      await expect(
        chat.sendMessage('conv-1', 'intruder-99', 'Spy', 'idem-key-123'),
      ).rejects.toThrow(ForbiddenException);
      expect(mockPrisma.message.findFirst).not.toHaveBeenCalled();
    });

    it('persists message and enqueues PUSH_NOTIFICATION outbox event for recipient atomically', async () => {
      const outboxCreate = jest.fn().mockResolvedValue({});
      const mockTx: any = {
        message: {
          create: jest.fn().mockResolvedValue({
            id: 'msg-new',
            conversationId: 'conv-1',
            senderUserId: 'buyer-1',
            clientMessageId: 'idem-new',
            body: 'Is this available?',
            sender: { id: 'buyer-1', fullName: 'Ibrahim', avatarUrl: null },
          }),
        },
        conversation: { update: jest.fn().mockResolvedValue({}) },
        outboxEvent: { create: outboxCreate },
      };
      const mockPrisma: any = {
        conversation: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'conv-1',
            buyerUserId: 'buyer-1',
            sellerAccount: { ownerUserId: 'seller-1' },
          }),
        },
        message: { findFirst: jest.fn().mockResolvedValue(null) },
        $transaction: jest.fn((cb: any) => cb(mockTx)),
      };

      const chat = new ChatService(mockPrisma);
      const res = await chat.sendMessage(
        'conv-1',
        'buyer-1',
        'Is this available?',
        'idem-new',
      );

      expect(res.id).toBe('msg-new');
      expect(outboxCreate).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            eventType: 'PUSH_NOTIFICATION',
            payload: expect.objectContaining({
              targetUserId: 'seller-1',
            }),
          }),
        }),
      );
    });
  });

  // =========================================================================
  // WORKSTREAM F1: Payment Webhook Atomic Idempotency (DB-001)
  // =========================================================================
  describe('Workstream F1: PaymentsService atomic PENDING -> SUCCESS lock', () => {
    it('prevents duplicate entitlement application when atomic updateMany returns count=0', async () => {
      const listingUpdate = jest.fn();
      const outboxCreate = jest.fn();
      const mockTx: any = {
        payment: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
        listing: { update: listingUpdate },
        outboxEvent: { create: outboxCreate },
      };
      const mockPrisma: any = {
        payment: {
          findFirst: jest
            .fn()
            .mockResolvedValueOnce(null)
            .mockResolvedValueOnce({
              id: '11111111-1111-4111-8111-111111111111',
              listingId: 'list-1',
              packageId: 'FEATURED_7_DAYS',
              status: PaymentStatus.PENDING,
              package: { durationDays: 7 },
            }),
        },
        $transaction: jest.fn((cb: any) => cb(mockTx)),
      };

      const payments = new PaymentsService(
        mockPrisma,
        makeConfig({
          NODE_ENV: 'test',
          PAYMOB_HMAC_SECRET: 'test_hmac_secret',
        }),
      );

      const res = await payments.handlePaymobWebhook({
        id: 'tx-concurrent-1',
        success: true,
        order_id: '11111111-1111-4111-8111-111111111111',
      });

      expect(res).toEqual({ success: true, processed: false });
      expect(listingUpdate).not.toHaveBeenCalled();
      expect(outboxCreate).not.toHaveBeenCalled();
    });
  });

  // =========================================================================
  // WORKSTREAM G: Recursive PII & Presigned URL Log Redaction (SEC-003)
  // =========================================================================
  describe('Workstream G: redactSensitiveData', () => {
    it('redacts KYC identifiers, presigned URLs, ciphertexts, and tokens recursively', () => {
      const sanitized = redactSensitiveData({
        nationalIdNumber: '29501011234567',
        taxIdNumber: 'TAX-998877',
        commercialRegisterNumber: 'CR-112233',
        uploadUrl:
          'https://acc.r2.cloudflarestorage.com/bucket/key?X-Amz-Signature=abcdef123456',
        nested: {
          genericField:
            'https://acc.r2.cloudflarestorage.com/bucket/key?X-Amz-Signature=deadbeef',
          encryptedBlob:
            'enc:v1:00112233445566778899aabb:00112233445566778899aabbccddeeff:aabb',
        },
      }) as any;

      expect(sanitized.nationalIdNumber).toBe('[REDACTED]');
      expect(sanitized.taxIdNumber).toBe('[REDACTED]');
      expect(sanitized.commercialRegisterNumber).toBe('[REDACTED]');
      expect(sanitized.uploadUrl).toBe('[REDACTED]');
      expect(sanitized.nested.genericField).toBe('[REDACTED_SIGNED_URL]');
      expect(sanitized.nested.encryptedBlob).toBe('[REDACTED_CIPHERTEXT]');
    });
  });
});
