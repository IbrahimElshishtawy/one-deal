import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Archive,
  CheckCircle2,
  Eye,
  EyeOff,
  MessageSquare,
  RotateCcw,
  XCircle,
} from 'lucide-react';
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
} from '../../components/ui';

interface ListingRow {
  id: string;
  title: string;
  price: string;
  currency: string;
  listingKind: string;
  moderationStatus: string;
  publicationStatus: string;
  availabilityStatus: string;
  createdAt: string;
  category: { id: string; nameAr: string; nameEn: string };
  account: { id: string; displayName: string; owner: { fullName: string; phone: string } };
  media: Array<{ id: string; publicUrl: string; thumbnailUrl: string | null }>;
  _count: { reports: number };
}

interface ListingDetailResponse {
  listing: ListingRow & {
    description: string;
    attributes: Record<string, unknown>;
  };
  moderationHistory: Array<{
    id: string;
    action: string;
    reasonCode: string | null;
    notes: string | null;
    createdAt: string;
    staff?: { fullName: string; email: string } | null;
  }>;
}

export function ListingsPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [q, setQ] = useState('');
  const [moderationStatus, setModerationStatus] = useState('all');
  const [publicationStatus, setPublicationStatus] = useState('all');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [confirmAction, setConfirmAction] = useState<{
    action: 'approve' | 'reject' | 'request-changes' | 'hide' | 'restore' | 'archive';
    listing: ListingRow;
  } | null>(null);

  const query = useQuery({
    queryKey: ['admin-listings', page, q, moderationStatus, publicationStatus],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: ListingRow[]; meta: PaginationMeta }>(
        '/admin/listings',
        { page, limit: 20, q, moderationStatus, publicationStatus },
        { signal },
      ),
  });

  const detailQuery = useQuery({
    queryKey: ['admin-listing-detail', selectedId],
    enabled: Boolean(selectedId),
    queryFn: ({ signal }) =>
      apiClient.get<ListingDetailResponse>(
        `/admin/listings/${selectedId}`,
        undefined,
        { signal },
      ),
  });

  const mutation = useMutation({
    mutationFn: async ({
      action,
      id,
      reason,
    }: {
      action: 'approve' | 'reject' | 'request-changes' | 'hide' | 'restore' | 'archive';
      id: string;
      reason: string;
    }) => {
      if (action === 'approve' || action === 'reject' || action === 'request-changes') {
        return apiClient.post(`/admin/listings/${id}/${action}`, {
          notes: reason || undefined,
          reasonCode: action === 'reject' ? 'POLICY_VIOLATION' : undefined,
        });
      }
      return apiClient.patch(`/admin/listings/${id}/${action}`, {
        notes: reason || undefined,
      });
    },
    onSuccess: () => {
      setConfirmAction(null);
      void qc.invalidateQueries({ queryKey: ['admin-listings'] });
      if (selectedId) {
        void qc.invalidateQueries({
          queryKey: ['admin-listing-detail', selectedId],
        });
      }
    },
  });

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">{t.nav.listings}</h2>

      <DataTable
        rowKey={(r) => r.id}
        data={query.data?.items ?? []}
        meta={query.data?.meta}
        isLoading={query.isLoading}
        error={
          query.error instanceof ApiClientError ? query.error.message : null
        }
        onRetry={() => void query.refetch()}
        onPageChange={setPage}
        search={q}
        onSearchChange={(val) => {
          setPage(1);
          setQ(val);
        }}
        filters={
          <div className="flex flex-wrap gap-2">
            <Select
              value={moderationStatus}
              onChange={(e) => {
                setPage(1);
                setModerationStatus(e.target.value);
              }}
              className="w-40"
            >
              <option value="all">Mod: {t.common.all}</option>
              <option value="pending">{t.common.pending}</option>
              <option value="approved">{t.common.approved}</option>
              <option value="rejected">{t.common.rejected}</option>
            </Select>
            <Select
              value={publicationStatus}
              onChange={(e) => {
                setPage(1);
                setPublicationStatus(e.target.value);
              }}
              className="w-40"
            >
              <option value="all">Pub: {t.common.all}</option>
              <option value="published">{t.common.published}</option>
              <option value="hidden">{t.common.hidden}</option>
              <option value="archived">{t.common.archived}</option>
            </Select>
          </div>
        }
        columns={[
          {
            key: 'title',
            header: locale === 'ar' ? 'الإعلان' : 'Listing',
            render: (l) => (
              <div>
                <p className="font-medium line-clamp-1">{l.title}</p>
                <p className="text-xs text-muted-foreground">
                  {locale === 'ar' ? l.category.nameAr : l.category.nameEn} •{' '}
                  {l.account.displayName}
                </p>
              </div>
            ),
          },
          {
            key: 'price',
            header: locale === 'ar' ? 'السعر' : 'Price',
            render: (l) => (
              <span className="font-semibold">
                {Number(l.price).toLocaleString()} {l.currency}
              </span>
            ),
          },
          {
            key: 'moderation',
            header: locale === 'ar' ? 'المراجعة' : 'Moderation',
            render: (l) => <StatusBadge status={l.moderationStatus} />,
          },
          {
            key: 'publication',
            header: locale === 'ar' ? 'النشر' : 'Publication',
            render: (l) => <StatusBadge status={l.publicationStatus} />,
          },
          {
            key: 'actions',
            header: t.common.actions,
            render: (l) => (
              <div className="flex flex-wrap gap-1">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setSelectedId(l.id)}
                >
                  <Eye className="h-3.5 w-3.5" />
                </Button>
                <PermissionGate permission="listings.approve">
                  {l.moderationStatus !== 'approved' && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        setConfirmAction({ action: 'approve', listing: l })
                      }
                      title="Approve"
                    >
                      <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
                    </Button>
                  )}
                  {l.publicationStatus === 'hidden' && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        setConfirmAction({ action: 'restore', listing: l })
                      }
                      title="Restore"
                    >
                      <RotateCcw className="h-3.5 w-3.5" />
                    </Button>
                  )}
                </PermissionGate>
                <PermissionGate permission="listings.reject">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setConfirmAction({ action: 'reject', listing: l })
                    }
                    title="Reject"
                  >
                    <XCircle className="h-3.5 w-3.5 text-rose-600" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setConfirmAction({ action: 'request-changes', listing: l })
                    }
                    title="Request Changes"
                  >
                    <MessageSquare className="h-3.5 w-3.5 text-amber-600" />
                  </Button>
                </PermissionGate>
                <PermissionGate permission="listings.hide">
                  {l.publicationStatus === 'published' && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        setConfirmAction({ action: 'hide', listing: l })
                      }
                      title="Hide"
                    >
                      <EyeOff className="h-3.5 w-3.5" />
                    </Button>
                  )}
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setConfirmAction({ action: 'archive', listing: l })
                    }
                    title="Archive"
                  >
                    <Archive className="h-3.5 w-3.5" />
                  </Button>
                </PermissionGate>
              </div>
            ),
          },
        ]}
      />

      <Modal
        open={Boolean(selectedId)}
        onClose={() => setSelectedId(null)}
        title={detailQuery.data?.listing.title || 'Listing Details'}
        maxWidth="max-w-3xl"
      >
        {detailQuery.data && (
          <div className="space-y-4 text-sm">
            <div className="flex flex-wrap gap-2">
              <StatusBadge status={detailQuery.data.listing.moderationStatus} />
              <StatusBadge status={detailQuery.data.listing.publicationStatus} />
              <StatusBadge status={detailQuery.data.listing.availabilityStatus} />
            </div>

            <p className="text-muted-foreground whitespace-pre-wrap">
              {detailQuery.data.listing.description}
            </p>

            {detailQuery.data.listing.media.length > 0 && (
              <div className="grid grid-cols-3 gap-2">
                {detailQuery.data.listing.media.map((m) => (
                  <img
                    key={m.id}
                    src={m.thumbnailUrl || m.publicUrl}
                    alt="Listing media"
                    className="h-28 w-full rounded-lg border object-cover"
                  />
                ))}
              </div>
            )}

            <div className="rounded-lg border bg-muted/30 p-3 text-xs">
              <p>
                <strong>Owner:</strong>{' '}
                {detailQuery.data.listing.account.owner.fullName} (
                {detailQuery.data.listing.account.owner.phone})
              </p>
              <p className="mt-1">
                <strong>Attributes:</strong>{' '}
                {JSON.stringify(detailQuery.data.listing.attributes)}
              </p>
            </div>

            <div>
              <h4 className="mb-2 font-semibold">Moderation History</h4>
              <div className="max-h-40 overflow-y-auto rounded-lg border divide-y text-xs">
                {detailQuery.data.moderationHistory.length === 0 ? (
                  <p className="p-3 text-muted-foreground">No moderation logs yet.</p>
                ) : (
                  detailQuery.data.moderationHistory.map((h) => (
                    <div key={h.id} className="flex justify-between p-2.5">
                      <div>
                        <span className="font-semibold uppercase">{h.action}</span>{' '}
                        {h.notes && `— ${h.notes}`}
                      </div>
                      <span className="text-muted-foreground">
                        {new Date(h.createdAt).toLocaleString()}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirmAction)}
        onClose={() => setConfirmAction(null)}
        title={
          confirmAction
            ? `${confirmAction.action.toUpperCase()} — ${confirmAction.listing.title}`
            : ''
        }
        description="This updates live marketplace visibility and records an immutable moderation log."
        requireReason={
          confirmAction?.action === 'reject' ||
          confirmAction?.action === 'request-changes'
        }
        destructive={confirmAction?.action === 'reject'}
        loading={mutation.isPending}
        onConfirm={(reason) => {
          if (!confirmAction) return;
          mutation.mutate({
            action: confirmAction.action,
            id: confirmAction.listing.id,
            reason,
          });
        }}
      />
    </div>
  );
}
