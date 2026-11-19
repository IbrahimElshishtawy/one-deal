import { z } from 'zod';

const boolFlag = (defaultValue: boolean) =>
  z.preprocess((val) => {
    if (val === undefined || val === null || val === '') return defaultValue;
    if (typeof val === 'boolean') return val;
    return String(val).toLowerCase() === 'true';
  }, z.boolean());

const DEV_ONLY_ACCESS_SECRET =
  'dev_only_local_access_secret_do_not_use_in_prod_9f8e7d6c5b4a';
const DEV_ONLY_REFRESH_SECRET =
  'dev_only_local_refresh_secret_do_not_use_in_prod_1a2b3c4d5e6f';

const KNOWN_WEAK_SECRET_EXACT = new Set([
  'dealone_default_access_secret_key_32chars_min_production!',
  'dealone_default_refresh_secret_key_32chars_min_production!',
  'replace_with_64_character_hex_secret_in_production',
  'deal_one_fallback_pepper',
  DEV_ONLY_ACCESS_SECRET,
  DEV_ONLY_REFRESH_SECRET,
]);

const KNOWN_WEAK_SECRET_PATTERNS = [
  /placeholder/i,
  /replace_with/i,
  /changeme/i,
  /default_.*secret/i,
  /your_.*secret/i,
  /dev_only/i,
  /^test[_-]?secret/i,
  /^password/i,
  /^123456/,
];

/**
 * Computes Shannon entropy (bits per character) of a secret string.
 */
export function calculateShannonEntropy(value: string): number {
  if (!value || value.length === 0) return 0;
  const freq = new Map<string, number>();
  for (const ch of value) {
    freq.set(ch, (freq.get(ch) ?? 0) + 1);
  }
  let entropy = 0;
  for (const count of freq.values()) {
    const p = count / value.length;
    entropy -= p * Math.log2(p);
  }
  return entropy;
}

/**
 * Validates that a secret is strong enough for production use.
 * Never includes the secret value itself in returned error messages.
 */
export function validateProductionSecret(
  name: string,
  value: string | undefined,
): string | null {
  if (!value || value.trim().length === 0) {
    return `${name} is required in production`;
  }
  if (value.length < 32) {
    return `${name} must be at least 32 characters in production`;
  }
  if (KNOWN_WEAK_SECRET_EXACT.has(value)) {
    return `${name} uses a known default or placeholder secret and is rejected in production`;
  }
  if (KNOWN_WEAK_SECRET_PATTERNS.some((pattern) => pattern.test(value))) {
    return `${name} matches a disallowed weak/placeholder pattern and is rejected in production`;
  }
  const uniqueChars = new Set(value).size;
  if (uniqueChars < 10) {
    return `${name} has insufficient character diversity (must have at least 10 unique characters)`;
  }
  const entropy = calculateShannonEntropy(value);
  if (entropy < 3.0) {
    return `${name} has insufficient entropy for production use`;
  }
  return null;
}

/**
 * Parses and validates CORS_ORIGIN into an explicit allowlist of origins.
 */
export function parseCorsOrigins(
  raw: string | undefined,
  nodeEnv: string,
): string[] {
  const trimmed = (raw ?? '').trim();
  if (!trimmed) {
    if (nodeEnv === 'production') {
      throw new Error(
        'CORS_ORIGIN must be explicitly configured with allowed origins in production',
      );
    }
    return [];
  }

  const origins = trimmed
    .split(',')
    .map((o) => o.trim())
    .filter((o) => o.length > 0);

  if (origins.length === 0) {
    if (nodeEnv === 'production') {
      throw new Error(
        'CORS_ORIGIN must contain at least one valid origin in production',
      );
    }
    return [];
  }

  for (const origin of origins) {
    if (origin === '*' || origin.includes('*')) {
      if (nodeEnv === 'production') {
        throw new Error(
          'CORS_ORIGIN must not contain wildcard (*) in production',
        );
      }
      continue;
    }

    let parsed: URL;
    try {
      parsed = new URL(origin);
    } catch {
      throw new Error(
        `Invalid CORS_ORIGIN entry: "${origin}" is not a valid URL`,
      );
    }

    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      throw new Error(
        `Invalid CORS_ORIGIN protocol for "${origin}": only http:// and https:// are allowed`,
      );
    }

    if (parsed.pathname !== '/' || parsed.search || parsed.hash) {
      throw new Error(
        `Invalid CORS_ORIGIN entry "${origin}": origin must not include path, query, or hash`,
      );
    }
  }

  return origins;
}

