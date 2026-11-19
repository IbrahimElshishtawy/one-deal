import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';
import {
  EMAIL_DEFAULTS,
  KNOWN_PLACEHOLDER_RESEND_KEYS,
} from './email.constants';
import {
  EmailReadinessStatus,
  EmailVerificationPayload,
  EmailVerifiedPayload,
  ListingApprovedEmailPayload,
  ListingRejectedEmailPayload,
  PaymentReceiptEmailPayload,
  SecurityNotificationEmailPayload,
  SendEmailOptions,
  SendEmailResult,
  WelcomeEmailPayload,
} from './email.types';
import { normalizeEmailLocale } from './templates/email-layout.template';
import { renderWelcomeTemplate } from './templates/welcome.template';
import { renderEmailVerificationTemplate } from './templates/email-verification.template';
import { renderEmailVerifiedTemplate } from './templates/email-verified.template';
import { renderListingApprovedTemplate } from './templates/listing-approved.template';
import { renderListingRejectedTemplate } from './templates/listing-rejected.template';
import { renderSecurityNotificationTemplate } from './templates/security-notification.template';
import { renderPaymentReceiptTemplate } from './templates/payment-receipt.template';

export const RESEND_CLIENT = 'RESEND_CLIENT';

function isPlaceholderApiKey(key: string): boolean {
  const lower = key.trim().toLowerCase();
  if (!lower) return true;
  if (
    KNOWN_PLACEHOLDER_RESEND_KEYS.some((placeholder) =>
      lower.includes(placeholder),
    )
  ) {
    return true;
  }
  return false;
}

function maskEmail(email: string): string {
  const trimmed = email.trim();
  const atIndex = trimmed.indexOf('@');
  if (atIndex <= 1) return '***';
  return `${trimmed[0]}***${trimmed.slice(atIndex)}`;
}

