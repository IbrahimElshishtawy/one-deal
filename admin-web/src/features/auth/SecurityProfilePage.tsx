import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Key, ShieldCheck, Trash2 } from 'lucide-react';
import { apiClient, ApiClientError } from '../../core/api/client';
import { useAuth } from '../../core/auth/AuthContext';
import { useI18n } from '../../core/i18n/I18nContext';
import {
  Button,
  Card,
  Input,
  LoadingState,
  StatusBadge,
} from '../../components/ui';

interface StaffSessionItem {
  id: string;
  ipAddress: string;
  userAgent: string | null;
  mfaVerified: boolean;
  createdAt: string;
  lastUsedAt: string;
  expiresAt: string;
  isCurrent: boolean;
}

export function SecurityProfilePage() {
  const { admin, refreshProfile } = useAuth();
  const { locale } = useI18n();
  const isAr = locale === 'ar';
  const qc = useQueryClient();

  const [mfaSetup, setMfaSetup] = useState<{
    secret: string;
    otpauthUrl: string;
  } | null>(null);
  const [totpCode, setTotpCode] = useState('');
  const [recoveryCodes, setRecoveryCodes] = useState<string[] | null>(null);
  const [disablePassword, setDisablePassword] = useState('');
  const [disableCode, setDisableCode] = useState('');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [feedback, setFeedback] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const sessionsQuery = useQuery({
    queryKey: ['admin-auth-sessions'],
    queryFn: ({ signal }) =>
      apiClient.get<StaffSessionItem[]>('/admin/auth/sessions', undefined, {
        signal,
      }),
  });

  const revokeMutation = useMutation({
    mutationFn: (sessionId: string) =>
      apiClient.delete(`/admin/auth/sessions/${sessionId}`),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['admin-auth-sessions'] });
    },
  });

  const startMfaSetup = async () => {
    setError(null);
    setFeedback(null);
    try {
      const res = await apiClient.post<{ secret: string; otpauthUrl: string }>(
        '/admin/auth/mfa/setup',
      );
      setMfaSetup(res);
    } catch (err) {
      setError(
        err instanceof ApiClientError
          ? err.message
          : isAr
            ? 'فشل إعداد التحقق الثنائي'
            : 'MFA setup failed',
      );
    }
  };

  const confirmEnableMfa = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      const res = await apiClient.post<{
        mfaEnabled: boolean;
        recoveryCodes: string[];
      }>('/admin/auth/mfa/enable', { code: totpCode });
      setRecoveryCodes(res.recoveryCodes);
      setMfaSetup(null);
      setTotpCode('');
      await refreshProfile();
      setFeedback(
        isAr
          ? 'تم تفعيل التحقق الثنائي. احتفظ برموز الاسترداد في مكان آمن.'
          : 'MFA enabled. Store your recovery codes safely.',
      );
    } catch (err) {
      setError(
        err instanceof ApiClientError
          ? err.message
          : isAr
            ? 'رمز غير صحيح'
            : 'Invalid code',
      );
    }
  };

  const handleDisableMfa = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      await apiClient.post('/admin/auth/mfa/disable', {
        currentPassword: disablePassword,
        code: disableCode,
      });
      setDisablePassword('');
      setDisableCode('');
      await refreshProfile();
      setFeedback(
        isAr ? 'تم تعطيل التحقق الثنائي.' : 'MFA has been disabled.',
      );
    } catch (err) {
      setError(
        err instanceof ApiClientError
          ? err.message
          : isAr
            ? 'تعذر تعطيل التحقق الثنائي'
            : 'Failed to disable MFA',
      );
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      const res = await apiClient.post<{ revokedSessionsCount: number }>(
        '/admin/auth/password/change',
        { currentPassword, newPassword },
      );
      setCurrentPassword('');
      setNewPassword('');
      setFeedback(
        isAr
          ? `تم تحديث كلمة المرور وإبطال ${res.revokedSessionsCount} جلسة أخرى.`
          : `Password updated. ${res.revokedSessionsCount} other session(s) revoked.`,
      );
      void qc.invalidateQueries({ queryKey: ['admin-auth-sessions'] });
    } catch (err) {
      setError(
        err instanceof ApiClientError
          ? err.message
          : isAr
            ? 'فشل تغيير كلمة المرور'
            : 'Password change failed',
      );
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">
          {isAr
            ? 'أمان الحساب والجلسات النشطة'
            : 'Account Security & Active Sessions'}
        </h2>
        <p className="text-sm text-muted-foreground">
          {admin?.fullName} • {admin?.email} •{' '}
          {isAr ? 'الدور:' : 'Role:'} <strong>{admin?.role.name}</strong>
        </p>
      </div>

      {error && (
        <div className="rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">
          {error}
        </div>
      )}
      {feedback && (
        <div className="rounded-lg border border-emerald-500/40 bg-emerald-500/10 p-3 text-sm text-emerald-700 dark:text-emerald-300">
          {feedback}
        </div>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="space-y-4 p-5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ShieldCheck className="h-5 w-5 text-primary" />
              <h3 className="font-semibold">
                {isAr
                  ? 'التحقق الثنائي (TOTP)'
                  : 'Two-Factor Authentication (TOTP)'}
              </h3>
            </div>
            <StatusBadge status={admin?.mfaEnabled ? 'active' : 'inactive'} />
          </div>

          {!admin?.mfaEnabled && !mfaSetup && (
            <Button onClick={startMfaSetup}>
              {isAr ? 'تفعيل تطبيق المصادقة TOTP' : 'Enroll TOTP Authenticator'}
            </Button>
          )}

          {mfaSetup && (
            <form
              onSubmit={confirmEnableMfa}
              className="space-y-3 rounded-lg border bg-muted/30 p-4"
            >
              <p className="text-xs text-muted-foreground">
                {isAr
                  ? 'أضف مفتاح Base32 التالي إلى Google Authenticator أو 1Password:'
                  : 'Add this Base32 secret to Google Authenticator / 1Password:'}
              </p>
              <code className="block break-all rounded bg-card p-2 font-mono text-xs">
                {mfaSetup.secret}
              </code>
              <p className="break-all text-[11px] text-muted-foreground">
                URI: {mfaSetup.otpauthUrl}
              </p>
              <div className="flex gap-2">
                <Input
                  id="totp-enable-code"
                  name="totpCode"
                  autoComplete="one-time-code"
                  value={totpCode}
                  onChange={(e) => setTotpCode(e.target.value)}
                  placeholder={
                    isAr ? 'أدخل الرمز المكون من 6 أرقام' : 'Enter 6-digit TOTP code'
                  }
                  required
                />
                <Button type="submit">
                  {isAr ? 'تفعيل MFA' : 'Enable MFA'}
                </Button>
              </div>
            </form>
          )}

          {recoveryCodes && (
            <div className="space-y-2 rounded-lg border border-amber-500/40 bg-amber-500/10 p-4">
              <p className="text-xs font-semibold">
                {isAr
                  ? 'رموز الاسترداد لمرة واحدة (تظهر مرة واحدة فقط):'
                  : 'One-Time Recovery Codes (shown once):'}
              </p>
              <div className="grid grid-cols-2 gap-1 font-mono text-xs">
                {recoveryCodes.map((c) => (
                  <span key={c} className="rounded bg-card px-2 py-1">
                    {c}
                  </span>
                ))}
              </div>
            </div>
          )}

          {admin?.mfaEnabled && (
            <form
              onSubmit={handleDisableMfa}
              className="space-y-2 border-t pt-2"
            >
              <p className="text-xs font-medium text-muted-foreground">
                {isAr
                  ? 'تعطيل التحقق الثنائي (يتطلب كلمة المرور الحالية ورمز TOTP)'
                  : 'Disable MFA (requires current password + TOTP code)'}
              </p>
              <div className="grid gap-2 sm:grid-cols-2">
                <Input
                  id="mfa-disable-password"
                  type="password"
                  autoComplete="current-password"
                  placeholder={isAr ? 'كلمة المرور الحالية' : 'Current password'}
                  value={disablePassword}
                  onChange={(e) => setDisablePassword(e.target.value)}
                  required
                />
                <Input
                  id="mfa-disable-code"
                  autoComplete="one-time-code"
                  placeholder={isAr ? 'رمز من 6 أرقام' : '6-digit code'}
                  value={disableCode}
                  onChange={(e) => setDisableCode(e.target.value)}
                  required
                />
              </div>
              <Button type="submit" variant="destructive" size="sm">
                {isAr ? 'تعطيل MFA' : 'Disable MFA'}
              </Button>
            </form>
          )}
        </Card>

        <Card className="space-y-4 p-5">
          <div className="flex items-center gap-2">
            <Key className="h-5 w-5 text-primary" />
            <h3 className="font-semibold">
              {isAr ? 'تغيير كلمة المرور' : 'Change Password'}
            </h3>
          </div>
          <form onSubmit={handleChangePassword} className="space-y-3">
            <Input
              id="sec-current-password"
              type="password"
              autoComplete="current-password"
              placeholder={isAr ? 'كلمة المرور الحالية' : 'Current password'}
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              required
            />
            <Input
              id="sec-new-password"
              type="password"
              autoComplete="new-password"
              placeholder={
                isAr
                  ? 'كلمة المرور الجديدة (8 أحرف على الأقل)'
                  : 'New password (min 8 chars)'
              }
              minLength={8}
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
            />
            <Button type="submit">
              {isAr ? 'تحديث كلمة المرور' : 'Update Password'}
            </Button>
          </form>
        </Card>
      </div>

      <Card className="space-y-4 p-5">
        <h3 className="font-semibold">
          {isAr ? 'جلسات الإدارة النشطة' : 'Active Admin Sessions'}
        </h3>
        {sessionsQuery.isLoading ? (
          <LoadingState />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-b bg-muted/50 text-xs text-muted-foreground">
                <tr>
                  <th className="px-3 py-2 text-start">
                    {isAr ? 'عنوان IP' : 'IP Address'}
                  </th>
                  <th className="px-3 py-2 text-start">
                    {isAr ? 'الجهاز / المتصفح' : 'User Agent'}
                  </th>
                  <th className="px-3 py-2 text-start">MFA</th>
                  <th className="px-3 py-2 text-start">
                    {isAr ? 'آخر استخدام' : 'Last Used'}
                  </th>
                  <th className="px-3 py-2 text-start">
                    {isAr ? 'إجراء' : 'Action'}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {(sessionsQuery.data ?? []).map((s) => (
                  <tr key={s.id}>
                    <td className="px-3 py-2 font-mono text-xs">
                      {s.ipAddress}{' '}
                      {s.isCurrent && (isAr ? '(الحالية)' : '(Current)')}
                    </td>
                    <td className="max-w-xs truncate px-3 py-2 text-xs text-muted-foreground">
                      {s.userAgent || '-'}
                    </td>
                    <td className="px-3 py-2">
                      <StatusBadge
                        status={s.mfaVerified ? 'approved' : 'pending'}
                      />
                    </td>
                    <td className="px-3 py-2 text-xs">
                      {new Date(s.lastUsedAt).toLocaleString()}
                    </td>
                    <td className="px-3 py-2">
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={revokeMutation.isPending}
                        onClick={() => revokeMutation.mutate(s.id)}
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                        {isAr ? 'إبطال' : 'Revoke'}
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}

