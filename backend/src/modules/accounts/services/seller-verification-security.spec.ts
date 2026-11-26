import { ConfigService } from '@nestjs/config';
import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { SensitiveDataCryptoService } from './sensitive-data-crypto.service';
import { PrivateDocumentStorageService } from './private-document-storage.service';

describe('Seller Verification Security Services (Unit)', () => {
  const mockConfig = {
    get: (key: string, defaultVal?: any) => {
      const map: Record<string, any> = {
        SELLER_PII_ENCRYPTION_KEY: 'unit_test_seller_pii_key_32_bytes_minimum!!',
        R2_BUCKET_NAME: 'marketspace-media',
        NODE_ENV: 'test',
        JWT_ACCESS_SECRET: 'unit_test_jwt_secret_key_for_signing_123456',
      };
      return map[key] ?? defaultVal;
    },
  } as unknown as ConfigService;

  describe('SensitiveDataCryptoService', () => {
    const cryptoSvc = new SensitiveDataCryptoService(mockConfig);

    it('encrypts national IDs with AES-256-GCM and decrypts accurately', () => {
      const plain = '29501011234567';
      const encrypted = cryptoSvc.encrypt(plain)!;

      expect(encrypted).toMatch(/^enc:v1:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$/);
      expect(encrypted).not.toContain(plain);
      expect(cryptoSvc.isEncrypted(encrypted)).toBe(true);
      expect(cryptoSvc.decrypt(encrypted)).toBe(plain);
    });

    it('produces masked representations without exposing plaintext', () => {
      const encrypted = cryptoSvc.encrypt('29501011234567');
      const masked = cryptoSvc.mask(encrypted);

      expect(masked).toBe('**********4567');
      expect(masked).not.toContain('295010');
    });

    it('handles legacy unencrypted values safely', () => {
      expect(cryptoSvc.decrypt('29501011234567')).toBe('29501011234567');
      expect(cryptoSvc.mask('29501011234567')).toBe('**********4567');
    });
  });

  describe('PrivateDocumentStorageService', () => {
    const storage = new PrivateDocumentStorageService(mockConfig);

    it('accepts valid magic-byte signatures for PDF, JPEG, PNG, and WEBP', () => {
      const pdfHeader = Buffer.from('%PDF-1.7\n...').toString('base64');
      const jpgHeader = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]).toString('base64');
      const pngHeader = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]).toString('base64');
      const webpHeader = Buffer.from('RIFF\x24\x00\x00\x00WEBP', 'binary').toString('base64');

      expect(() => storage.validateFileContentSignature('application/pdf', pdfHeader)).not.toThrow();
      expect(() => storage.validateFileContentSignature('image/jpeg', jpgHeader)).not.toThrow();
      expect(() => storage.validateFileContentSignature('image/png', pngHeader)).not.toThrow();
      expect(() => storage.validateFileContentSignature('image/webp', webpHeader)).not.toThrow();
    });

    it('rejects spoofed file content whose magic bytes do not match declared MIME type', () => {
      const htmlSpoof = Buffer.from('<script>alert(1)</script>').toString('base64');
      expect(() =>
        storage.validateFileContentSignature('image/jpeg', htmlSpoof),
      ).toThrow(BadRequestException);

      const pngBytes = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]).toString('base64');
      expect(() =>
        storage.validateFileContentSignature('application/pdf', pngBytes),
      ).toThrow(BadRequestException);
    });

    it('rejects oversized files and disallowed MIME types', () => {
      expect(() =>
        storage.validateFileMetadata('application/x-msdownload', 1024),
      ).toThrow(BadRequestException);
      expect(() =>
        storage.validateFileMetadata('image/jpeg', 15 * 1024 * 1024),
      ).toThrow(BadRequestException);
      expect(() =>
        storage.validateFileMetadata('image/jpeg', 3 * 1024 * 1024, {
          maxFileSizeBytes: 2 * 1024 * 1024,
        }),
      ).toThrow(BadRequestException);
    });

    it('blocks public media paths and path traversal attempts in storage keys', () => {
      expect(() =>
        storage.assertPrivateStorageKeyFormat('uploads/images/2026-11/u/file.jpg'),
      ).toThrow(ForbiddenException);
      expect(() =>
        storage.assertPrivateStorageKeyFormat(
          'private/seller-verification/../../../etc/passwd',
        ),
      ).toThrow(ForbiddenException);
    });
  });
});
