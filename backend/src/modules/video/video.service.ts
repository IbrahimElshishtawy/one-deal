import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  InternalServerErrorException,
  Logger,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';

@Injectable()
export class VideoService {
  private readonly logger = new Logger(VideoService.name);
  private readonly streamApiToken: string;
  private readonly streamAccountId: string;
  private readonly webhookSecret: string;
  private readonly webhookToleranceSeconds: number;
  private readonly nodeEnv: string;
  private readonly processedWebhookCache = new Map<string, number>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Optional() private readonly redis?: RedisService,
  ) {
    this.streamApiToken = this.configService.get<string>(
      'CLOUDFLARE_STREAM_API_TOKEN',
      '',
    );
    this.streamAccountId = this.configService.get<string>(
      'CLOUDFLARE_STREAM_ACCOUNT_ID',
      '',
    );
    this.webhookSecret = this.configService.get<string>(
      'CLOUDFLARE_STREAM_WEBHOOK_SECRET',
      '',
    );
    this.webhookToleranceSeconds = this.configService.get<number>(
      'VIDEO_WEBHOOK_TOLERANCE_SEC',
      300,
    );
    this.nodeEnv = this.configService.get<string>('NODE_ENV', 'development');
  }

  private hasRealStreamCredentials(): boolean {
    return (
      !!this.streamApiToken &&
      !!this.streamAccountId &&
      !this.streamApiToken.startsWith('placeholder') &&
      !this.streamAccountId.startsWith('placeholder')
    );
  }

  /**
   * Requests a direct-creator upload URL from Cloudflare Stream with strict 30s max duration limit.
   */
  async requestDirectUploadToken(userId: string) {
    if (this.hasRealStreamCredentials()) {
      const endpoint = `https://api.cloudflare.com/client/v4/accounts/${this.streamAccountId}/stream/direct_upload`;
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.streamApiToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          maxDurationSeconds: 30,
          meta: { userId },
        }),
      });

      const data = (await response.json()) as {
        success?: boolean;
        result?: { uid: string; uploadURL: string };
        errors?: Array<{ message: string }>;
      };

      if (!response.ok || !data?.success || !data?.result?.uid) {
        const errMsg =
          data?.errors?.[0]?.message || 'Cloudflare Stream API error';
        this.logger.error(`Cloudflare Stream direct_upload failed: ${errMsg}`);
        throw new InternalServerErrorException(
          'Failed to initialize video upload session',
        );
      }

      return {
        streamUid: data.result.uid,
        uploadUrl: data.result.uploadURL,
        maxDurationSeconds: 30,
        instructions: 'Upload video binary directly via POST/TUS to uploadUrl',
      };
    }

    if (this.nodeEnv === 'production') {
      throw new InternalServerErrorException(
        'Cloudflare Stream credentials are missing in production environment',
      );
    }

    const streamUid = crypto.randomUUID();
    const uploadUrl = `https://upload.videodelivery.net/${streamUid}`;
    return {
      streamUid,
      uploadUrl,
      maxDurationSeconds: 30,
      instructions: 'Upload video binary directly via POST/TUS to uploadUrl',
    };
  }

  /**
   * Verifies Cloudflare Stream Webhook-Signature header (time=<ts>,sig1=<hmac_sha256>),
   * validates timestamp freshness, prevents replay/duplicate processing via Redis idempotency,
   * and updates video processing status in DB.
   */
  async handleWebhook(
    payload: any,
    signatureHeader?: string,
    rawBody?: string,
  ) {
    const hasRealWebhookSecret =
      !!this.webhookSecret && !this.webhookSecret.startsWith('placeholder');

    let parsedParts: { time: string; sig1: string } | null = null;

    if (hasRealWebhookSecret || this.nodeEnv === 'production') {
      if (!signatureHeader || !hasRealWebhookSecret) {
        throw new UnauthorizedException(
          'Missing Cloudflare Stream webhook signature or secret',
        );
      }
      parsedParts = this.parseSignatureHeader(signatureHeader);
      if (!parsedParts) {
        throw new UnauthorizedException(
          'Malformed Cloudflare Stream webhook signature header',
        );
      }

      if (!this.isTimestampFresh(parsedParts.time)) {
        throw new UnauthorizedException(
          'Cloudflare Stream webhook timestamp is expired or outside tolerance window',
        );
      }

      const bodyToVerify =
        typeof rawBody === 'string' && rawBody.length > 0 ? rawBody : payload;
      const isValid = this.verifyWebhookSignature(
        bodyToVerify,
        signatureHeader,
      );
      if (!isValid) {
        throw new UnauthorizedException(
          'Invalid Cloudflare Stream webhook signature',
        );
      }
    }

    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      throw new BadRequestException('Malformed video webhook payload');
    }

    const uid = payload?.uid ?? payload?.data?.uid;
    const readyToStream =
      payload?.readyToStream ?? payload?.data?.readyToStream;

    if (typeof uid !== 'string' || !/^[a-zA-Z0-9_-]{6,128}$/.test(uid)) {
      throw new BadRequestException(
        'Video webhook payload is missing a valid stream uid',
      );
    }

    if (typeof readyToStream !== 'boolean') {
      throw new BadRequestException(
        'Video webhook payload must include a boolean readyToStream field',
      );
    }

    // Idempotency & replay protection
    const eventFingerprint = crypto
      .createHash('sha256')
      .update(
        `${parsedParts?.time ?? 'unsigned'}:${parsedParts?.sig1 ?? ''}:${uid}:${String(readyToStream)}`,
      )
      .digest('hex');
    const isNewEvent = await this.claimWebhookEvent(eventFingerprint);
    if (!isNewEvent) {
      this.logger.warn(
        `Duplicate or replayed Cloudflare Stream webhook ignored for uid=${uid}`,
      );
      return { received: true, duplicate: true };
    }

    await this.prisma.listingMedia.updateMany({
      where: {
        mediaType: 'video',
        OR: [{ storageKey: uid }, { storageKey: { endsWith: `/${uid}` } }],
      },
      data: {
        processingStatus: readyToStream ? 'ready' : 'failed',
      },
    });

    return { received: true };
  }

  private parseSignatureHeader(
    signatureHeader: string,
  ): { time: string; sig1: string } | null {
    const parts = signatureHeader
      .split(',')
      .reduce<Record<string, string>>((acc, pair) => {
        const eqIdx = pair.indexOf('=');
        if (eqIdx > 0) {
          const k = pair.slice(0, eqIdx).trim();
          const v = pair.slice(eqIdx + 1).trim();
          if (k && v) acc[k] = v;
        }
        return acc;
      }, {});

    if (!parts.time || !parts.sig1) {
      return null;
    }
    if (!/^\d{9,12}$/.test(parts.time)) {
      return null;
    }
    if (!/^[0-9a-f]{64}$/i.test(parts.sig1)) {
      return null;
    }
    return { time: parts.time, sig1: parts.sig1 };
  }

  isTimestampFresh(
    timeStr: string,
    nowEpochSeconds = Math.floor(Date.now() / 1000),
  ): boolean {
    if (!/^\d{9,12}$/.test(timeStr)) return false;
    const timestamp = Number(timeStr);
    if (!Number.isFinite(timestamp)) return false;
    return (
      Math.abs(nowEpochSeconds - timestamp) <= this.webhookToleranceSeconds
    );
  }

  private async claimWebhookEvent(fingerprint: string): Promise<boolean> {
    const ttlSeconds = Math.max(this.webhookToleranceSeconds * 2, 600);
    const key = `video:webhook:seen:${fingerprint}`;

    if (this.redis) {
      return this.redis.setIfNotExists(key, '1', ttlSeconds);
    }

    // Fallback in-memory idempotency set when Redis is not injected (unit tests)
    const now = Date.now();
    const existingExpiry = this.processedWebhookCache.get(key);
    if (existingExpiry && now < existingExpiry) {
      return false;
    }
    this.processedWebhookCache.set(key, now + ttlSeconds * 1000);
    return true;
  }

  verifyWebhookSignature(payload: unknown, signatureHeader: string): boolean {
    const parts = this.parseSignatureHeader(signatureHeader);
    if (!parts) {
      return false;
    }

    const serializedBody =
      typeof payload === 'string' ? payload : JSON.stringify(payload);
    const sourceString = `${parts.time}.${serializedBody}`;
    const expectedHex = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(sourceString)
      .digest('hex');

    const expectedBuf = Buffer.from(expectedHex, 'hex');
    const actualBuf = Buffer.from(parts.sig1, 'hex');
    return (
      expectedBuf.length === actualBuf.length &&
      crypto.timingSafeEqual(expectedBuf, actualBuf)
    );
  }

  /**
   * Retrieves the vertical swipe video feed consisting only of published listings with READY videos.
   */
  async getVideoFeed(cursor?: string, limit = 10) {
    const where: any = {
      publicationStatus: 'published',
      media: {
        some: {
          mediaType: 'video',
          processingStatus: 'ready',
        },
      },
    };

    if (cursor) {
      where.refreshedAt = { lt: new Date(cursor) };
    }

    const items = await this.prisma.listing.findMany({
      where,
      take: limit + 1,
      orderBy: { refreshedAt: 'desc' },
      include: {
        media: {
          where: { mediaType: 'video' },
          take: 1,
        },
        area: {
          include: {
            city: {
              include: { governorate: true },
            },
          },
        },
        account: {
          include: {
            owner: { select: { id: true, fullName: true, avatarUrl: true } },
          },
        },
      },
    });

    let nextCursor: string | null = null;
    let results = items;

    if (items.length > limit) {
      nextCursor = items[items.length - 1].refreshedAt.toISOString();
      results = items.slice(0, limit);
    }

    return {
      items: results.map((item) => ({
        listingId: item.id,
        title: item.title,
        price: Number(item.price),
        cityName: item.area.city.nameAr,
        governorateName: item.area.city.governorate.nameAr,
        videoHlsUrl: item.media[0]?.publicUrl ?? null,
        videoStreamUid: item.media[0]?.storageKey ?? null,
        seller: item.account.owner,
        refreshedAt: item.refreshedAt,
      })),
      nextCursor,
    };
  }
}
