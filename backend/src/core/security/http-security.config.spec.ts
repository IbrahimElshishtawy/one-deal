import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import {
  buildCorsOptions,
  buildHelmetOptions,
  shouldEnableSwagger,
} from './http-security.config';

describe('HTTP Security Configuration (CORS, Helmet, Swagger)', () => {
  describe('Swagger gating', () => {
    it('should disable Swagger in production by default', () => {
      expect(shouldEnableSwagger('production', false)).toBe(false);
    });

    it('should allow Swagger in production only when explicitly enabled', () => {
      expect(shouldEnableSwagger('production', true)).toBe(true);
    });

    it('should enable Swagger in development and test environments', () => {
      expect(shouldEnableSwagger('development', false)).toBe(true);
      expect(shouldEnableSwagger('test', false)).toBe(true);
    });
  });

  describe('Production CORS & Preflight enforcement (real Fastify)', () => {
    const allowedOrigin1 = 'https://dealone.eg';
    const allowedOrigin2 = 'https://admin.dealone.eg';
    const unauthorizedOrigin = 'https://evil-phishing.example';

    async function createProdFastify() {
      const app = Fastify();
      await app.register(helmet, buildHelmetOptions(false));
      await app.register(
        cors,
        buildCorsOptions(`${allowedOrigin1}, ${allowedOrigin2}`, 'production'),
      );
      app.get('/api/v1/listings', async () => ({ success: true, data: [] }));
      await app.ready();
      return app;
    }

    it('should allow authorized origin and return Access-Control-Allow-Credentials: true', async () => {
      const app = await createProdFastify();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/listings',
        headers: { origin: allowedOrigin1 },
      });

      expect(res.statusCode).toBe(200);
      expect(res.headers['access-control-allow-origin']).toBe(allowedOrigin1);
      expect(res.headers['access-control-allow-credentials']).toBe('true');
      expect(res.headers['content-security-policy']).toContain(
        "default-src 'none'",
      );
      expect(res.headers['x-frame-options']).toBe('DENY');
      await app.close();
    });

    it('should allow second origin in multiple allowed origins list', async () => {
      const app = await createProdFastify();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/listings',
        headers: { origin: allowedOrigin2 },
      });

      expect(res.statusCode).toBe(200);
      expect(res.headers['access-control-allow-origin']).toBe(allowedOrigin2);
      await app.close();
    });

    it('should reject unauthorized origin without reflecting Access-Control-Allow-Origin', async () => {
      const app = await createProdFastify();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/listings',
        headers: { origin: unauthorizedOrigin },
      });

      expect(res.headers['access-control-allow-origin']).toBeUndefined();
      await app.close();
    });

    it('should handle preflight OPTIONS for authorized vs unauthorized origins', async () => {
      const app = await createProdFastify();

      const okPreflight = await app.inject({
        method: 'OPTIONS',
        url: '/api/v1/listings',
        headers: {
          origin: allowedOrigin1,
          'access-control-request-method': 'POST',
          'access-control-request-headers': 'Authorization, Content-Type',
        },
      });
      expect(okPreflight.statusCode).toBe(204);
      expect(okPreflight.headers['access-control-allow-origin']).toBe(
        allowedOrigin1,
      );
      expect(okPreflight.headers['access-control-allow-credentials']).toBe(
        'true',
      );

      const badPreflight = await app.inject({
        method: 'OPTIONS',
        url: '/api/v1/listings',
        headers: {
          origin: unauthorizedOrigin,
          'access-control-request-method': 'POST',
        },
      });
      expect(
        badPreflight.headers['access-control-allow-origin'],
      ).toBeUndefined();

      await app.close();
    });

    it('should keep native Flutter mobile requests (no Origin header) functional', async () => {
      const app = await createProdFastify();
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/listings',
      });

      expect(res.statusCode).toBe(200);
      await app.close();
    });

    it('should fail fast when production CORS_ORIGIN is missing or wildcard', () => {
      expect(() => buildCorsOptions('', 'production')).toThrow(
        /CORS_ORIGIN must be explicitly configured/,
      );
      expect(() => buildCorsOptions('*', 'production')).toThrow(
        /must not contain wildcard/,
      );
    });
  });
});
