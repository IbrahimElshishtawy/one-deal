import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { CheckCircle2, Plus, Send, Users } from 'lucide-react';
import { apiClient, ApiClientError } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import { DataTable, PaginationMeta } from '../../components/DataTable';
import {
  Button,
  Input,
  Modal,
  Select,
  StatusBadge,
  Textarea,
} from '../../components/ui';

interface CampaignRow {
  id: string;
  titleAr: string;
  titleEn: string;
  bodyAr: string;
  bodyEn: string;
  audienceType: string;
  status: string;
  estimatedRecipients: number;
  sentCount: number;
  deliveredCount: number;
  failedCount: number;
  createdAt: string;
  sentAt: string | null;
}

export function NotificationsPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('all');
  const [createOpen, setCreateOpen] = useState(false);
  const [previewCount, setPreviewCount] = useState<number | null>(null);
  const [errMsg, setErrMsg] = useState<string | null>(null);

  const [form, setForm] = useState({
    titleAr: '',
    titleEn: '',
    bodyAr: '',
    bodyEn: '',
    audienceType: 'all' as 'all' | 'verified' | 'new_users' | 'category',
    submitForApproval: true,
  });

  const query = useQuery({
    queryKey: ['admin-notification-campaigns', page, statusFilter],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: CampaignRow[]; meta: PaginationMeta }>(
        '/admin/notifications/campaigns',
        { page, limit: 20, status: statusFilter },
        { signal },
      ),
  });

  const previewAudience = async (audienceType: string) => {
    const res = await apiClient.post<{ estimatedRecipients: number }>(
      '/admin/notifications/audience-preview',
      { audienceType },
    );
    setPreviewCount(res.estimatedRecipients);
  };

  const createMutation = useMutation({
    mutationFn: () => apiClient.post('/admin/notifications/campaigns', form),
    onSuccess: () => {
      setCreateOpen(false);
      setForm({
        titleAr: '',
        titleEn: '',
        bodyAr: '',
        bodyEn: '',
        audienceType: 'all',
        submitForApproval: true,
      });
      void qc.invalidateQueries({ queryKey: ['admin-notification-campaigns'] });
    },
    onError: (err) => {
      setErrMsg(err instanceof ApiClientError ? err.message : 'Failed');
    },
  });

  const approveMutation = useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/admin/notifications/campaigns/${id}/approve`),
    onSuccess: () =>
      void qc.invalidateQueries({ queryKey: ['admin-notification-campaigns'] }),
  });

  const sendMutation = useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/admin/notifications/campaigns/${id}/send`),
    onSuccess: () =>
      void qc.invalidateQueries({ queryKey: ['admin-notification-campaigns'] }),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">{t.nav.notifications}</h2>
        <PermissionGate permission="notifications.create">
          <Button
            onClick={() => {
              setErrMsg(null);
              setCreateOpen(true);
              void previewAudience(form.audienceType);
            }}
          >
            <Plus className="h-4 w-4" />
            New Campaign
          </Button>
        </PermissionGate>
      </div>

      <DataTable
        rowKey={(r) => r.id}
        data={query.data?.items ?? []}
        meta={query.data?.meta}
        isLoading={query.isLoading}
        onPageChange={setPage}
        filters={
          <Select
            value={statusFilter}
            onChange={(e) => {
              setPage(1);
              setStatusFilter(e.target.value);
            }}
            className="w-44"
          >
            <option value="all">{t.common.all}</option>
            <option value="draft">draft</option>
            <option value="pending_approval">pending_approval</option>
            <option value="approved">approved</option>
            <option value="sent">sent</option>
          </Select>
        }
        columns={[
          {
            key: 'title',
            header: 'Campaign',
            render: (c) => (
              <div>
                <p className="font-medium">
                  {locale === 'ar' ? c.titleAr : c.titleEn}
                </p>
                <p className="text-xs text-muted-foreground line-clamp-1">
                  {locale === 'ar' ? c.bodyAr : c.bodyEn}
                </p>
              </div>
            ),
          },
          {
            key: 'audience',
            header: 'Audience',
            render: (c) => (
              <span className="text-xs">
                {c.audienceType} ({c.estimatedRecipients})
              </span>
            ),
          },
          {
            key: 'status',
            header: t.common.status,
            render: (c) => <StatusBadge status={c.status} />,
          },
          {
            key: 'stats',
            header: 'Delivery',
            render: (c) => (
              <span className="text-xs font-mono">
                {c.deliveredCount}/{c.sentCount} (fail {c.failedCount})
              </span>
            ),
          },
          {
            key: 'actions',
            header: t.common.actions,
            render: (c) => (
              <div className="flex gap-1.5">
                <PermissionGate permission="notifications.approve">
                  {['draft', 'pending_approval', 'scheduled'].includes(
                    c.status,
                  ) && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => approveMutation.mutate(c.id)}
                    >
                      <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
                      Approve
                    </Button>
                  )}
                </PermissionGate>
                <PermissionGate permission="notifications.send">
                  {c.status === 'approved' && (
                    <Button
                      size="sm"
                      onClick={() => sendMutation.mutate(c.id)}
                      disabled={sendMutation.isPending}
                    >
                      <Send className="h-3.5 w-3.5" />
                      Send
                    </Button>
                  )}
                </PermissionGate>
              </div>
            ),
          },
        ]}
      />

      <Modal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Create Notification Campaign"
      >
        <div className="space-y-3 text-sm">
          {errMsg && (
            <div className="rounded border border-destructive/40 bg-destructive/10 p-2 text-xs text-destructive">
              {errMsg}
            </div>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-medium">Title (AR)</label>
              <Input
                value={form.titleAr}
                onChange={(e) =>
                  setForm((f) => ({ ...f, titleAr: e.target.value }))
                }
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium">Title (EN)</label>
              <Input
                value={form.titleEn}
                onChange={(e) =>
                  setForm((f) => ({ ...f, titleEn: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-medium">Body (AR)</label>
              <Textarea
                value={form.bodyAr}
                onChange={(e) =>
                  setForm((f) => ({ ...f, bodyAr: e.target.value }))
                }
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium">Body (EN)</label>
              <Textarea
                value={form.bodyEn}
                onChange={(e) =>
                  setForm((f) => ({ ...f, bodyEn: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-muted/30 p-3">
            <div className="flex items-center gap-2">
              <Select
                value={form.audienceType}
                onChange={(e) => {
                  const val = e.target.value as any;
                  setForm((f) => ({ ...f, audienceType: val }));
                  void previewAudience(val);
                }}
                className="w-44"
              >
                <option value="all">All Active Users</option>
                <option value="verified">Verified Sellers</option>
                <option value="new_users">New Users (7d)</option>
              </Select>
              <span className="inline-flex items-center gap-1 text-xs font-semibold">
                <Users className="h-3.5 w-3.5" />
                Est: {previewCount ?? '...'}
              </span>
            </div>
            <label className="flex items-center gap-1.5 text-xs">
              <input
                type="checkbox"
                checked={form.submitForApproval}
                onChange={(e) =>
                  setForm((f) => ({
                    ...f,
                    submitForApproval: e.target.checked,
                  }))
                }
              />
              Submit for Approval
            </label>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              {t.common.cancel}
            </Button>
            <Button
              onClick={() => createMutation.mutate()}
              disabled={createMutation.isPending}
            >
              Create Campaign
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
