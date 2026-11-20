import React, { useMemo, useState } from 'react';
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Activity,
  BarChart3,
  Bell,
  ChevronDown,
  FileText,
  Flag,
  FolderTree,
  Globe,
  LayoutDashboard,
  Lock,
  LogOut,
  Menu,
  MessageSquareWarning,
  Moon,
  Search,
  Settings,
  Shield,
  ShieldCheck,
  ShoppingBag,
  Sun,
  UserCog,
  Users,
  X,
} from 'lucide-react';
import { apiClient } from '../core/api/client';
import { useAuth } from '../core/auth/AuthContext';
import { useI18n } from '../core/i18n/I18nContext';
import { useTheme } from '../core/theme/ThemeContext';
import { Button, Input } from './ui';

interface NavItem {
  to: string;
  label: string;
  icon: React.ReactNode;
  permission?: string;
}

export function AppShell() {
  const { admin, hasPermission, logout } = useAuth();
  const { t, locale, toggleLocale } = useI18n();
  const { theme, toggleTheme } = useTheme();
  const location = useLocation();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [quickSearch, setQuickSearch] = useState('');
  const [notifOpen, setNotifOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);

  const alertsQuery = useQuery({
    queryKey: ['header-alerts-summary'],
    enabled: hasPermission('analytics.read'),
    staleTime: 30_000,
    queryFn: ({ signal }) =>
      apiClient.get<{
        kpis: {
          listings: { pending: number };
          moderation: { openReports: number; pendingVerifications: number };
        };
      }>('/admin/dashboard/overview', undefined, { signal }),
  });

  const pendingListings = alertsQuery.data?.kpis.listings.pending ?? 0;
  const openReports = alertsQuery.data?.kpis.moderation.openReports ?? 0;
  const pendingVerifications =
    alertsQuery.data?.kpis.moderation.pendingVerifications ?? 0;
  const totalAlerts = pendingListings + openReports + pendingVerifications;

  const navItems: NavItem[] = useMemo(
    () => [
      {
        to: '/',
        label: t.nav.overview,
        icon: <LayoutDashboard className="h-4 w-4" />,
        permission: 'analytics.read',
      },
      {
        to: '/users',
        label: t.nav.users,
        icon: <Users className="h-4 w-4" />,
        permission: 'users.read',
      },
      {
        to: '/listings',
        label: t.nav.listings,
        icon: <ShoppingBag className="h-4 w-4" />,
        permission: 'listings.read',
      },
      {
        to: '/categories',
        label: t.nav.categories,
        icon: <FolderTree className="h-4 w-4" />,
        permission: 'categories.read',
      },
      {
        to: '/reports',
        label: t.nav.reports,
        icon: <Flag className="h-4 w-4" />,
        permission: 'reports.read',
      },
      {
        to: '/verification',
        label: t.nav.verification,
        icon: <ShieldCheck className="h-4 w-4" />,
        permission: 'verification.read',
      },
      {
        to: '/messaging',
        label: t.nav.messaging,
        icon: <MessageSquareWarning className="h-4 w-4" />,
        permission: 'messaging.complaints.read',
      },
      {
        to: '/notifications',
        label: t.nav.notifications,
        icon: <Bell className="h-4 w-4" />,
        permission: 'notifications.read',
      },
      {
        to: '/cms',
        label: t.nav.cms,
        icon: <FileText className="h-4 w-4" />,
        permission: 'cms.read',
      },
      {
        to: '/analytics',
        label: t.nav.analytics,
        icon: <BarChart3 className="h-4 w-4" />,
        permission: 'analytics.read',
      },
      {
        to: '/admins',
        label: t.nav.admins,
        icon: <UserCog className="h-4 w-4" />,
        permission: 'admins.read',
      },
      {
        to: '/roles',
        label: t.nav.roles,
        icon: <Shield className="h-4 w-4" />,
        permission: 'roles.read',
      },
      {
        to: '/audit-logs',
        label: t.nav.auditLogs,
        icon: <Lock className="h-4 w-4" />,
        permission: 'audit_logs.read',
      },
      {
        to: '/system-health',
        label: t.nav.systemHealth,
        icon: <Activity className="h-4 w-4" />,
        permission: 'system_health.read',
      },
      {
        to: '/feature-flags',
        label: t.nav.featureFlags,
        icon: <Flag className="h-4 w-4" />,
        permission: 'feature_flags.read',
      },
      {
        to: '/settings',
        label: t.nav.settings,
        icon: <Settings className="h-4 w-4" />,
        permission: 'settings.read',
      },
      {
        to: '/security',
        label: t.nav.security,
        icon: <Lock className="h-4 w-4" />,
      },
    ],
    [t],
  );

  const visibleNav = navItems.filter(
    (item) => !item.permission || hasPermission(item.permission),
  );

  const currentNav = visibleNav.find((n) =>
    n.to === '/' ? location.pathname === '/' : location.pathname.startsWith(n.to),
  );

  const handleQuickSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const q = quickSearch.trim();
    if (!q) return;
    if (hasPermission('listings.read')) {
      navigate(`/listings?q=${encodeURIComponent(q)}`);
    } else if (hasPermission('users.read')) {
      navigate(`/users?q=${encodeURIComponent(q)}`);
    }
  };

  return (
    <div className="flex min-h-screen bg-background text-foreground">
      {/* Mobile Sidebar Backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 z-50 flex w-64 flex-col border-e bg-card transition-transform lg:static lg:!translate-x-0 ${
          sidebarOpen
            ? 'translate-x-0'
            : 'ltr:-translate-x-full rtl:translate-x-full'
        }`}
      >
        <div className="flex h-16 items-center justify-between border-b px-4">
          <Link to="/" className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-sm font-bold text-primary-foreground">
              D1
            </div>
            <div>
              <p className="text-sm font-bold leading-none">{t.brand}</p>
              <p className="mt-1 text-[11px] text-muted-foreground">
                {t.brandSub}
              </p>
            </div>
          </Link>
          <button
            type="button"
            className="rounded p-1 lg:hidden"
            onClick={() => setSidebarOpen(false)}
            aria-label="Close sidebar"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="flex-1 space-y-1 overflow-y-auto p-3">
          {visibleNav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition ${
                  isActive
                    ? 'bg-primary text-primary-foreground shadow-sm'
                    : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                }`
              }
            >
              {item.icon}
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="border-t p-3 text-xs text-muted-foreground">
          <div className="flex items-center justify-between">
            <span>{admin?.role?.name}</span>
            <span className="rounded bg-emerald-500/15 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-600 dark:text-emerald-300">
              {admin?.mfaEnabled ? 'MFA ON' : 'MFA OFF'}
            </span>
          </div>
        </div>
      </aside>

      {/* Main Column */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-between gap-3 border-b bg-card/95 px-4 backdrop-blur-sm lg:px-6">
          <div className="flex items-center gap-3">
            <button
              type="button"
              className="rounded-lg border p-2 lg:hidden"
              onClick={() => setSidebarOpen(true)}
              aria-label="Open menu"
            >
              <Menu className="h-4 w-4" />
            </button>
            <div className="hidden items-center gap-2 text-sm sm:flex">
              <Link to="/" className="text-muted-foreground hover:text-foreground">
                {t.brand}
              </Link>
              <span className="text-muted-foreground">/</span>
              <span className="font-semibold">
                {currentNav?.label || t.nav.overview}
              </span>
            </div>
          </div>

          <form
            onSubmit={handleQuickSearch}
            className="hidden max-w-xs flex-1 md:block"
          >
            <div className="relative">
              <Search className="pointer-events-none absolute top-2.5 h-4 w-4 text-muted-foreground ltr:left-3 rtl:right-3" />
              <Input
                id="header-quick-search"
                name="quickSearch"
                aria-label={t.common.search}
                value={quickSearch}
                onChange={(e) => setQuickSearch(e.target.value)}
                placeholder={t.common.search}
                className="ltr:pl-9 rtl:pr-9"
              />
            </div>
          </form>

          <div className="flex items-center gap-2">
            {hasPermission('analytics.read') && (
              <div className="relative">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setNotifOpen((o) => !o);
                    setProfileOpen(false);
                  }}
                  aria-label={t.nav.notifications}
                  title={locale === 'ar' ? 'تنبيهات المراجعة' : 'Queue Alerts'}
                >
                  <Bell className="h-4 w-4" />
                  {totalAlerts > 0 && (
                    <span className="rounded-full bg-rose-600 px-1.5 py-0.2 text-[10px] font-bold text-white">
                      {totalAlerts}
                    </span>
                  )}
                </Button>
                {notifOpen && (
                  <div className="absolute top-full z-50 mt-2 w-64 rounded-xl border bg-card p-3 shadow-lg ltr:right-0 rtl:left-0">
                    <p className="mb-2 text-xs font-bold">
                      {locale === 'ar' ? 'قوائم بانتظار المراجعة' : 'Pending Queues'}
                    </p>
                    <div className="space-y-1 text-xs">
                      <Link
                        to="/listings"
                        onClick={() => setNotifOpen(false)}
                        className="flex items-center justify-between rounded-md px-2 py-1.5 hover:bg-muted"
                      >
                        <span>{t.nav.listings}</span>
                        <span className="font-bold">{pendingListings}</span>
                      </Link>
                      <Link
                        to="/reports"
                        onClick={() => setNotifOpen(false)}
                        className="flex items-center justify-between rounded-md px-2 py-1.5 hover:bg-muted"
                      >
                        <span>{t.nav.reports}</span>
                        <span className="font-bold">{openReports}</span>
                      </Link>
                      <Link
                        to="/verification"
                        onClick={() => setNotifOpen(false)}
                        className="flex items-center justify-between rounded-md px-2 py-1.5 hover:bg-muted"
                      >
                        <span>{t.nav.verification}</span>
                        <span className="font-bold">{pendingVerifications}</span>
                      </Link>
                    </div>
                  </div>
                )}
              </div>
            )}

            <Button
              variant="outline"
              size="sm"
              onClick={toggleLocale}
              title="Toggle Language"
            >
              <Globe className="h-4 w-4" />
              <span className="hidden sm:inline">{t.common.language}</span>
            </Button>

            <Button
              variant="outline"
              size="sm"
              onClick={toggleTheme}
              title={theme === 'dark' ? t.common.lightMode : t.common.darkMode}
            >
              {theme === 'dark' ? (
                <Sun className="h-4 w-4" />
              ) : (
                <Moon className="h-4 w-4" />
              )}
            </Button>

            <div className="relative">
              <button
                type="button"
                onClick={() => {
                  setProfileOpen((o) => !o);
                  setNotifOpen(false);
                }}
                className="flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs hover:bg-muted"
              >
                <span className="hidden font-semibold sm:inline">
                  {admin?.fullName}
                </span>
                <ChevronDown className="h-3.5 w-3.5 text-muted-foreground" />
              </button>
              {profileOpen && (
                <div className="absolute top-full z-50 mt-2 w-56 rounded-xl border bg-card p-3 shadow-lg ltr:right-0 rtl:left-0">
                  <p className="text-xs font-bold">{admin?.fullName}</p>
                  <p className="truncate font-mono text-[11px] text-muted-foreground">
                    {admin?.email}
                  </p>
                  <p className="mt-1 inline-block rounded bg-primary/10 px-1.5 py-0.5 text-[10px] font-semibold text-primary">
                    {admin?.role?.name}
                  </p>
                  <div className="mt-3 space-y-1 border-t pt-2 text-xs">
                    <Link
                      to="/security"
                      onClick={() => setProfileOpen(false)}
                      className="flex items-center gap-2 rounded-md px-2 py-1.5 hover:bg-muted"
                    >
                      <Lock className="h-3.5 w-3.5" />
                      <span>{t.nav.security}</span>
                    </Link>
                    <button
                      type="button"
                      onClick={() => {
                        setProfileOpen(false);
                        void logout();
                      }}
                      className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-destructive hover:bg-destructive/10"
                    >
                      <LogOut className="h-3.5 w-3.5" />
                      <span>{t.common.logout}</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        <main className="flex-1 p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
