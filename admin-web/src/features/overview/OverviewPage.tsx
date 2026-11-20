import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Activity,
  Flag,
  RefreshCw,
  ShieldCheck,
  ShoppingBag,
  Users,
} from 'lucide-react';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { apiClient, ApiClientError } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import {
  Button,
  Card,
  ErrorState,
  LoadingState,
  StatCard,
  StatusBadge,
} from '../../components/ui';

interface OverviewResponse {
  kpis: {
    users: {
      total: number;
      new7d: number;
      new30d: number;
      active30d: number;
      suspended: number;
      banned: number;
    };
    accounts: { total: number; verified: number };
    listings: {
      total: number;
      published: number;
      pending: number;
      rejected: number;
      hidden: number;
      expired: number;
    };
    moderation: {
      openReports: number;
      pendingVerifications: number;
      totalConversations: number;
    };
  };
  platformHealth: {
    status: string;
    database: string;
    redisCache: string;
    redisQueue: string;
  };
  recentActivities: Array<{
    id: string;
    actorType: string;
    actorId: string | null;
    action: string;
    targetEntity: string;
    createdAt: string;
  }>;
  generatedAt: string;
}

interface ChartsResponse {
  activitySeries: Array<{ date: string; users: number; listings: number }>;
  categoryStats: Array<{
    categoryId: string;
    nameEn: string;
    nameAr: string;
    count: number;
  }>;
}

