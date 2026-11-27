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

export interface UploadedObjectVerificationResult {
  verified: boolean;
  skippedReason?: 'NO_R2_CREDENTIALS';
  contentType?: string | null;
  contentLength?: number | null;
  etag?: string | null;
}

export interface StorageDeleteResult {
  deleted: boolean;
  skippedReason?: 'NO_R2_CREDENTIALS';
  statusCode?: number;
}

export interface MalwareScanResult {
  status: 'CLEAN' | 'INFECTED' | 'SCANNER_NOT_CONFIGURED';
  provider: string;
  detail?: string;
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

  validateFileMetadata(
    mimeType: string,
    fileSizeBytes: number,
    options?: {
      acceptedMimeTypes?: readonly string[];
      maxFileSizeBytes?: number;
    },
  ): void {
    const allowedMimes =
      options?.acceptedMimeTypes && options.acceptedMimeTypes.length > 0
        ? options.acceptedMimeTypes
        : ALLOWED_VERIFICATION_MIME_TYPES;

    if (!allowedMimes.includes(mimeType)) {
      throw new BadRequestException({
        code: 'INVALID_DOCUMENT_MIME_TYPE',
        message: `Unsupported verification document type '${mimeType}'. Allowed types: ${allowedMimes.join(', ')}`,
      });
    }

    const effectiveMaxSize = Math.min(
      options?.maxFileSizeBytes && options.maxFileSizeBytes > 0
        ? options.maxFileSizeBytes
        : MAX_VERIFICATION_DOC_SIZE_BYTES,
      25 * 1024 * 1024, // hard global safety ceiling: 25 MB
    );

    if (
      !Number.isInteger(fileSizeBytes) ||
      fileSizeBytes <= 0 ||
      fileSizeBytes > effectiveMaxSize
    ) {
      throw new BadRequestException({
        code: 'DOCUMENT_SIZE_EXCEEDED',
        message: `Verification document size must be between 1 byte and ${(effectiveMaxSize / (1024 * 1024)).toFixed(2).replace(/\.00$/, '')} MB`,
        maxSizeBytes: effectiveMaxSize,
      });
    }
  }

  /**
   * Validates that a provided filename has a permitted extension that matches
   * the declared MIME type (blocks double-extension / disguised executable uploads).
   */
  validateFileExtension(fileName: string, mimeType: string): void {
    const trimmed = (fileName || '').trim();
    const lastDot = trimmed.lastIndexOf('.');
    if (lastDot <= 0 || lastDot === trimmed.length - 1) {
      throw new BadRequestException({
        code: 'INVALID_DOCUMENT_EXTENSION',
        message:
          'Verification document filename must include a valid file extension',
      });
    }

    const ext = trimmed.slice(lastDot + 1).toLowerCase();
    const allowedByMime: Record<string, string[]> = {
      'application/pdf': ['pdf'],
      'image/jpeg': ['jpg', 'jpeg'],
      'image/png': ['png'],
      'image/webp': ['webp'],
    };

    const allowedExtensions = allowedByMime[mimeType];
    if (!allowedExtensions || !allowedExtensions.includes(ext)) {
      throw new BadRequestException({
        code: 'FILE_EXTENSION_MIME_MISMATCH',
        message: `File extension '.${ext}' does not match declared MIME type '${mimeType}'`,
      });
    }
  }

  /**
   * Validates actual file magic bytes against the declared MIME type to block
   * spoofed/renamed executable or polyglot payloads.
   */
  validateFileContentSignature(
    mimeType: string,
    fileHeaderBase64?: string | null,
  ): void {
    if (!fileHeaderBase64) {
      return;
    }

    let buf: Buffer;
    try {
      buf = Buffer.from(fileHeaderBase64.trim(), 'base64');
    } catch {
      throw new BadRequestException({
        code: 'INVALID_FILE_CONTENT',
        message: 'Invalid base64 file header provided for content verification',
      });
    }

    if (buf.length < 4) {
      throw new BadRequestException({
        code: 'INVALID_FILE_CONTENT',
        message: 'File content header is too short to verify file signature',
      });
    }

    this.validateMagicBytesBuffer(mimeType, buf);
  }

