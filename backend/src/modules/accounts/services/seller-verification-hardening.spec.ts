import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SensitiveDataCryptoService } from './sensitive-data-crypto.service';
import { PrivateDocumentStorageService } from './private-document-storage.service';
import { SellerApplicationService } from './seller-application.service';
import { SellerVerificationMaintenanceProcessor } from '../../../workers/seller-verification-maintenance.processor';
import {
  assertValidSellerStatusTransition,
  isValidSellerStatusTransition,
} from '../seller-application-state-machine';
import { mapApplicationStatusToAccountVerificationStatus } from '../verification-tier.helper';
import {
  AccountType,
  SellerApplicationStatus,
  SellerApplicationType,
  SellerDocumentStatus,
  SellerDocumentType,
  SellerType,
  VerificationStatus,
} from '../../../core/enums/domain.enums';

function makeConfig(values: Record<string, any>): ConfigService {
  return {
    get: jest.fn((key: string, defaultVal?: any) =>
      key in values ? values[key] : defaultVal,
    ),
  } as unknown as ConfigService;
}

describe('Seller Verification Hardening Suite', () => {
  // =========================================================================
  // 1. AES-256-GCM ENCRYPTION & VERSIONED KEY ROTATION
  // =========================================================================
  describe('SensitiveDataCryptoService (AES-256-GCM & Key Rotation)', () => {
    it('encrypts with unique random IV per call and validates auth tag', () => {
      const cryptoSvc = new SensitiveDataCryptoService(
        makeConfig({
          SELLER_PII_ENCRYPTION_KEY: 'super-strong-v1-secret-key-32bytes-min!',
        }),
      );

      const c1 = cryptoSvc.encrypt('29501011234567');
      const c2 = cryptoSvc.encrypt('29501011234567');

      expect(c1).toMatch(/^enc:v1:[0-9a-f]{24}:[0-9a-f]{32}:[0-9a-f]+$/);
      expect(c2).toMatch(/^enc:v1:[0-9a-f]{24}:[0-9a-f]{32}:[0-9a-f]+$/);
      expect(c1).not.toBe(c2); // unique IVs
      expect(cryptoSvc.decrypt(c1)).toBe('29501011234567');
      expect(cryptoSvc.mask(c1)).toBe('**********4567');

      // Tamper with ciphertext -> auth tag verification MUST fail safely
      const tampered = c1!.slice(0, -2) + (c1!.endsWith('00') ? 'ff' : '00');
      const res = cryptoSvc.decryptResult(tampered);
      expect(res.ok).toBe(false);
      expect(res.error).toBe('DECRYPTION_FAILED');
      expect(res.value).toBeNull();
      expect(cryptoSvc.mask(tampered)).toBe('********');
    });

    it('supports seamless multi-key rotation (v1 -> v2) without breaking existing records', () => {
      const v1Svc = new SensitiveDataCryptoService(
        makeConfig({
          SELLER_PII_ENCRYPTION_KEYS:
            'v1:first-key-secret-32-chars-minimum-111',
          SELLER_PII_ENCRYPTION_KEY_VERSION: 'v1',
        }),
      );
      const oldCiphertext = v1Svc.encrypt('CR-99887766');
      expect(v1Svc.getKeyVersion(oldCiphertext)).toBe('v1');

      const rotatedSvc = new SensitiveDataCryptoService(
        makeConfig({
          SELLER_PII_ENCRYPTION_KEYS:
            'v1:first-key-secret-32-chars-minimum-111,v2:second-key-secret-32-chars-minimum-222',
          SELLER_PII_ENCRYPTION_KEY_VERSION: 'v2',
        }),
      );

      // Still decrypts v1 records and legacy plaintext
      expect(rotatedSvc.decrypt(oldCiphertext)).toBe('CR-99887766');
      expect(rotatedSvc.decrypt('LEGACY-CR-12345')).toBe('LEGACY-CR-12345');

      // New encryptions use v2
      const newCiphertext = rotatedSvc.encrypt('CR-11223344');
      expect(rotatedSvc.getKeyVersion(newCiphertext)).toBe('v2');

      // Detects old records needing re-encryption and re-encrypts cleanly
      expect(rotatedSvc.needsReencryption(oldCiphertext)).toBe(true);
      expect(rotatedSvc.needsReencryption('LEGACY-CR-12345')).toBe(true);
      expect(rotatedSvc.needsReencryption(newCiphertext)).toBe(false);

      const upgraded = rotatedSvc.reencrypt(oldCiphertext);
      expect(rotatedSvc.getKeyVersion(upgraded)).toBe('v2');
      expect(rotatedSvc.decrypt(upgraded)).toBe('CR-99887766');
    });

    it('handles unknown key version safely without leaking raw ciphertext', () => {
      const svc = new SensitiveDataCryptoService(
        makeConfig({
          SELLER_PII_ENCRYPTION_KEYS:
            'v2:only-v2-key-configured-32-chars-min!!',
          SELLER_PII_ENCRYPTION_KEY_VERSION: 'v2',
        }),
      );
      const res = svc.decryptResult(
        'enc:v9:00112233445566778899aabb:00112233445566778899aabbccddeeff:aabbcc',
      );
      expect(res.ok).toBe(false);
      expect(res.error).toBe('UNKNOWN_KEY_VERSION');
      expect(
        svc.mask(
          'enc:v9:00112233445566778899aabb:00112233445566778899aabbccddeeff:aabbcc',
        ),
      ).toBe('********');
    });
  });

  // =========================================================================
  // 2. R2 STORAGE HARDENING (HEAD VERIFICATION & DELETE)
  // =========================================================================
  describe('PrivateDocumentStorageService (R2 HEAD & DELETE)', () => {
    const validKey =
      'private/seller-verification/11111111-1111-4111-8111-111111111111/22222222-2222-4222-8222-222222222222/doc.pdf';

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('skips remote HEAD/DELETE cleanly when R2 credentials are not configured', async () => {
      const storage = new PrivateDocumentStorageService(
        makeConfig({ NODE_ENV: 'test', R2_ACCOUNT_ID: '' }),
      );
      const headRes = await storage.verifyUploadedObject(
        validKey,
        'application/pdf',
      );
      expect(headRes.verified).toBe(true);
      expect(headRes.skippedReason).toBe('NO_R2_CREDENTIALS');

      const delRes = await storage.deleteObject(validKey);
      expect(delRes.deleted).toBe(true);
      expect(delRes.skippedReason).toBe('NO_R2_CREDENTIALS');

      const scanRes = await storage.scanDocumentBoundary(validKey);
      expect(scanRes.status).toBe('SCANNER_NOT_CONFIGURED');
    });

    it('verifies uploaded object via SigV4 HEAD and rejects missing, oversized, or mismatched MIME objects', async () => {
      const storage = new PrivateDocumentStorageService(
        makeConfig({
          NODE_ENV: 'production',
          R2_ACCOUNT_ID: 'acc123456',
          R2_ACCESS_KEY_ID: 'key123456',
          R2_SECRET_ACCESS_KEY: 'secret123456',
          R2_PRIVATE_BUCKET_NAME: 'dealone-kyc-private',
        }),
      );

      // 404 -> DOCUMENT_NOT_UPLOADED
      jest.spyOn(global, 'fetch').mockResolvedValueOnce({
        status: 404,
        ok: false,
        headers: new Headers(),
      } as Response);
      await expect(
        storage.verifyUploadedObject(validKey, 'application/pdf', 1024),
      ).rejects.toThrow(BadRequestException);

      // Oversized -> DOCUMENT_SIZE_EXCEEDED
      jest.spyOn(global, 'fetch').mockResolvedValueOnce({
        status: 200,
        ok: true,
        headers: new Headers({
          'content-length': '2048',
          'content-type': 'application/pdf',
        }),
      } as Response);
      await expect(
        storage.verifyUploadedObject(validKey, 'application/pdf', 1024),
      ).rejects.toThrow(BadRequestException);

      // Mismatched content-type -> FILE_CONTENT_MIME_MISMATCH
      jest.spyOn(global, 'fetch').mockResolvedValueOnce({
        status: 200,
        ok: true,
        headers: new Headers({
          'content-length': '512',
          'content-type': 'image/png',
        }),
      } as Response);
      await expect(
        storage.verifyUploadedObject(validKey, 'application/pdf', 1024),
      ).rejects.toThrow(BadRequestException);

      // Valid HEAD + valid ranged GET (%PDF-)
      const pdfBytes = Buffer.from('%PDF-1.7\n1 0 obj', 'ascii');
      jest
        .spyOn(global, 'fetch')
        .mockResolvedValueOnce({
          status: 200,
          ok: true,
          headers: new Headers({
            'content-length': '512',
            'content-type': 'application/pdf',
            etag: '"abc123"',
          }),
        } as Response)
        .mockResolvedValueOnce({
          status: 206,
          ok: true,
          arrayBuffer: async () =>
            pdfBytes.buffer.slice(
              pdfBytes.byteOffset,
              pdfBytes.byteOffset + pdfBytes.byteLength,
            ),
        } as Response);
      const okRes = await storage.verifyUploadedObject(
        validKey,
        'application/pdf',
        1024,
      );
      expect(okRes.verified).toBe(true);
      expect(okRes.contentLength).toBe(512);

      // Idempotent DELETE (204 or 404)
      jest
        .spyOn(global, 'fetch')
        .mockResolvedValueOnce({ status: 204, ok: true } as Response);
      const delRes = await storage.deleteObject(validKey);
      expect(delRes.deleted).toBe(true);
      expect(delRes.statusCode).toBe(204);
    });
  });

  // =========================================================================
  // 3. STATE MACHINE & ACCOUNT MAPPING
  // =========================================================================
  describe('State Machine & Account Status Mapping', () => {
    it('supports WITHDRAWN from DRAFT, PENDING, NEEDS_CORRECTION and blocks invalid withdrawals', () => {
      expect(
        isValidSellerStatusTransition(
          SellerApplicationStatus.DRAFT,
          SellerApplicationStatus.WITHDRAWN,
        ),
      ).toBe(true);
      expect(
        isValidSellerStatusTransition(
          SellerApplicationStatus.PENDING,
          SellerApplicationStatus.WITHDRAWN,
        ),
      ).toBe(true);
      expect(
        isValidSellerStatusTransition(
          SellerApplicationStatus.NEEDS_CORRECTION,
          SellerApplicationStatus.WITHDRAWN,
        ),
      ).toBe(true);
      expect(() =>
        assertValidSellerStatusTransition(
          SellerApplicationStatus.APPROVED,
          SellerApplicationStatus.WITHDRAWN,
        ),
      ).toThrow(BadRequestException);
      expect(() =>
        assertValidSellerStatusTransition(
          SellerApplicationStatus.UNDER_REVIEW,
          SellerApplicationStatus.WITHDRAWN,
        ),
      ).toThrow(BadRequestException);
    });

    it('maps EXPIRED -> VerificationStatus.EXPIRED and WITHDRAWN -> NOT_SUBMITTED', () => {
      expect(
        mapApplicationStatusToAccountVerificationStatus(
          SellerApplicationStatus.EXPIRED,
        ),
      ).toBe(VerificationStatus.EXPIRED);
      expect(
        mapApplicationStatusToAccountVerificationStatus(
          SellerApplicationStatus.WITHDRAWN,
        ),
      ).toBe(VerificationStatus.NOT_SUBMITTED);
    });
  });

  // =========================================================================
  // 4. FOUR-EYES APPROVAL, WITHDRAW & RENEWAL WORKFLOWS
  // =========================================================================
  describe('SellerApplicationService (Four-Eyes, Withdraw, Renewal)', () => {
    it('blocks same-admin approval when ENABLE_FOUR_EYES_VERIFICATION_REVIEW=true', async () => {
      const mockPrisma: any = {
        sellerApplication: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'app-1',
            userId: 'user-1',
            accountId: 'acc-1',
            applicationType: SellerApplicationType.INITIAL,
            status: SellerApplicationStatus.UNDER_REVIEW,
            sellerType: SellerType.INDIVIDUAL,
            businessType: AccountType.INDIVIDUAL,
            businessName: 'Ibrahim Store',
            nationalIdNumber: '29501011234567',
            firstReviewedByStaffId: 'staff-A',
            documents: [
              {
                documentType: SellerDocumentType.NATIONAL_ID_FRONT,
                status: SellerDocumentStatus.UPLOADED,
                isCurrent: true,
                deletedAt: null,
              },
              {
                documentType: SellerDocumentType.NATIONAL_ID_BACK,
                status: SellerDocumentStatus.UPLOADED,
                isCurrent: true,
                deletedAt: null,
              },
            ],
            user: {
              id: 'user-1',
              fullName: 'Ibrahim',
              email: 'seller@example.com',
              phone: '+201000000001',
              isActive: true,
              deletedAt: null,
            },
          }),
        },
      };

      const service = new SellerApplicationService(
        mockPrisma,
        new PrivateDocumentStorageService(makeConfig({})),
        { logEvent: jest.fn() } as any,
        undefined,
        new SensitiveDataCryptoService(makeConfig({})),
        undefined,
        undefined,
        makeConfig({ ENABLE_FOUR_EYES_VERIFICATION_REVIEW: true }),
      );

      await expect(
        service.approveApplication(
          'app-1',
          {
            id: 'staff-A',
            staffId: 'staff-A',
            actorType: 'staff',
            email: 'adminA@dealone.eg',
            fullName: 'Admin A',
            roleId: 1,
            role: 'admin',
            permissions: ['verification.approve'],
            mfaVerified: true,
          },
          {},
        ),
      ).rejects.toThrow(ForbiddenException);

      // Also blocks direct PENDING -> APPROVED when firstReviewedByStaffId is null
      mockPrisma.sellerApplication.findUnique.mockResolvedValueOnce({
        id: 'app-2',
        userId: 'user-1',
        accountId: 'acc-1',
        applicationType: SellerApplicationType.INITIAL,
        status: SellerApplicationStatus.PENDING,
        sellerType: SellerType.INDIVIDUAL,
        businessType: AccountType.INDIVIDUAL,
        businessName: 'Ibrahim Store',
        nationalIdNumber: '29501011234567',
        firstReviewedByStaffId: null,
        documents: [
          {
            documentType: SellerDocumentType.NATIONAL_ID_FRONT,
            status: SellerDocumentStatus.UPLOADED,
            isCurrent: true,
            deletedAt: null,
          },
          {
            documentType: SellerDocumentType.NATIONAL_ID_BACK,
            status: SellerDocumentStatus.UPLOADED,
            isCurrent: true,
            deletedAt: null,
          },
        ],
        user: {
          id: 'user-1',
          fullName: 'Ibrahim',
          email: 'seller@example.com',
          phone: '+201000000001',
          isActive: true,
          deletedAt: null,
        },
      });
      await expect(
        service.approveApplication(
          'app-2',
          {
            id: 'staff-B',
            staffId: 'staff-B',
            actorType: 'staff',
            email: 'adminB@dealone.eg',
            fullName: 'Admin B',
            roleId: 1,
            role: 'admin',
            permissions: ['verification.approve'],
            mfaVerified: true,
          },
          {},
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('withdraws a PENDING BUSINESS_UPGRADE without modifying the existing verified Account', async () => {
      const mockTx: any = {
        sellerApplication: {
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          findUniqueOrThrow: jest.fn().mockResolvedValue({
            id: 'upg-1',
            userId: 'user-1',
            accountId: 'acc-1',
            applicationType: SellerApplicationType.BUSINESS_UPGRADE,
            status: SellerApplicationStatus.WITHDRAWN,
            sellerType: SellerType.BUSINESS,
            businessType: AccountType.COMPANY,
            documents: [],
          }),
        },
        user: { update: jest.fn() },
        sellerApplicationDocument: { updateMany: jest.fn() },
        sellerApplicationHistory: { create: jest.fn() },
      };

      const mockPrisma: any = {
        sellerApplication: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'upg-1',
            userId: 'user-1',
            accountId: 'acc-1',
            applicationType: SellerApplicationType.BUSINESS_UPGRADE,
            status: SellerApplicationStatus.PENDING,
          }),
        },
        $transaction: jest.fn((cb: any) => cb(mockTx)),
      };

      const mockRedis: any = {
        del: jest.fn().mockResolvedValue(1),
        incr: jest.fn().mockResolvedValue(2),
        delByPattern: jest.fn().mockResolvedValue(1),
      };
      const mockAudit: any = {
        logEvent: jest.fn().mockResolvedValue(undefined),
      };

      const service = new SellerApplicationService(
        mockPrisma,
        new PrivateDocumentStorageService(makeConfig({})),
        mockAudit,
        mockRedis,
        new SensitiveDataCryptoService(makeConfig({})),
        undefined,
        undefined,
        makeConfig({ VERIFICATION_DOC_RETENTION_WITHDRAWN_DAYS: 30 }),
      );

      const res = await service.withdrawApplication('user-1', {
        reason: 'Will upload renewed CR next week',
      });

      expect(res.status).toBe(SellerApplicationStatus.WITHDRAWN);
      // Must NOT reset User.sellerStatus for a BUSINESS_UPGRADE withdrawal
      expect(mockTx.user.update).not.toHaveBeenCalled();
      expect(mockTx.sellerApplicationDocument.updateMany).toHaveBeenCalled();
      expect(mockRedis.incr).toHaveBeenCalledWith('listings:feed:ver');
      expect(mockRedis.incr).toHaveBeenCalledWith('home:feed:ver');
      expect(mockAudit.logEvent).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'SELLER_APPLICATION_WITHDRAWN' }),
      );
    });
  });

  // =========================================================================
  // 5. SCHEDULED MAINTENANCE WORKER (EXPIRY, RENEWAL REMINDERS, RETENTION)
  // =========================================================================
  describe('SellerVerificationMaintenanceProcessor', () => {
    it('sends renewal reminders idempotently and purges retention-expired & orphan R2 documents without touching active reviews', async () => {
      const mockPrisma: any = {
        sellerApplication: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'app-expiring',
              userId: 'user-9',
              accountId: 'acc-9',
              verificationExpiresAt: new Date(Date.now() + 10 * 86_400_000),
            },
          ]),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        sellerApplicationDocument: {
          findMany: jest
            .fn()
            // 1st call: retention-expired docs
            .mockResolvedValueOnce([
              {
                id: 'doc-old-1',
                applicationId: 'app-rejected',
                userId: 'user-2',
                documentType: SellerDocumentType.NATIONAL_ID_FRONT,
                version: 1,
                storageKey:
                  'private/seller-verification/11111111-1111-4111-8111-111111111111/22222222-2222-4222-8222-222222222222/old.jpg',
              },
            ])
            // 2nd call: orphaned PENDING_UPLOAD docs
            .mockResolvedValueOnce([
              {
                id: 'doc-orphan-1',
                applicationId: 'app-draft',
                userId: 'user-3',
                documentType: SellerDocumentType.TAX_CARD,
                version: 1,
                storageKey:
                  'private/seller-verification/11111111-1111-4111-8111-111111111111/33333333-3333-4333-8333-333333333333/orphan.pdf',
              },
            ]),
          update: jest.fn().mockResolvedValue({}),
        },
      };

      const mockStorage: any = {
        deleteObject: jest.fn().mockResolvedValue({ deleted: true }),
      };
      const mockAudit: any = {
        logEvent: jest.fn().mockResolvedValue(undefined),
      };
      const mockNotifications: any = {
        sendPushNotification: jest.fn().mockResolvedValue(undefined),
      };
      const mockSellerAppSvc: any = {
        expireOverdueVerifications: jest
          .fn()
          .mockResolvedValue({ expiredCount: 2 }),
      };

      const processor = new SellerVerificationMaintenanceProcessor(
        mockPrisma,
        mockSellerAppSvc,
        mockStorage,
        mockAudit,
        mockNotifications,
        makeConfig({
          VERIFICATION_RENEWAL_REMINDER_DAYS: 30,
          VERIFICATION_ORPHAN_UPLOAD_TTL_HOURS: 24,
        }),
      );

      const expRes = await processor.processOverdueVerifications();
      expect(expRes.expiredCount).toBe(2);

      const remRes = await processor.processRenewalReminders();
      expect(remRes.remindedCount).toBe(1);
      expect(mockNotifications.sendPushNotification).toHaveBeenCalledWith(
        'user-9',
        expect.any(String),
        expect.stringContaining('expire'),
        expect.objectContaining({ type: 'SELLER_VERIFICATION_EXPIRING_SOON' }),
      );

      const purgeRes = await processor.processDocumentRetentionCleanup();
      expect(purgeRes).toEqual({
        purgedRetentionCount: 1,
        purgedOrphanCount: 1,
      });
      expect(mockStorage.deleteObject).toHaveBeenCalledTimes(2);
      expect(mockPrisma.sellerApplicationDocument.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'doc-old-1' },
          data: expect.objectContaining({
            status: SellerDocumentStatus.PURGED,
            originalFileName: '[REDACTED_RETENTION_PURGED]',
          }),
        }),
      );
      // Verify active review exclusion filter was passed to Prisma
      expect(
        mockPrisma.sellerApplicationDocument.findMany,
      ).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({
          where: expect.objectContaining({
            application: {
              status: {
                notIn: [
                  SellerApplicationStatus.PENDING,
                  SellerApplicationStatus.UNDER_REVIEW,
                  SellerApplicationStatus.NEEDS_CORRECTION,
                ],
              },
            },
          }),
        }),
      );
    });
  });
});