export function OverviewPage() {
  const { locale, t } = useI18n();

  const overviewQuery = useQuery({
    queryKey: ['admin-dashboard-overview'],
    queryFn: ({ signal }) =>
      apiClient.get<OverviewResponse>('/admin/dashboard/overview', undefined, {
        signal,
      }),
  });

  const chartsQuery = useQuery({
    queryKey: ['admin-dashboard-charts'],
    queryFn: ({ signal }) =>
      apiClient.get<ChartsResponse>(
        '/admin/dashboard/charts',
        { days: 30 },
        { signal },
      ),
  });

  if (overviewQuery.isLoading) return <LoadingState />;
  if (overviewQuery.error) {
    return (
      <ErrorState
        message={
          overviewQuery.error instanceof ApiClientError
            ? overviewQuery.error.message
            : 'Failed to load dashboard overview'
        }
        onRetry={() => void overviewQuery.refetch()}
      />
    );
  }

  const data = overviewQuery.data!;
  const charts = chartsQuery.data;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-2xl font-bold">{t.nav.overview}</h2>
          <p className="text-xs text-muted-foreground">
            {locale === 'ar' ? 'آخر تحديث:' : 'Last updated:'}{' '}
            {new Date(data.generatedAt).toLocaleString()}
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            void overviewQuery.refetch();
            void chartsQuery.refetch();
          }}
        >
          <RefreshCw className="h-4 w-4" />
          {t.common.refresh}
        </Button>
      </div>

      {/* Primary KPIs */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title={locale === 'ar' ? 'إجمالي المستخدمين' : 'Total Users'}
          value={data.kpis.users.total.toLocaleString()}
          subtitle={`${locale === 'ar' ? 'جدد (7 أيام)' : 'New 7d'}: ${data.kpis.users.new7d} • ${locale === 'ar' ? 'نشطون (30ي)' : 'Active 30d'}: ${data.kpis.users.active30d}`}
          icon={<Users className="h-5 w-5" />}
        />
        <StatCard
          title={locale === 'ar' ? 'إجمالي الإعلانات' : 'Total Listings'}
          value={data.kpis.listings.total.toLocaleString()}
          subtitle={`${locale === 'ar' ? 'منشور' : 'Published'}: ${data.kpis.listings.published} • ${locale === 'ar' ? 'معلق' : 'Pending'}: ${data.kpis.listings.pending} • ${locale === 'ar' ? 'مرفوض' : 'Rejected'}: ${data.kpis.listings.rejected}`}
          icon={<ShoppingBag className="h-5 w-5" />}
        />
        <StatCard
          title={locale === 'ar' ? 'البلاغات المفتوحة' : 'Open Reports'}
          value={data.kpis.moderation.openReports.toLocaleString()}
          subtitle={`${locale === 'ar' ? 'طلبات توثيق معلقة' : 'Pending Verifications'}: ${data.kpis.moderation.pendingVerifications}`}
          icon={<Flag className="h-5 w-5" />}
        />
        <StatCard
          title={locale === 'ar' ? 'صحة المنصة' : 'Platform Health'}
          value={data.platformHealth.status.toUpperCase()}
          subtitle={`DB: ${data.platformHealth.database} • Cache: ${data.platformHealth.redisCache} • Queue: ${data.platformHealth.redisQueue}`}
          icon={<Activity className="h-5 w-5" />}
        />
      </div>

      {/* Secondary KPIs */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card className="p-4 flex items-center justify-between">
          <div>
            <p className="text-xs text-muted-foreground">
              {locale === 'ar' ? 'الحسابات الموثقة' : 'Verified Accounts'}
            </p>
            <p className="text-lg font-bold">
              {data.kpis.accounts.verified} / {data.kpis.accounts.total}
            </p>
          </div>
          <ShieldCheck className="h-5 w-5 text-emerald-500" />
        </Card>
        <Card className="p-4 flex items-center justify-between">
          <div>
            <p className="text-xs text-muted-foreground">
              {locale === 'ar' ? 'مستخدمون معلقون / محظورون' : 'Suspended / Banned Users'}
            </p>
            <p className="text-lg font-bold">
              {data.kpis.users.suspended} / {data.kpis.users.banned}
            </p>
          </div>
          <Users className="h-5 w-5 text-amber-500" />
        </Card>
        <Card className="p-4 flex items-center justify-between">
          <div>
            <p className="text-xs text-muted-foreground">
              {locale === 'ar' ? 'إعلانات مخفية / منتهية' : 'Hidden / Expired Listings'}
            </p>
            <p className="text-lg font-bold">
              {data.kpis.listings.hidden} / {data.kpis.listings.expired}
            </p>
          </div>
          <ShoppingBag className="h-5 w-5 text-slate-500" />
        </Card>
      </div>

      {/* Charts */}
      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="p-5">
          <h3 className="mb-4 text-sm font-semibold">
            {locale === 'ar'
              ? 'نشاط التسجيلات والإعلانات (30 يوم)'
              : '30-Day Registrations & Listings'}
          </h3>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={charts?.activitySeries ?? []}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="users"
                  name={locale === 'ar' ? 'مستخدمون' : 'Users'}
                  stroke="#3b82f6"
                  fill="#3b82f6"
                  fillOpacity={0.2}
                />
                <Area
                  type="monotone"
                  dataKey="listings"
                  name={locale === 'ar' ? 'إعلانات' : 'Listings'}
                  stroke="#10b981"
                  fill="#10b981"
                  fillOpacity={0.2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-5">
          <h3 className="mb-4 text-sm font-semibold">
            {locale === 'ar' ? 'الإعلانات حسب القسم' : 'Listings by Category'}
          </h3>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={charts?.categoryStats ?? []}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
                <XAxis
                  dataKey={locale === 'ar' ? 'nameAr' : 'nameEn'}
                  tick={{ fontSize: 11 }}
                />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar
                  dataKey="count"
                  name={locale === 'ar' ? 'الإعلانات' : 'Listings'}
                  fill="#6366f1"
                  radius={[6, 6, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      {/* Recent Admin Activities */}
      <Card className="p-5">
        <h3 className="mb-3 text-sm font-semibold">
          {locale === 'ar'
            ? 'أحدث العمليات الإدارية'
            : 'Recent Administrative Activities'}
        </h3>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b bg-muted/40 text-xs text-muted-foreground">
              <tr>
                <th className="px-3 py-2 text-start">Action</th>
                <th className="px-3 py-2 text-start">Actor</th>
                <th className="px-3 py-2 text-start">Target</th>
                <th className="px-3 py-2 text-start">Time</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {data.recentActivities.map((act) => (
                <tr key={act.id}>
                  <td className="px-3 py-2 font-mono text-xs">{act.action}</td>
                  <td className="px-3 py-2 text-xs">
                    <StatusBadge status={act.actorType} />
                  </td>
                  <td className="px-3 py-2 text-xs">{act.targetEntity}</td>
                  <td className="px-3 py-2 text-xs text-muted-foreground">
                    {new Date(act.createdAt).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
