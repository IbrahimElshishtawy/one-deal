import React, { useState } from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import {
  AlertTriangle,
  Inbox,
  Loader2,
  RefreshCw,
  X,
} from 'lucide-react';
import { useI18n } from '../core/i18n/I18nContext';

export function cn(...inputs: Array<string | undefined | null | false>) {
  return twMerge(clsx(inputs));
}

export function Button({
  children,
  variant = 'primary',
  size = 'md',
  className,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'outline' | 'destructive' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}) {
  const variants = {
    primary: 'bg-primary text-primary-foreground hover:opacity-90',
    secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
    outline: 'border bg-card hover:bg-muted text-foreground',
    destructive: 'bg-destructive text-destructive-foreground hover:opacity-90',
    ghost: 'hover:bg-muted text-foreground',
  };
  const sizes = {
    sm: 'h-8 px-3 text-xs',
    md: 'h-9 px-4 text-sm',
    lg: 'h-11 px-6 text-base',
  };
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center gap-2 rounded-lg font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50',
        variants[variant],
        sizes[size],
        className,
      )}
      {...props}
    >
      {children}
    </button>
  );
}

export function Card({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        'rounded-xl border bg-card text-card-foreground shadow-sm',
        className,
      )}
    >
      {children}
    </div>
  );
}

export const Input = React.forwardRef<
  HTMLInputElement,
  React.InputHTMLAttributes<HTMLInputElement>
>(({ className, ...props }, ref) => (
  <input
    ref={ref}
    className={cn(
      'flex h-9 w-full rounded-lg border bg-background px-3 py-1 text-sm shadow-sm transition placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50',
      className,
    )}
    {...props}
  />
));
Input.displayName = 'Input';

export const Select = React.forwardRef<
  HTMLSelectElement,
  React.SelectHTMLAttributes<HTMLSelectElement>
>(({ className, children, ...props }, ref) => (
  <select
    ref={ref}
    className={cn(
      'flex h-9 w-full rounded-lg border bg-background px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
      className,
    )}
    {...props}
  >
    {children}
  </select>
));
Select.displayName = 'Select';

export const Textarea = React.forwardRef<
  HTMLTextAreaElement,
  React.TextareaHTMLAttributes<HTMLTextAreaElement>
>(({ className, ...props }, ref) => (
  <textarea
    ref={ref}
    className={cn(
      'flex min-h-[84px] w-full rounded-lg border bg-background px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
      className,
    )}
    {...props}
  />
));
Textarea.displayName = 'Textarea';

export function StatusBadge({ status }: { status: string }) {
  const normalized = (status || '').toLowerCase();
  const styles: Record<string, string> = {
    active: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    approved: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    published: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    resolved: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    sent: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    healthy: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    up: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    configured: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30',
    pending: 'bg-amber-500/15 text-amber-700 dark:text-amber-300 border-amber-500/30',
    pending_approval: 'bg-amber-500/15 text-amber-700 dark:text-amber-300 border-amber-500/30',
    open: 'bg-amber-500/15 text-amber-700 dark:text-amber-300 border-amber-500/30',
    draft: 'bg-slate-500/15 text-slate-700 dark:text-slate-300 border-slate-500/30',
    scheduled: 'bg-blue-500/15 text-blue-700 dark:text-blue-300 border-blue-500/30',
    hidden: 'bg-slate-500/15 text-slate-700 dark:text-slate-300 border-slate-500/30',
    unpublished: 'bg-slate-500/15 text-slate-700 dark:text-slate-300 border-slate-500/30',
    archived: 'bg-slate-500/15 text-slate-700 dark:text-slate-300 border-slate-500/30',
    suspended: 'bg-orange-500/15 text-orange-700 dark:text-orange-300 border-orange-500/30',
    escalated: 'bg-orange-500/15 text-orange-700 dark:text-orange-300 border-orange-500/30',
    resubmission: 'bg-orange-500/15 text-orange-700 dark:text-orange-300 border-orange-500/30',
    rejected: 'bg-rose-500/15 text-rose-700 dark:text-rose-300 border-rose-500/30',
    banned: 'bg-rose-500/15 text-rose-700 dark:text-rose-300 border-rose-500/30',
    disabled: 'bg-rose-500/15 text-rose-700 dark:text-rose-300 border-rose-500/30',
    dismissed: 'bg-slate-500/15 text-slate-700 dark:text-slate-300 border-slate-500/30',
    down: 'bg-rose-500/15 text-rose-700 dark:text-rose-300 border-rose-500/30',
    high: 'bg-rose-500/15 text-rose-700 dark:text-rose-300 border-rose-500/30',
    critical: 'bg-rose-500/20 text-rose-800 dark:text-rose-200 border-rose-500/40',
    medium: 'bg-amber-500/15 text-amber-700 dark:text-amber-300 border-amber-500/30',
    low: 'bg-blue-500/15 text-blue-700 dark:text-blue-300 border-blue-500/30',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold capitalize',
        styles[normalized] || 'bg-muted text-muted-foreground border-border',
      )}
    >
      {status}
    </span>
  );
}

