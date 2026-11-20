import React from 'react';
import { useAuth } from './AuthContext';
import { useI18n } from '../i18n/I18nContext';
import { ShieldAlert } from 'lucide-react';

interface PermissionGateProps {
  permission?: string;
  anyOf?: string[];
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export function PermissionGate({
  permission,
  anyOf,
  children,
  fallback = null,
}: PermissionGateProps) {
  const { hasPermission, hasAnyPermission } = useAuth();

  let allowed = true;
  if (permission) {
    allowed = hasPermission(permission);
  } else if (anyOf && anyOf.length > 0) {
    allowed = hasAnyPermission(anyOf);
  }

  return allowed ? <>{children}</> : <>{fallback}</>;
}

export function PagePermissionGuard({
  permission,
  anyOf,
  children,
}: {
  permission?: string;
  anyOf?: string[];
  children: React.ReactNode;
}) {
  const { t } = useI18n();
  return (
    <PermissionGate
      permission={permission}
      anyOf={anyOf}
      fallback={
        <div className="flex flex-col items-center justify-center rounded-xl border bg-card p-12 text-center shadow-sm">
          <ShieldAlert className="mb-3 h-10 w-10 text-destructive" />
          <h3 className="text-lg font-semibold">403 — Access Restricted</h3>
          <p className="mt-1 text-sm text-muted-foreground">
            {t.common.noPermission}
          </p>
        </div>
      }
    >
      {children}
    </PermissionGate>
  );
}
