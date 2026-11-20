import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Globe, KeyRound, Lock, Moon, ShieldCheck, Sun } from 'lucide-react';
import { useAuth } from '../../core/auth/AuthContext';
import { useI18n } from '../../core/i18n/I18nContext';
import { useTheme } from '../../core/theme/ThemeContext';
import { apiClient, ApiClientError } from '../../core/api/client';
import { Button, Card, Input } from '../../components/ui';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

type LoginFormValues = z.infer<typeof loginSchema>;

export function LoginPage() {
  const { login, verifyMfa } = useAuth();
  const { t, toggleLocale } = useI18n();
  const { theme, toggleTheme } = useTheme();

  const [mode, setMode] = useState<'login' | 'mfa' | 'forgot' | 'reset'>('login');
  const [mfaChallengeToken, setMfaChallengeToken] = useState('');
  const [mfaCode, setMfaCode] = useState('');
  const [forgotEmail, setForgotEmail] = useState('');
  const [resetToken, setResetToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [infoMsg, setInfoMsg] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
  });

  const onLoginSubmit = async (values: LoginFormValues) => {
    setErrorMsg(null);
    setInfoMsg(null);
    setSubmitting(true);
    try {
      const res = await login(values.email, values.password);
      if (res.requiresMfa && res.mfaChallengeToken) {
        setMfaChallengeToken(res.mfaChallengeToken);
        setMode('mfa');
      }
    } catch (err) {
      setErrorMsg(
        err instanceof ApiClientError ? err.message : 'Authentication failed',
      );
    } finally {
      setSubmitting(false);
    }
  };

  const onMfaSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSubmitting(true);
    try {
      await verifyMfa(mfaChallengeToken, mfaCode);
    } catch (err) {
      setErrorMsg(
        err instanceof ApiClientError ? err.message : 'Invalid MFA code',
      );
    } finally {
      setSubmitting(false);
    }
  };

  const onForgotSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setInfoMsg(null);
    setSubmitting(true);
    try {
      const res = await apiClient.post<{ message: string }>(
        '/admin/auth/password/forgot',
        { email: forgotEmail },
        { skipAuth: true },
      );
      setInfoMsg(res.message);
      setMode('reset');
    } catch (err) {
      setErrorMsg(
        err instanceof ApiClientError ? err.message : 'Request failed',
      );
    } finally {
      setSubmitting(false);
    }
  };

  const onResetSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setInfoMsg(null);
    setSubmitting(true);
    try {
      await apiClient.post(
        '/admin/auth/password/reset',
        { token: resetToken, newPassword },
        { skipAuth: true },
      );
      setInfoMsg('Password updated. You may now sign in.');
      setMode('login');
    } catch (err) {
      setErrorMsg(
        err instanceof ApiClientError ? err.message : 'Reset failed',
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-muted/30 p-4">
      <div className="mb-4 flex items-center gap-2">
        <Button variant="outline" size="sm" onClick={toggleLocale}>
          <Globe className="h-4 w-4" />
          {t.common.language}
        </Button>
        <Button variant="outline" size="sm" onClick={toggleTheme}>
          {theme === 'dark' ? (
            <Sun className="h-4 w-4" />
          ) : (
            <Moon className="h-4 w-4" />
          )}
        </Button>
      </div>

      <Card className="w-full max-w-md p-6 sm:p-8">
        <div className="mb-6 flex flex-col items-center text-center">
          <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-primary text-lg font-bold text-primary-foreground shadow">
            {mode === 'mfa' ? <ShieldCheck className="h-6 w-6" /> : <Lock className="h-6 w-6" />}
          </div>
          <h1 className="text-xl font-bold">
            {mode === 'mfa'
              ? t.auth.mfaTitle
              : mode === 'forgot' || mode === 'reset'
                ? t.auth.resetTitle
                : t.auth.title}
          </h1>
          <p className="mt-1 text-xs text-muted-foreground">
            {mode === 'mfa' ? t.auth.mfaSubtitle : t.auth.subtitle}
          </p>
        </div>

        {errorMsg && (
          <div className="mb-4 rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-xs text-destructive">
            {errorMsg}
          </div>
        )}
        {infoMsg && (
          <div className="mb-4 rounded-lg border border-emerald-500/40 bg-emerald-500/10 p-3 text-xs text-emerald-700 dark:text-emerald-300">
            {infoMsg}
          </div>
        )}

        {mode === 'login' && (
          <form onSubmit={handleSubmit(onLoginSubmit)} className="space-y-4">
            <div>
              <label htmlFor="login-email" className="mb-1.5 block text-xs font-medium">
                {t.auth.email}
              </label>
              <Input
                id="login-email"
                type="email"
                autoComplete="email"
                placeholder="superadmin@dealone.eg"
                {...register('email')}
              />
              {errors.email && (
                <p className="mt-1 text-xs text-destructive">
                  {errors.email.message}
                </p>
              )}
            </div>

            <div>
              <label htmlFor="login-password" className="mb-1.5 block text-xs font-medium">
                {t.auth.password}
              </label>
              <Input
                id="login-password"
                type="password"
                autoComplete="current-password"
                {...register('password')}
              />
              {errors.password && (
                <p className="mt-1 text-xs text-destructive">
                  {errors.password.message}
                </p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={submitting}>
              {t.auth.signIn}
            </Button>

            <div className="text-center">
              <button
                type="button"
                onClick={() => {
                  setErrorMsg(null);
                  setMode('forgot');
                }}
                className="text-xs text-primary hover:underline"
              >
                {t.auth.forgotPassword}
              </button>
            </div>
          </form>
        )}

        {mode === 'mfa' && (
          <form onSubmit={onMfaSubmit} className="space-y-4">
            <div>
              <label className="mb-1.5 block text-xs font-medium">
                {t.auth.mfaCode}
              </label>
              <Input
                value={mfaCode}
                onChange={(e) => setMfaCode(e.target.value)}
                placeholder="123456 or ABCD-EF12"
                required
              />
            </div>
            <Button type="submit" className="w-full" disabled={submitting}>
              {t.auth.verifyMfa}
            </Button>
            <Button
              type="button"
              variant="ghost"
              className="w-full"
              onClick={() => setMode('login')}
            >
              {t.auth.backToLogin}
            </Button>
          </form>
        )}

        {mode === 'forgot' && (
          <form onSubmit={onForgotSubmit} className="space-y-4">
            <div>
              <label className="mb-1.5 block text-xs font-medium">
                {t.auth.email}
              </label>
              <Input
                type="email"
                value={forgotEmail}
                onChange={(e) => setForgotEmail(e.target.value)}
                required
              />
            </div>
            <Button type="submit" className="w-full" disabled={submitting}>
              <KeyRound className="h-4 w-4" />
              {t.auth.sendReset}
            </Button>
            <Button
              type="button"
              variant="ghost"
              className="w-full"
              onClick={() => setMode('login')}
            >
              {t.auth.backToLogin}
            </Button>
          </form>
        )}

        {mode === 'reset' && (
          <form onSubmit={onResetSubmit} className="space-y-4">
            <div>
              <label className="mb-1.5 block text-xs font-medium">
                {t.auth.resetToken}
              </label>
              <Input
                value={resetToken}
                onChange={(e) => setResetToken(e.target.value)}
                required
              />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-medium">
                {t.auth.newPassword}
              </label>
              <Input
                type="password"
                minLength={8}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
              />
            </div>
            <Button type="submit" className="w-full" disabled={submitting}>
              {t.auth.completeReset}
            </Button>
            <Button
              type="button"
              variant="ghost"
              className="w-full"
              onClick={() => setMode('login')}
            >
              {t.auth.backToLogin}
            </Button>
          </form>
        )}
      </Card>
    </div>
  );
}
