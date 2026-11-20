import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Download, Eye } from 'lucide-react';
import { apiClient } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import { DataTable, PaginationMeta } from '../../components/DataTable';
import { Button, Input, Modal, Select, StatusBadge } from '../../components/ui';

interface AuditRow {
  id: string;
  actorType: string;
  actorId: string | null;
  action: string;
  targetEntity: string;
  targetId: string | null;
  ipAddress: string | null;
  diffPayload: unknown;
  createdAt: string;
}

export function AuditLogsPage() {
  const { t } = useI18n();
  const [page, setPage] = useState(1);
  const [q, setQ] = useState('');
  const [actorType, setActorType] = useState('');
  const [targetEntity, setTargetEntity] = useState('');
  const [from, setFrom] = useState('');
  const [selected, setSelected] = useState<AuditRow | null>(null);

  const query = useQuery({
    queryKey: ['admin-audit-logs', page, q, actorType, targetEntity, from],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: AuditRow[]; meta: PaginationMeta }>(
        '/admin/audit-logs',
        {
          page,
          limit: 30,
          q,
          actorType: actorType || undefined,
          targetEntity: targetEntity || undefined,
          from: from || undefined,
        },
        { signal },
      ),
  });

  const handleExport = async (format: 'csv' | 'json') => {
    const res = await apiClient.get<{ csv?: string }>(
      '/admin/audit-logs/export',
      { q, actorType: actorType || undefined, format },
    );
    const content =
      format === 'csv' ? res.csv || '' : JSON.stringify(res, null, 2);
    const blob = new Blob([content], {
      type: format === 'csv' ? 'text/csv;charset=utf-8' : 'application/json',
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `dealone-audit-logs.${format}`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div>
          <h2 className="text-2xl font-bold">{t.nav.auditLogs}</h2>
          <p className="text-xs text-muted-foreground">
            Immutable append-only administrative and security audit trail.
          </p>
        </div>
        <PermissionGate permission="audit_logs.export">
          <div className="flex gap-2">
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
          </div>
        </PermissionGate>
      </div>

      <DataTable
        rowKey={(r) => r.id}
        data={query.data?.items ?? []}
        meta={query.data?.meta}
        isLoading={query.isLoading}
        onPageChange={setPage}
        search={q}
        onSearchChange={(val) => {
          setPage(1);
          setQ(val);
        }}
        filters={
          <div className="flex flex-wrap gap-2">
            <Select
              value={actorType}
              onChange={(e) => {
                setPage(1);
                setActorType(e.target.value);
              }}
              className="w-36"
            >
              <option value="">Actor: All</option>
              <option value="staff">staff</option>
              <option value="user">user</option>
              <option value="system">system</option>
            </Select>
            <Input
              placeholder="Target entity..."
              value={targetEntity}
              onChange={(e) => {
                setPage(1);
                setTargetEntity(e.target.value);
              }}
              className="w-40"
            />
            <Input
              type="date"
              value={from}
              onChange={(e) => {
                setPage(1);
                setFrom(e.target.value);
              }}
              className="w-36"
            />
          </div>
        }
        columns={[
          {
            key: 'action',
            header: 'Action',
            render: (r) => <span className="font-mono text-xs">{r.action}</span>,
          },
          {
            key: 'actor',
            header: 'Actor',
            render: (r) => (
              <div className="text-xs">
                <StatusBadge status={r.actorType} />{' '}
                <span className="font-mono text-muted-foreground">
                  {r.actorId?.slice(0, 8) || '-'}
                </span>
              </div>
            ),
          },
          {
            key: 'target',
            header: 'Target',
            render: (r) => (
              <span className="text-xs">
                {r.targetEntity}{' '}
                {r.targetId ? `(${r.targetId.slice(0, 8)})` : ''}
              </span>
            ),
          },
          {
            key: 'ip',
            header: 'IP',
            render: (r) => (
              <span className="font-mono text-xs">{r.ipAddress || '-'}</span>
            ),
          },
          {
            key: 'created',
            header: t.common.createdAt,
            render: (r) => (
              <span className="text-xs text-muted-foreground">
                {new Date(r.createdAt).toLocaleString()}
              </span>
            ),
          },
          {
            key: 'diff',
            header: t.common.actions,
            render: (r) => (
              <Button
                size="sm"
                variant="outline"
                onClick={() => setSelected(r)}
              >
                <Eye className="h-3.5 w-3.5" />
              </Button>
            ),
          },
        ]}
      />

      <Modal
        open={Boolean(selected)}
        onClose={() => setSelected(null)}
        title={`Audit Event — ${selected?.action || ''}`}
      >
        {selected && (
          <div className="space-y-3 text-xs">
            <p>
              <strong>Event ID:</strong> <span className="font-mono">{selected.id}</span>
            </p>
            <p>
              <strong>Actor:</strong> {selected.actorType} /{' '}
              <span className="font-mono">{selected.actorId || 'system'}</span>
            </p>
            <p>
              <strong>Target:</strong> {selected.targetEntity} /{' '}
              <span className="font-mono">{selected.targetId || '-'}</span>
            </p>
            <div>
              <strong>Diff / Metadata Payload:</strong>
              <pre className="mt-1 max-h-64 overflow-auto rounded-lg border bg-muted/40 p-3 font-mono text-[11px]">
                {JSON.stringify(selected.diffPayload ?? {}, null, 2)}
              </pre>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
