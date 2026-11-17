import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import {
  PresignedUploadDto,
  AllowedImageMime,
} from './dto/presigned-upload.dto';
import { ConfirmUploadDto } from './dto/confirm-upload.dto';

export interface PresignedTarget {
  key: string;
  uploadUrl: string;
  publicUrl: string;
  contentType: string;
}

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);
  private readonly publicDomain: string;
  private readonly bucketName: string;
  private readonly r2AccountId: string;
  private readonly r2AccessKeyId: string;
  private readonly r2SecretAccessKey: string;
  private readonly nodeEnv: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.publicDomain = this.configService.get<string>(
      'R2_PUBLIC_DOMAIN',
      'https://cdn.marketspace.eg',
    );
    this.bucketName = this.configService.get<string>(
      'R2_BUCKET_NAME',
      'marketspace-media',
    );
    this.r2AccountId = this.configService.get<string>('R2_ACCOUNT_ID', '');
    this.r2AccessKeyId = this.configService.get<string>('R2_ACCESS_KEY_ID', '');
    this.r2SecretAccessKey = this.configService.get<string>(
      'R2_SECRET_ACCESS_KEY',
      '',
    );
    this.nodeEnv = this.configService.get<string>('NODE_ENV', 'development');
  }

  private hasRealR2Credentials(): boolean {
    return (
      !!this.r2AccountId &&
      !!this.r2AccessKeyId &&
      !!this.r2SecretAccessKey &&
      !this.r2AccountId.startsWith('placeholder') &&
      !this.r2AccessKeyId.startsWith('placeholder') &&
      !this.r2SecretAccessKey.startsWith('placeholder')
    );
  }

  /**
   * Generates direct-to-storage AWS SigV4 presigned PUT URLs for Cloudflare R2, isolated per user.
   */
  async generateImageUploadUrls(
    userId: string,
    dto: PresignedUploadDto,
  ): Promise<PresignedTarget[]> {
    const targets: PresignedTarget[] = [];
    const datePrefix = new Date().toISOString().slice(0, 7);
    const hasCredentials = this.hasRealR2Credentials();

    if (!hasCredentials && this.nodeEnv === 'production') {
      throw new InternalServerErrorException(
        'Cloudflare R2 storage credentials are missing in production environment',
      );
    }

    for (const mime of dto.contentTypes) {
      const ext = this.getExtensionFromMime(mime);
      const randomUuid = crypto.randomUUID();
      const storageKey = `uploads/images/${datePrefix}/${userId}/${randomUuid}.${ext}`;
      const publicUrl = `${this.publicDomain}/${storageKey}`;

      let uploadUrl: string;
      if (hasCredentials) {
        uploadUrl = this.signR2PresignedPutUrl(storageKey, mime, 900);
      } else {
        this.logger.warn(
          `[MediaService] Using local fallback upload URL for ${storageKey} (R2 credentials not configured)`,
        );
        const token = crypto.randomBytes(16).toString('hex');
        uploadUrl = `https://${this.bucketName}.r2.cloudflarestorage.com/${storageKey}?X-Amz-Expires=900&token=${token}`;
      }

      targets.push({
        key: storageKey,
        uploadUrl,
        publicUrl,
        contentType: mime,
      });
    }

    return targets;
  }

  /**
   * Computes a standard AWS Signature Version 4 (SigV4) presigned PUT URL for Cloudflare R2.
   */
  signR2PresignedPutUrl(
    storageKey: string,
    contentType: string,
    expiresSeconds = 900,
    now = new Date(),
  ): string {
    const host = `${this.r2AccountId}.r2.cloudflarestorage.com`;
    const region = 'auto';
    const service = 's3';
    const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, '');
    const dateStamp = amzDate.slice(0, 8);
    const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
    const canonicalUri = `/${encodeURIComponent(this.bucketName)}/${storageKey
      .split('/')
      .map((seg) => encodeURIComponent(seg))
      .join('/')}`;

    const queryParams = new URLSearchParams({
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': `${this.r2AccessKeyId}/${credentialScope}`,
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': String(expiresSeconds),
      'X-Amz-SignedHeaders': 'content-type;host',
    });
    queryParams.sort();
    const canonicalQuery = queryParams.toString();

    const canonicalHeaders = `content-type:${contentType}\nhost:${host}\n`;
    const canonicalRequest = [
      'PUT',
      canonicalUri,
      canonicalQuery,
      canonicalHeaders,
      'content-type;host',
      'UNSIGNED-PAYLOAD',
    ].join('\n');

    const stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      crypto.createHash('sha256').update(canonicalRequest).digest('hex'),
    ].join('\n');

    const kDate = this.hmac(`AWS4${this.r2SecretAccessKey}`, dateStamp);
    const kRegion = this.hmac(kDate, region);
    const kService = this.hmac(kRegion, service);
    const kSigning = this.hmac(kService, 'aws4_request');
    const signature = crypto
      .createHmac('sha256', kSigning)
      .update(stringToSign)
      .digest('hex');

    return `https://${host}${canonicalUri}?${canonicalQuery}&X-Amz-Signature=${signature}`;
  }

  private hmac(key: string | Buffer, data: string): Buffer {
    return crypto.createHmac('sha256', key).update(data).digest();
  }

  /**
   * Confirms upload completion, validates path isolation, and optionally attaches to listing.
   */
  async confirmUpload(userId: string, dto: ConfirmUploadDto) {
    if (!dto.storageKey.includes(`/${userId}/`)) {
      throw new ForbiddenException(
        'Cannot confirm upload for storage keys belonging to other users',
      );
    }

    const publicUrl = `${this.publicDomain}/${dto.storageKey}`;
    let mediaRecord = null;

    if (dto.listingId) {
      const listing = await this.prisma.listing.findUnique({
        where: { id: dto.listingId },
        include: { account: true },
      });

      if (!listing || listing.deletedAt) {
        throw new NotFoundException('Listing not found');
      }

      if (listing.account.ownerUserId !== userId) {
        const member = await this.prisma.accountMember.findUnique({
          where: {
            uq_account_user: {
              accountId: listing.accountId,
              userId,
            },
          },
        });
        if (!member) {
          throw new ForbiddenException(
            'You do not have permission to attach media to this listing',
          );
        }
      }

      if (dto.isPrimary) {
        await this.prisma.listingMedia.updateMany({
          where: { listingId: dto.listingId },
          data: { isPrimary: false },
        });
      }

      mediaRecord = await this.prisma.listingMedia.create({
        data: {
          listingId: dto.listingId,
          mediaType: 'image',
          storageKey: dto.storageKey,
          publicUrl,
          thumbnailUrl: publicUrl,
          sortOrder: dto.sortOrder ?? 0,
          isPrimary: dto.isPrimary ?? false,
          processingStatus: 'ready',
        },
      });
    }

    return {
      success: true,
      storageKey: dto.storageKey,
      publicUrl,
      mediaId: mediaRecord?.id ?? null,
      processingStatus: 'ready',
    };
  }

  private getExtensionFromMime(mime: AllowedImageMime): string {
    switch (mime) {
      case AllowedImageMime.JPEG:
        return 'jpg';
      case AllowedImageMime.PNG:
        return 'png';
      case AllowedImageMime.WEBP:
        return 'webp';
      default:
        return 'jpg';
    }
  }
}
