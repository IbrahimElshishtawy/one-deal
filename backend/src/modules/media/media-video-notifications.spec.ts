import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import * as crypto from 'crypto';
import { MediaService } from '../media/media.service';
import { AllowedImageMime } from '../media/dto/presigned-upload.dto';
import { VideoService } from '../video/video.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('External Integration Adapters (R2 SigV4, CF Stream HMAC, FCM Persistence)', () => {
  it('MediaService should generate valid AWS SigV4 presigned URLs when R2 credentials are configured', async () => {
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

    const service = new MediaService(config, {} as any);
    const targets = await service.generateImageUploadUrls('user-123', {
      contentTypes: [AllowedImageMime.JPEG],
    });

    expect(targets).toHaveLength(1);
    expect(targets[0].uploadUrl).toContain(
      'https://cf-account-123.r2.cloudflarestorage.com/deal-one-prod/uploads/images/',
    );
    expect(targets[0].uploadUrl).toContain('X-Amz-Algorithm=AWS4-HMAC-SHA256');
    expect(targets[0].uploadUrl).toContain('X-Amz-Signature=');
  });

  it('VideoService should verify Cloudflare Stream HMAC webhook signature', async () => {
    const secret = 'stream_webhook_secret_key';
    const config = {
      get: jest.fn((key: string, def?: any) => {
        if (key === 'CLOUDFLARE_STREAM_WEBHOOK_SECRET') return secret;
        if (key === 'NODE_ENV') return 'production';
        return def;
      }),
    } as unknown as ConfigService;

    const mockPrisma = {
      listingMedia: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
    };

    const service = new VideoService(mockPrisma as any, config);
    const payload = { uid: 'stream-uid-1', readyToStream: true };
    const ts = '1730000000';
    const sig1 = crypto
      .createHmac('sha256', secret)
      .update(`${ts}.${JSON.stringify(payload)}`)
      .digest('hex');

    await expect(
      service.handleWebhook(payload, `time=${ts},sig1=${sig1}`),
    ).resolves.toEqual({ received: true });

    await expect(
      service.handleWebhook(payload, `time=${ts},sig1=0000`),
    ).rejects.toThrow(UnauthorizedException);
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
