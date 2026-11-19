import { EmailLocale, RenderedEmailTemplate } from '../email.types';
import { escapeHtml, renderEmailLayout } from './email-layout.template';

export function renderPaymentReceiptTemplate(params: {
  displayName: string;
  amountEgp: string | number;
  currency: string;
  packageName?: string;
  listingTitle?: string;
  transactionReference?: string;
  paidAt: Date;
  locale: EmailLocale;
}): RenderedEmailTemplate {
  const safeName = escapeHtml(params.displayName);
  const safeAmount = escapeHtml(String(params.amountEgp));
  const safeCurrency = escapeHtml(params.currency);
  const safePackage = escapeHtml(params.packageName || '');
  const safeListing = escapeHtml(params.listingTitle || '');
  const safeRef = escapeHtml(params.transactionReference || '');
  const paidAtStr = escapeHtml(params.paidAt.toISOString());

  if (params.locale === 'en') {
    return {
      subject: `Payment receipt (${params.amountEgp} ${params.currency}) — Deal One`,
      html: renderEmailLayout({
        locale: 'en',
        previewText: `Your payment of ${params.amountEgp} ${params.currency} on Deal One was successful.`,
        heading: 'Payment receipt',
        bodyHtml: `
          <p style="margin: 0 0 12px 0;">Hello ${safeName},</p>
          <p style="margin: 0 0 12px 0;">Thank you for your payment on <strong>Deal One</strong>. Your promotion has been activated.</p>
          <div style="margin: 16px 0; padding: 14px 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 6px; font-size: 14px; color: #1E293B;">
            <strong>Amount:</strong> ${safeAmount} ${safeCurrency}<br/>
            ${safePackage ? `<strong>Package:</strong> ${safePackage}<br/>` : ''}
            ${safeListing ? `<strong>Listing:</strong> ${safeListing}<br/>` : ''}
            ${safeRef ? `<strong>Reference:</strong> ${safeRef}<br/>` : ''}
            <strong>Date (UTC):</strong> ${paidAtStr}
          </div>
        `,
      }),
      text: `Hello ${params.displayName},\n\nThank you for your payment on Deal One.\nAmount: ${params.amountEgp} ${params.currency}${params.packageName ? `\nPackage: ${params.packageName}` : ''}${params.listingTitle ? `\nListing: ${params.listingTitle}` : ''}${params.transactionReference ? `\nReference: ${params.transactionReference}` : ''}\nDate (UTC): ${params.paidAt.toISOString()}`,
    };
  }

  return {
    subject: `إيصال الدفع (${params.amountEgp} ${params.currency}) — صفقة ون`,
    html: renderEmailLayout({
      locale: 'ar',
      previewText: `تمت عملية الدفع بمبلغ ${params.amountEgp} ${params.currency} بنجاح على صفقة ون.`,
      heading: 'إيصال الدفع',
      bodyHtml: `
        <p style="margin: 0 0 12px 0;">مرحبًا ${safeName}،</p>
        <p style="margin: 0 0 12px 0;">شكرًا لك على الدفع عبر <strong>صفقة ون</strong>. تم تفعيل الترويج بنجاح.</p>
        <div style="margin: 16px 0; padding: 14px 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 6px; font-size: 14px; color: #1E293B;">
          <strong>المبلغ:</strong> ${safeAmount} ${safeCurrency}<br/>
          ${safePackage ? `<strong>الباقة:</strong> ${safePackage}<br/>` : ''}
          ${safeListing ? `<strong>الإعلان:</strong> ${safeListing}<br/>` : ''}
          ${safeRef ? `<strong>المرجع:</strong> ${safeRef}<br/>` : ''}
          <strong>التاريخ (UTC):</strong> ${paidAtStr}
        </div>
      `,
    }),
    text: `مرحبًا ${params.displayName}،\n\nشكرًا لك على الدفع عبر صفقة ون.\nالمبلغ: ${params.amountEgp} ${params.currency}${params.packageName ? `\nالباقة: ${params.packageName}` : ''}${params.listingTitle ? `\nالإعلان: ${params.listingTitle}` : ''}${params.transactionReference ? `\nالمرجع: ${params.transactionReference}` : ''}\nالتاريخ (UTC): ${params.paidAt.toISOString()}`,
  };
}
