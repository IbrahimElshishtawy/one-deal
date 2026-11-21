import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

const BASE32_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

@Injectable()
export class TotpService {
  private readonly encryptionKey: Buffer;

  constructor(private readonly configService: ConfigService) {
    const rawKey =
      this.configService.get<string>('ADMIN_MFA_ENCRYPTION_KEY') ||
      this.configService.get<string>('JWT_ACCESS_SECRET') ||
      'dev_only_local_mfa_key_32_bytes_min';
    this.encryptionKey = crypto.createHash('sha256').update(rawKey).digest();
  }

  generateBase32Secret(byteLength = 20): string {
    const bytes = crypto.randomBytes(byteLength);
    let bits = 0;
    let value = 0;
    let output = '';

    for (const byte of bytes) {
      value = (value << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        output += BASE32_ALPHABET[(value >>> (bits - 5)) & 31];
        bits -= 5;
      }
    }
    if (bits > 0) {
      output += BASE32_ALPHABET[(value << (5 - bits)) & 31];
    }
    return output;
  }

  buildOtpAuthUri(
    email: string,
    secret: string,
    issuer = 'Deal One Admin',
  ): string {
    const label = encodeURIComponent(`${issuer}:${email}`);
    const encodedIssuer = encodeURIComponent(issuer);
    return `otpauth://totp/${label}?secret=${secret}&issuer=${encodedIssuer}&algorithm=SHA1&digits=6&period=30`;
  }

  verifyTotp(secretBase32: string, code: string, window = 1): boolean {
    const cleanCode = String(code ?? '')
      .trim()
      .replace(/\s+/g, '');
    if (!/^\d{6}$/.test(cleanCode)) {
      return false;
    }

    const secretBytes = this.decodeBase32(secretBase32);
    if (secretBytes.length === 0) return false;

    const currentCounter = Math.floor(Date.now() / 1000 / 30);
    const candidateBuf = Buffer.from(cleanCode, 'utf8');

    for (let offset = -window; offset <= window; offset++) {
      const expected = this.generateHotp(secretBytes, currentCounter + offset);
      const expectedBuf = Buffer.from(expected, 'utf8');
      if (
        expectedBuf.length === candidateBuf.length &&
        crypto.timingSafeEqual(expectedBuf, candidateBuf)
      ) {
        return true;
      }
    }
    return false;
  }

  generateTotpForTime(secretBase32: string, timestampMs = Date.now()): string {
    const secretBytes = this.decodeBase32(secretBase32);
    const counter = Math.floor(timestampMs / 1000 / 30);
    return this.generateHotp(secretBytes, counter);
  }

  encryptSecret(plainSecret: string): string {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    const encrypted = Buffer.concat([
      cipher.update(plainSecret, 'utf8'),
      cipher.final(),
    ]);
    const authTag = cipher.getAuthTag();
    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
  }

  decryptSecret(payload: string): string {
    const parts = payload.split(':');
    if (parts.length !== 3) {
      throw new Error('Invalid encrypted MFA secret format');
    }
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
  }

  generateRecoveryCodes(count = 8): {
    plainCodes: string[];
    hashedCodes: string[];
  } {
    const plainCodes: string[] = [];
    const hashedCodes: string[] = [];
    for (let i = 0; i < count; i++) {
      const part1 = crypto.randomBytes(2).toString('hex').toUpperCase();
      const part2 = crypto.randomBytes(2).toString('hex').toUpperCase();
      const code = `${part1}-${part2}`;
      plainCodes.push(code);
      hashedCodes.push(this.hashRecoveryCode(code));
    }
    return { plainCodes, hashedCodes };
  }

  hashRecoveryCode(code: string): string {
    const normalized = code.trim().toUpperCase();
    return crypto.createHash('sha256').update(normalized).digest('hex');
  }

  private generateHotp(secret: Buffer, counter: number): string {
    const counterBuf = Buffer.alloc(8);
    counterBuf.writeBigInt64BE(BigInt(counter), 0);

    const hmac = crypto.createHmac('sha1', secret).update(counterBuf).digest();
    const offset = hmac[hmac.length - 1] & 0x0f;
    const binary =
      ((hmac[offset] & 0x7f) << 24) |
      ((hmac[offset + 1] & 0xff) << 16) |
      ((hmac[offset + 2] & 0xff) << 8) |
      (hmac[offset + 3] & 0xff);

    return String(binary % 1_000_000).padStart(6, '0');
  }

  private decodeBase32(input: string): Buffer {
    const clean = input.toUpperCase().replace(/=+$/, '').replace(/\s+/g, '');
    let bits = 0;
    let value = 0;
    const bytes: number[] = [];

    for (const char of clean) {
      const idx = BASE32_ALPHABET.indexOf(char);
      if (idx === -1) continue;
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        bytes.push((value >>> (bits - 8)) & 255);
        bits -= 8;
      }
    }
    return Buffer.from(bytes);
  }
}
