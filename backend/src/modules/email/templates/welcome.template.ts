import { EmailLocale, RenderedEmailTemplate } from '../email.types';
import { escapeHtml, renderEmailLayout } from './email-layout.template';

export function renderWelcomeTemplate(params: {
  displayName: string;
  locale: EmailLocale;
  appUrl: string;
}): RenderedEmailTemplate {
  const safeName = escapeHtml(params.displayName);

  if (params.locale === 'en') {
    const subject = 'Welcome to Deal One';
    const bodyHtml = `
      <p style="margin: 0 0 12px 0;">Hello ${safeName},</p>
      <p style="margin: 0 0 12px 0;">Welcome to <strong>Deal One</strong>! Your account is now ready so you can browse listings, publish ads, and connect with buyers and sellers across Egypt.</p>
      <p style="margin: 0;">If you ever need assistance, our team is here to help.</p>
    `;
    return {
      subject,
      html: renderEmailLayout({
        locale: 'en',
        previewText: 'Welcome to Deal One — your marketplace account is ready.',
        heading: 'Welcome to Deal One',
        bodyHtml,
        ctaLabel: 'Open Deal One',
        ctaUrl: params.appUrl,
      }),
      text: `Hello ${params.displayName},\n\nWelcome to Deal One! Your account is now ready so you can browse listings, publish ads, and connect with buyers and sellers across Egypt.\n\nOpen Deal One: ${params.appUrl}`,
    };
  }

  const subject = 'أهلًا بك في صفقة ون (Deal One)';
  const bodyHtml = `
    <p style="margin: 0 0 12px 0;">مرحبًا ${safeName}،</p>
    <p style="margin: 0 0 12px 0;">أهلًا بك في <strong>صفقة ون (Deal One)</strong>! حسابك جاهز الآن لتصفح الإعلانات، نشر عروضك، والتواصل بسهولة مع المشترين والبائعين في جميع أنحاء مصر.</p>
    <p style="margin: 0;">يسعدنا دائمًا دعمك في أي وقت.</p>
  `;
  return {
    subject,
    html: renderEmailLayout({
      locale: 'ar',
      previewText: 'أهلًا بك في صفقة ون — حسابك جاهز الآن.',
      heading: 'أهلًا بك في صفقة ون',
      bodyHtml,
      ctaLabel: 'افتح صفقة ون',
      ctaUrl: params.appUrl,
    }),
    text: `مرحبًا ${params.displayName}،\n\nأهلًا بك في صفقة ون (Deal One)! حسابك جاهز الآن لتصفح الإعلانات ونشر عروضك والتواصل مع المشترين والبائعين في مصر.\n\nافتح صفقة ون: ${params.appUrl}`,
  };
}
