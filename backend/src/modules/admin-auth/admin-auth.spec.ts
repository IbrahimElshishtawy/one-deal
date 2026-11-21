import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { TotpService } from './services/totp.service';
import { PermissionsGuard } from './guards/permissions.guard';

describe('Admin Auth Unit Tests (TotpService & PermissionsGuard)', () => {
  describe('TotpService', () => {
    const configService = {
      get: (key: string) =>
        key === 'ADMIN_MFA_ENCRYPTION_KEY'
          ? 'unit_test_32_byte_mfa_encryption_secret_key'
          : undefined,
    } as unknown as ConfigService;

    const totp = new TotpService(configService);

    it('generates valid Base32 secret, encrypts/decrypts with AES-256-GCM, and verifies current TOTP', () => {
      const secret = totp.generateBase32Secret();
      expect(secret).toMatch(/^[A-Z2-7]+$/);

      const encrypted = totp.encryptSecret(secret);
      expect(encrypted).not.toContain(secret);
      expect(totp.decryptSecret(encrypted)).toBe(secret);

      const code = totp.generateTotpForTime(secret);
      expect(code).toMatch(/^\d{6}$/);
      expect(totp.verifyTotp(secret, code)).toBe(true);
      expect(totp.verifyTotp(secret, '000000')).toBe(code === '000000');
    });

    it('generates 8 distinct recovery codes and SHA-256 hashes them consistently', () => {
      const { plainCodes, hashedCodes } = totp.generateRecoveryCodes(8);
      expect(plainCodes).toHaveLength(8);
      expect(hashedCodes).toHaveLength(8);
      expect(totp.hashRecoveryCode(plainCodes[0].toLowerCase())).toBe(
        hashedCodes[0],
      );
    });
  });

  describe('PermissionsGuard', () => {
    const reflector = new Reflector();
    const guard = new PermissionsGuard(reflector);

    function mockCtx(userPerms: string[] | null, handlerMeta?: string[]) {
      jest
        .spyOn(reflector, 'getAllAndOverride')
        .mockImplementation((key: unknown) =>
          key === 'admin_permissions' ? handlerMeta : undefined,
        );

      return {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: userPerms ? { id: 's1', permissions: userPerms } : undefined,
          }),
        }),
      } as unknown as ExecutionContext;
    }

    it('allows access when all required permissions are present', () => {
      const ctx = mockCtx(
        ['listings.read', 'listings.approve'],
        ['listings.approve'],
      );
      expect(guard.canActivate(ctx)).toBe(true);
    });

    it('denies access with ForbiddenException when required permission is missing', () => {
      const ctx = mockCtx(['analytics.read'], ['users.ban']);
      expect(() => guard.canActivate(ctx)).toThrow(ForbiddenException);
    });

    it('denies access when staff context is missing', () => {
      const ctx = mockCtx(null, ['settings.read']);
      expect(() => guard.canActivate(ctx)).toThrow(ForbiddenException);
    });
  });
});
