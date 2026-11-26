import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

const CIPHERTEXT_HEADER = 'enc:';
const VERSION_SEGMENT_REGEX = /^v\d+$/i;

export interface DecryptionResult {
  ok: boolean;
  value: string | null;
  keyVersion: string | null;
  legacyPlaintext: boolean;
  error?: 'MALFORMED_CIPHERTEXT' | 'UNKNOWN_KEY_VERSION' | 'DECRYPTION_FAILED';
}

/**
 * AES-256-GCM Encryption Service for Sensitive Seller Identity Data.
 *
 * Security invariants:
 * - Encrypts sensitive identity identifiers (national ID, tax ID, commercial
 *   register number, authorized representative ID) at rest using AES-256-GCM
 *   with a cryptographically random 96-bit (12-byte) IV/nonce per encryption
 *   and 128-bit authentication tag validation.
 * - Supports versioned key rotation via `SELLER_PII_ENCRYPTION_KEYS`
 *   (format: `v1:<secret1>,v2:<secret2>`) and `SELLER_PII_ENCRYPTION_KEY_VERSION`
 *   without breaking decryption of existing records encrypted under older keys.
 * - Ciphertext format: `enc:<keyVersion>:<ivHex>:<authTagHex>:<ciphertextHex>`.
 * - Backward compatible with legacy `enc:v1:...` ciphertexts and pre-migration
 *   plaintext rows.
 * - NEVER logs plaintext values, keys, or raw ciphertext.
 */
@Injectable()
export class SensitiveDataCryptoService {
  private readonly logger = new Logger(SensitiveDataCryptoService.name);
  private readonly keyRing: Map<string, Buffer> = new Map();
  private readonly activeKeyVersion: string;

  constructor(private readonly configService: ConfigService) {
    const rawKeyRing =
      this.configService.get<string>('SELLER_PII_ENCRYPTION_KEYS') || '';
    const primarySingleKey =
      this.configService.get<string>('SELLER_PII_ENCRYPTION_KEY') ||
      this.configService.get<string>('ADMIN_MFA_ENCRYPTION_KEY') ||
      this.configService.get<string>('JWT_ACCESS_SECRET') ||
      'dev_only_local_seller_pii_key_32_bytes_min';

    // Parse comma-separated versioned key ring: "v1:secretA,v2:secretB"
    if (rawKeyRing.trim().length > 0) {
      for (const entry of rawKeyRing.split(',')) {
        const trimmed = entry.trim();
        if (!trimmed) continue;
        const colonIdx = trimmed.indexOf(':');
        if (colonIdx <= 0) continue;
        const version = trimmed.slice(0, colonIdx).trim().toLowerCase();
        const secret = trimmed.slice(colonIdx + 1).trim();
        if (VERSION_SEGMENT_REGEX.test(version) && secret.length > 0) {
          this.keyRing.set(version, this.deriveAes256Key(secret));
        }
      }
    }

    // Ensure v1 is always populated from SELLER_PII_ENCRYPTION_KEY (or fallback)
    if (!this.keyRing.has('v1')) {
      this.keyRing.set('v1', this.deriveAes256Key(primarySingleKey));
    }

    const configuredActiveVersion = (
      this.configService.get<string>('SELLER_PII_ENCRYPTION_KEY_VERSION') || ''
    )
      .trim()
      .toLowerCase();

    if (
      configuredActiveVersion &&
      this.keyRing.has(configuredActiveVersion)
    ) {
      this.activeKeyVersion = configuredActiveVersion;
    } else {
      // Pick the highest configured key version (e.g. v2 > v1)
      const sortedVersions = Array.from(this.keyRing.keys()).sort((a, b) => {
        const numA = parseInt(a.slice(1), 10);
        const numB = parseInt(b.slice(1), 10);
        return numB - numA;
      });
      this.activeKeyVersion = sortedVersions[0] ?? 'v1';
    }
  }

  private deriveAes256Key(secret: string): Buffer {
    return crypto.createHash('sha256').update(secret).digest();
  }

  getActiveKeyVersion(): string {
    return this.activeKeyVersion;
  }

  getAvailableKeyVersions(): string[] {
    return Array.from(this.keyRing.keys());
  }

  /**
   * Returns the key version prefix of an encrypted string (e.g. 'v1', 'v2'),
   * or null if plaintext / unencrypted.
   */
  getKeyVersion(stored?: string | null): string | null {
    if (!stored || !stored.startsWith(CIPHERTEXT_HEADER)) {
      return null;
    }
    const parts = stored.split(':');
    if (parts.length !== 5 || !VERSION_SEGMENT_REGEX.test(parts[1])) {
      return null;
    }
    return parts[1].toLowerCase();
  }

