import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Check, Eye, AlertTriangle, X } from 'lucide-react';
import { apiClient } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import { DataTable, PaginationMeta } from '../../components/DataTable';
import {
  Button,
  ConfirmDialog,
  Modal,
  Select,
  StatusBadge,
  Textarea,
} from '../../components/ui';

interface ReportRow {
  id: string;
  reason: string;
  details: string | null;
  status: string;
  priority: string;
  createdAt: string;
  reporter: { id: string; fullName: string; phone: string };
  listing: { id: string; title: string } | null;
  reportedAccount: { id: string; displayName: string } | null;
  assignedTo: { id: string; fullName: string } | null;
}

export function ReportsPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [status, setStatus] = useState('open');
  const [priority, setPriority] = useState('');
  const [q, setQ] = useState('');
  const [selectedReportId, setSelectedReportId] = useState<string | null>(null);
  const [noteInput, setNoteInput] = useState('');
  const [adjudicateTarget, setAdjudicateTarget] = useState<{
    report: ReportRow;
    status: 'resolved' | 'dismissed' | 'escalated';
  } | null>(null);

  const query = useQuery({
    queryKey: ['admin-reports', page, status, priority, q],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: ReportRow[]; meta: PaginationMeta }>(
        '/admin/moderation/queue',
        { page, limit: 20, status, priority: priority || undefined, q },
        { signal },
      ),
  });

  const detailQuery = useQuery({
    queryKey: ['admin-report-detail', selectedReportId],
    enabled: Boolean(selectedReportId),
    queryFn: ({ signal }) =>
      apiClient.get<{
        report: ReportRow & {
          internalNotes?: Array<{ id: string; authorName: string; note: string }>;
        };
        history: Array<{ id: string; action: string; notes: string | null; createdAt: string }>;
      }>(`/admin/moderation/reports/${selectedReportId}`, undefined, { signal }),
  });

  const staffQuery = useQuery({
    queryKey: ['admin-staff-list-min'],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: Array<{ id: string; fullName: string }> }>(
        '/admin/staff',
        { page: 1, limit: 50 },
        { signal },
      ),
  });

  const adjudicateMutation = useMutation({
    mutationFn: ({
      id,
      nextStatus,
      actionTaken,
    }: {
      id: string;
      nextStatus: string;
      actionTaken: string;
    }) =>
      apiClient.patch(`/admin/moderation/reports/${id}`, {
        status: nextStatus,
        actionTaken,
      }),
    onSuccess: () => {
      setAdjudicateTarget(null);
      void qc.invalidateQueries({ queryKey: ['admin-reports'] });
      if (selectedReportId) {
        void qc.invalidateQueries({
          queryKey: ['admin-report-detail', selectedReportId],
        });
      }
    },
  });

  const assignMutation = useMutation({
    mutationFn: ({
      id,
      staffId,
      nextPriority,
    }: {
      id: string;
      staffId?: string;
      nextPriority?: string;
    }) =>
      apiClient.post(`/admin/moderation/reports/${id}/assign`, {
        staffId: staffId || undefined,
        priority: nextPriority || undefined,
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['admin-reports'] });
      if (selectedReportId) {
        void qc.invalidateQueries({
          queryKey: ['admin-report-detail', selectedReportId],
        });
      }
    },
  });

  const addNoteMutation = useMutation({
    mutationFn: ({ id, note }: { id: string; note: string }) =>
      apiClient.post(`/admin/moderation/reports/${id}/notes`, { note }),
    onSuccess: () => {
      setNoteInput('');
      if (selectedReportId) {
        void qc.invalidateQueries({
          queryKey: ['admin-report-detail', selectedReportId],
        });
      }
    },
  });

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">{t.nav.reports}</h2>

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
              value={status}
              onChange={(e) => {
                setPage(1);
                setStatus(e.target.value);
              }}
              className="w-36"
            >
              <option value="all">{t.common.all}</option>
              <option value="open">{t.common.open}</option>
              <option value="resolved">{t.common.resolved}</option>
              <option value="dismissed">{t.common.dismissed}</option>
              <option value="escalated">{t.common.escalated}</option>
            </Select>
            <Select
              value={priority}
              onChange={(e) => {
                setPage(1);
                setPriority(e.target.value);
              }}
              className="w-36"
            >
              <option value="">Priority: {t.common.all}</option>
              <option value="low">low</option>
              <option value="medium">medium</option>
              <option value="high">high</option>
              <option value="critical">critical</option>
            </Select>
          </div>
        }
        columns={[
          {
            key: 'reason',
            header: locale === 'ar' ? 'البلاغ والهدف' : 'Report & Target',
            render: (r) => (
              <div>
                <p className="font-medium capitalize">{r.reason}</p>
                <p className="text-xs text-muted-foreground">
                  {r.listing?.title || r.reportedAccount?.displayName || '-'}
                </p>
              </div>
            ),
          },
          {
            key: 'reporter',
            header: locale === 'ar' ? 'المُبلّغ' : 'Reporter',
            render: (r) => (
              <span className="text-xs">
                {r.reporter.fullName} ({r.reporter.phone})
              </span>
            ),
          },
          {
            key: 'priority',
            header: 'Priority',
            render: (r) => <StatusBadge status={r.priority} />,
          },
          {
            key: 'status',
            header: t.common.status,
            render: (r) => <StatusBadge status={r.status} />,
          },
          {
            key: 'assignee',
            header: locale === 'ar' ? 'المراجع' : 'Assignee',
            render: (r) => (
              <span className="text-xs">
                {r.assignedTo?.fullName || 'Unassigned'}
              </span>
            ),
          },
          {
            key: 'actions',
            header: t.common.actions,
            render: (r) => (
              <div className="flex gap-1">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setSelectedReportId(r.id)}
                >
                  <Eye className="h-3.5 w-3.5" />
                </Button>
                <PermissionGate permission="reports.resolve">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setAdjudicateTarget({ report: r, status: 'resolved' })
                    }
                    title="Resolve"
                  >
                    <Check className="h-3.5 w-3.5 text-emerald-600" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setAdjudicateTarget({ report: r, status: 'dismissed' })
                    }
                    title="Dismiss"
                  >
                    <X className="h-3.5 w-3.5 text-slate-600" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setAdjudicateTarget({ report: r, status: 'escalated' })
                    }
                    title="Escalate"
                  >
                    <AlertTriangle className="h-3.5 w-3.5 text-amber-600" />
                  </Button>
                </PermissionGate>
              </div>
            ),
          },
        ]}
      />

      <Modal
        open={Boolean(selectedReportId)}
        onClose={() => setSelectedReportId(null)}
        title="Report Details"
      >
        {detailQuery.data && (
          <div className="space-y-4 text-sm">
            <div className="flex items-center justify-between">
              <StatusBadge status={detailQuery.data.report.status} />
              <StatusBadge status={detailQuery.data.report.priority} />
            </div>
            <p className="rounded-lg border bg-muted/30 p-3 text-xs">
              {detailQuery.data.report.details || 'No additional details provided.'}
            </p>

            <PermissionGate permission="reports.assign">
              <div className="grid gap-2 sm:grid-cols-2">
                <Select
                  defaultValue={detailQuery.data.report.assignedTo?.id || ''}
                  onChange={(e) =>
                    assignMutation.mutate({
                      id: detailQuery.data!.report.id,
                      staffId: e.target.value,
                    })
                  }
                >
                  <option value="">Assign Reviewer...</option>
                  {(staffQuery.data?.items ?? []).map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.fullName}
                    </option>
                  ))}
                </Select>
                <Select
                  defaultValue={detailQuery.data.report.priority}
                  onChange={(e) =>
                    assignMutation.mutate({
                      id: detailQuery.data!.report.id,
                      nextPriority: e.target.value,
                    })
                  }
                >
                  <option value="low">Priority: low</option>
                  <option value="medium">Priority: medium</option>
                  <option value="high">Priority: high</option>
                  <option value="critical">Priority: critical</option>
                </Select>
              </div>
            </PermissionGate>

            <PermissionGate permission="reports.resolve">
              <div className="space-y-2 border-t pt-3">
                <h4 className="font-semibold text-xs">Internal Notes</h4>
                {(detailQuery.data.report.internalNotes ?? []).map((n) => (
                  <div key={n.id} className="rounded border p-2 text-xs">
                    <strong>{n.authorName}:</strong> {n.note}
                  </div>
                ))}
                <div className="flex gap-2">
                  <Textarea
                    value={noteInput}
                    onChange={(e) => setNoteInput(e.target.value)}
                    placeholder="Add moderation note..."
                    className="min-h-[54px]"
                  />
                  <Button
                    disabled={!noteInput.trim() || addNoteMutation.isPending}
                    onClick={() =>
                      addNoteMutation.mutate({
                        id: detailQuery.data!.report.id,
                        note: noteInput,
                      })
                    }
                  >
                    Save
                  </Button>
                </div>
              </div>
            </PermissionGate>

            <div>
              <h4 className="mb-1.5 font-semibold text-xs">Moderation History</h4>
              <div className="max-h-36 overflow-y-auto rounded border divide-y text-xs">
                {detailQuery.data.history.map((h) => (
                  <div key={h.id} className="flex justify-between p-2">
                    <span>
                      <strong>{h.action}</strong> {h.notes && `— ${h.notes}`}
                    </span>
                    <span className="text-muted-foreground">
                      {new Date(h.createdAt).toLocaleString()}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={Boolean(adjudicateTarget)}
        onClose={() => setAdjudicateTarget(null)}
        title={`Mark Report as ${adjudicateTarget?.status.toUpperCase()}`}
        description="Record moderation action taken and update report state."
        requireReason
        reasonLabel="Action Taken / Resolution Notes"
        loading={adjudicateMutation.isPending}
        onConfirm={(reason) => {
          if (!adjudicateTarget) return;
          adjudicateMutation.mutate({
            id: adjudicateTarget.report.id,
            nextStatus: adjudicateTarget.status,
            actionTaken: reason,
          });
        }}
      />
    </div>
  );
}
