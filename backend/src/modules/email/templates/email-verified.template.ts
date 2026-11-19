import { EmailLocale, RenderedEmailTemplate } from '../email.types';
import { escapeHtml, renderEmailLayout } from './email-layout.template';

export function renderEmailVerifiedTemplate(params: {
  displayName: string;
  locale: EmailLocale;
  appUrl: string;
}): RenderedEmailTemplate {
  const safeName = escapeHtml(params.displayName);

  if (params.locale === 'en') {
    return {
      subject: 'Your email address is verified — Deal One',
      html: renderEmailLayout({
        locale: 'en',
        previewText: 'Your Deal One email address has been verified.',
        heading: 'Email verified successfully',
        bodyHtml: `
          <p style="margin: 0 0 12px 0;">Hello ${safeName},</p>
          <p style="margin: 0 0 12px 0;">Your email address has been successfully verified on your <strong>Deal One</strong> account.</p>
          <p style="margin: 0;">You will now receive important account security alerts and listing updates at this address.</p>
        `,
        ctaLabel: 'Open Deal One',
        ctaUrl: params.appUrl,
      }),
      text: `Hello ${params.displayName},\n\nYour email address has been successfully verified on your Deal One account.\n\nOpen Deal One: ${params.appUrl}`,
    };
  }

  return {
    subject: 'تم تأكيد بريدك الإلكتروني بنجاح — صفقة ون',
    html: renderEmailLayout({
      locale: 'ar',
      previewText: 'تم تأكيد بريدك الإلكتروني في حسابك على صفقة ون.',
      heading: 'تم تأكيد البريد الإلكتروني بنجاح',
      bodyHtml: `
        <p style="margin: 0 0 12px 0;">مرحبًا ${safeName}،</p>
        <p style="margin: 0 0 12px 0;">تم تأكيد بريدك الإلكتروني بنجاح على حسابك في <strong>صفقة ون (Deal One)</strong>.</p>
        <p style="margin: 0;">ستتلقى الآن تنبيهات الأمان المهمة وتحديثات إعلاناتك على هذا البريد.</p>
      `,
      ctaLabel: 'افتح صفقة ون',
      ctaUrl: params.appUrl,
    }),
    text: `مرحبًا ${params.displayName}،\n\nتم تأكيد بريدك الإلكتروني بنجاح على حسابك في صفقة ون (Deal One).\n\nافتح صفقة ون: ${params.appUrl}`,
  };
}
