export type EmailLocale = 'ar' | 'en';

export type EmailReadinessStatus = 'configured' | 'unconfigured';

export type EmailTemplateKey =
  | 'welcome'
  | 'email-verification'
  | 'email-verified'
  | 'listing-approved'
  | 'listing-rejected'
  | 'security-notification'
  | 'payment-receipt';

export interface RenderedEmailTemplate {
  subject: string;
  html: string;
  text: string;
}

export interface SendEmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  text: string;
  template: EmailTemplateKey;
  locale?: EmailLocale;
  idempotencyKey?: string;
  replyTo?: string;
  tags?: Array<{ name: string; value: string }>;
}

export interface SendEmailResult {
  success: boolean;
  messageId?: string;
  skipped?: boolean;
  reason?: string;
  error?: string;
  attempts?: number;
}

export interface WelcomeEmailPayload {
  to: string;
  displayName: string;
  locale?: EmailLocale;
  idempotencyKey?: string;
}

export interface EmailVerificationPayload {
  to: string;
  displayName: string;
  verificationUrl: string;
  expiresInMinutes: number;
  locale?: EmailLocale;
  idempotencyKey?: string;
}

export interface EmailVerifiedPayload {
  to: string;
  displayName: string;
  locale?: EmailLocale;
  idempotencyKey?: string;
}

export interface ListingApprovedEmailPayload {
  to: string;
  displayName: string;
  listingTitle: string;
  listingUrl?: string;
  locale?: EmailLocale;
  idempotencyKey?: string;
}

export interface ListingRejectedEmailPayload {
  to: string;
  displayName: string;
  listingTitle: string;
  reasonCode?: string | null;
  reasonNotes?: string | null;
  listingUrl?: string;
  locale?: EmailLocale;
  idempotencyKey?: string;
}

export type SecurityEventKind =
  | 'PASSWORD_CHANGED'
  | 'PASSWORD_RESET'
  | 'ALL_SESSIONS_TERMINATED'
  | 'EMAIL_CHANGED';

export interface SecurityNotificationEmailPayload {
  to: string;
  displayName: string;
  eventKind: SecurityEventKind;
  occurredAt?: Date;
  ipAddress?: string;
  locale?: EmailLocale;
  idempotencyKey?: string;
}

export interface PaymentReceiptEmailPayload {
  to: string;
  displayName: string;
  amountEgp: string | number;
  currency?: string;
  packageName?: string;
  listingTitle?: string;
  transactionReference?: string;
  paidAt?: Date;
  locale?: EmailLocale;
  idempotencyKey?: string;
}
