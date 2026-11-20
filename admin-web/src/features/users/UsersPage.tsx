import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Ban, Eye, KeyRound, PauseCircle, PlayCircle, ShieldCheck } from 'lucide-react';
import { apiClient, ApiClientError } from '../../core/api/client';
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

interface UserRow {
  id: string;
  fullName: string;
  phone: string;
  email: string | null;
  isActive: boolean;
  moderationStatus: string;
  createdAt: string;
  _count: { ownedAccounts: number; reportsFiled: number };
  ownedAccounts: Array<{
    id: string;
    displayName: string;
    verificationStatus: string;
    _count: { listings: number };
  }>;
}

interface UserDetailResponse {
  user: UserRow & {
    suspensionReason?: string | null;
    banReason?: string | null;
    internalNotes?: Array<{
      id: string;
      authorName: string;
      note: string;
      createdAt: string;
    }>;
    ownedAccounts: Array<{
      id: string;
      displayName: string;
      accountType: string;
      verificationStatus: string;
    }>;
    reportsFiled: Array<{ id: string; reason: string; status: string; createdAt: string }>;
  };
  listings: Array<{
    id: string;
    title: string;
    price: string;
    moderationStatus: string;
    publicationStatus: string;
  }>;
  reportsAgainst: Array<{ id: string; reason: string; status: string; createdAt: string }>;
  activeSessionCount: number;
  accountHistory: Array<{ id: string; action: string; createdAt: string }>;
}

