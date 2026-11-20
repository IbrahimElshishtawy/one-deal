import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Archive, Edit, Eye, Globe, History, Plus } from 'lucide-react';
import { apiClient } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import { DataTable } from '../../components/DataTable';
import {
  Button,
  Input,
  Modal,
  Select,
  StatusBadge,
  Textarea,
} from '../../components/ui';

interface CmsItem {
  id: string;
  type: 'banner' | 'home_section' | 'page' | 'faq' | 'terms' | 'privacy';
  slug: string;
  titleAr: string;
  titleEn: string;
  bodyAr: string | null;
  bodyEn: string | null;
  imageUrl: string | null;
  targetUrl: string | null;
  placement: string | null;
  sortOrder: number;
  status: string;
  isActive: boolean;
  startsAt?: string | null;
  endsAt?: string | null;
  revisions: Array<{
    version: number;
    savedAt: string;
    titleEn: string;
    status: string;
  }>;
  updatedAt: string;
}

export function CmsPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [q, setQ] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<CmsItem | null>(null);
  const [previewItem, setPreviewItem] = useState<CmsItem | null>(null);

  const [form, setForm] = useState({
    type: 'banner' as CmsItem['type'],
    slug: '',
    titleAr: '',
    titleEn: '',
    bodyAr: '',
    bodyEn: '',
    imageUrl: '',
    targetUrl: '',
    placement: 'home_hero',
    sortOrder: 0,
    status: 'draft',
    startsAt: '',
    endsAt: '',
  });

  const query = useQuery({
    queryKey: ['admin-cms', typeFilter, statusFilter, q],
    queryFn: ({ signal }) =>
      apiClient.get<CmsItem[]>(
        '/admin/cms',
        { type: typeFilter, status: statusFilter, q },
        { signal },
      ),
  });

  const saveMutation = useMutation({
    mutationFn: () => {
      const schedulePayload = {
        startsAt: form.startsAt ? new Date(form.startsAt).toISOString() : undefined,
        endsAt: form.endsAt ? new Date(form.endsAt).toISOString() : undefined,
      };
      if (editing) {
        return apiClient.patch(`/admin/cms/${editing.id}`, {
          titleAr: form.titleAr,
          titleEn: form.titleEn,
          bodyAr: form.bodyAr || null,
          bodyEn: form.bodyEn || null,
          imageUrl: form.imageUrl || null,
          targetUrl: form.targetUrl || null,
          placement: form.placement || null,
          sortOrder: Number(form.sortOrder),
          status: form.status,
          ...schedulePayload,
        });
      }
      return apiClient.post('/admin/cms', {
        ...form,
        sortOrder: Number(form.sortOrder),
        ...schedulePayload,
      });
    },
    onSuccess: () => {
      setModalOpen(false);
      setEditing(null);
      void qc.invalidateQueries({ queryKey: ['admin-cms'] });
    },
  });

  const statusAction = useMutation({
    mutationFn: ({
      id,
      action,
    }: {
      id: string;
      action: 'publish' | 'unpublish' | 'archive';
    }) => apiClient.post(`/admin/cms/${id}/${action}`),
    onSuccess: () => void qc.invalidateQueries({ queryKey: ['admin-cms'] }),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">{t.nav.cms}</h2>
        <PermissionGate permission="cms.manage">
          <Button
            onClick={() => {
              setEditing(null);
              setForm({
                type: 'banner',
                slug: '',
                titleAr: '',
                titleEn: '',
                bodyAr: '',
                bodyEn: '',
                imageUrl: '',
                targetUrl: '',
                placement: 'home_hero',
                sortOrder: 0,
                status: 'draft',
                startsAt: '',
                endsAt: '',
              });
              setModalOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            New CMS Item
          </Button>
        </PermissionGate>
      </div>

      <DataTable
        rowKey={(r) => r.id}
        data={query.data ?? []}
        isLoading={query.isLoading}
        search={q}
        onSearchChange={setQ}
        filters={
          <div className="flex gap-2">
            <Select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="w-36"
            >
              <option value="all">{t.common.all}</option>
              <option value="banner">banner</option>
              <option value="home_section">home_section</option>
              <option value="page">page</option>
              <option value="faq">faq</option>
              <option value="terms">terms</option>
              <option value="privacy">privacy</option>
            </Select>
            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-36"
            >
              <option value="all">{t.common.all}</option>
              <option value="draft">draft</option>
              <option value="scheduled">scheduled</option>
              <option value="published">published</option>
              <option value="archived">archived</option>
            </Select>
          </div>
        }
        columns={[
          {
            key: 'title',
            header: 'Content',
            render: (c) => (
              <div>
                <p className="font-medium">
                  {locale === 'ar' ? c.titleAr : c.titleEn}
                </p>
                <p className="text-xs font-mono text-muted-foreground">
                  {c.type} • /{c.slug}
                </p>
              </div>
            ),
          },
          {
            key: 'status',
            header: t.common.status,
            render: (c) => <StatusBadge status={c.status} />,
          },
          {
            key: 'revisions',
            header: 'Revisions',
            render: (c) => (
              <span className="inline-flex items-center gap-1 text-xs">
                <History className="h-3.5 w-3.5" />
                {c.revisions?.length ?? 0}
              </span>
            ),
          },
          {
            key: 'actions',
            header: t.common.actions,
            render: (c) => (
              <div className="flex flex-wrap gap-1.5">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setPreviewItem(c)}
                >
                  <Eye className="h-3.5 w-3.5" />
                </Button>
                <PermissionGate permission="cms.manage">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      setEditing(c);
                      setForm({
                        type: c.type,
                        slug: c.slug,
                        titleAr: c.titleAr,
                        titleEn: c.titleEn,
                        bodyAr: c.bodyAr || '',
                        bodyEn: c.bodyEn || '',
                        imageUrl: c.imageUrl || '',
                        targetUrl: c.targetUrl || '',
                        placement: c.placement || '',
                        sortOrder: c.sortOrder,
                        status: c.status,
                        startsAt: c.startsAt ? c.startsAt.slice(0, 16) : '',
                        endsAt: c.endsAt ? c.endsAt.slice(0, 16) : '',
                      });
                      setModalOpen(true);
                    }}
                  >
                    <Edit className="h-3.5 w-3.5" />
                  </Button>
                  {c.status !== 'published' ? (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        statusAction.mutate({ id: c.id, action: 'publish' })
                      }
                    >
                      <Globe className="h-3.5 w-3.5 text-emerald-600" />
                      Publish
                    </Button>
                  ) : (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        statusAction.mutate({ id: c.id, action: 'unpublish' })
                      }
                    >
                      Unpublish
                    </Button>
                  )}
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      statusAction.mutate({ id: c.id, action: 'archive' })
                    }
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
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editing ? `Edit CMS — ${editing.slug}` : 'Create CMS Content'}
      >
        <div className="space-y-3 text-sm">
          {!editing && (
            <div className="grid gap-3 sm:grid-cols-2">
              <Select
                value={form.type}
                onChange={(e) =>
                  setForm((f) => ({ ...f, type: e.target.value as any }))
                }
              >
                <option value="banner">banner</option>
                <option value="home_section">home_section</option>
                <option value="page">page</option>
                <option value="faq">faq</option>
                <option value="terms">terms</option>
                <option value="privacy">privacy</option>
              </Select>
              <Input
                placeholder="slug (e.g. summer-promo)"
                value={form.slug}
                onChange={(e) =>
                  setForm((f) => ({ ...f, slug: e.target.value }))
                }
              />
            </div>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            <Input
              placeholder="Title (AR)"
              value={form.titleAr}
              onChange={(e) =>
                setForm((f) => ({ ...f, titleAr: e.target.value }))
              }
            />
            <Input
              placeholder="Title (EN)"
              value={form.titleEn}
              onChange={(e) =>
                setForm((f) => ({ ...f, titleEn: e.target.value }))
              }
            />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <Textarea
              placeholder="Body (AR)"
              value={form.bodyAr}
              onChange={(e) =>
                setForm((f) => ({ ...f, bodyAr: e.target.value }))
              }
            />
            <Textarea
              placeholder="Body (EN)"
              value={form.bodyEn}
              onChange={(e) =>
                setForm((f) => ({ ...f, bodyEn: e.target.value }))
              }
            />
          </div>
          <div className="grid gap-3 sm:grid-cols-3">
            <Input
              placeholder="Image URL"
              value={form.imageUrl}
              onChange={(e) =>
                setForm((f) => ({ ...f, imageUrl: e.target.value }))
              }
            />
            <Input
              placeholder="Target URL"
              value={form.targetUrl}
              onChange={(e) =>
                setForm((f) => ({ ...f, targetUrl: e.target.value }))
              }
            />
            <Input
              type="number"
              placeholder="Sort order"
              value={form.sortOrder}
              onChange={(e) =>
                setForm((f) => ({ ...f, sortOrder: Number(e.target.value) }))
              }
            />
          </div>
          <div className="grid gap-3 sm:grid-cols-3">
            <Select
              value={form.status}
              onChange={(e) =>
                setForm((f) => ({ ...f, status: e.target.value }))
              }
            >
              <option value="draft">draft</option>
              <option value="scheduled">scheduled</option>
              <option value="published">published</option>
              <option value="archived">archived</option>
            </Select>
            <Input
              type="datetime-local"
              title="Starts At (optional)"
              value={form.startsAt}
              onChange={(e) =>
                setForm((f) => ({ ...f, startsAt: e.target.value }))
              }
            />
            <Input
              type="datetime-local"
              title="Ends At (optional)"
              value={form.endsAt}
              onChange={(e) =>
                setForm((f) => ({ ...f, endsAt: e.target.value }))
              }
            />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              {t.common.cancel}
            </Button>
            <Button
              onClick={() => saveMutation.mutate()}
              disabled={saveMutation.isPending}
            >
              {t.common.save}
            </Button>
          </div>
        </div>
      </Modal>

      <Modal
        open={Boolean(previewItem)}
        onClose={() => setPreviewItem(null)}
        title={`Preview & Revisions — ${previewItem?.slug || ''}`}
      >
        {previewItem && (
          <div className="space-y-4 text-sm">
            <div className="rounded-lg border p-3">
              <p className="font-bold">{previewItem.titleAr}</p>
              <p className="text-xs text-muted-foreground mt-1">
                {previewItem.bodyAr}
              </p>
            </div>
            <div className="rounded-lg border p-3">
              <p className="font-bold">{previewItem.titleEn}</p>
              <p className="text-xs text-muted-foreground mt-1">
                {previewItem.bodyEn}
              </p>
            </div>
            <div>
              <h4 className="mb-2 text-xs font-semibold">Revision History</h4>
              <div className="max-h-36 overflow-y-auto rounded border divide-y text-xs">
                {(previewItem.revisions ?? []).length === 0 ? (
                  <p className="p-2 text-muted-foreground">No prior revisions</p>
                ) : (
                  previewItem.revisions.map((r) => (
                    <div key={r.version} className="flex justify-between p-2">
                      <span>
                        v{r.version} — {r.titleEn} ({r.status})
                      </span>
                      <span>{new Date(r.savedAt).toLocaleString()}</span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
