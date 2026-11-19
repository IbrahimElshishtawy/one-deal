import { EmailLocale } from '../email.types';

/**
 * Escapes HTML special characters to prevent XSS / HTML injection in email clients
 * when interpolating any user-provided or database-sourced strings.
 */
export function escapeHtml(input: string | undefined | null): string {
  if (!input) return '';
  return String(input)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Normalizes any user language preference into a supported EmailLocale ('ar' | 'en').
 */
export function normalizeEmailLocale(language?: string | null): EmailLocale {
  if (typeof language === 'string' && language.toLowerCase().startsWith('en')) {
    return 'en';
  }
  return 'ar';
}

export interface EmailLayoutOptions {
  locale: EmailLocale;
  previewText: string;
  heading: string;
  bodyHtml: string;
  ctaLabel?: string;
  ctaUrl?: string;
  footerNote?: string;
}

/**
 * Renders a responsive, table-based, zero-external-dependency HTML email wrapper
 * with full Arabic RTL and English LTR support and accessible contrast.
 */
export function renderEmailLayout(options: EmailLayoutOptions): string {
  const isRtl = options.locale === 'ar';
  const dir = isRtl ? 'rtl' : 'ltr';
  const align = isRtl ? 'right' : 'left';
  const lang = isRtl ? 'ar' : 'en';
  const brandTitle = isRtl ? 'صفقة ون — Deal One' : 'Deal One';
  const defaultFooter = isRtl
    ? 'تم إرسال هذا البريد الإلكتروني تلقائيًا من منصة صفقة ون (Deal One). يُرجى عدم الرد إذا لم يكن هناك حاجة لذلك.'
    : 'This transactional email was sent automatically by Deal One. If you did not expect this message, please contact support.';

  const safePreview = escapeHtml(options.previewText);
  const safeHeading = escapeHtml(options.heading);
  const safeFooter = escapeHtml(options.footerNote || defaultFooter);

  const ctaSection =
    options.ctaLabel && options.ctaUrl
      ? `
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin: 24px 0 16px 0;">
          <tr>
            <td align="${align}" style="border-radius: 8px; background-color: #0F4C81;">
              <a href="${escapeHtml(options.ctaUrl)}" target="_blank" rel="noopener noreferrer"
                 style="display: inline-block; padding: 14px 28px; font-size: 16px; font-weight: 700; color: #FFFFFF; text-decoration: none; border-radius: 8px;">
                ${escapeHtml(options.ctaLabel)}
              </a>
            </td>
          </tr>
        </table>
      `
      : '';

  return `<!DOCTYPE html>
<html lang="${lang}" dir="${dir}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${safeHeading}</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F4F6F9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Tahoma, Arial, sans-serif; color: #1E293B; direction: ${dir};">
  <div style="display: none; max-height: 0; overflow: hidden; opacity: 0; mso-hide: all;">
    ${safePreview}
  </div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #F4F6F9; padding: 24px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 600px; background-color: #FFFFFF; border-radius: 12px; overflow: hidden; border: 1px solid #E2E8F0;">
          <tr>
            <td align="${align}" style="background-color: #0F4C81; padding: 24px 28px;">
              <span style="font-size: 20px; font-weight: 700; color: #FFFFFF; letter-spacing: 0.2px;">
                ${brandTitle}
              </span>
            </td>
          </tr>
          <tr>
            <td align="${align}" style="padding: 28px; text-align: ${align}; line-height: 1.7; font-size: 15px; color: #1E293B;">
              <h1 style="margin: 0 0 16px 0; font-size: 22px; font-weight: 700; color: #0F172A; line-height: 1.4;">
                ${safeHeading}
              </h1>
              ${options.bodyHtml}
              ${ctaSection}
            </td>
          </tr>
          <tr>
            <td align="${align}" style="padding: 18px 28px; background-color: #F8FAFC; border-top: 1px solid #E2E8F0; font-size: 12px; color: #64748B; line-height: 1.6; text-align: ${align};">
              ${safeFooter}
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}