/**
 * Parses TRUST_PROXY into a safe Fastify trustProxy value.
 * Never silently enables blanket `true` unless explicitly set to a hop count,
 * loopback, or explicit IP/CIDR list.
 */
export function parseTrustProxy(
  raw: string | undefined,
): boolean | number | string | string[] {
  if (!raw || raw.trim() === '' || raw.trim().toLowerCase() === 'false') {
    return false;
  }

  const trimmed = raw.trim();

  if (trimmed.toLowerCase() === 'true') {
    throw new Error(
      'TRUST_PROXY=true is disallowed because it trusts arbitrary X-Forwarded-For chains. Configure an exact hop count (e.g. "1"), "loopback", or explicit proxy IP/CIDR list.',
    );
  }

  if (/^\d+$/.test(trimmed)) {
    const hops = Number(trimmed);
    if (hops < 0 || hops > 10) {
      throw new Error('TRUST_PROXY hop count must be between 0 and 10');
    }
    return hops === 0 ? false : hops;
  }

  if (
    trimmed === 'loopback' ||
    trimmed === 'linklocal' ||
    trimmed === 'uniquelocal'
  ) {
    return trimmed;
  }

  const entries = trimmed
    .split(',')
    .map((entry) => entry.trim())
    .filter(Boolean);

  if (entries.length === 0) {
    return false;
  }

  return entries.length === 1 ? entries[0] : entries;
}