function isRetryableError(statusCode?: number | null, name?: string): boolean {
  if (typeof statusCode === 'number') {
    return statusCode === 429 || statusCode >= 500;
  }
  if (name === 'rate_limit_exceeded' || name === 'application_error') {
    return true;
  }
  return false;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly resend: Resend | null;
  private readonly configured: boolean;
  private readonly fromAddress: string;
  private readonly replyToAddress?: string;
  private readonly appPublicUrl: string;
  private readonly requestTimeoutMs: number;
  private readonly maxRetries: number;
  private readonly initialRetryDelayMs: number;

  constructor(
    private readonly configService: ConfigService,
    @Optional() resendClient?: Resend,
  ) {
    const apiKey = (
      this.configService.get<string>('RESEND_API_KEY', '') || ''
    ).trim();

    this.fromAddress = (
      this.configService.get<string>(
        'EMAIL_FROM',
        EMAIL_DEFAULTS.FROM_TESTING,
      ) || EMAIL_DEFAULTS.FROM_TESTING
    ).trim();

    const rawReplyTo = (
      this.configService.get<string>('EMAIL_REPLY_TO', '') || ''
    ).trim();
    this.replyToAddress = rawReplyTo || undefined;

    this.appPublicUrl = (
      this.configService.get<string>(
        'APP_PUBLIC_URL',
        EMAIL_DEFAULTS.APP_PUBLIC_URL,
      ) || EMAIL_DEFAULTS.APP_PUBLIC_URL
    )
      .trim()
      .replace(/\/+$/, '');

    this.requestTimeoutMs = EMAIL_DEFAULTS.REQUEST_TIMEOUT_MS;
    this.maxRetries = EMAIL_DEFAULTS.MAX_RETRIES;
    this.initialRetryDelayMs = EMAIL_DEFAULTS.INITIAL_RETRY_DELAY_MS;

    if (resendClient) {
      this.resend = resendClient;
      this.configured = true;
    } else if (apiKey && !isPlaceholderApiKey(apiKey)) {
      this.resend = new Resend(apiKey);
      this.configured = true;
    } else {
      this.resend = null;
      this.configured = false;
      this.logger.warn(
        'Email delivery is disabled: RESEND_API_KEY is not configured. Transactional emails will be skipped safely.',
      );
    }
  }

  isConfigured(): boolean {
    return this.configured && this.resend !== null;
  }

  getReadinessStatus(): EmailReadinessStatus {
    return this.isConfigured() ? 'configured' : 'unconfigured';
  }

  getSenderAddress(): string {
    return this.fromAddress;
  }

  getAppPublicUrl(): string {
    return this.appPublicUrl;
  }

  async sendEmail(options: SendEmailOptions): Promise<SendEmailResult> {
    const recipients = Array.isArray(options.to) ? options.to : [options.to];
    const maskedRecipients = recipients.map(maskEmail).join(', ');
    const locale = options.locale ?? 'ar';

    if (!this.isConfigured() || !this.resend) {
      this.logger.warn(
        JSON.stringify({
          event: 'email_skipped_unconfigured',
          template: options.template,
          locale,
          recipientCount: recipients.length,
        }),
      );
      return {
        success: false,
        skipped: true,
        reason: 'EMAIL_PROVIDER_UNCONFIGURED',
        attempts: 0,
      };
    }

    const payload = {
      from: this.fromAddress,
      to: options.to,
      subject: options.subject,
      html: options.html,
      text: options.text,
      ...(options.replyTo || this.replyToAddress
        ? { replyTo: options.replyTo || this.replyToAddress }
        : {}),
      tags: [
        { name: 'template', value: options.template },
        { name: 'locale', value: locale },
        ...(options.tags ?? []),
      ],
    };

    const requestOptions = options.idempotencyKey
      ? { idempotencyKey: options.idempotencyKey }
      : undefined;

    let lastError = 'Unknown Resend error';

    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        const response = await this.executeWithTimeout(
          this.resend.emails.send(payload, requestOptions),
          this.requestTimeoutMs,
        );

        if (response?.error) {
          const statusCode = (response.error as any).statusCode as
            number | null | undefined;
          const errorName = response.error.name;
          lastError = response.error.message || errorName || 'Resend API error';

          if (
            attempt < this.maxRetries &&
            isRetryableError(statusCode, errorName)
          ) {
            await this.delay(
              this.initialRetryDelayMs * Math.pow(2, attempt - 1),
            );
            continue;
          }

          this.logger.error(
            JSON.stringify({
              event: 'email_send_failed',
              template: options.template,
              locale,
              recipients: maskedRecipients,
              attempt,
              statusCode: statusCode ?? null,
              errorName,
              error: lastError,
            }),
          );

          return {
            success: false,
            error: lastError,
            attempts: attempt,
          };
        }

        const messageId = response?.data?.id;
        this.logger.log(
          JSON.stringify({
            event: 'email_sent',
            template: options.template,
            locale,
            recipients: maskedRecipients,
            messageId: messageId ?? null,
            attempt,
          }),
        );

        return {
          success: true,
          messageId,
          attempts: attempt,
        };
      } catch (err: any) {
        lastError = err?.message || 'Network or timeout error sending email';
        if (attempt < this.maxRetries) {
          await this.delay(this.initialRetryDelayMs * Math.pow(2, attempt - 1));
          continue;
        }

        this.logger.error(
          JSON.stringify({
            event: 'email_send_exception',
            template: options.template,
            locale,
            recipients: maskedRecipients,
            attempt,
            error: lastError,
          }),
        );

        return {
          success: false,
          error: lastError,
          attempts: attempt,
        };
      }
    }

    return {
      success: false,
      error: lastError,
      attempts: this.maxRetries,
    };
  }

  async sendWelcomeEmail(
    payload: WelcomeEmailPayload,
  ): Promise<SendEmailResult> {
    const locale = normalizeEmailLocale(payload.locale);
    const rendered = renderWelcomeTemplate({
      displayName: payload.displayName,
      locale,
      appUrl: this.appPublicUrl,
    });
    return this.sendEmail({
      to: payload.to,
      ...rendered,
      template: 'welcome',
      locale,
      idempotencyKey: payload.idempotencyKey,
    });
  }

  async sendEmailVerification(
    payload: EmailVerificationPayload,
  ): Promise<SendEmailResult> {
    const locale = normalizeEmailLocale(payload.locale);
    const rendered = renderEmailVerificationTemplate({
      displayName: payload.displayName,
      verificationUrl: payload.verificationUrl,
      expiresInMinutes: payload.expiresInMinutes,
      locale,
    });
    return this.sendEmail({
      to: payload.to,
      ...rendered,
      template: 'email-verification',
      locale,
      idempotencyKey: payload.idempotencyKey,
    });
  }

  async sendEmailVerifiedConfirmation(
    payload: EmailVerifiedPayload,
  ): Promise<SendEmailResult> {
    const locale = normalizeEmailLocale(payload.locale);
    const rendered = renderEmailVerifiedTemplate({
      displayName: payload.displayName,
      locale,
      appUrl: this.appPublicUrl,
    });
    return this.sendEmail({
      to: payload.to,
      ...rendered,
      template: 'email-verified',
      locale,
      idempotencyKey: payload.idempotencyKey,
    });
  }

  async sendListingApprovedEmail(
    payload: ListingApprovedEmailPayload,
  ): Promise<SendEmailResult> {
    const locale = normalizeEmailLocale(payload.locale);
    const rendered = renderListingApprovedTemplate({
      displayName: payload.displayName,
      listingTitle: payload.listingTitle,
      listingUrl: payload.listingUrl,
      locale,
    });
    return this.sendEmail({
      to: payload.to,
      ...rendered,
      template: 'listing-approved',
      locale,
      idempotencyKey: payload.idempotencyKey,
    });
  }

  async sendListingRejectedEmail(
    payload: ListingRejectedEmailPayload,
  ): Promise<SendEmailResult> {
    const locale = normalizeEmailLocale(payload.locale);
    const rendered = renderListingRejectedTemplate({
      displayName: payload.displayName,
      listingTitle: payload.listingTitle,
      reasonCode: payload.reasonCode,
      reasonNotes: payload.reasonNotes,
      listingUrl: payload.listingUrl,
      locale,
    });
    return this.sendEmail({
      to: payload.to,
      ...rendered,
      template: 'listing-rejected',
      locale,
      idempotencyKey: payload.idempotencyKey,
    });
  }

  async sendSecurityNotificationEmail(
    payload: SecurityNotificationEmailPayload,
  ): Promise<SendEmailResult> {
    const locale = normalizeEmailLocale(payload.locale);
    const rendered = renderSecurityNotificationTemplate({
      displayName: payload.displayName,
      eventKind: payload.eventKind,
      occurredAt: payload.occurredAt ?? new Date(),
      ipAddress: payload.ipAddress,
      locale,
    });
    return this.sendEmail({
      to: payload.to,
      ...rendered,
      template: 'security-notification',
      locale,
      idempotencyKey: payload.idempotencyKey,
    });
  }

  async sendPaymentReceiptEmail(
    payload: PaymentReceiptEmailPayload,
  ): Promise<SendEmailResult> {
    const locale = normalizeEmailLocale(payload.locale);
    const rendered = renderPaymentReceiptTemplate({
      displayName: payload.displayName,
      amountEgp: payload.amountEgp,
      currency: payload.currency || 'EGP',
      packageName: payload.packageName,
      listingTitle: payload.listingTitle,
      transactionReference: payload.transactionReference,
      paidAt: payload.paidAt ?? new Date(),
      locale,
    });
    return this.sendEmail({
      to: payload.to,
      ...rendered,
      template: 'payment-receipt',
      locale,
      idempotencyKey: payload.idempotencyKey,
    });
  }

  private async executeWithTimeout<T>(
    promise: Promise<T>,
    timeoutMs: number,
  ): Promise<T> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      return await Promise.race([
        promise,
        new Promise<never>((_, reject) => {
          timer = setTimeout(
            () =>
              reject(
                new Error(`Resend API request timed out after ${timeoutMs}ms`),
              ),
            timeoutMs,
          );
          timer.unref?.();
        }),
      ]);
    } finally {
      if (timer) clearTimeout(timer);
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => {
      const timer = setTimeout(resolve, ms);
      timer.unref?.();
    });
  }
}
