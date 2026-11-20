import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Check, FileSearch, RotateCcw, X } from 'lucide-react';
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

interface VerificationRow {
  id: string;
  accountId: string;
  documentType: string;
  documentNumber: string | null;
  fileUrl: string | null;
  status: string;
  rejectionReason: string | null;
  createdAt: string;
  reviewedAt: string | null;
  account: {
    id: string;
    displayName: string;
    accountType: string;
    verificationStatus: string;
    owner: { id: string; fullName: string; phone: string };
  };
  reviewedBy?: { id: string; fullName: string; email: string } | null;
}

export function VerificationPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [status, setStatus] = useState('pending');
  const [q, setQ] = useState('');
  const [docModal, setDocModal] = useState<{
    id: string;
    documentType: string;
    documentNumber: string | null;
    fileUrl: string;
    accessedAt: string;
  } | null>(null);
  const [docError, setDocError] = useState<string | null>(null);
  const [decisionTarget, setDecisionTarget] = useState<{
    row: VerificationRow;
    action: 'approve' | 'reject' | 'request_resubmission';
  } | null>(null);

  const query = useQuery({
    queryKey: ['admin-verifications', page, status, q],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: VerificationRow[]; meta: PaginationMeta }>(
        '/admin/moderation/verifications',
        { page, limit: 20, status, q },
        { signal },
      ),
  });

  const decisionMutation = useMutation({
    mutationFn: ({
      id,
      action,
      reason,
    }: {
      id: string;
      action: 'approve' | 'reject' | 'request_resubmission';
      reason: string;
    }) =>
      apiClient.post(`/admin/moderation/verifications/${id}/decision`, {
        action,
        rejectionReason: action === 'approve' ? undefined : reason,
        notes: reason || undefined,
      }),
    onSuccess: () => {
      setDecisionTarget(null);
      void qc.invalidateQueries({ queryKey: ['admin-verifications'] });
    },
  });

  const viewSecureDocument = async (id: string) => {
    setDocError(null);
    try {
      const res = await apiClient.get<{
        id: string;
        documentType: string;
        documentNumber: string | null;
        fileUrl: string;
        accessedAt: string;
      }>(`/admin/moderation/verifications/${id}/document`);
      setDocModal(res);
    } catch (err) {
      setDocError(
        err instanceof ApiClientError
          ? err.message
          : 'Unable to access verification document',
      );
    }
  };

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">{t.nav.verification}</h2>

      {docError && (
        <div className="rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">
          {docError}
        </div>
      )}

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
          <Select
            value={status}
            onChange={(e) => {
              setPage(1);
              setStatus(e.target.value);
            }}
            className="w-44"
          >
            <option value="all">{t.common.all}</option>
            <option value="pending">{t.common.pending}</option>
            <option value="approved">{t.common.approved}</option>
            <option value="rejected">{t.common.rejected}</option>
            <option value="resubmission_required">Resubmission</option>
          </Select>
        }
        columns={[
          {
            key: 'account',
            header: locale === 'ar' ? 'الحساب والمالك' : 'Account & Owner',
            render: (r) => (
              <div>
                <p className="font-medium">{r.account.displayName}</p>
                <p className="text-xs text-muted-foreground">
                  {r.account.owner.fullName} • {r.account.owner.phone}
                </p>
              </div>
            ),
          },
          {
            key: 'doc',
            header: locale === 'ar' ? 'المستند' : 'Document',
            render: (r) => (
              <div className="text-xs">
                <p className="font-medium">{r.documentType}</p>
                <p className="font-mono text-muted-foreground">
                  {r.documentNumber || '-'}
                </p>
              </div>
            ),
          },
          {
            key: 'status',
            header: t.common.status,
            render: (r) => <StatusBadge status={r.status} />,
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
            key: 'actions',
            header: t.common.actions,
            render: (r) => (
              <div className="flex flex-wrap gap-1.5">
                <PermissionGate permission="verification.documents.read">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => void viewSecureDocument(r.id)}
                    title="Audited Document Access"
                  >
                    <FileSearch className="h-3.5 w-3.5" />
                    Doc
                  </Button>
                </PermissionGate>
                {(r.status === 'pending' || r.status === 'resubmission') && (
                  <>
                    <PermissionGate permission="verification.approve">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() =>
                          setDecisionTarget({ row: r, action: 'approve' })
                        }
                      >
                        <Check className="h-3.5 w-3.5 text-emerald-600" />
                      </Button>
                    </PermissionGate>
                    <PermissionGate permission="verification.reject">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() =>
                          setDecisionTarget({
                            row: r,
                            action: 'request_resubmission',
                          })
                        }
                        title="Request Resubmission"
                      >
                        <RotateCcw className="h-3.5 w-3.5 text-amber-600" />
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={() =>
                          setDecisionTarget({ row: r, action: 'reject' })
                        }
                      >
                        <X className="h-3.5 w-3.5" />
                      </Button>
                    </PermissionGate>
                  </>
                )}
              </div>
            ),
          },
        ]}
      />

      <Modal
        open={Boolean(docModal)}
        onClose={() => setDocModal(null)}
        title="Audited Verification Document Access"
      >
        {docModal && (
          <div className="space-y-3 text-sm">
            <div className="rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 text-xs">
              This document view was recorded in the security audit log at{' '}
              {new Date(docModal.accessedAt).toLocaleString()}.
            </div>
            <p>
              <strong>Type:</strong> {docModal.documentType}
            </p>
            <p>
              <strong>Number:</strong>{' '}
              <span className="font-mono">{docModal.documentNumber || '-'}</span>
            </p>
            <p className="break-all">
              <strong>File URL:</strong>{' '}
              <a
                href={docModal.fileUrl}
                target="_blank"
                rel="noreferrer"
                className="text-primary underline"
              >
                {docModal.fileUrl}
              </a>
            </p>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={Boolean(decisionTarget)}
        onClose={() => setDecisionTarget(null)}
        title={
          decisionTarget
            ? `${decisionTarget.action.toUpperCase()} — ${decisionTarget.row.account.displayName}`
            : ''
        }
        description="This updates the seller account's live verification badge in Deal One."
        requireReason={decisionTarget?.action !== 'approve'}
        destructive={decisionTarget?.action === 'reject'}
        loading={decisionMutation.isPending}
        onConfirm={(reason) => {
          if (!decisionTarget) return;
          decisionMutation.mutate({
            id: decisionTarget.row.id,
            action: decisionTarget.action,
            reason,
          });
        }}
      />
    </div>
  );
}
