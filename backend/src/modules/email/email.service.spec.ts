import { ConfigService } from '@nestjs/config';
import { EmailService } from './email.service';
import { renderWelcomeTemplate } from './templates/welcome.template';
import { renderEmailVerificationTemplate } from './templates/email-verification.template';
import { renderListingApprovedTemplate } from './templates/listing-approved.template';
import { renderListingRejectedTemplate } from './templates/listing-rejected.template';
import { renderSecurityNotificationTemplate } from './templates/security-notification.template';
import { renderPaymentReceiptTemplate } from './templates/payment-receipt.template';

function createConfig(overrides: Record<string, any> = {}): ConfigService {
  const defaults: Record<string, any> = {
    RESEND_API_KEY: '',
    EMAIL_FROM: 'Deal One <onboarding@resend.dev>',
    EMAIL_REPLY_TO: '',
    APP_PUBLIC_URL: 'https://one-deal-cjjt-production.up.railway.app',
    ...overrides,
  };
  return {
    get: jest.fn((key: string, defaultValue?: any) =>
      key in defaults ? defaults[key] : defaultValue,
    ),
  } as unknown as ConfigService;
}

describe('EmailService & Templates', () => {
  describe('Initialization & Configuration', () => {
    it('disables email delivery safely when RESEND_API_KEY is missing', async () => {
      const service = new EmailService(createConfig({ RESEND_API_KEY: '' }));
      expect(service.isConfigured()).toBe(false);
      expect(service.getReadinessStatus()).toBe('unconfigured');

      const result = await service.sendWelcomeEmail({
        to: 'user@example.com',
        displayName: 'Ahmed',
        locale: 'ar',
      });

      expect(result.success).toBe(false);
      expect(result.skipped).toBe(true);
      expect(result.reason).toBe('EMAIL_PROVIDER_UNCONFIGURED');
    });

    it('treats placeholder API keys as unconfigured', () => {
      const service = new EmailService(
        createConfig({ RESEND_API_KEY: 're_placeholder_key' }),
      );
      expect(service.isConfigured()).toBe(false);
      expect(service.getReadinessStatus()).toBe('unconfigured');
    });

    it('reports configured when a valid Resend client is provided', () => {
      const mockResend = { emails: { send: jest.fn() } } as any;
      const service = new EmailService(
        createConfig({ EMAIL_FROM: 'Deal One <noreply@mail.dealone.eg>' }),
        mockResend,
      );
      expect(service.isConfigured()).toBe(true);
      expect(service.getReadinessStatus()).toBe('configured');
      expect(service.getSenderAddress()).toBe(
        'Deal One <noreply@mail.dealone.eg>',
      );
    });
  });

  describe('Sending, Idempotency & Retries', () => {
    it('sends email via Resend SDK with idempotencyKey and returns messageId', async () => {
      const sendMock = jest.fn().mockResolvedValue({
        data: { id: 'email_msg_12345' },
        error: null,
      });
      const service = new EmailService(
        createConfig({ EMAIL_REPLY_TO: 'support@dealone.eg' }),
        { emails: { send: sendMock } } as any,
      );

      const res = await service.sendWelcomeEmail({
        to: 'buyer@example.com',
        displayName: 'Karim',
        locale: 'en',
        idempotencyKey: 'welcome-user-1',
      });

      expect(res.success).toBe(true);
      expect(res.messageId).toBe('email_msg_12345');
      expect(res.attempts).toBe(1);
      expect(sendMock).toHaveBeenCalledTimes(1);
      expect(sendMock).toHaveBeenCalledWith(
        expect.objectContaining({
          from: 'Deal One <onboarding@resend.dev>',
          to: 'buyer@example.com',
          replyTo: 'support@dealone.eg',
        }),
        { idempotencyKey: 'welcome-user-1' },
      );
    });

    it('does NOT retry non-retryable 4xx Resend API errors', async () => {
      const sendMock = jest.fn().mockResolvedValue({
        data: null,
        error: {
          name: 'validation_error',
          message: 'Invalid recipient address',
          statusCode: 422,
        },
      });
      const service = new EmailService(createConfig(), {
        emails: { send: sendMock },
      } as any);

      const res = await service.sendWelcomeEmail({
        to: 'bad@example.com',
        displayName: 'Test',
        locale: 'en',
      });

      expect(res.success).toBe(false);
      expect(res.attempts).toBe(1);
      expect(res.error).toContain('Invalid recipient');
      expect(sendMock).toHaveBeenCalledTimes(1);
    });

    it('retries retryable 5xx/429 errors and succeeds on subsequent attempt', async () => {
      const sendMock = jest
        .fn()
        .mockResolvedValueOnce({
          data: null,
          error: {
            name: 'rate_limit_exceeded',
            message: 'Too many requests',
            statusCode: 429,
          },
        })
        .mockResolvedValueOnce({
          data: { id: 'email_retry_ok' },
          error: null,
        });

      const service = new EmailService(createConfig(), {
        emails: { send: sendMock },
      } as any);
      jest.spyOn(service as any, 'delay').mockResolvedValue(undefined);

      const res = await service.sendWelcomeEmail({
        to: 'buyer@example.com',
        displayName: 'Test',
        locale: 'ar',
      });

      expect(res.success).toBe(true);
      expect(res.messageId).toBe('email_retry_ok');
      expect(res.attempts).toBe(2);
      expect(sendMock).toHaveBeenCalledTimes(2);
    });

    it('handles thrown network exceptions safely without crashing caller', async () => {
      const sendMock = jest.fn().mockRejectedValue(new Error('ECONNRESET'));
      const service = new EmailService(createConfig(), {
        emails: { send: sendMock },
      } as any);
      jest.spyOn(service as any, 'delay').mockResolvedValue(undefined);

      const res = await service.sendWelcomeEmail({
        to: 'buyer@example.com',
        displayName: 'Test',
        locale: 'ar',
      });

      expect(res.success).toBe(false);
      expect(res.error).toBe('ECONNRESET');
      expect(res.attempts).toBe(3);
    });
  });

  describe('Templates (RTL/LTR, XSS Escaping, Plain Text)', () => {
    it('renders Arabic RTL layout with plain-text fallback', () => {
      const rendered = renderWelcomeTemplate({
        displayName: 'إبراهيم',
        locale: 'ar',
        appUrl: 'https://dealone.eg',
      });
      expect(rendered.html).toContain('lang="ar" dir="rtl"');
      expect(rendered.html).toContain('إبراهيم');
      expect(rendered.text).toContain('إبراهيم');
      expect(rendered.subject).toContain('صفقة ون');
    });

    it('renders English LTR layout with plain-text fallback', () => {
      const rendered = renderEmailVerificationTemplate({
        displayName: 'Ibrahim',
        verificationUrl: 'https://dealone.eg/verify-email?token=abc',
        expiresInMinutes: 30,
        locale: 'en',
      });
      expect(rendered.html).toContain('lang="en" dir="ltr"');
      expect(rendered.html).toContain('30 minutes');
      expect(rendered.text).toContain(
        'https://dealone.eg/verify-email?token=abc',
      );
    });

    it('escapes HTML/XSS payloads in user-supplied fields', () => {
      const rendered = renderListingRejectedTemplate({
        displayName: '<script>alert(1)</script>',
        listingTitle: 'Villa "Luxury" & <img src=x onerror=alert(2)>',
        reasonCode: 'POLICY_VIOLATION',
        reasonNotes: '<b>Prohibited</b>',
        locale: 'en',
      });
      expect(rendered.html).not.toContain('<script>');
      expect(rendered.html).not.toContain('<img src=x');
      expect(rendered.html).toContain('&lt;script&gt;alert(1)&lt;/script&gt;');
      expect(rendered.html).toContain('&lt;b&gt;Prohibited&lt;/b&gt;');
    });

    it('renders listing approved, security notification, and payment receipt templates', () => {
      const approved = renderListingApprovedTemplate({
        displayName: 'Ali',
        listingTitle: 'Apartment in Nasr City',
        listingUrl: 'https://dealone.eg/listings/1',
        locale: 'en',
      });
      expect(approved.html).toContain('Apartment in Nasr City');
      expect(approved.text).toContain('https://dealone.eg/listings/1');

      const security = renderSecurityNotificationTemplate({
        displayName: 'علي',
        eventKind: 'PASSWORD_CHANGED',
        occurredAt: new Date('2026-11-19T12:00:00Z'),
        ipAddress: '197.55.10.2',
        locale: 'ar',
      });
      expect(security.html).toContain('dir="rtl"');
      expect(security.html).toContain('197.55.10.2');

      const receipt = renderPaymentReceiptTemplate({
        displayName: 'Ali',
        amountEgp: 250,
        currency: 'EGP',
        packageName: 'Featured 7 Days',
        listingTitle: 'Toyota Corolla 2022',
        transactionReference: 'TX-999',
        paidAt: new Date('2026-11-19T12:00:00Z'),
        locale: 'en',
      });
      expect(receipt.html).toContain('250 EGP');
      expect(receipt.html).toContain('TX-999');
    });
  });
});
