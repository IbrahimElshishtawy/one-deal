import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Lock, ShieldAlert } from 'lucide-react';
import { apiClient, ApiClientError } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import { DataTable, PaginationMeta } from '../../components/DataTable';
import {
  Button,
  Card,
  Input,
  Modal,
  Select,
  StatusBadge,
} from '../../components/ui';

interface ConversationOversightRow {
  id: string;
  status: string;
  lastMessageAt: string;
  listing: { id: string; title: string; _count: { reports: number } };
  buyer: { id: string; fullName: string };
  sellerAccount: { id: string; displayName: string };
  _count: { messages: number };
  deliveryStats: { sent: number; delivered: number; read: number };
}

export function MessagingOversightPage() {
  const { t } = useI18n();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [q, setQ] = useState('');
  const [inspectTarget, setInspectTarget] =
    useState<ConversationOversightRow | null>(null);
  const [reason, setReason] = useState('');
  const [messagesData, setMessagesData] = useState<Array<{
    id: string;
    senderUserId: string;
    body: string;
    status: string;
    sentAt: string;
  }> | null>(null);
  const [inspectError, setInspectError] = useState<string | null>(null);

  const query = useQuery({
    queryKey: ['admin-chat-complaints', page, q],
    queryFn: ({ signal }) =>
      apiClient.get<{
        conversations: ConversationOversightRow[];
        relatedComplaints: Array<{
          id: string;
          reason: string;
          status: string;
          createdAt: string;
        }>;
        meta: PaginationMeta;
      }>('/admin/chat/complaints', { page, limit: 20, q }, { signal }),
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      apiClient.patch(`/admin/chat/conversations/${id}/status`, {
        status,
        reason: 'Updated by support/oversight administrator',
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['admin-chat-complaints'] });
    },
  });

  const handleLoadMessages = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inspectTarget) return;
    setInspectError(null);
    try {
      const res = await apiClient.get<{
        items: Array<{
          id: string;
          senderUserId: string;
          body: string;
          status: string;
          sentAt: string;
        }>;
      }>(`/admin/chat/conversations/${inspectTarget.id}/messages`, { reason });
      setMessagesData(res.items);
    } catch (err) {
      setInspectError(
        err instanceof ApiClientError ? err.message : 'Unable to inspect messages',
      );
    }
  };

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-2xl font-bold">{t.nav.messaging}</h2>
        <p className="text-xs text-muted-foreground">
          Privacy-protected technical delivery monitoring and audited complaint resolution.
        </p>
      </div>

      <DataTable
        rowKey={(r) => r.id}
        data={query.data?.conversations ?? []}
        meta={query.data?.meta}
        isLoading={query.isLoading}
        onPageChange={setPage}
        search={q}
        onSearchChange={(val) => {
          setPage(1);
          setQ(val);
        }}
        columns={[
          {
            key: 'listing',
            header: 'Listing & Parties',
            render: (c) => (
              <div>
                <p className="font-medium">{c.listing.title}</p>
                <p className="text-xs text-muted-foreground">
                  {c.buyer.fullName} ↔ {c.sellerAccount.displayName}
                </p>
              </div>
            ),
          },
          {
            key: 'delivery',
            header: 'Technical Delivery',
            render: (c) => (
              <div className="text-xs font-mono">
                Total: {c._count.messages} (sent: {c.deliveryStats.sent}, deliv:{' '}
                {c.deliveryStats.delivered}, read: {c.deliveryStats.read})
              </div>
            ),
          },
          {
            key: 'status',
            header: t.common.status,
            render: (c) => <StatusBadge status={c.status} />,
          },
          {
            key: 'actions',
            header: t.common.actions,
            render: (c) => (
              <div className="flex flex-wrap gap-2">
                <PermissionGate permission="chat.oversight.read">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      setInspectTarget(c);
                      setMessagesData(null);
                      setReason('');
                      setInspectError(null);
                    }}
                  >
                    <Lock className="h-3.5 w-3.5" />
                    Audited View
                  </Button>
                </PermissionGate>
                <PermissionGate permission="messaging.support.resolve">
                  <Select
                    value={c.status}
                    onChange={(e) =>
                      statusMutation.mutate({ id: c.id, status: e.target.value })
                    }
                    className="w-28 h-8 text-xs"
                  >
                    <option value="open">open</option>
                    <option value="closed">closed</option>
                    <option value="archived">archived</option>
                  </Select>
                </PermissionGate>
              </div>
            ),
          },
        ]}
      />

      <Card className="p-4">
        <h3 className="mb-2 text-sm font-semibold">
          Related Messaging & Abuse Reports ({query.data?.relatedComplaints.length ?? 0})
        </h3>
        <div className="divide-y text-xs">
          {(query.data?.relatedComplaints ?? []).map((rep) => (
            <div key={rep.id} className="flex items-center justify-between py-2">
              <span className="capitalize font-medium">{rep.reason}</span>
              <StatusBadge status={rep.status} />
              <span className="text-muted-foreground">
                {new Date(rep.createdAt).toLocaleString()}
              </span>
            </div>
          ))}
        </div>
      </Card>

      <Modal
        open={Boolean(inspectTarget)}
        onClose={() => setInspectTarget(null)}
        title="Privacy-Audited Conversation Inspection"
      >
        <div className="space-y-4 text-sm">
          <div className="flex items-start gap-2 rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 text-xs">
            <ShieldAlert className="h-4 w-4 shrink-0 text-amber-600" />
            <span>
              Viewing private conversation messages requires an explicit ticket/report justification and writes a permanent audit log entry.
            </span>
          </div>

          {!messagesData && (
            <form onSubmit={handleLoadMessages} className="space-y-3">
              <Input
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Enter justification (min 5 chars, e.g. Report #123 scam check)"
                minLength={5}
                required
              />
              {inspectError && (
                <p className="text-xs text-destructive">{inspectError}</p>
              )}
              <Button type="submit">Log Access & View Messages</Button>
            </form>
          )}

          {messagesData && (
            <div className="max-h-72 space-y-2 overflow-y-auto rounded-lg border p-3">
              {messagesData.length === 0 ? (
                <p className="text-xs text-muted-foreground">No messages in conversation.</p>
              ) : (
                messagesData.map((m) => (
                  <div key={m.id} className="rounded border bg-muted/30 p-2 text-xs">
                    <div className="flex justify-between text-muted-foreground">
                      <span className="font-mono">{m.senderUserId.slice(0, 8)}</span>
                      <span>
                        {m.status} • {new Date(m.sentAt).toLocaleString()}
                      </span>
                    </div>
                    <p className="mt-1">{m.body}</p>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
      </Modal>
    </div>
  );
}
