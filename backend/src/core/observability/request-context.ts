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
    requestContextStorage.getStore()?.requestId || fallback || 'no-request-id'
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
  /password|passcode|token|authorization|secret|otp|codehash|cookie|cvv|card|credit|apikey|privatekey|messagecontent|chatbody|nationalid|taxid|commercialregister|authorizedrepresentative|uploadurl|accessurl|presigned|signedurl|x-amz-signature|x-amz-credential|fileheaderbase64/i;

/**
 * Sanitizes arbitrary log strings (error messages, URLs, stack traces, external service outputs)
 * to strip Bearer tokens, presigned URL signatures, connection string credentials,
 * encrypted ciphertexts, and inline sensitive key=value pairs.
 */
export function sanitizeLogString(value: string, maxLength = 1000): string {
  if (!value || typeof value !== 'string') {
    return '';
  }

  let sanitized = value;

  // 1. Standalone or embedded Bearer tokens
  sanitized = sanitized.replace(
    /\bBearer\s+[A-Za-z0-9._~+/=-]+/gi,
    'Bearer [REDACTED]',
  );

  // 2. Presigned URLs (R2 / S3 SigV4 or local signed fallback)
  if (
    /X-Amz-Signature=|X-Amz-Credential=|X-Amz-Security-Token=|&sig=[0-9a-f]{16,}/i.test(
      sanitized,
    )
  ) {
    sanitized = sanitized.replace(
      /https?:\/\/[^\s"'<>]*?(?:X-Amz-Signature=|X-Amz-Credential=|X-Amz-Security-Token=|&sig=[0-9a-f]{16,})[^\s"'<>]*/gi,
      '[REDACTED_SIGNED_URL]',
    );
    // Catch relative URLs / query fragments containing signatures
    sanitized = sanitized.replace(
      /(X-Amz-Signature|X-Amz-Credential|X-Amz-Security-Token|sig)=[^&\s"'<>]+/gi,
      '$1=[REDACTED]',
    );
  }

  // 3. Connection string credentials (redis://user:pass@host, postgres://user:pass@host)
  sanitized = sanitized.replace(
    /\b(rediss?|postgres(?:ql)?|amqps?|mongodb(?:\+srv)?):\/\/[^@\s"'<>]+@/gi,
    '$1://[REDACTED]@',
  );

  // 4. Encrypted PII ciphertexts (enc:v1:iv:tag:ciphertext)
  sanitized = sanitized.replace(
    /\benc:v\d+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]*/gi,
    '[REDACTED_CIPHERTEXT]',
  );

  // 5. Inline sensitive key=value or key: value patterns
  sanitized = sanitized.replace(
    /\b(password|passcode|access_?token|refresh_?token|api_?key|secret|national_?id(?:_?number)?|tax_?id(?:_?number)?|commercial_?register(?:_?number)?)\s*([:=])\s*["']?[^\s,"'&;}\]]+["']?/gi,
    '$1$2[REDACTED]',
  );

  return sanitized.length > maxLength
    ? `${sanitized.slice(0, maxLength)}...[truncated]`
    : sanitized;
}

/**
 * Recursively redacts sensitive fields from objects before logging.
 * Safe against circular references and Error objects; never throws.
 */
export function redactSensitiveData(
  value: unknown,
  depth = 0,
  seen = new WeakSet<object>(),
): unknown {
  if (value === null || value === undefined || depth > 5) {
    return value;
  }
  if (typeof value === 'string') {
    if (/^bearer\s+/i.test(value)) {
      return 'Bearer [REDACTED]';
    }
    if (
      /^https?:\/\/.*(?:X-Amz-Signature=|X-Amz-Credential=|&sig=[0-9a-f]{16,})/i.test(
        value,
      )
    ) {
      return '[REDACTED_SIGNED_URL]';
    }
    if (/^enc:v\d+:[0-9a-f]+:[0-9a-f]+:/i.test(value)) {
      return '[REDACTED_CIPHERTEXT]';
    }
    return sanitizeLogString(value, 300);
  }
  if (typeof value === 'object') {
    if (seen.has(value as object)) {
      return '[CIRCULAR]';
    }
    seen.add(value as object);

    if (value instanceof Error) {
      return {
        name: value.name,
        message: sanitizeLogString(value.message, 500),
      };
    }
    if (Array.isArray(value)) {
      return value
        .slice(0, 20)
        .map((item) => redactSensitiveData(item, depth + 1, seen));
    }

    const output: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(value as Record<string, unknown>)) {
      if (SENSITIVE_KEY_PATTERN.test(key)) {
        output[key] = '[REDACTED]';
      } else if (key.toLowerCase() === 'email' && typeof val === 'string') {
        output[key] = maskEmail(val);
      } else if (key.toLowerCase() === 'phone' && typeof val === 'string') {
        output[key] = maskPhone(val);
      } else {
        output[key] = redactSensitiveData(val, depth + 1, seen);
      }
    }
    return output;
  }
  return value;
}