export const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z.coerce.number().default(3000),
  API_BASE_URL: z.string().url().default('http://localhost:3000/api/v1'),
  CORS_ORIGIN: z.string().optional().default(''),
  TRUST_PROXY: z.string().optional().default('false'),
  ENABLE_SWAGGER: boolFlag(false),
  ENABLE_WORKERS: boolFlag(true),
  AUTO_APPROVE_LISTINGS: boolFlag(false),
  AUDIT_QUEUE_ENABLED: boolFlag(false),

  // Demo Data & Development Guest Auth Controls (Fail-Closed in Production)
  ENABLE_DEMO_DATA: boolFlag(false),
  ALLOW_DEMO_CLEANUP: boolFlag(false),
  ENABLE_DEV_AUTH_BYPASS: boolFlag(false),

  // Observability / Internal Endpoints Protection
  METRICS_AUTH_TOKEN: z.string().optional().default(''),

  // Configurable Authentication Rate Limits
  RATE_LIMIT_LOGIN_MAX: z.coerce.number().int().positive().default(5),
  RATE_LIMIT_LOGIN_WINDOW_SEC: z.coerce.number().int().positive().default(900),
  RATE_LIMIT_REFRESH_MAX: z.coerce.number().int().positive().default(20),
  RATE_LIMIT_REFRESH_WINDOW_SEC: z.coerce
    .number()
    .int()
    .positive()
    .default(900),
  RATE_LIMIT_OTP_VERIFY_MAX: z.coerce.number().int().positive().default(10),
  RATE_LIMIT_OTP_VERIFY_WINDOW_SEC: z.coerce
    .number()
    .int()
    .positive()
    .default(900),

  // Database & PgBouncer Pooling
  DATABASE_URL: z.string().optional(),
  DATABASE_CONNECTION_LIMIT: z.coerce.number().optional().default(10),
  PGBOUNCER_ENABLED: boolFlag(false),

  // Redis Infrastructure (Separated Cache & Queue Instances)
  REDIS_CACHE_HOST: z.string().optional().default('localhost'),
  REDIS_CACHE_PORT: z.coerce.number().optional().default(6379),
  REDIS_CACHE_PASSWORD: z.string().optional().default(''),
  REDIS_CACHE_URL: z.string().optional(),

  REDIS_QUEUE_HOST: z.string().optional().default('localhost'),
  REDIS_QUEUE_PORT: z.coerce.number().optional().default(6380),
  REDIS_QUEUE_PASSWORD: z.string().optional().default(''),
  REDIS_QUEUE_URL: z.string().optional(),

  // Cloud & Managed Redis Compatibility (Railway, Render, Upstash, etc.)
  REDIS_URL: z.string().optional(),
  REDISHOST: z.string().optional(),
  REDISPORT: z.coerce.number().optional(),
  REDISPASSWORD: z.string().optional(),
  REDISUSER: z.string().optional(),

  // Legacy Redis Compatibility
  REDIS_HOST: z.string().optional().default('localhost'),
  REDIS_PORT: z.coerce.number().optional().default(6379),
  REDIS_PASSWORD: z.string().optional().default(''),

  // Security & JWT
  JWT_ACCESS_SECRET: z
    .string()
    .min(16, 'JWT_ACCESS_SECRET must be at least 16 chars')
    .optional(),
  JWT_REFRESH_SECRET: z
    .string()
    .min(16, 'JWT_REFRESH_SECRET must be at least 16 chars')
    .optional(),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),

  // SMS & WhatsApp OTP Gateways (Egypt)
  SMS_PROVIDER: z.string().default('SMS_MISR'),
  SMS_MISR_USERNAME: z.string().optional().default(''),
  SMS_MISR_PASSWORD: z.string().optional().default(''),
  SMS_MISR_SENDER_ID: z.string().default('MarketSpace'),

  // WhatsApp Cloud API (Meta)
  WHATSAPP_PHONE_NUMBER_ID: z.string().optional().default(''),
  WHATSAPP_ACCESS_TOKEN: z.string().optional().default(''),
  WHATSAPP_TEMPLATE_NAME: z.string().optional().default('auth_otp'),
  WHATSAPP_TEMPLATE_LANG: z.string().optional().default('en_US'),
  WHATSAPP_API_VERSION: z.string().optional().default('v21.0'),
  WHATSAPP_INCLUDE_COPY_BUTTON: boolFlag(true),
  WHATSAPP_FALLBACK_TO_SMS: boolFlag(false),

  // Media (Cloudflare R2 / S3)
  R2_ACCOUNT_ID: z.string().optional().default(''),
  R2_ACCESS_KEY_ID: z.string().optional().default(''),
  R2_SECRET_ACCESS_KEY: z.string().optional().default(''),
  R2_BUCKET_NAME: z.string().default('marketspace-media'),
  R2_PUBLIC_DOMAIN: z.string().url().default('https://cdn.marketspace.eg'),

  // Video (Cloudflare Stream)
  CLOUDFLARE_STREAM_API_TOKEN: z.string().optional().default(''),
  CLOUDFLARE_STREAM_ACCOUNT_ID: z.string().optional().default(''),
  CLOUDFLARE_STREAM_WEBHOOK_SECRET: z.string().optional().default(''),
  VIDEO_WEBHOOK_TOLERANCE_SEC: z.coerce.number().int().positive().default(300),

  // Payments (Paymob Egypt - Feature Flagged for V2)
  ENABLE_V2_PAYMENTS: z.coerce.boolean().optional().default(false),
  PAYMOB_API_KEY: z.string().optional().default(''),
  PAYMOB_INTEGRATION_ID_CARD: z.coerce.number().optional().default(0),
  PAYMOB_INTEGRATION_ID_WALLET: z.coerce.number().optional().default(0),
  PAYMOB_HMAC_SECRET: z.string().optional().default(''),

  // Push Notifications (FCM)
  FIREBASE_PROJECT_ID: z.string().optional().default(''),
  FIREBASE_CLIENT_EMAIL: z.string().optional().default(''),
  FIREBASE_PRIVATE_KEY: z.string().optional().default(''),

  // Transactional Email (Resend)
  RESEND_API_KEY: z.string().optional().default(''),
  EMAIL_FROM: z.string().optional().default('Deal One <onboarding@resend.dev>'),
  EMAIL_REPLY_TO: z.string().email().optional(),
  APP_PUBLIC_URL: z
    .string()
    .url()
    .default('https://one-deal-cjjt-production.up.railway.app'),
  EMAIL_VERIFICATION_TTL_MINUTES: z.coerce
    .number()
    .int()
    .positive()
    .max(1440)
    .default(30),

  // Observability / Error Tracking
  SENTRY_DSN: z.string().optional().default(''),
});

