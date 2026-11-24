import { Logger } from '@nestjs/common';
import {
  isDevelopmentObservabilityEnabled,
  maskEmail,
  maskPhone,
  redactSensitiveData,
  runWithRequestContext,
} from './request-context';
import { StructuredFlowLogger } from './structured-flow.logger';

describe('Backend Observability & Dev OTP Logging', () => {
  const originalNodeEnv = process.env.NODE_ENV;

  afterEach(() => {
    process.env.NODE_ENV = originalNodeEnv;
    jest.restoreAllMocks();
  });

  it('masks email and phone safely', () => {
    expect(maskEmail('testuser@gmail.com')).toBe('tes***@gmail.com');
    expect(maskEmail('a@b.com')).toBe('a***@b.com');
    expect(maskPhone('+201012345678')).toBe('+2010***5678');
  });

  it('redacts sensitive fields recursively without leaking secrets', () => {
    const sanitized = redactSensitiveData({
      password: 'MySecretPassword123',
      accessToken: 'jwt.access.token',
      refreshToken: 'jwt.refresh.token',
      authorization: 'Bearer secret-bearer',
      otp: '123456',
      email: 'ahmed.ali@example.com',
      phone: '+201012345678',
      nested: {
        newPassword: 'AnotherPassword',
        safeField: 'hello',
      },
    }) as Record<string, any>;

    expect(sanitized.password).toBe('[REDACTED]');
    expect(sanitized.accessToken).toBe('[REDACTED]');
    expect(sanitized.refreshToken).toBe('[REDACTED]');
    expect(sanitized.authorization).toBe('[REDACTED]');
    expect(sanitized.otp).toBe('[REDACTED]');
    expect(sanitized.email).toBe('ahm***@example.com');
    expect(sanitized.phone).toBe('+2010***5678');
    expect(sanitized.nested.newPassword).toBe('[REDACTED]');
    expect(sanitized.nested.safeField).toBe('hello');
  });

  it('strictly disables dev OTP logging in production', () => {
    process.env.NODE_ENV = 'production';
    const logSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation();

    expect(isDevelopmentObservabilityEnabled('development')).toBe(false);
    expect(isDevelopmentObservabilityEnabled('production')).toBe(false);

    StructuredFlowLogger.logDevOtpGenerated({
      configuredEnv: 'production',
      targetPhone: '+201012345678',
      purpose: 'AUTH',
      otp: '987654',
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 180_000),
      requestId: 'req-prod-1',
    });

    expect(logSpy).not.toHaveBeenCalled();
  });

  it('emits structured [AUTH][DEV] OTP log in development with masked target & requestId', () => {
    process.env.NODE_ENV = 'development';
    const logSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation();

    runWithRequestContext(
      { requestId: 'req-dev-42', startedAt: Date.now() },
      () => {
        StructuredFlowLogger.logDevOtpGenerated({
          configuredEnv: 'development',
          targetPhone: '+201012345678',
          purpose: 'REGISTRATION',
          otp: '654321',
          createdAt: new Date('2026-11-24T17:00:00.000Z'),
          expiresAt: new Date('2026-11-24T17:03:00.000Z'),
        });
      },
    );

    expect(logSpy).toHaveBeenCalledTimes(1);
    const loggedMessage = String(logSpy.mock.calls[0][0]);
    expect(loggedMessage).toContain('[AUTH][DEV]');
    expect(loggedMessage).toContain('Event: OTP_GENERATED');
    expect(loggedMessage).toContain('+2010***5678');
    expect(loggedMessage).toContain('Purpose: REGISTRATION');
    expect(loggedMessage).toContain('OTP: 654321');
    expect(loggedMessage).toContain('Request ID: req-dev-42');
    expect(loggedMessage).not.toContain('+201012345678');
  });
});