export function StatCard({
  title,
  value,
  subtitle,
  icon,
}: {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: React.ReactNode;
}) {
  return (
    <Card className="p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-xs font-medium text-muted-foreground">{title}</p>
          <p className="mt-2 text-2xl font-bold tracking-tight">{value}</p>
          {subtitle && (
            <p className="mt-1 text-xs text-muted-foreground">{subtitle}</p>
          )}
        </div>
        {icon && (
          <div className="rounded-lg bg-primary/10 p-2.5 text-primary">
            {icon}
          </div>
        )}
      </div>
    </Card>
  );
}

export function LoadingState({ message }: { message?: string }) {
  const { t } = useI18n();
  return (
    <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
      <Loader2 className="mb-2 h-7 w-7 animate-spin text-primary" />
      <p className="text-sm">{message || t.common.loading}</p>
    </div>
  );
}

export function EmptyState({
  title,
  description,
}: {
  title?: string;
  description?: string;
}) {
  const { t } = useI18n();
  return (
    <div className="flex flex-col items-center justify-center rounded-xl border border-dashed py-12 text-center">
      <Inbox className="mb-2 h-9 w-9 text-muted-foreground/70" />
      <p className="text-sm font-medium">{title || t.common.emptyTitle}</p>
      <p className="mt-1 text-xs text-muted-foreground">
        {description || t.common.emptyDesc}
      </p>
    </div>
  );
}

export function ErrorState({
  message,
  onRetry,
}: {
  message?: string;
  onRetry?: () => void;
}) {
  const { t } = useI18n();
  return (
    <div className="flex flex-col items-center justify-center rounded-xl border border-destructive/30 bg-destructive/5 p-8 text-center">
      <AlertTriangle className="mb-2 h-8 w-8 text-destructive" />
      <p className="text-sm font-semibold">{t.common.errorTitle}</p>
      {message && (
        <p className="mt-1 text-xs text-muted-foreground">{message}</p>
      )}
      {onRetry && (
        <Button variant="outline" size="sm" className="mt-4" onClick={onRetry}>
          <RefreshCw className="h-3.5 w-3.5" />
          {t.common.retry}
        </Button>
      )}
    </div>
  );
}

export function Modal({
  open,
  onClose,
  title,
  children,
  maxWidth = 'max-w-2xl',
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  maxWidth?: string;
}) {
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/55 p-4 backdrop-blur-xs"
      role="dialog"
      aria-modal="true"
    >
      <div
        className={cn(
          'max-h-[90vh] w-full overflow-y-auto rounded-xl border bg-card p-6 shadow-xl',
          maxWidth,
        )}
      >
        <div className="mb-4 flex items-center justify-between border-b pb-3">
          <h3 className="text-lg font-semibold">{title}</h3>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md p-1 text-muted-foreground hover:bg-muted"
            aria-label="Close modal"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  requireReason = false,
  reasonLabel,
  destructive = false,
  loading = false,
}: {
  open: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => void;
  title: string;
  description: string;
  requireReason?: boolean;
  reasonLabel?: string;
  destructive?: boolean;
  loading?: boolean;
}) {
  const { t } = useI18n();
  const [reason, setReason] = useState('');
  const [error, setError] = useState('');

  if (!open) return null;

  const submit = () => {
    if (requireReason && reason.trim().length < 3) {
      setError(t.common.reasonRequired);
      return;
    }
    setError('');
    onConfirm(reason.trim());
    setReason('');
  };

  return (
    <Modal open={open} onClose={onClose} title={title} maxWidth="max-w-md">
      <p className="text-sm text-muted-foreground">{description}</p>
      {requireReason && (
        <div className="mt-4 space-y-1.5">
          <label className="text-xs font-medium">
            {reasonLabel || t.common.reason} *
          </label>
          <Textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder={reasonLabel || t.common.reason}
          />
          {error && <p className="text-xs text-destructive">{error}</p>}
        </div>
      )}
      <div className="mt-6 flex justify-end gap-2">
        <Button variant="outline" onClick={onClose} disabled={loading}>
          {t.common.cancel}
        </Button>
        <Button
          variant={destructive ? 'destructive' : 'primary'}
          onClick={submit}
          disabled={loading}
        >
          {loading && <Loader2 className="h-4 w-4 animate-spin" />}
          {t.common.confirm}
        </Button>
      </div>
    </Modal>
  );
}
