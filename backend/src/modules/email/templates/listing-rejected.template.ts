import { EmailLocale, RenderedEmailTemplate } from '../email.types';
import { escapeHtml, renderEmailLayout } from './email-layout.template';

export function renderListingRejectedTemplate(params: {
  displayName: string;
  listingTitle: string;
  reasonCode?: string | null;
  reasonNotes?: string | null;
  listingUrl?: string;
  locale: EmailLocale;
}): RenderedEmailTemplate {
  const safeName = escapeHtml(params.displayName);
  const safeTitle = escapeHtml(params.listingTitle);
  const reasonParts = [params.reasonCode, params.reasonNotes]
    .map((p) => (p ?? '').trim())
    .filter(Boolean);
  const combinedReason = reasonParts.join(' — ');
  const safeReason = escapeHtml(combinedReason);

  if (params.locale === 'en') {
    const reasonBlock = safeReason
      ? `<div style="margin: 16px 0; padding: 14px 16px; background-color: #FEF2F2; border-left: 4px solid #DC2626; border-radius: 6px; color: #7F1D1D;"><strong>Reason:</strong> ${safeReason}</div>`
      : '';
    return {
      subject: `Action required on your listing: ${params.listingTitle}`,
      html: renderEmailLayout({
        locale: 'en',
        previewText: `Your listing "${params.listingTitle}" was not approved.`,
        heading: 'Your listing was not approved',
        bodyHtml: `
          <p style="margin: 0 0 12px 0;">Hello ${safeName},</p>
          <p style="margin: 0 0 12px 0;">Your listing <strong>${safeTitle}</strong> could not be published after moderation review.</p>
          ${reasonBlock}
          <p style="margin: 0;">You can update your listing details to comply with Deal One marketplace guidelines and resubmit it for review.</p>
        `,
        ctaLabel: params.listingUrl ? 'Edit Listing' : undefined,
        ctaUrl: params.listingUrl,
      }),
      text: `Hello ${params.displayName},\n\nYour listing "${params.listingTitle}" could not be published after moderation review.${combinedReason ? `\n\nReason: ${combinedReason}` : ''}\n\nPlease update your listing and resubmit it for review.${params.listingUrl ? `\n\nEdit listing: ${params.listingUrl}` : ''}`,
    };
  }

  const reasonBlockAr = safeReason
    ? `<div style="margin: 16px 0; padding: 14px 16px; background-color: #FEF2F2; border-right: 4px solid #DC2626; border-radius: 6px; color: #7F1D1D;"><strong>سبب الرفض:</strong> ${safeReason}</div>`
    : '';
  return {
    subject: `تحديث بخصوص إعلانك: ${params.listingTitle}`,
    html: renderEmailLayout({
      locale: 'ar',
      previewText: `لم تتم الموافقة على إعلانك "${params.listingTitle}".`,
      heading: 'لم تتم الموافقة على إعلانك',
      bodyHtml: `
        <p style="margin: 0 0 12px 0;">مرحبًا ${safeName}،</p>
        <p style="margin: 0 0 12px 0;">تعذر نشر إعلانك <strong>${safeTitle}</strong> بعد المراجعة.</p>
        ${reasonBlockAr}
        <p style="margin: 0;">يمكنك تعديل بيانات الإعلان بما يتوافق مع سياسات صفقة ون وإعادة إرساله للمراجعة.</p>
      `,
      ctaLabel: params.listingUrl ? 'تعديل الإعلان' : undefined,
      ctaUrl: params.listingUrl,
    }),
    text: `مرحبًا ${params.displayName}،\n\nتعذر نشر إعلانك "${params.listingTitle}" بعد المراجعة.${combinedReason ? `\n\nسبب الرفض: ${combinedReason}` : ''}\n\nيمكنك تعديل الإعلان وإعادة إرساله للمراجعة.${params.listingUrl ? `\n\nتعديل الإعلان: ${params.listingUrl}` : ''}`,
  };
}
