import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

export const ALLOWED_VERIFICATION_MIME_TYPES = [
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
] as const;

export type AllowedVerificationMimeType =
  (typeof ALLOWED_VERIFICATION_MIME_TYPES)[number];

export const MAX_VERIFICATION_DOC_SIZE_BYTES = 10 * 1024 * 1024; // 10 MB

export interface PrivateUploadTarget {
  storageKey: string;
  uploadUrl: string;
  expiresInSeconds: number;
  contentType: string;
  maxSizeBytes: number;
}

export interface PrivateAccessTarget {
  accessUrl: string;
  expiresInSeconds: number;
}

/**
 * Private Verification Document Storage Service.
 *
 * Security invariants:
 * - Sensitive KYC/business verification documents are NEVER placed under public
 *   listing media paths (`uploads/images/...`) and NEVER exposed via `R2_PUBLIC_DOMAIN`.
 * - Canonical private key format:
 *     `private/seller-verification/<userId>/<applicationId>/<uuid>.<ext>`
 * - Uses dedicated private bucket (`R2_PRIVATE_BUCKET_NAME` or `${R2_BUCKET_NAME}-private`).
 * - Generates short-lived AWS SigV4 presigned PUT/GET URLs (never leaks raw credentials).
 */
@Injectable()
export class PrivateDocumentStorageService {
  private readonly logger = new Logger(PrivateDocumentStorageService.name);
  private readonly privateBucketName: string;
  private readonly r2AccountId: string;
  private readonly r2AccessKeyId: string;
  private readonly r2SecretAccessKey: string;
  private readonly nodeEnv: string;
  private readonly fallbackSigningSecret: string;

  constructor(private readonly configService: ConfigService) {
    const publicBucket = this.configService.get<string>(
      'R2_BUCKET_NAME',
      'marketspace-media',
    );
    this.privateBucketName = this.configService.get<string>(
      'R2_PRIVATE_BUCKET_NAME',
      `${publicBucket}-private`,
    );
    this.r2AccountId = this.configService.get<string>('R2_ACCOUNT_ID', '');
    this.r2AccessKeyId = this.configService.get<string>('R2_ACCESS_KEY_ID', '');
    this.r2SecretAccessKey = this.configService.get<string>(
      'R2_SECRET_ACCESS_KEY',
      '',
    );
    this.nodeEnv = this.configService.get<string>('NODE_ENV', 'development');
    this.fallbackSigningSecret = this.configService.get<string>(
      'JWT_ACCESS_SECRET',
      'dev-private-doc-signing-secret',
    );
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

  validateFileMetadata(mimeType: string, fileSizeBytes: number): void {
    if (
      !ALLOWED_VERIFICATION_MIME_TYPES.includes(
        mimeType as AllowedVerificationMimeType,
      )
    ) {
      throw new BadRequestException(
        `Unsupported verification document type '${mimeType}'. Allowed types: ${ALLOWED_VERIFICATION_MIME_TYPES.join(', ')}`,
      );
    }

    if (
      !Number.isInteger(fileSizeBytes) ||
      fileSizeBytes <= 0 ||
      fileSizeBytes > MAX_VERIFICATION_DOC_SIZE_BYTES
    ) {
      throw new BadRequestException(
        `Verification document size must be between 1 byte and ${MAX_VERIFICATION_DOC_SIZE_BYTES / (1024 * 1024)} MB`,
      );
    }
  }

  generatePrivateUploadUrl(
    userId: string,
    applicationId: string,
    mimeType: string,
    fileSizeBytes: number,
  ): PrivateUploadTarget {
    this.validateFileMetadata(mimeType, fileSizeBytes);

    const hasCredentials = this.hasRealR2Credentials();
    if (!hasCredentials && this.nodeEnv === 'production') {
      throw new InternalServerErrorException(
        'Private document storage credentials are not configured in production',
      );
    }

    const ext = this.getExtensionFromMime(
      mimeType as AllowedVerificationMimeType,
    );
    const randomUuid = crypto.randomUUID();
    const storageKey = `private/seller-verification/${userId}/${applicationId}/${randomUuid}.${ext}`;
    const expiresInSeconds = 900; // 15 minutes

    const uploadUrl = hasCredentials
      ? this.signR2PresignedUrl('PUT', storageKey, expiresInSeconds, mimeType)
      : this.buildLocalFallbackSignedUrl('PUT', storageKey, expiresInSeconds);

    return {
      storageKey,
      uploadUrl,
      expiresInSeconds,
      contentType: mimeType,
      maxSizeBytes: MAX_VERIFICATION_DOC_SIZE_BYTES,
    };
  }

  generatePrivateAccessUrl(
    storageKey: string,
    expiresInSeconds = 300,
  ): PrivateAccessTarget {
    this.assertPrivateStorageKeyFormat(storageKey);

    const hasCredentials = this.hasRealR2Credentials();
    if (!hasCredentials && this.nodeEnv === 'production') {
      throw new InternalServerErrorException(
        'Private document storage credentials are not configured in production',
      );
    }

    const accessUrl = hasCredentials
      ? this.signR2PresignedUrl('GET', storageKey, expiresInSeconds)
      : this.buildLocalFallbackSignedUrl('GET', storageKey, expiresInSeconds);

    return {
      accessUrl,
      expiresInSeconds,
    };
  }

  /**
   * Validates strict private storage key format and blocks path traversal or public paths.
   */
  assertPrivateStorageKeyFormat(storageKey: string): {
    userId: string;
    applicationId: string;
    fileName: string;
  } {
    if (!storageKey || typeof storageKey !== 'string') {
      throw new ForbiddenException('Invalid verification document storage key');
    }

    if (
      storageKey !== storageKey.trim() ||
      storageKey.startsWith('/') ||
      storageKey.includes('..') ||
      storageKey.includes('\\') ||
      storageKey.includes('?') ||
      storageKey.includes('#') ||
      storageKey.includes('\0') ||
      /%2e|%2f|%5c/i.test(storageKey)
    ) {
      throw new ForbiddenException(
        'Invalid storage key format or disallowed path characters',
      );
    }

    const segments = storageKey.split('/');
    if (segments.length !== 5) {
      throw new ForbiddenException(
        'Storage key does not match private verification document path structure',
      );
    }

    const [root, scope, ownerUserId, applicationId, fileName] = segments;

    if (root !== 'private' || scope !== 'seller-verification') {
      throw new ForbiddenException(
        'Verification documents must be stored exclusively in private verification storage',
      );
    }

    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(ownerUserId) || !uuidRegex.test(applicationId)) {
      throw new ForbiddenException('Invalid owner or application identifier in storage key');
    }

    if (!/^[a-zA-Z0-9_-]{1,128}\.(pdf|jpg|jpeg|png|webp)$/i.test(fileName)) {
      throw new ForbiddenException('Invalid verification document filename or extension');
    }

    return { userId: ownerUserId, applicationId, fileName };
  }

