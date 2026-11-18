import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MetricsAuthGuard } from './metrics-auth.guard';

describe('MetricsAuthGuard', () => {
  function buildGuard(env: Record<string, string>) {
    const configService = {
      get: jest.fn((key: string, defaultVal?: any) =>
        key in env ? env[key] : defaultVal,
      ),
    } as unknown as ConfigService;
    return new MetricsAuthGuard(configService);
  }

  function createContext(request: Record<string, any>): ExecutionContext {
    return {
      switchToHttp: () => ({
        getRequest: () => request,
      }),
    } as any;
  }

  it('should reject unauthorized external requests in production when token is configured', () => {
    const guard = buildGuard({
      NODE_ENV: 'production',
      METRICS_AUTH_TOKEN: 'super-secret-prometheus-scrape-token-1234',
    });

    expect(() =>
      guard.canActivate(createContext({ ip: '203.0.113.50', headers: {} })),
    ).toThrow(UnauthorizedException);

    expect(() =>
      guard.canActivate(
        createContext({
          ip: '203.0.113.50',
          headers: { authorization: 'Bearer wrong-token' },
        }),
      ),
    ).toThrow(UnauthorizedException);
  });

  it('should allow authorized Prometheus scraper with Bearer token or X-Metrics-Token', () => {
    const token = 'super-secret-prometheus-scrape-token-1234';
    const guard = buildGuard({
      NODE_ENV: 'production',
      METRICS_AUTH_TOKEN: token,
    });

    expect(
      guard.canActivate(
        createContext({
          ip: '203.0.113.50',
          headers: { authorization: `Bearer ${token}` },
        }),
      ),
    ).toBe(true);

    expect(
      guard.canActivate(
        createContext({
          ip: '203.0.113.50',
          headers: { 'x-metrics-token': token },
        }),
      ),
    ).toBe(true);
  });

  it('should fail closed for external IPs in production when METRICS_AUTH_TOKEN is unset', () => {
    const guard = buildGuard({
      NODE_ENV: 'production',
      METRICS_AUTH_TOKEN: '',
    });

    expect(() =>
      guard.canActivate(createContext({ ip: '203.0.113.50', headers: {} })),
    ).toThrow(UnauthorizedException);

    expect(
      guard.canActivate(createContext({ ip: '127.0.0.1', headers: {} })),
    ).toBe(true);
  });

  it('should allow private/loopback network scraping in development when token is unset', () => {
    const guard = buildGuard({
      NODE_ENV: 'development',
      METRICS_AUTH_TOKEN: '',
    });

    expect(
      guard.canActivate(createContext({ ip: '172.18.0.5', headers: {} })),
    ).toBe(true);
    expect(() =>
      guard.canActivate(createContext({ ip: '8.8.8.8', headers: {} })),
    ).toThrow(UnauthorizedException);
  });
});
