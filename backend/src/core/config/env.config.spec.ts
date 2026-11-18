import {
  validateEnv,
  parseCorsOrigins,
  parseTrustProxy,
  validateProductionSecret,
} from './env.config';

const STRONG_ACCESS_SECRET =
  '9f4a2c8e1b7d6035a9c8e7f2b4d16803e5a7c9f1b2d4e6a8c0f2b4d6e8a0c2f4';
const STRONG_REFRESH_SECRET =
  '3b7e9d1f5a2c4860d2f4a6c8e0b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7';

describe('Environment Configuration Validation', () => {
  describe('Development / Test mode', () => {
    it('should validate and parse valid configuration with default values', () => {
      const rawConfig = {
        DATABASE_URL: 'postgresql://user:pass@localhost:5432/marketspace',
        JWT_ACCESS_SECRET: 'super_secret_access_key_1234567890',
        JWT_REFRESH_SECRET: 'super_secret_refresh_key_1234567890',
      };

      const validated = validateEnv(rawConfig);
      expect(validated.NODE_ENV).toBe('development');
      expect(validated.PORT).toBe(3000);
      expect(validated.DATABASE_URL).toBe(rawConfig.DATABASE_URL);
      expect(validated.JWT_ACCESS_EXPIRES_IN).toBe('15m');
      expect(validated.TRUST_PROXY).toBe('false');
    });

    it('should fallback to default DATABASE_URL and distinct dev JWT secrets when omitted in development', () => {
      const validated = validateEnv({ NODE_ENV: 'development' });
      expect(validated.DATABASE_URL).toContain('postgresql://');
      expect(validated.JWT_ACCESS_SECRET).toBeTruthy();
      expect(validated.JWT_REFRESH_SECRET).toBeTruthy();
      expect(validated.JWT_ACCESS_SECRET).not.toBe(
        validated.JWT_REFRESH_SECRET,
      );
    });

    it('should throw an error when JWT secrets are shorter than 16 characters', () => {
      const rawConfig = {
        DATABASE_URL: 'postgresql://user:pass@localhost:5432/marketspace',
        JWT_ACCESS_SECRET: 'short',
        JWT_REFRESH_SECRET: 'short_other',
      };

      expect(() => validateEnv(rawConfig)).toThrow(
        /JWT_ACCESS_SECRET must be at least 16 chars/,
      );
    });

    it('should reject identical access and refresh secrets even in development', () => {
      const sameSecret = 'super_secret_identical_key_1234567890';
      expect(() =>
        validateEnv({
          NODE_ENV: 'development',
          JWT_ACCESS_SECRET: sameSecret,
          JWT_REFRESH_SECRET: sameSecret,
        }),
      ).toThrow(/must be different/);
    });
  });

  describe('Production JWT Secret Management (fail-fast)', () => {
    const validProdBase = {
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://prod:secret@db.internal:5432/dealone',
      CORS_ORIGIN: 'https://dealone.eg,https://admin.dealone.eg',
      JWT_ACCESS_SECRET: STRONG_ACCESS_SECRET,
      JWT_REFRESH_SECRET: STRONG_REFRESH_SECRET,
      TRUST_PROXY: '1',
    };

    it('should accept a valid production configuration', () => {
      const validated = validateEnv(validProdBase);
      expect(validated.NODE_ENV).toBe('production');
      expect(validated.JWT_ACCESS_SECRET).toBe(STRONG_ACCESS_SECRET);
      expect(validated.JWT_REFRESH_SECRET).toBe(STRONG_REFRESH_SECRET);
      expect(validated.CORS_ORIGIN).toBe(
        'https://dealone.eg,https://admin.dealone.eg',
      );
    });

    it('should fail startup when JWT_ACCESS_SECRET is missing in production', () => {
      const { JWT_ACCESS_SECRET: _, ...withoutAccess } = validProdBase;
      expect(() => validateEnv(withoutAccess)).toThrow(
        /JWT_ACCESS_SECRET is required in production/,
      );
    });

    it('should fail startup when JWT_REFRESH_SECRET is missing in production', () => {
      const { JWT_REFRESH_SECRET: _, ...withoutRefresh } = validProdBase;
      expect(() => validateEnv(withoutRefresh)).toThrow(
        /JWT_REFRESH_SECRET is required in production/,
      );
    });

    it('should reject weak secrets (<32 chars or low entropy) in production without leaking secret value', () => {
      const weakLowEntropy = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      expect(() =>
        validateEnv({
          ...validProdBase,
          JWT_ACCESS_SECRET: weakLowEntropy,
        }),
      ).toThrow(/insufficient character diversity/);

      let thrownMessage = '';
      try {
        validateEnv({
          ...validProdBase,
          JWT_ACCESS_SECRET: 'short_prod_secret_12345',
        });
      } catch (err: any) {
        thrownMessage = err.message;
      }
      expect(thrownMessage).toContain('at least 32 characters in production');
      expect(thrownMessage).not.toContain('short_prod_secret_12345');
    });

    it('should reject identical access and refresh secrets in production', () => {
      expect(() =>
        validateEnv({
          ...validProdBase,
          JWT_REFRESH_SECRET: STRONG_ACCESS_SECRET,
        }),
      ).toThrow(/must be different/);
    });

    it('should reject known default and placeholder secrets in production', () => {
      expect(
        validateProductionSecret(
          'JWT_ACCESS_SECRET',
          'dealone_default_access_secret_key_32chars_min_production!',
        ),
      ).toMatch(/known default or placeholder/);

      expect(
        validateProductionSecret(
          'JWT_REFRESH_SECRET',
          'replace_with_64_character_hex_secret_in_production',
        ),
      ).toMatch(/known default or placeholder/);

      expect(() =>
        validateEnv({
          ...validProdBase,
          JWT_ACCESS_SECRET:
            'my_placeholder_secret_value_for_testing_1234567890',
        }),
      ).toThrow(/weak\/placeholder pattern/);
    });

    it('should fail startup when DATABASE_URL is missing in production', () => {
      const { DATABASE_URL: _, ...withoutDb } = validProdBase;
      expect(() => validateEnv(withoutDb)).toThrow(
        /DATABASE_URL is required in production/,
      );
    });
  });

  describe('CORS_ORIGIN validation', () => {
    it('should reject missing or wildcard CORS_ORIGIN in production', () => {
      expect(() => parseCorsOrigins('', 'production')).toThrow(
        /CORS_ORIGIN must be explicitly configured/,
      );
      expect(() => parseCorsOrigins('*', 'production')).toThrow(
        /must not contain wildcard/,
      );
      expect(() =>
        parseCorsOrigins('https://dealone.eg,*', 'production'),
      ).toThrow(/must not contain wildcard/);
    });

    it('should accept multiple valid explicit origins in production', () => {
      const origins = parseCorsOrigins(
        'https://dealone.eg, https://admin.dealone.eg',
        'production',
      );
      expect(origins).toEqual([
        'https://dealone.eg',
        'https://admin.dealone.eg',
      ]);
    });

    it('should reject malformed URLs or origins with paths', () => {
      expect(() => parseCorsOrigins('not-a-url', 'production')).toThrow(
        /not a valid URL/,
      );
      expect(() =>
        parseCorsOrigins('https://dealone.eg/api', 'production'),
      ).toThrow(/must not include path/);
    });
  });

  describe('TRUST_PROXY validation', () => {
    it('should reject blanket TRUST_PROXY=true', () => {
      expect(() => parseTrustProxy('true')).toThrow(
        /TRUST_PROXY=true is disallowed/,
      );
    });

    it('should accept hop counts, loopback, or explicit CIDRs', () => {
      expect(parseTrustProxy(undefined)).toBe(false);
      expect(parseTrustProxy('false')).toBe(false);
      expect(parseTrustProxy('1')).toBe(1);
      expect(parseTrustProxy('loopback')).toBe('loopback');
      expect(parseTrustProxy('100.64.0.0/10, 127.0.0.1')).toEqual([
        '100.64.0.0/10',
        '127.0.0.1',
      ]);
    });
  });
});
