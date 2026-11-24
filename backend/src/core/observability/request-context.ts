import { AsyncLocalStorage } from 'async_hooks';

export interface RequestContextStore {
  requestId: string;
  method?: string;
  path?: string;
  userId?: string | null;
  startedAt: number;
}

const requestContextStorage = new AsyncLocalStorage<RequestContextStore>();

export function runWithRequestContext<T>(
  store: RequestContextStore,
  fn: () => T,
): T {
  return requestContextStorage.run(store, fn);
}

export function getRequestContext(): RequestContextStore | undefined {
  return requestContextStorage.getStore();
}

export function getCurrentRequestId(fallback?: string): string {
  return (
    requestContextStorage.getStore()?.requestId ||
    fallback ||
    'no-request-id'
  );
}

/**
 * Fail-closed check for development-only observability (such as OTP terminal logging).
 * Strictly returns false in production, staging, or whenever NODE_ENV !== 'development'.
 */
export function isDevelopmentObservabilityEnabled(
  configuredEnv?: string,
): boolean {
  const processEnv = (process.env.NODE_ENV || '').trim().toLowerCase();
  const effectiveEnv = (configuredEnv || processEnv).trim().toLowerCase();
  if (processEnv === 'production' || effectiveEnv === 'production') {
    return false;
  }
  return processEnv === 'development' && effectiveEnv === 'development';
}

/**
 * Masks an email address safely for logs (e.g. "testuser@gmail.com" -> "tes***@gmail.com").
 */
export function maskEmail(email?: string | null): string {
  if (!email) return '***';
  const trimmed = email.trim();
  const atIndex = trimmed.indexOf('@');
  if (atIndex <= 0) return '***';
  const local = trimmed.slice(0, atIndex);
  const domain = trimmed.slice(atIndex);
  const visible = local.length <= 3 ? local.slice(0, 1) : local.slice(0, 3);
  return `${visible}***${domain}`;
}

/**
 * Masks an E.164 phone number safely for logs (e.g. "+201012345678" -> "+2010***5678").
 */
export function maskPhone(phone?: string | null): string {
  if (!phone) return '***';
  const trimmed = phone.trim();
  if (trimmed.length <= 6) return '***';
  return `${trimmed.slice(0, 5)}***${trimmed.slice(-4)}`;
}

const SENSITIVE_KEY_PATTERN =
  /password|passcode|token|authorization|secret|otp|codehash|cookie|cvv|card|credit|apikey|privatekey|messagecontent|chatbody/i;

/**
 * Recursively redacts sensitive fields from objects before logging.
 */
export function redactSensitiveData(value: unknown, depth = 0): unknown {
  if (value === null || value === undefined || depth > 5) {
    return value;
  }
  if (typeof value === 'string') {
    if (/^bearer\s+/i.test(value)) {
      return 'Bearer [REDACTED]';
    }
    return value.length > 300 ? `${value.slice(0, 300)}...[truncated]` : value;
  }
  if (Array.isArray(value)) {
    return value.slice(0, 20).map((item) => redactSensitiveData(item, depth + 1));
  }
  if (typeof value === 'object') {
    const output: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(value as Record<string, unknown>)) {
      if (SENSITIVE_KEY_PATTERN.test(key)) {
        output[key] = '[REDACTED]';
      } else if (key.toLowerCase() === 'email' && typeof val === 'string') {
        output[key] = maskEmail(val);
      } else if (key.toLowerCase() === 'phone' && typeof val === 'string') {
        output[key] = maskPhone(val);
      } else {
        output[key] = redactSensitiveData(val, depth + 1);
      }
    }
    return output;
  }
  return value;
}
