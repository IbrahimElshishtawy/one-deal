import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Download } from 'lucide-react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { apiClient } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import { Button, Card, Input, LoadingState, StatCard } from '../../components/ui';

interface AnalyticsSummary {
  period: { from: string; to: string };
  scopeNote: string;
  users: {
    newRegistrations: number;
    totalActive: number;
    suspended: number;
    banned: number;
  };
  listings: {
    byModerationStatus: Array<{ status: string; count: number }>;
    byPublicationStatus: Array<{ status: string; count: number }>;
  };
  moderation: {
    reportsByStatus: Array<{ status: string; count: number }>;
    reportsByReason: Array<{ reason: string; count: number }>;
  };
  verifications: { byStatus: Array<{ status: string; count: number }> };
  notifications: {
    campaignsCount: number;
    sentCount: number;
    deliveredCount: number;
    failedCount: number;
  };
  categoryStats: Array<{ nameEn: string; nameAr: string; count: number }>;
}

export function AnalyticsPage() {
  const { t, locale } = useI18n();
  const [from, setFrom] = useState(
    new Date(Date.now() - 30 * 86400_000).toISOString().slice(0, 10),
  );
  const [to, setTo] = useState(new Date().toISOString().slice(0, 10));

  const query = useQuery({
    queryKey: ['admin-analytics', from, to],
    queryFn: ({ signal }) =>
      apiClient.get<AnalyticsSummary>(
        '/admin/analytics/summary',
        { from, to },
        { signal },
      ),
  });

  const handleExport = async (format: 'csv' | 'json') => {
    const res = await apiClient.get<{ csv?: string }>(
      '/admin/analytics/export',
      { from, to, format },
    );
    const content =
      format === 'csv' ? res.csv || '' : JSON.stringify(res, null, 2);
    const blob = new Blob([content], {
      type: format === 'csv' ? 'text/csv;charset=utf-8' : 'application/json',
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `dealone-analytics-${from}-to-${to}.${format}`;
    a.click();
    URL.revokeObjectURL(url);
  };

  if (query.isLoading) return <LoadingState />;
  const data = query.data;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-2xl font-bold">{t.nav.analytics}</h2>
          <p className="text-xs text-muted-foreground">{data?.scopeNote}</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Input
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="w-36"
          />
          <Input
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="w-36"
          />
          <PermissionGate permission="analytics.export">
            <Button
              size="sm"
              variant="outline"
              onClick={() => void handleExport('csv')}
            >
              <Download className="h-4 w-4" />
              {t.common.exportCsv}
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => void handleExport('json')}
            >
              <Download className="h-4 w-4" />
              {t.common.exportJson}
            </Button>
          </PermissionGate>
        </div>
      </div>

      {data && (
        <>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatCard
              title="New Registrations"
              value={data.users.newRegistrations}
              subtitle={`Active: ${data.users.totalActive} | Suspended: ${data.users.suspended}`}
            />
            <StatCard
              title="Notifications Campaigns"
              value={data.notifications.campaignsCount}
              subtitle={`Delivered: ${data.notifications.deliveredCount}/${data.notifications.sentCount}`}
            />
            <StatCard
              title="Verification Requests"
              value={data.verifications.byStatus.reduce(
                (s, v) => s + v.count,
                0,
              )}
              subtitle={data.verifications.byStatus
                .map((v) => `${v.status}: ${v.count}`)
                .join(' • ')}
            />
            <StatCard
              title="Reports in Period"
              value={data.moderation.reportsByStatus.reduce(
                (s, r) => s + r.count,
                0,
              )}
              subtitle={data.moderation.reportsByStatus
                .map((r) => `${r.status}: ${r.count}`)
                .join(' • ')}
            />
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <Card className="p-5">
              <h3 className="mb-4 text-sm font-semibold">
                Category Distribution
              </h3>
              <div className="h-72">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={data.categoryStats}>
                    <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
                    <XAxis
                      dataKey={locale === 'ar' ? 'nameAr' : 'nameEn'}
                      tick={{ fontSize: 11 }}
                    />
                    <YAxis tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Bar dataKey="count" fill="#3b82f6" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card className="p-5">
              <h3 className="mb-4 text-sm font-semibold">
                Moderation & Listing Breakdown
              </h3>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-xs font-semibold text-muted-foreground mb-1">
                    Listings by Moderation Status
                  </p>
                  <div className="grid grid-cols-2 gap-2">
                    {data.listings.byModerationStatus.map((item) => (
                      <div
                        key={item.status}
                        className="flex justify-between rounded border p-2 text-xs"
                      >
                        <span className="capitalize">{item.status}</span>
                        <strong>{item.count}</strong>
                      </div>
                    ))}
                  </div>
                </div>
                <div>
                  <p className="text-xs font-semibold text-muted-foreground mb-1">
                    Reports by Reason
                  </p>
                  <div className="grid grid-cols-2 gap-2">
                    {data.moderation.reportsByReason.map((item) => (
                      <div
                        key={item.reason}
                        className="flex justify-between rounded border p-2 text-xs"
                      >
                        <span className="capitalize">{item.reason}</span>
                        <strong>{item.count}</strong>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </Card>
          </div>
        </>
      )}
    </div>
  );
}