  /**
   * Encrypts plaintext using the active AES-256-GCM key version.
   * Already-encrypted values with the active version are returned as-is.
   */
  encrypt(plaintext?: string | null): string | null {
    if (!plaintext) return null;
    const trimmed = plaintext.trim();
    if (!trimmed) return null;

    const existingVersion = this.getKeyVersion(trimmed);
    if (existingVersion) {
      return trimmed;
    }

    const key = this.keyRing.get(this.activeKeyVersion);
    if (!key) {
      throw new Error(
        `Active encryption key version '${this.activeKeyVersion}' is unavailable`,
      );
    }

    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    const encrypted = Buffer.concat([
      cipher.update(trimmed, 'utf8'),
      cipher.final(),
    ]);
    const authTag = cipher.getAuthTag();
    return `${CIPHERTEXT_HEADER}${this.activeKeyVersion}:${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
  }

  /**
   * Decrypts a stored value and returns structured metadata without leaking PII.
   */
  decryptResult(stored?: string | null): DecryptionResult {
    if (!stored) {
      return {
        ok: true,
        value: null,
        keyVersion: null,
        legacyPlaintext: false,
      };
    }

    if (!stored.startsWith(CIPHERTEXT_HEADER)) {
      // Legacy plaintext fallback for pre-migration rows
      return {
        ok: true,
        value: stored,
        keyVersion: null,
        legacyPlaintext: true,
      };
    }

    const parts = stored.split(':');
    if (parts.length !== 5 || !VERSION_SEGMENT_REGEX.test(parts[1])) {
      this.logger.warn(
        'SensitiveDataCryptoService: malformed ciphertext format encountered',
      );
      return {
        ok: false,
        value: null,
        keyVersion: null,
        legacyPlaintext: false,
        error: 'MALFORMED_CIPHERTEXT',
      };
    }

    const keyVersion = parts[1].toLowerCase();
    const [, , ivHex, tagHex, dataHex] = parts;
    const key = this.keyRing.get(keyVersion);
    if (!key) {
      this.logger.warn(
        `SensitiveDataCryptoService: decryption key version '${keyVersion}' not configured in key ring`,
      );
      return {
        ok: false,
        value: null,
        keyVersion,
        legacyPlaintext: false,
        error: 'UNKNOWN_KEY_VERSION',
      };
    }

    try {
      const iv = Buffer.from(ivHex, 'hex');
      const authTag = Buffer.from(tagHex, 'hex');
      const ciphertext = Buffer.from(dataHex, 'hex');

      if (iv.length !== 12 || authTag.length !== 16) {
        return {
          ok: false,
          value: null,
          keyVersion,
          legacyPlaintext: false,
          error: 'MALFORMED_CIPHERTEXT',
        };
      }

      const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
      decipher.setAuthTag(authTag);
      const decrypted = Buffer.concat([
        decipher.update(ciphertext),
        decipher.final(),
      ]);
      return {
        ok: true,
        value: decrypted.toString('utf8'),
        keyVersion,
        legacyPlaintext: false,
      };
    } catch {
      this.logger.warn(
        `SensitiveDataCryptoService: AES-256-GCM authentication/decryption failed for keyVersion=${keyVersion}`,
      );
      return {
        ok: false,
        value: null,
        keyVersion,
        legacyPlaintext: false,
        error: 'DECRYPTION_FAILED',
      };
    }
  }

  decrypt(stored?: string | null): string | null {
    return this.decryptResult(stored).value;
  }

  isEncrypted(stored?: string | null): boolean {
    return this.getKeyVersion(stored) !== null;
  }

  /**
   * Returns true if the stored value is either legacy plaintext or encrypted
   * under an older key version than the currently active key version.
   */
  needsReencryption(stored?: string | null): boolean {
    if (!stored || !stored.trim()) return false;
    const version = this.getKeyVersion(stored);
    return version === null || version !== this.activeKeyVersion;
  }

  /**
   * Safely re-encrypts a value from an older key version (or legacy plaintext)
   * using the currently active key version. Returns null if decryption fails.
   */
  reencrypt(stored?: string | null): string | null {
    if (!stored) return null;
    if (!this.needsReencryption(stored)) {
      return stored;
    }
    const res = this.decryptResult(stored);
    if (!res.ok || !res.value) {
      return null;
    }
    return this.encrypt(res.value);
  }

  /**
   * Returns a safe masked representation (e.g. "**********4567") without exposing
   * the underlying identity number in normal API responses.
   */
  mask(stored?: string | null): string | null {
    const res = this.decryptResult(stored);
    if (!res.ok) {
      // Never leak raw ciphertext or crash serialization if a key is rotated out
      return '********';
    }
    const plain = res.value;
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