  /**
   * Validates raw file magic bytes buffer against the declared MIME type.
   * Used both for pre-check headers and authoritative server-side R2 ranged-GET verification.
   */
  validateMagicBytesBuffer(mimeType: string, buf: Buffer): void {
    if (!buf || buf.length < 4) {
      throw new BadRequestException({
        code: 'INVALID_FILE_CONTENT',
        message:
          'Uploaded file content is truncated or too short to verify file signature',
      });
    }

    let valid = false;
    switch (mimeType) {
      case 'application/pdf':
        // %PDF-
        valid =
          buf.length >= 5 &&
          buf[0] === 0x25 &&
          buf[1] === 0x50 &&
          buf[2] === 0x44 &&
          buf[3] === 0x46 &&
          buf[4] === 0x2d;
        break;
      case 'image/jpeg':
        // FF D8 FF
        valid = buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff;
        break;
      case 'image/png':
        // 89 50 4E 47 0D 0A 1A 0A
        valid =
          buf.length >= 8 &&
          buf[0] === 0x89 &&
          buf[1] === 0x50 &&
          buf[2] === 0x4e &&
          buf[3] === 0x47 &&
          buf[4] === 0x0d &&
          buf[5] === 0x0a &&
          buf[6] === 0x1a &&
          buf[7] === 0x0a;
        break;
      case 'image/webp':
        // RIFF....WEBP
        valid =
          buf.length >= 12 &&
          buf.toString('ascii', 0, 4) === 'RIFF' &&
          buf.toString('ascii', 8, 12) === 'WEBP';
        break;
      default:
        valid = false;
    }

    if (!valid) {
      throw new BadRequestException({
        code: 'FILE_CONTENT_MIME_MISMATCH',
        message: `Uploaded file content signature does not match declared MIME type '${mimeType}'`,
      });
    }
  }

  generatePrivateUploadUrl(
    userId: string,
    applicationId: string,
    mimeType: string,
    fileSizeBytes: number,
    options?: {
      acceptedMimeTypes?: readonly string[];
      maxFileSizeBytes?: number;
    },
  ): PrivateUploadTarget {
    this.validateFileMetadata(mimeType, fileSizeBytes, options);

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
      maxSizeBytes:
        options?.maxFileSizeBytes ?? MAX_VERIFICATION_DOC_SIZE_BYTES,
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
      throw new ForbiddenException(
        'Invalid owner or application identifier in storage key',
      );
    }

