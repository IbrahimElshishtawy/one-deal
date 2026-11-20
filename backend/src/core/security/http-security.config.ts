import { FastifyCorsOptions } from '@fastify/cors';
import { FastifyHelmetOptions } from '@fastify/helmet';
import { parseCorsOrigins } from '../config/env.config';

export function shouldEnableSwagger(
  nodeEnv: string,
  enableSwaggerFlag: boolean,
): boolean {
  return nodeEnv !== 'production' || enableSwaggerFlag === true;
}

/**
 * Builds strict CORS options.
 * - Production: explicit validated allowlist required; never reflects arbitrary origins with credentials.
 * - Native mobile clients (Flutter iOS/Android) send no Origin header and are always permitted.
 */
export function buildCorsOptions(
  rawCorsOrigin: string | undefined,
  nodeEnv: string,
): FastifyCorsOptions {
  const allowedOrigins = parseCorsOrigins(rawCorsOrigin, nodeEnv);
  const isProd = nodeEnv === 'production';
  const allowAllInDev =
    !isProd && (allowedOrigins.length === 0 || allowedOrigins.includes('*'));

  return {
    origin: (origin, cb) => {
      // Allow non-browser / native mobile clients (no Origin header)
      if (!origin) {
        cb(null, true);
        return;
      }

      if (allowAllInDev) {
        cb(null, true);
        return;
      }

      if (allowedOrigins.includes(origin)) {
        cb(null, origin);
        return;
      }

      // Reject unauthorized origin cleanly (no ACAO header)
      cb(null, false);
    },
    credentials: true,
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Trace-Id',
      'X-Request-Id',
      'X-Account-Id',
      'X-Metrics-Token',
      'X-CSRF-Token',
      'X-Requested-With',
    ],
    exposedHeaders: [
      'X-Trace-Id',
      'X-Request-Id',
      'X-RateLimit-Limit',
      'X-RateLimit-Remaining',
      'X-RateLimit-Reset',
      'Retry-After',
    ],
    maxAge: 600,
  };
}

/**
 * Builds Helmet HTTP security headers configuration.
 * Enables strict API CSP when Swagger UI is disabled (production default).
 */
export function buildHelmetOptions(
  swaggerEnabled: boolean,
): FastifyHelmetOptions {
  return {
    contentSecurityPolicy: swaggerEnabled
      ? false
      : {
          directives: {
            defaultSrc: ["'none'"],
            frameAncestors: ["'none'"],
          },
        },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
    },
    referrerPolicy: { policy: 'no-referrer' },
    frameguard: { action: 'deny' },
  };
}
