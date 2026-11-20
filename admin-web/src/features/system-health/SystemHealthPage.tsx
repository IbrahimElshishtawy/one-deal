import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Activity, Database, HardDrive, RefreshCw, Server } from 'lucide-react';
import { apiClient } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import {
  Button,
  Card,
  LoadingState,
  StatCard,
  StatusBadge,
} from '../../components/ui';

interface SystemHealthResponse {
  overallStatus: string;
  timestamp: string;
  runtime: {
    nodeEnv: string;
    uptimeSeconds: number;
    memoryRssMb: number;
    heapUsedMb: number;
  };
  database: {
    status: string;
    latencyMs: number;
    postgisSupported: boolean;
    postgisVersion: string | null;
  };
  redis: {
    cacheStatus: string;
    cacheLatencyMs: number;
    queueStatus: string;
  };
  integrations: {
    objectStorage: string;
    emailResend: string;
    pushFcm: string;
  };
  queuesAndOutbox: {
    outbox: Record<string, number>;
  };
  apiPerformance: {
    totalHttpRequests: number;
    serverErrors5xx: number;
    errorRatePercent: number;
  };
}

export function SystemHealthPage() {
  const { t } = useI18n();

  const query = useQuery({
    queryKey: ['admin-system-health'],
    queryFn: ({ signal }) =>
      apiClient.get<SystemHealthResponse>('/admin/system/health', undefined, {
        signal,
      }),
    refetchInterval: 30_000,
  });

  if (query.isLoading) return <LoadingState />;
  const h = query.data!;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">{t.nav.systemHealth}</h2>
          <p className="text-xs text-muted-foreground">
            Read-only infrastructure telemetry • Last check:{' '}
            {new Date(h.timestamp).toLocaleString()}
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={() => void query.refetch()}>
          <RefreshCw className="h-4 w-4" />
          {t.common.refresh}
        </Button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Overall Status"
          value={h.overallStatus.toUpperCase()}
          subtitle={`Env: ${h.runtime.nodeEnv} • Uptime: ${h.runtime.uptimeSeconds}s`}
          icon={<Activity className="h-5 w-5" />}
        />
        <StatCard
          title="PostgreSQL & PostGIS"
          value={h.database.status.toUpperCase()}
          subtitle={`Latency: ${h.database.latencyMs}ms • PostGIS: ${h.database.postgisVersion || 'off'}`}
          icon={<Database className="h-5 w-5" />}
        />
        <StatCard
          title="Redis Dual Topology"
          value={`${h.redis.cacheStatus.toUpperCase()} / ${h.redis.queueStatus.toUpperCase()}`}
          subtitle={`Cache Ping: ${h.redis.cacheLatencyMs}ms`}
          icon={<Server className="h-5 w-5" />}
        />
        <StatCard
          title="API Error Rate"
          value={`${h.apiPerformance.errorRatePercent}%`}
          subtitle={`Requests: ${h.apiPerformance.totalHttpRequests} • 5xx: ${h.apiPerformance.serverErrors5xx}`}
          icon={<HardDrive className="h-5 w-5" />}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="p-5 space-y-3">
          <h3 className="font-semibold">Storage & External Integrations</h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span>Cloudflare R2 Object Storage</span>
              <StatusBadge status={h.integrations.objectStorage} />
            </div>
            <div className="flex justify-between">
              <span>Resend Transactional Email</span>
              <StatusBadge status={h.integrations.emailResend} />
            </div>
            <div className="flex justify-between">
              <span>Firebase Push (FCM)</span>
              <StatusBadge status={h.integrations.pushFcm} />
            </div>
          </div>
        </Card>

        <Card className="p-5 space-y-3">
          <h3 className="font-semibold">Transactional Outbox & Memory</h3>
          <div className="grid grid-cols-2 gap-2 text-xs">
            {Object.entries(h.queuesAndOutbox.outbox).map(([k, v]) => (
              <div key={k} className="flex justify-between rounded border p-2">
                <span>Outbox {k}</span>
                <strong>{v}</strong>
              </div>
            ))}
          </div>
          <p className="text-xs text-muted-foreground">
            RSS Memory: {h.runtime.memoryRssMb} MB • Heap Used:{' '}
            {h.runtime.heapUsedMb} MB
          </p>
        </Card>
      </div>
    </div>
  );
}
