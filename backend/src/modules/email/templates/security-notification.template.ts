import {
  EmailLocale,
  RenderedEmailTemplate,
  SecurityEventKind,
} from '../email.types';
import { escapeHtml, renderEmailLayout } from './email-layout.template';

const EVENT_COPY: Record<
  SecurityEventKind,
  {
    en: { subject: string; heading: string; message: string };
    ar: { subject: string; heading: string; message: string };
  }
> = {
  PASSWORD_CHANGED: {
    en: {
      subject: 'Security alert: Your password was changed — Deal One',
      heading: 'Your password was changed',
      message:
        'Your Deal One account password was recently changed and all other active sessions were signed out.',
    },
    ar: {
      subject: 'تنبيه أمني: تم تغيير كلمة المرور — صفقة ون',
      heading: 'تم تغيير كلمة المرور الخاصة بك',
      message:
        'تم تغيير كلمة مرور حسابك على صفقة ون مؤخرًا، وتم تسجيل الخروج من جميع الجلسات الأخرى النشطة.',
    },
  },
  PASSWORD_RESET: {
    en: {
      subject: 'Security alert: Your password was reset — Deal One',
      heading: 'Your password was reset',
      message:
        'Your Deal One account password was recently reset and all active sessions have been revoked.',
    },
    ar: {
      subject: 'تنبيه أمني: تمت إعادة تعيين كلمة المرور — صفقة ون',
      heading: 'تمت إعادة تعيين كلمة المرور',
      message:
        'تمت إعادة تعيين كلمة مرور حسابك على صفقة ون مؤخرًا، وتم إنهاء جميع الجلسات النشطة.',
    },
  },
  ALL_SESSIONS_TERMINATED: {
    en: {
      subject: 'Security alert: All active sessions were signed out — Deal One',
      heading: 'All sessions signed out',
      message:
        'All active sessions on your Deal One account were terminated as requested.',
    },
    ar: {
      subject: 'تنبيه أمني: تم تسجيل الخروج من جميع الجلسات — صفقة ون',
      heading: 'تم تسجيل الخروج من جميع الأجهزة',
      message:
        'تم إنهاء جميع الجلسات النشطة على حسابك في صفقة ون بناءً على طلبك.',
    },
  },
  EMAIL_CHANGED: {
    en: {
      subject: 'Security alert: Your account email was updated — Deal One',
      heading: 'Your email address was updated',
      message:
        'The email address associated with your Deal One account was updated and verified.',
    },
    ar: {
      subject: 'تنبيه أمني: تم تحديث بريدك الإلكتروني — صفقة ون',
      heading: 'تم تحديث البريد الإلكتروني لحسابك',
      message:
        'تم تحديث وتأكيد عنوان البريد الإلكتروني المرتبط بحسابك على صفقة ون.',
    },
  },
};

export function renderSecurityNotificationTemplate(params: {
  displayName: string;
  eventKind: SecurityEventKind;
  occurredAt: Date;
  ipAddress?: string;
  locale: EmailLocale;
}): RenderedEmailTemplate {
  const safeName = escapeHtml(params.displayName);
  const copy = EVENT_COPY[params.eventKind][params.locale];
  const timestampStr = params.occurredAt.toISOString();
  const safeIp = params.ipAddress ? escapeHtml(params.ipAddress) : '';

  if (params.locale === 'en') {
    const ipRow = safeIp ? `<br/><strong>IP Address:</strong> ${safeIp}` : '';
    return {
      subject: copy.subject,
      html: renderEmailLayout({
        locale: 'en',
        previewText: copy.message,
        heading: copy.heading,
        bodyHtml: `
          <p style="margin: 0 0 12px 0;">Hello ${safeName},</p>
          <p style="margin: 0 0 12px 0;">${escapeHtml(copy.message)}</p>
          <div style="margin: 16px 0; padding: 12px 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 6px; font-size: 13px; color: #334155;">
            <strong>Time (UTC):</strong> ${escapeHtml(timestampStr)}${ipRow}
          </div>
          <p style="margin: 0;">If you did not perform this action, please reset your password immediately and contact Deal One support.</p>
        `,
      }),
      text: `Hello ${params.displayName},\n\n${copy.message}\n\nTime (UTC): ${timestampStr}${params.ipAddress ? `\nIP Address: ${params.ipAddress}` : ''}\n\nIf you did not perform this action, please reset your password immediately and contact Deal One support.`,
    };
  }

  const ipRowAr = safeIp ? `<br/><strong>عنوان IP:</strong> ${safeIp}` : '';
  return {
    subject: copy.subject,
    html: renderEmailLayout({
      locale: 'ar',
      previewText: copy.message,
      heading: copy.heading,
      bodyHtml: `
        <p style="margin: 0 0 12px 0;">مرحبًا ${safeName}،</p>
        <p style="margin: 0 0 12px 0;">${escapeHtml(copy.message)}</p>
        <div style="margin: 16px 0; padding: 12px 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 6px; font-size: 13px; color: #334155;">
          <strong>الوقت (UTC):</strong> ${escapeHtml(timestampStr)}${ipRowAr}
        </div>
        <p style="margin: 0;">إذا لم تقم بهذا الإجراء، يُرجى إعادة تعيين كلمة المرور فورًا والتواصل مع دعم صفقة ون.</p>
      `,
    }),
    text: `مرحبًا ${params.displayName}،\n\n${copy.message}\n\nالوقت (UTC): ${timestampStr}${params.ipAddress ? `\nعنوان IP: ${params.ipAddress}` : ''}\n\nإذا لم تقم بهذا الإجراء، يُرجى إعادة تعيين كلمة المرور فورًا والتواصل مع دعم صفقة ون.`,
  };
}