  validatePrivateDocumentOwnership(
    userId: string,
    applicationId: string,
    storageKey: string,
  ): void {
    const parsed = this.assertPrivateStorageKeyFormat(storageKey);
    if (parsed.userId !== userId || parsed.applicationId !== applicationId) {
      throw new ForbiddenException(
        'Cannot attach verification document belonging to another user or application',
      );
    }
  }

  private signR2PresignedUrl(
    method: 'PUT' | 'GET',
    storageKey: string,
    expiresSeconds: number,
    contentType?: string,
    now = new Date(),
  ): string {
    const host = `${this.r2AccountId}.r2.cloudflarestorage.com`;
    const region = 'auto';
    const service = 's3';
    const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, '');
    const dateStamp = amzDate.slice(0, 8);
    const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
    const canonicalUri = `/${encodeURIComponent(this.privateBucketName)}/${storageKey
      .split('/')
      .map((seg) => encodeURIComponent(seg))
      .join('/')}`;

    const signedHeaders = contentType ? 'content-type;host' : 'host';
    const queryParams = new URLSearchParams({
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': `${this.r2AccessKeyId}/${credentialScope}`,
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': String(expiresSeconds),
      'X-Amz-SignedHeaders': signedHeaders,
    });
    queryParams.sort();
    const canonicalQuery = queryParams.toString();

    const canonicalHeaders = contentType
      ? `content-type:${contentType}\nhost:${host}\n`
      : `host:${host}\n`;

    const canonicalRequest = [
      method,
      canonicalUri,
      canonicalQuery,
      canonicalHeaders,
      signedHeaders,
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

  private buildLocalFallbackSignedUrl(
    method: 'PUT' | 'GET',
    storageKey: string,
    expiresInSeconds: number,
  ): string {
    const expiresAt = Math.floor(Date.now() / 1000) + expiresInSeconds;
    const sig = crypto
      .createHmac('sha256', this.fallbackSigningSecret)
      .update(`${method}:${storageKey}:${expiresAt}`)
      .digest('hex');
    const opaqueRef = crypto
      .createHash('sha256')
      .update(storageKey)
      .digest('hex')
      .slice(0, 32);
    this.logger.warn(
      `[PrivateDocumentStorage] Using signed fallback URL for ref=${opaqueRef} (R2 credentials not configured)`,
    );
    return `https://private-storage.deal-one.local/v1/docs/${opaqueRef}?op=${method.toLowerCase()}&expires=${expiresAt}&sig=${sig}`;
  }

  private hmac(key: string | Buffer, data: string): Buffer {
    return crypto.createHmac('sha256', key).update(data).digest();
  }

  private getExtensionFromMime(mime: AllowedVerificationMimeType): string {
    switch (mime) {
      case 'application/pdf':
        return 'pdf';
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'bin';
    }
  }
}