export type EnvConfig = z.infer<typeof envSchema> & {
  DATABASE_URL: string;
  JWT_ACCESS_SECRET: string;
  JWT_REFRESH_SECRET: string;
};

export function validateEnv(config: Record<string, unknown>): EnvConfig {
  const mergedConfig: Record<string, unknown> = {
    ...config,
  };

  if (!mergedConfig.DATABASE_URL) {
    const fallbackDb =
      mergedConfig.POSTGRES_URL ||
      mergedConfig.POSTGRESQL_URL ||
      mergedConfig.DATABASE_PUBLIC_URL;
    if (fallbackDb) {
      mergedConfig.DATABASE_URL = fallbackDb;
    }
  }

  // Strip empty or whitespace-only strings so missing values are detected cleanly
  for (const key of Object.keys(mergedConfig)) {
    if (
      typeof mergedConfig[key] === 'string' &&
      (mergedConfig[key] as string).trim() === ''
    ) {
      delete mergedConfig[key];
    }
  }

  const result = envSchema.safeParse(mergedConfig);
  if (!result.success) {
    const issues = result.error.issues
      .map((issue) => `[${issue.path.join('.')}]: ${issue.message}`)
      .join('\n');
    throw new Error(`\n❌ Configuration validation failed:\n${issues}\n`);
  }

  const data = result.data;
  const isProd = data.NODE_ENV === 'production';
  const errors: string[] = [];

  // Validate TRUST_PROXY syntax in all environments
  try {
    parseTrustProxy(data.TRUST_PROXY);
  } catch (err: any) {
    errors.push(`[TRUST_PROXY]: ${err.message}`);
  }

  if (isProd) {
    if (data.ENABLE_DEV_AUTH_BYPASS) {
      errors.push(
        '[ENABLE_DEV_AUTH_BYPASS]: Development auth bypass is strictly prohibited in production',
      );
    }

    if (!data.DATABASE_URL) {
      errors.push('[DATABASE_URL]: DATABASE_URL is required in production');
    }

    const accessErr = validateProductionSecret(
      'JWT_ACCESS_SECRET',
      data.JWT_ACCESS_SECRET,
    );
    if (accessErr) errors.push(`[JWT_ACCESS_SECRET]: ${accessErr}`);

    const refreshErr = validateProductionSecret(
      'JWT_REFRESH_SECRET',
      data.JWT_REFRESH_SECRET,
    );
    if (refreshErr) errors.push(`[JWT_REFRESH_SECRET]: ${refreshErr}`);

    if (
      data.JWT_ACCESS_SECRET &&
      data.JWT_REFRESH_SECRET &&
      data.JWT_ACCESS_SECRET === data.JWT_REFRESH_SECRET
    ) {
      errors.push(
        '[JWT_REFRESH_SECRET]: JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be different',
      );
    }

    try {
      parseCorsOrigins(data.CORS_ORIGIN, data.NODE_ENV);
    } catch (err: any) {
      errors.push(`[CORS_ORIGIN]: ${err.message}`);
    }
  } else {
    // Non-production convenience defaults (distinct, non-production secrets)
    if (!data.DATABASE_URL) {
      data.DATABASE_URL =
        'postgresql://postgres:postgres@localhost:5432/market_space_db?schema=public';
    }
    if (!data.JWT_ACCESS_SECRET) {
      data.JWT_ACCESS_SECRET = DEV_ONLY_ACCESS_SECRET;
    }
    if (!data.JWT_REFRESH_SECRET) {
      data.JWT_REFRESH_SECRET = DEV_ONLY_REFRESH_SECRET;
    }
    if (data.JWT_ACCESS_SECRET === data.JWT_REFRESH_SECRET) {
      errors.push(
        '[JWT_REFRESH_SECRET]: JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be different',
      );
    }
    if (data.CORS_ORIGIN) {
      try {
        parseCorsOrigins(data.CORS_ORIGIN, data.NODE_ENV);
      } catch (err: any) {
        errors.push(`[CORS_ORIGIN]: ${err.message}`);
      }
    }
  }

  if (errors.length > 0) {
    throw new Error(
      `\n❌ Configuration validation failed:\n${errors.join('\n')}\n`,
    );
  }

  return data as EnvConfig;
}