export function UsersPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [q, setQ] = useState('');
  const [moderationStatus, setModerationStatus] = useState('all');
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [noteInput, setNoteInput] = useState('');
  const [confirmState, setConfirmState] = useState<{
    type: 'suspend' | 'unsuspend' | 'ban' | 'unban' | 'revoke';
    user: UserRow;
  } | null>(null);

  const usersQuery = useQuery({
    queryKey: ['admin-users', page, q, moderationStatus],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: UserRow[]; meta: PaginationMeta }>(
        '/admin/users',
        { page, limit: 20, q, moderationStatus },
        { signal },
      ),
  });

  const detailQuery = useQuery({
    queryKey: ['admin-user-detail', selectedUserId],
    enabled: Boolean(selectedUserId),
    queryFn: ({ signal }) =>
      apiClient.get<UserDetailResponse>(
        `/admin/users/${selectedUserId}`,
        undefined,
        { signal },
      ),
  });

  const actionMutation = useMutation({
    mutationFn: async ({
      type,
      userId,
      reason,
    }: {
      type: 'suspend' | 'unsuspend' | 'ban' | 'unban' | 'revoke';
      userId: string;
      reason: string;
    }) => {
      if (type === 'suspend') {
        return apiClient.post(`/admin/users/${userId}/suspend`, { reason });
      }
      if (type === 'unsuspend') {
        return apiClient.post(`/admin/users/${userId}/unsuspend`, { notes: reason });
      }
      if (type === 'ban') {
        return apiClient.post(`/admin/users/${userId}/ban`, { reason });
      }
      if (type === 'unban') {
        return apiClient.post(`/admin/users/${userId}/unban`, { notes: reason });
      }
      return apiClient.post(`/admin/users/${userId}/revoke-sessions`);
    },
    onSuccess: () => {
      setConfirmState(null);
      void qc.invalidateQueries({ queryKey: ['admin-users'] });
      if (selectedUserId) {
        void qc.invalidateQueries({
          queryKey: ['admin-user-detail', selectedUserId],
        });
      }
    },
  });

  const noteMutation = useMutation({
    mutationFn: ({ userId, note }: { userId: string; note: string }) =>
      apiClient.post(`/admin/users/${userId}/notes`, { note }),
    onSuccess: () => {
      setNoteInput('');
      if (selectedUserId) {
        void qc.invalidateQueries({
          queryKey: ['admin-user-detail', selectedUserId],
        });
      }
    },
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-2xl font-bold">{t.nav.users}</h2>
      </div>

      <DataTable
        rowKey={(r) => r.id}
        data={usersQuery.data?.items ?? []}
        meta={usersQuery.data?.meta}
        isLoading={usersQuery.isLoading}
        error={
          usersQuery.error instanceof ApiClientError
            ? usersQuery.error.message
            : usersQuery.error
              ? 'Error loading users'
              : null
        }
        onRetry={() => void usersQuery.refetch()}
        onPageChange={setPage}
        search={q}
        onSearchChange={(val) => {
          setPage(1);
          setQ(val);
        }}
        filters={
          <Select
            value={moderationStatus}
            onChange={(e) => {
              setPage(1);
              setModerationStatus(e.target.value);
            }}
            className="w-44"
          >
            <option value="all">{t.common.all}</option>
            <option value="active">{t.common.active}</option>
            <option value="suspended">{t.common.suspended}</option>
            <option value="banned">{t.common.banned}</option>
          </Select>
        }
        columns={[
          {
            key: 'name',
            header: locale === 'ar' ? 'المستخدم' : 'User',
            render: (u) => (
              <div>
                <p className="font-medium">{u.fullName}</p>
                <p className="text-xs text-muted-foreground font-mono">
                  {u.phone} {u.email ? `• ${u.email}` : ''}
                </p>
              </div>
            ),
          },
          {
            key: 'status',
            header: t.common.status,
            render: (u) => <StatusBadge status={u.moderationStatus} />,
          },
          {
            key: 'verification',
            header: locale === 'ar' ? 'التوثيق' : 'Verification',
            render: (u) => (
              <StatusBadge
                status={u.ownedAccounts[0]?.verificationStatus || 'pending'}
              />
            ),
          },
          {
            key: 'counts',
            header: locale === 'ar' ? 'الإعلانات / البلاغات' : 'Listings / Reports',
            render: (u) => (
              <span className="text-xs">
                {u.ownedAccounts.reduce((s, a) => s + a._count.listings, 0)} /{' '}
                {u._count.reportsFiled}
              </span>
            ),
          },
          {
            key: 'created',
            header: t.common.createdAt,
            render: (u) => (
              <span className="text-xs text-muted-foreground">
                {new Date(u.createdAt).toLocaleDateString()}
              </span>
            ),
          },
          {
            key: 'actions',
            header: t.common.actions,
            render: (u) => (
              <div className="flex flex-wrap gap-1.5">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setSelectedUserId(u.id)}
                >
                  <Eye className="h-3.5 w-3.5" />
                </Button>
                <PermissionGate permission="users.suspend">
                  {u.moderationStatus === 'suspended' ? (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        setConfirmState({ type: 'unsuspend', user: u })
                      }
                    >
                      <PlayCircle className="h-3.5 w-3.5" />
                    </Button>
                  ) : (
                    u.moderationStatus === 'active' && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() =>
                          setConfirmState({ type: 'suspend', user: u })
                        }
                      >
                        <PauseCircle className="h-3.5 w-3.5 text-amber-600" />
                      </Button>
                    )
                  )}
                </PermissionGate>
                <PermissionGate permission="users.ban">
                  {u.moderationStatus === 'banned' ? (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setConfirmState({ type: 'unban', user: u })}
                    >
                      <ShieldCheck className="h-3.5 w-3.5 text-emerald-600" />
                    </Button>
                  ) : (
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => setConfirmState({ type: 'ban', user: u })}
                    >
                      <Ban className="h-3.5 w-3.5" />
                    </Button>
                  )}
                </PermissionGate>
              </div>
            ),
          },
        ]}
      />

      <Modal
        open={Boolean(selectedUserId)}
        onClose={() => setSelectedUserId(null)}
        title={detailQuery.data?.user.fullName || 'User Details'}
        maxWidth="max-w-3xl"
      >
        {detailQuery.data && (
          <div className="space-y-5 text-sm">
            <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-muted/30 p-3">
              <div>
                <p className="font-mono text-xs">{detailQuery.data.user.phone}</p>
                <p className="text-xs text-muted-foreground">
                  Active mobile sessions: {detailQuery.data.activeSessionCount}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <StatusBadge status={detailQuery.data.user.moderationStatus} />
                <PermissionGate permission="users.suspend">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setConfirmState({
                        type: 'revoke',
                        user: detailQuery.data!.user,
                      })
                    }
                  >
                    <KeyRound className="h-3.5 w-3.5" />
                    Revoke Sessions
                  </Button>
                </PermissionGate>
              </div>
            </div>

            <div>
              <h4 className="mb-2 font-semibold">
                Listings ({detailQuery.data.listings.length})
              </h4>
              <div className="max-h-40 overflow-y-auto rounded-lg border divide-y">
                {detailQuery.data.listings.length === 0 ? (
                  <p className="p-3 text-xs text-muted-foreground">No listings</p>
                ) : (
                  detailQuery.data.listings.map((l) => (
                    <div
                      key={l.id}
                      className="flex items-center justify-between p-2.5 text-xs"
                    >
                      <span>{l.title}</span>
                      <div className="flex gap-1.5">
                        <StatusBadge status={l.moderationStatus} />
                        <StatusBadge status={l.publicationStatus} />
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            <div>
              <h4 className="mb-2 font-semibold">
                Reports (Filed: {detailQuery.data.user.reportsFiled.length} • Against:{' '}
                {detailQuery.data.reportsAgainst.length})
              </h4>
            </div>

            <PermissionGate permission="users.update">
              <div className="space-y-2 border-t pt-3">
                <h4 className="font-semibold">Internal Notes</h4>
                <div className="space-y-1.5 max-h-32 overflow-y-auto">
                  {(detailQuery.data.user.internalNotes ?? []).map((n) => (
                    <div
                      key={n.id}
                      className="rounded border bg-muted/30 p-2 text-xs"
                    >
                      <span className="font-semibold">{n.authorName}:</span>{' '}
                      {n.note}
                    </div>
                  ))}
                </div>
                <div className="flex gap-2">
                  <Textarea
                    value={noteInput}
                    onChange={(e) => setNoteInput(e.target.value)}
                    placeholder="Add internal support/moderation note..."
                    className="min-h-[56px]"
                  />
                  <Button
                    disabled={!noteInput.trim() || noteMutation.isPending}
                    onClick={() =>
                      noteMutation.mutate({
                        userId: detailQuery.data!.user.id,
                        note: noteInput,
                      })
                    }
                  >
                    Add Note
                  </Button>
                </div>
              </div>
            </PermissionGate>

            <div>
              <h4 className="mb-2 font-semibold">Account History</h4>
              <div className="max-h-36 overflow-y-auto rounded-lg border divide-y text-xs">
                {detailQuery.data.accountHistory.map((h) => (
                  <div key={h.id} className="flex justify-between p-2">
                    <span className="font-mono">{h.action}</span>
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
        open={Boolean(confirmState)}
        onClose={() => setConfirmState(null)}
        title={
          confirmState
            ? `${confirmState.type.toUpperCase()} — ${confirmState.user.fullName}`
            : ''
        }
        description={
          confirmState?.type === 'ban'
            ? 'Banning permanently disables login, revokes all mobile sessions, and hides active listings.'
            : 'Please confirm this administrative action.'
        }
        requireReason={
          confirmState?.type === 'suspend' || confirmState?.type === 'ban'
        }
        destructive={
          confirmState?.type === 'ban' || confirmState?.type === 'suspend'
        }
        loading={actionMutation.isPending}
        onConfirm={(reason) => {
          if (!confirmState) return;
          actionMutation.mutate({
            type: confirmState.type,
            userId: confirmState.user.id,
            reason,
          });
        }}
      />
    </div>
  );
}
