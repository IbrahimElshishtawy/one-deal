import { ConfigService } from '@nestjs/config';
import {
  BadRequestException,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { MediaService } from '../media/media.service';
import { AllowedImageMime } from '../media/dto/presigned-upload.dto';
import { VideoService } from '../video/video.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('External Integration Adapters, Media Ownership & Video Webhook Security', () => {
  describe('MediaService (R2 SigV4 & Strict Ownership Validation)', () => {
    const buildMediaService = () => {
      const config = {
        get: jest.fn((key: string, def?: any) => {
          const map: Record<string, string> = {
            R2_PUBLIC_DOMAIN: 'https://cdn.marketspace.eg',
            R2_BUCKET_NAME: 'deal-one-prod',
            R2_ACCOUNT_ID: 'cf-account-123',
            R2_ACCESS_KEY_ID: 'AKIAIOSFODNN7EXAMPLE',
            R2_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
            NODE_ENV: 'production',
          };
          return map[key] ?? def;
        }),
      } as unknown as ConfigService;

      return new MediaService(config, {} as any);
    };

    it('should generate valid AWS SigV4 presigned URLs when R2 credentials are configured', async () => {
      const service = buildMediaService();
      const targets = await service.generateImageUploadUrls('user-123', {
        contentTypes: [AllowedImageMime.JPEG],
      });

      expect(targets).toHaveLength(1);
      expect(targets[0].uploadUrl).toContain(
        'https://cf-account-123.r2.cloudflarestorage.com/deal-one-prod/uploads/images/',
      );
      expect(targets[0].uploadUrl).toContain(
        'X-Amz-Algorithm=AWS4-HMAC-SHA256',
      );
      expect(targets[0].uploadUrl).toContain('X-Amz-Signature=');
    });

    it('should confirm valid canonical storage keys belonging to the authenticated user', async () => {
      const service = buildMediaService();
      const res = await service.confirmUpload('user-123', {
        storageKey: 'uploads/images/2026-11/user-123/550e8400-e29b.jpg',
      });
      expect(res.success).toBe(true);
      expect(res.publicUrl).toBe(
        'https://cdn.marketspace.eg/uploads/images/2026-11/user-123/550e8400-e29b.jpg',
      );
    });

    it('should reject cross-user keys, path traversal, query spoofing, and invalid resource paths', async () => {
      const service = buildMediaService();
      const maliciousKeys = [
        'uploads/images/2026-11/victim-user/photo.jpg',
        'uploads/images/2026-11/user-123/../victim-user/photo.jpg',
        'uploads/images/2026-11/victim-user/photo.jpg?x=/user-123/',
        'uploads/images/2026-11/user-123/%2e%2e/victim-user/photo.jpg',
        '/uploads/images/2026-11/user-123/photo.jpg',
        'uploads/private/2026-11/user-123/photo.jpg',
        'uploads/images/2026-11/user-123/evil.svg',
        'uploads/images/2026-11/user-123/sub/photo.jpg',
      ];

      for (const storageKey of maliciousKeys) {
        await expect(
          service.confirmUpload('user-123', { storageKey }),
        ).rejects.toThrow(ForbiddenException);
      }
    });
  });

  describe('VideoService (Cloudflare Stream HMAC, Timestamp Freshness & Replay Protection)', () => {
    const secret = 'stream_webhook_secret_key_for_hmac_verification';

    function signPayload(payload: unknown, ts: number): string {
      const raw =
        typeof payload === 'string' ? payload : JSON.stringify(payload);
      const sig1 = crypto
        .createHmac('sha256', secret)
        .update(`${ts}.${raw}`)
        .digest('hex');
      return `time=${ts},sig1=${sig1}`;
    }

    function createVideoService() {
      const config = {
        get: jest.fn((key: string, def?: any) => {
          if (key === 'CLOUDFLARE_STREAM_WEBHOOK_SECRET') return secret;
          if (key === 'NODE_ENV') return 'production';
          if (key === 'VIDEO_WEBHOOK_TOLERANCE_SEC') return 300;
          return def;
        }),
      } as unknown as ConfigService;

      const mockPrisma = {
        listingMedia: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      };

      const seen = new Set<string>();
      const mockRedis = {
        setIfNotExists: jest.fn(async (key: string) => {
          if (seen.has(key)) return false;
          seen.add(key);
          return true;
        }),
      };

      const service = new VideoService(
        mockPrisma as any,
        config,
        mockRedis as any,
      );
      return { service, mockPrisma, mockRedis };
    }

    it('should accept a valid fresh Cloudflare Stream webhook and update DB once', async () => {
      const { service, mockPrisma } = createVideoService();
      const payload = { uid: 'stream-uid-12345', readyToStream: true };
      const freshTs = Math.floor(Date.now() / 1000);
      const header = signPayload(payload, freshTs);

      const res = await service.handleWebhook(
        payload,
        header,
        JSON.stringify(payload),
      );
      expect(res).toEqual({ received: true });
      expect(mockPrisma.listingMedia.updateMany).toHaveBeenCalledTimes(1);
    });

    it('should reject invalid or missing signatures', async () => {
      const { service } = createVideoService();
      const payload = { uid: 'stream-uid-12345', readyToStream: true };
      const freshTs = Math.floor(Date.now() / 1000);

      await expect(service.handleWebhook(payload, undefined)).rejects.toThrow(
        UnauthorizedException,
      );
      await expect(
        service.handleWebhook(payload, `time=${freshTs},sig1=0000`),
      ).rejects.toThrow(UnauthorizedException);
      await expect(
        service.handleWebhook(
          payload,
          `time=${freshTs},sig1=${'a'.repeat(64)}`,
        ),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should reject expired webhook timestamps to prevent replay attacks', async () => {
      const { service } = createVideoService();
      const payload = { uid: 'stream-uid-12345', readyToStream: true };
      const expiredTs = Math.floor(Date.now() / 1000) - 600; // 10 minutes old
      const header = signPayload(payload, expiredTs);

      await expect(
        service.handleWebhook(payload, header, JSON.stringify(payload)),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should treat duplicate/replayed webhook deliveries idempotently without re-updating DB', async () => {
      const { service, mockPrisma } = createVideoService();
      const payload = { uid: 'stream-uid-99999', readyToStream: true };
      const freshTs = Math.floor(Date.now() / 1000);
      const raw = JSON.stringify(payload);
      const header = signPayload(raw, freshTs);

      const first = await service.handleWebhook(payload, header, raw);
      const second = await service.handleWebhook(payload, header, raw);

      expect(first).toEqual({ received: true });
      expect(second).toEqual({ received: true, duplicate: true });
      expect(mockPrisma.listingMedia.updateMany).toHaveBeenCalledTimes(1);
    });

    it('should reject malformed payloads even when signed', async () => {
      const { service } = createVideoService();
      const badPayload = { uid: 'x', readyToStream: 'not-a-boolean' };
      const freshTs = Math.floor(Date.now() / 1000);
      const raw = JSON.stringify(badPayload);
      const header = signPayload(raw, freshTs);

      await expect(
        service.handleWebhook(badPayload, header, raw),
      ).rejects.toThrow(BadRequestException);
    });
  });

  it('NotificationsService should persist FCM device token in UserDevice table', async () => {
    const config = {
      get: jest.fn((_k: string, def?: any) => def),
    } as unknown as ConfigService;
    const mockPrisma = {
      userDevice: { upsert: jest.fn().mockResolvedValue({ id: 'dev-1' }) },
    };

    const service = new NotificationsService(config, mockPrisma as any);
    const res = await service.registerDeviceToken(
      'user-1',
      'fcm-token-xyz',
      'android',
      '1.0.0',
    );

    expect(res.success).toBe(true);
    expect(mockPrisma.userDevice.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          uq_user_device_token: {
            userId: 'user-1',
            fcmToken: 'fcm-token-xyz',
          },
        },
      }),
    );
  });
});
