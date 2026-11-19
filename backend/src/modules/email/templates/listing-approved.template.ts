import { EmailLocale, RenderedEmailTemplate } from '../email.types';
import { escapeHtml, renderEmailLayout } from './email-layout.template';

export function renderListingApprovedTemplate(params: {
  displayName: string;
  listingTitle: string;
  listingUrl?: string;
  locale: EmailLocale;
}): RenderedEmailTemplate {
  const safeName = escapeHtml(params.displayName);
  const safeTitle = escapeHtml(params.listingTitle);

  if (params.locale === 'en') {
    return {
      subject: `Your listing is live: ${params.listingTitle}`,
      html: renderEmailLayout({
        locale: 'en',
        previewText: `Your listing "${params.listingTitle}" has been approved and published.`,
        heading: 'Your listing has been approved',
        bodyHtml: `
          <p style="margin: 0 0 12px 0;">Hello ${safeName},</p>
          <p style="margin: 0 0 12px 0;">Great news! Your listing <strong>${safeTitle}</strong> has passed moderation review and is now live on <strong>Deal One</strong>.</p>
          <p style="margin: 0;">Buyers can now discover your listing and contact you directly.</p>
        `,
        ctaLabel: params.listingUrl ? 'View Listing' : undefined,
        ctaUrl: params.listingUrl,
      }),
      text: `Hello ${params.displayName},\n\nGreat news! Your listing "${params.listingTitle}" has been approved and is now live on Deal One.${params.listingUrl ? `\n\nView listing: ${params.listingUrl}` : ''}`,
    };
  }

  return {
    subject: `تمت الموافقة على إعلانك: ${params.listingTitle}`,
    html: renderEmailLayout({
      locale: 'ar',
      previewText: `تمت الموافقة على إعلانك "${params.listingTitle}" ونشره على صفقة ون.`,
      heading: 'تمت الموافقة على إعلانك ونشره',
      bodyHtml: `
        <p style="margin: 0 0 12px 0;">مرحبًا ${safeName}،</p>
        <p style="margin: 0 0 12px 0;">خبر سار! تمت مراجعة إعلانك <strong>${safeTitle}</strong> والموافقة عليه، وأصبح منشورًا الآن على <strong>صفقة ون</strong>.</p>
        <p style="margin: 0;">يمكن للمشترين الآن مشاهدة إعلانك والتواصل معك مباشرة.</p>
      `,
      ctaLabel: params.listingUrl ? 'عرض الإعلان' : undefined,
      ctaUrl: params.listingUrl,
    }),
    text: `مرحبًا ${params.displayName}،\n\nتمت الموافقة على إعلانك "${params.listingTitle}" وأصبح منشورًا الآن على صفقة ون.${params.listingUrl ? `\n\nعرض الإعلان: ${params.listingUrl}` : ''}`,
  };
}
