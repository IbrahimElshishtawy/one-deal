import React from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './core/auth/AuthContext';
import { PagePermissionGuard } from './core/auth/PermissionGate';
import { I18nProvider } from './core/i18n/I18nContext';
import { ThemeProvider } from './core/theme/ThemeContext';
import { AppShell } from './components/AppShell';
import { LoadingState } from './components/ui';
import { LoginPage } from './features/auth/LoginPage';
import { SecurityProfilePage } from './features/auth/SecurityProfilePage';
import { OverviewPage } from './features/overview/OverviewPage';
import { UsersPage } from './features/users/UsersPage';
import { ListingsPage } from './features/listings/ListingsPage';
import { CategoriesPage } from './features/categories/CategoriesPage';
import { ReportsPage } from './features/reports/ReportsPage';
import { VerificationPage } from './features/verification/VerificationPage';
import { MessagingOversightPage } from './features/messaging/MessagingOversightPage';
import { NotificationsPage } from './features/notifications/NotificationsPage';
import { CmsPage } from './features/cms/CmsPage';
import { AnalyticsPage } from './features/analytics/AnalyticsPage';
import { AdminAccountsPage } from './features/admins/AdminAccountsPage';
import { RolesPermissionsPage } from './features/roles/RolesPermissionsPage';
import { AuditLogsPage } from './features/audit-logs/AuditLogsPage';
import { SystemHealthPage } from './features/system-health/SystemHealthPage';
import { FeatureFlagsPage } from './features/feature-flags/FeatureFlagsPage';
import { PlatformSettingsPage } from './features/settings/PlatformSettingsPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 15_000,
      refetchOnWindowFocus: false,
    },
  },
});

function ProtectedRoutes() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <LoadingState />
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  return (
    <Routes>
      <Route path="/login" element={<Navigate to="/" replace />} />
      <Route element={<AppShell />}>
        <Route
          path="/"
          element={
            <PagePermissionGuard permission="analytics.read">
              <OverviewPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/users"
          element={
            <PagePermissionGuard permission="users.read">
              <UsersPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/listings"
          element={
            <PagePermissionGuard permission="listings.read">
              <ListingsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/categories"
          element={
            <PagePermissionGuard permission="categories.read">
              <CategoriesPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/reports"
          element={
            <PagePermissionGuard permission="reports.read">
              <ReportsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/verification"
          element={
            <PagePermissionGuard permission="verification.read">
              <VerificationPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/messaging"
          element={
            <PagePermissionGuard permission="messaging.complaints.read">
              <MessagingOversightPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/notifications"
          element={
            <PagePermissionGuard permission="notifications.read">
              <NotificationsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/cms"
          element={
            <PagePermissionGuard permission="cms.read">
              <CmsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/analytics"
          element={
            <PagePermissionGuard permission="analytics.read">
              <AnalyticsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/admins"
          element={
            <PagePermissionGuard permission="admins.read">
              <AdminAccountsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/roles"
          element={
            <PagePermissionGuard permission="roles.read">
              <RolesPermissionsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/audit-logs"
          element={
            <PagePermissionGuard permission="audit_logs.read">
              <AuditLogsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/system-health"
          element={
            <PagePermissionGuard permission="system_health.read">
              <SystemHealthPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/feature-flags"
          element={
            <PagePermissionGuard permission="feature_flags.read">
              <FeatureFlagsPage />
            </PagePermissionGuard>
          }
        />
        <Route
          path="/settings"
          element={
            <PagePermissionGuard permission="settings.read">
              <PlatformSettingsPage />
            </PagePermissionGuard>
          }
        />
        <Route path="/security" element={<SecurityProfilePage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <I18nProvider>
          <AuthProvider>
            <BrowserRouter>
              <ProtectedRoutes />
            </BrowserRouter>
          </AuthProvider>
        </I18nProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
