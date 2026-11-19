import { EmailLocale, RenderedEmailTemplate } from '../email.types';
import { escapeHtml, renderEmailLayout } from './email-layout.template';

export function renderEmailVerificationTemplate(params: {
  displayName: string;
  verificationUrl: string;
  expiresInMinutes: number;
  locale: EmailLocale;
}): RenderedEmailTemplate {
  const safeName = escapeHtml(params.displayName);
  const safeUrl = escapeHtml(params.verificationUrl);

  if (params.locale === 'en') {
    const subject = 'Verify your email address — Deal One';
    const bodyHtml = `
      <p style="margin: 0 0 12px 0;">Hello ${safeName},</p>
      <p style="margin: 0 0 12px 0;">Please confirm your email address for your <strong>Deal One</strong> account by clicking the button below.</p>
      <p style="margin: 0 0 12px 0;">This verification link is valid for <strong>${params.expiresInMinutes} minutes</strong> and can only be used once.</p>
      <p style="margin: 16px 0 0 0; font-size: 13px; color: #475569;">If the button does not work, copy and paste this link into your browser:<br/><span style="word-break: break-all; color: #0F4C81;">${safeUrl}</span></p>
    `;
    return {
      subject,
      html: renderEmailLayout({
        locale: 'en',
        previewText:
          'Confirm your email address to secure your Deal One account.',
        heading: 'Verify your email address',
        bodyHtml,
        ctaLabel: 'Verify Email',
        ctaUrl: params.verificationUrl,
        footerNote:
          'If you did not request this verification email, you can safely ignore it.',
      }),
      text: `Hello ${params.displayName},\n\nPlease confirm your email address for your Deal One account using the link below (valid for ${params.expiresInMinutes} minutes, single-use):\n\n${params.verificationUrl}\n\nIf you did not request this email, you can safely ignore it.`,
    };
  }

  const subject = 'تأكيد بريدك الإلكتروني — صفقة ون';
  const bodyHtml = `
    <p style="margin: 0 0 12px 0;">مرحبًا ${safeName}،</p>
    <p style="margin: 0 0 12px 0;">يُرجى تأكيد بريدك الإلكتروني لحسابك في <strong>صفقة ون (Deal One)</strong> بالضغط على الزر أدناه.</p>
    <p style="margin: 0 0 12px 0;">هذا الرابط صالح لمدة <strong>${params.expiresInMinutes} دقيقة</strong> ويُستخدم لمرة واحدة فقط.</p>
    <p style="margin: 16px 0 0 0; font-size: 13px; color: #475569;">إذا لم يعمل الزر، يمكنك نسخ الرابط التالي ولصقه في المتصفح:<br/><span style="word-break: break-all; color: #0F4C81;">${safeUrl}</span></p>
  `;
  return {
    subject,
    html: renderEmailLayout({
      locale: 'ar',
      previewText: 'أكد بريدك الإلكتروني لتأمين حسابك في صفقة ون.',
      heading: 'تأكيد بريدك الإلكتروني',
      bodyHtml,
      ctaLabel: 'تأكيد البريد الإلكتروني',
      ctaUrl: params.verificationUrl,
      footerNote:
        'إذا لم تطلب تأكيد بريدك الإلكتروني، يمكنك تجاهل هذه الرسالة بأمان.',
    }),
    text: `مرحبًا ${params.displayName}،\n\nيُرجى تأكيد بريدك الإلكتروني لحسابك في صفقة ون عبر الرابط التالي (صالح لمدة ${params.expiresInMinutes} دقيقة وللاستخدام مرة واحدة):\n\n${params.verificationUrl}\n\nإذا لم تطلب هذه الرسالة، يمكنك تجاهلها بأمان.`,
  };
}
