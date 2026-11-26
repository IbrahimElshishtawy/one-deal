import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

const CIPHERTEXT_PREFIX = 'enc:v1:';

/**
 * AES-256-GCM Encryption Service for Sensitive Seller Identity Data.
 *
 * Encrypts sensitive identity identifiers (national ID, tax ID, authorized
 * representative ID) at rest using the project's established AES-256-GCM
 * architecture. Never logs plaintext values.
 */
@Injectable()
export class SensitiveDataCryptoService {
  private readonly encryptionKey: Buffer;

  constructor(private readonly configService: ConfigService) {
    const rawKey =
      this.configService.get<string>('SELLER_PII_ENCRYPTION_KEY') ||
      this.configService.get<string>('ADMIN_MFA_ENCRYPTION_KEY') ||
      this.configService.get<string>('JWT_ACCESS_SECRET') ||
      'dev_only_local_seller_pii_key_32_bytes_min';
    this.encryptionKey = crypto.createHash('sha256').update(rawKey).digest();
  }

  encrypt(plaintext?: string | null): string | null {
    if (!plaintext) return null;
    const trimmed = plaintext.trim();
    if (!trimmed) return null;
    if (trimmed.startsWith(CIPHERTEXT_PREFIX)) {
      return trimmed;
    }

    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    const encrypted = Buffer.concat([
      cipher.update(trimmed, 'utf8'),
      cipher.final(),
    ]);
    const authTag = cipher.getAuthTag();
    return `${CIPHERTEXT_PREFIX}${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
  }

  decrypt(stored?: string | null): string | null {
    if (!stored) return null;
    if (!stored.startsWith(CIPHERTEXT_PREFIX)) {
      // Legacy plaintext fallback for pre-migration rows
      return stored;
    }

    const body = stored.slice(CIPHERTEXT_PREFIX.length);
    const parts = body.split(':');
    if (parts.length !== 3) {
      return null;
    }

    try {
      const [ivHex, tagHex, dataHex] = parts;
      const decipher = crypto.createDecipheriv(
        'aes-256-gcm',
        this.encryptionKey,
        Buffer.from(ivHex, 'hex'),
      );
      decipher.setAuthTag(Buffer.from(tagHex, 'hex'));
      const decrypted = Buffer.concat([
        decipher.update(Buffer.from(dataHex, 'hex')),
        decipher.final(),
      ]);
      return decrypted.toString('utf8');
    } catch {
      return null;
    }
  }

  isEncrypted(stored?: string | null): boolean {
    return typeof stored === 'string' && stored.startsWith(CIPHERTEXT_PREFIX);
  }

  /**
   * Returns a safe masked representation (e.g. "**********4567") without exposing
   * the underlying identity number in normal API responses.
   */
  mask(stored?: string | null): string | null {
    const plain = this.decrypt(stored);
    if (!plain) return null;
    if (plain.length <= 4) return '****';
    return `${'*'.repeat(Math.max(4, plain.length - 4))}${plain.slice(-4)}`;
  }

  /**
   * Validates whether a stored value (encrypted or legacy) meets minimum length.
   */
  hasMinimumLength(stored: string | null | undefined, minLen: number): boolean {
    const plain = this.decrypt(stored);
    return !!plain && plain.trim().length >= minLen;
  }
}