    if (!/^[a-zA-Z0-9_-]{1,128}\.(pdf|jpg|jpeg|png|webp)$/i.test(fileName)) {
      throw new ForbiddenException(
        'Invalid verification document filename or extension',
      );
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

  /**
   * Server-side object verification via AWS SigV4 signed HEAD request against Cloudflare R2.
   * Confirms the uploaded object actually exists, is non-empty, within maxSizeBytes,
   * and matches the declared content-type when real R2 credentials are configured.
   * In local/test environments without R2 credentials, returns `skippedReason: 'NO_R2_CREDENTIALS'`.
   */
  async verifyUploadedObject(
    storageKey: string,
    expectedMimeType: string,
    maxSizeBytes = MAX_VERIFICATION_DOC_SIZE_BYTES,
  ): Promise<UploadedObjectVerificationResult> {
    this.assertPrivateStorageKeyFormat(storageKey);

    if (!this.hasRealR2Credentials()) {
      return { verified: true, skippedReason: 'NO_R2_CREDENTIALS' };
    }

    const headUrl = this.signR2PresignedUrl('HEAD', storageKey, 60);
    let response: Response;
    try {
      response = await fetch(headUrl, {
        method: 'HEAD',
        signal: AbortSignal.timeout(10_000),
      });
    } catch (err: any) {
      this.logger.error(
        `[PrivateDocumentStorage] R2 HEAD request failed: ${err?.message ?? err}`,
      );
      throw new InternalServerErrorException({
        code: 'DOCUMENT_STORAGE_VERIFICATION_FAILED',
        message:
          'Could not verify uploaded verification document in private storage',
      });
    }

    if (response.status === 404) {
      throw new BadRequestException({
        code: 'DOCUMENT_NOT_UPLOADED',
        message:
          'Uploaded document was not found in private storage. Please upload the file before confirming.',
      });
    }

    if (!response.ok) {
      throw new InternalServerErrorException({
        code: 'DOCUMENT_STORAGE_VERIFICATION_FAILED',
        message: `Private storage verification failed with status ${response.status}`,
      });
    }

    const contentLengthHeader = response.headers.get('content-length');
    const contentLength = contentLengthHeader
      ? Number(contentLengthHeader)
      : null;
    const rawContentType = response.headers.get('content-type');
    const normalizedContentType = rawContentType
      ? rawContentType.split(';')[0].trim().toLowerCase()
      : null;

    if (
      contentLength !== null &&
      (!Number.isFinite(contentLength) ||
        contentLength <= 0 ||
        contentLength > maxSizeBytes)
    ) {
      throw new BadRequestException({
        code: 'DOCUMENT_SIZE_EXCEEDED',
        message: `Uploaded object size (${contentLength} bytes) exceeds maximum allowed limit (${maxSizeBytes} bytes)`,
      });
    }

    if (
      normalizedContentType &&
      normalizedContentType !== 'application/octet-stream' &&
      normalizedContentType !== expectedMimeType.toLowerCase()
    ) {
      throw new BadRequestException({
        code: 'FILE_CONTENT_MIME_MISMATCH',
        message: `Uploaded object content-type '${normalizedContentType}' does not match declared MIME type '${expectedMimeType}'`,
      });
    }

    // Step 2: Authoritative server-side ranged GET (first 16 bytes) for real magic-byte verification.
    // Never rely solely on client-supplied fileHeaderBase64 or R2 HEAD metadata.
    const getUrl = this.signR2PresignedUrl('GET', storageKey, 60);
    let rangeResponse: Response;
    try {
      rangeResponse = await fetch(getUrl, {
        method: 'GET',
        headers: { Range: 'bytes=0-15' },
        signal: AbortSignal.timeout(10_000),
      });
    } catch (err: any) {
      this.logger.error(
        `[PrivateDocumentStorage] R2 ranged GET failed: ${err?.message ?? err}`,
      );
      throw new InternalServerErrorException({
        code: 'DOCUMENT_STORAGE_VERIFICATION_FAILED',
        message:
          'Could not inspect uploaded verification document bytes in private storage',
      });
    }

    if (rangeResponse.status === 404) {
      throw new BadRequestException({
        code: 'DOCUMENT_NOT_UPLOADED',
        message: 'Uploaded document was not found in private storage.',
      });
    }

    if (rangeResponse.status === 416) {
      throw new BadRequestException({
        code: 'INVALID_FILE_CONTENT',
        message: 'Uploaded verification document is empty or truncated.',
      });
    }

    if (rangeResponse.status !== 200 && rangeResponse.status !== 206) {
      throw new InternalServerErrorException({
        code: 'DOCUMENT_STORAGE_VERIFICATION_FAILED',
        message: `Private storage byte inspection failed with status ${rangeResponse.status}`,
      });
    }

    const headerBytes = Buffer.from(await rangeResponse.arrayBuffer());
    this.validateMagicBytesBuffer(expectedMimeType, headerBytes);

    return {
      verified: true,
      contentType: normalizedContentType,
      contentLength,
      etag: response.headers.get('etag'),
    };
  }

  /**
   * Permanently deletes a private verification document object from Cloudflare R2
   * using an AWS SigV4 signed DELETE request (used by retention & orphan cleanup workers).
   * Treats 404 as already deleted (idempotent).
   */
  async deleteObject(storageKey: string): Promise<StorageDeleteResult> {
    this.assertPrivateStorageKeyFormat(storageKey);

    if (!this.hasRealR2Credentials()) {
      return { deleted: true, skippedReason: 'NO_R2_CREDENTIALS' };
    }

    const deleteUrl = this.signR2PresignedUrl('DELETE', storageKey, 60);
    const response = await fetch(deleteUrl, { method: 'DELETE' });

    if (
      response.status === 204 ||
      response.status === 200 ||
      response.status === 404
    ) {
      return { deleted: true, statusCode: response.status };
    }

    throw new InternalServerErrorException(
      `Failed to delete private document object from R2 (HTTP ${response.status})`,
    );
  }

  /**
   * Malware scanning integration boundary.
   * Currently no external AV/malware engine (e.g. ClamAV / Cloudflare R2 Security Scan)
   * is provisioned in this environment; returns SCANNER_NOT_CONFIGURED transparently.
   */
  async scanDocumentBoundary(_storageKey: string): Promise<MalwareScanResult> {
    return {
      status: 'SCANNER_NOT_CONFIGURED',
      provider: 'none',
      detail:
        'External malware scanner is not configured; MIME, extension, size, and magic-byte signature checks were enforced.',
    };
  }

  private signR2PresignedUrl(
    method: 'PUT' | 'GET' | 'HEAD' | 'DELETE',
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
