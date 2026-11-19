export const EMAIL_DEFAULTS = {
  FROM_TESTING: 'Deal One <onboarding@resend.dev>',
  FROM_PRODUCTION_PREFERRED: 'Deal One <noreply@mail.dealone.eg>',
  APP_PUBLIC_URL: 'https://one-deal-cjjt-production.up.railway.app',
  REQUEST_TIMEOUT_MS: 10_000,
  MAX_RETRIES: 3,
  INITIAL_RETRY_DELAY_MS: 400,
  VERIFICATION_TTL_MINUTES: 30,
  VERIFICATION_COOLDOWN_SECONDS: 60,
} as const;

export const EMAIL_REDIS_KEYS = {
  verificationToken: (tokenHash: string) => `email:verify:token:${tokenHash}`,
  verificationUserActiveToken: (userId: string) =>
    `email:verify:user:${userId}`,
  verificationCooldown: (userId: string) => `email:verify:cooldown:${userId}`,
} as const;

export const KNOWN_PLACEHOLDER_RESEND_KEYS = [
  're_placeholder',
  'replace_with_resend_api_key',
  'your_resend_api_key',
  'changeme',
] as const;
