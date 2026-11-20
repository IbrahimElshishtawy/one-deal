import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Edit, Plus, Sliders } from 'lucide-react';
import { apiClient } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import {
  Button,
  Card,
  Input,
  LoadingState,
  Modal,
  Select,
  StatusBadge,
} from '../../components/ui';

interface CategoryField {
  id: string;
  fieldKey: string;
  labelAr: string;
  labelEn: string;
  fieldType: string;
  isRequired: boolean;
  isFilterable: boolean;
  sortOrder: number;
  isActive: boolean;
}

interface CategoryItem {
  id: string;
  parentId: string | null;
  nameAr: string;
  nameEn: string;
  slug: string;
  sortOrder: number;
  isActive: boolean;
  _count: { listings: number; fields: number };
  fields: CategoryField[];
  children?: CategoryItem[];
}

export function CategoriesPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [createOpen, setCreateOpen] = useState(false);
  const [editingCat, setEditingCat] = useState<CategoryItem | null>(null);
  const [fieldsCat, setFieldsCat] = useState<CategoryItem | null>(null);

  const [formState, setFormState] = useState({
    slug: '',
    nameAr: '',
    nameEn: '',
    parentId: '',
    sortOrder: 0,
    isActive: true,
  });

  const [fieldForm, setFieldForm] = useState({
    fieldKey: '',
    labelAr: '',
    labelEn: '',
    fieldType: 'text',
    isRequired: false,
    isFilterable: true,
    sortOrder: 0,
  });

  const query = useQuery({
    queryKey: ['admin-categories'],
    queryFn: ({ signal }) =>
      apiClient.get<CategoryItem[]>('/admin/categories', undefined, { signal }),
  });

  const saveCategoryMutation = useMutation({
    mutationFn: () => {
      if (editingCat) {
        return apiClient.patch(`/admin/categories/${editingCat.id}`, {
          nameAr: formState.nameAr,
          nameEn: formState.nameEn,
          sortOrder: Number(formState.sortOrder),
          isActive: formState.isActive,
        });
      }
      return apiClient.post('/admin/categories', {
        slug: formState.slug,
        nameAr: formState.nameAr,
        nameEn: formState.nameEn,
        parentId: formState.parentId || undefined,
        sortOrder: Number(formState.sortOrder),
        isActive: formState.isActive,
      });
    },
    onSuccess: () => {
      setCreateOpen(false);
      setEditingCat(null);
      void qc.invalidateQueries({ queryKey: ['admin-categories'] });
    },
  });

  const upsertFieldMutation = useMutation({
    mutationFn: () =>
      apiClient.post(`/admin/categories/${fieldsCat!.id}/fields`, {
        ...fieldForm,
        sortOrder: Number(fieldForm.sortOrder),
      }),
    onSuccess: () => {
      setFieldForm({
        fieldKey: '',
        labelAr: '',
        labelEn: '',
        fieldType: 'text',
        isRequired: false,
        isFilterable: true,
        sortOrder: 0,
      });
      void qc.invalidateQueries({ queryKey: ['admin-categories'] });
    },
  });

  const toggleFieldActive = useMutation({
    mutationFn: ({
      catId,
      fieldId,
      isActive,
    }: {
      catId: string;
      fieldId: string;
      isActive: boolean;
    }) =>
      apiClient.patch(`/admin/categories/${catId}/fields/${fieldId}`, {
        isActive,
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['admin-categories'] });
    },
  });

  if (query.isLoading) return <LoadingState />;

  const roots = query.data ?? [];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">{t.nav.categories}</h2>
        <PermissionGate permission="categories.create">
          <Button
            onClick={() => {
              setEditingCat(null);
              setFormState({
                slug: '',
                nameAr: '',
                nameEn: '',
                parentId: '',
                sortOrder: 0,
                isActive: true,
              });
              setCreateOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            {t.common.create}
          </Button>
        </PermissionGate>
      </div>

      <div className="space-y-3">
        {roots.map((root) => (
          <Card key={root.id} className="p-4 space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <h3 className="font-bold">
                  {locale === 'ar' ? root.nameAr : root.nameEn}
                </h3>
                <p className="text-xs text-muted-foreground font-mono">
                  {root.slug} • Order: {root.sortOrder} • Listings:{' '}
                  {root._count.listings}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <StatusBadge status={root.isActive ? 'active' : 'inactive'} />
                <PermissionGate permission="categories.update">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      setEditingCat(root);
                      setFormState({
                        slug: root.slug,
                        nameAr: root.nameAr,
                        nameEn: root.nameEn,
                        parentId: '',
                        sortOrder: root.sortOrder,
                        isActive: root.isActive,
                      });
                      setCreateOpen(true);
                    }}
                  >
                    <Edit className="h-3.5 w-3.5" />
                  </Button>
                </PermissionGate>
              </div>
            </div>

            {root.children && root.children.length > 0 && (
              <div className="grid gap-2 border-t pt-3 md:grid-cols-2">
                {root.children.map((sub) => (
                  <div
                    key={sub.id}
                    className="flex items-center justify-between rounded-lg border bg-muted/30 p-3 text-xs"
                  >
                    <div>
                      <p className="font-semibold">
                        {locale === 'ar' ? sub.nameAr : sub.nameEn}
                      </p>
                      <p className="text-muted-foreground font-mono">
                        {sub.slug} • Fields: {sub._count.fields} • Listings:{' '}
                        {sub._count.listings}
                      </p>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <StatusBadge
                        status={sub.isActive ? 'active' : 'inactive'}
                      />
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setFieldsCat(sub)}
                        title="Dynamic Attributes"
                      >
                        <Sliders className="h-3.5 w-3.5" />
                      </Button>
                      <PermissionGate permission="categories.update">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => {
                            setEditingCat(sub);
                            setFormState({
                              slug: sub.slug,
                              nameAr: sub.nameAr,
                              nameEn: sub.nameEn,
                              parentId: sub.parentId || '',
                              sortOrder: sub.sortOrder,
                              isActive: sub.isActive,
                            });
                            setCreateOpen(true);
                          }}
                        >
                          <Edit className="h-3.5 w-3.5" />
                        </Button>
                      </PermissionGate>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        ))}
      </div>

      <Modal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title={editingCat ? 'Edit Category' : 'Create Category'}
      >
        <div className="space-y-3 text-sm">
          {!editingCat && (
            <>
              <div>
                <label className="mb-1 block text-xs font-medium">Slug</label>
                <Input
                  value={formState.slug}
                  onChange={(e) =>
                    setFormState((s) => ({ ...s, slug: e.target.value }))
                  }
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium">
                  Parent Category (Optional)
                </label>
                <Select
                  value={formState.parentId}
                  onChange={(e) =>
                    setFormState((s) => ({ ...s, parentId: e.target.value }))
                  }
                >
                  <option value="">Root Category</option>
                  {roots.map((r) => (
                    <option key={r.id} value={r.id}>
                      {r.nameEn} / {r.nameAr}
                    </option>
                  ))}
                </Select>
              </div>
            </>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-medium">
                Arabic Name
              </label>
              <Input
                value={formState.nameAr}
                onChange={(e) =>
                  setFormState((s) => ({ ...s, nameAr: e.target.value }))
                }
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium">
                English Name
              </label>
              <Input
                value={formState.nameEn}
                onChange={(e) =>
                  setFormState((s) => ({ ...s, nameEn: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-medium">Sort Order</label>
              <Input
                type="number"
                value={formState.sortOrder}
                onChange={(e) =>
                  setFormState((s) => ({
                    ...s,
                    sortOrder: Number(e.target.value),
                  }))
                }
              />
            </div>
            <label className="flex items-center gap-2 pt-6 text-xs font-medium">
              <input
                type="checkbox"
                checked={formState.isActive}
                onChange={(e) =>
                  setFormState((s) => ({ ...s, isActive: e.target.checked }))
                }
              />
              Active
            </label>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              {t.common.cancel}
            </Button>
            <Button
              onClick={() => saveCategoryMutation.mutate()}
              disabled={saveCategoryMutation.isPending}
            >
              {t.common.save}
            </Button>
          </div>
        </div>
      </Modal>

      <Modal
        open={Boolean(fieldsCat)}
        onClose={() => setFieldsCat(null)}
        title={`Dynamic Attributes — ${fieldsCat?.nameEn || ''}`}
        maxWidth="max-w-3xl"
      >
        {fieldsCat && (
          <div className="space-y-4 text-sm">
            <div className="divide-y rounded-lg border">
              {(
                roots
                  .flatMap((r) => [r, ...(r.children ?? [])])
                  .find((c) => c.id === fieldsCat.id)?.fields ?? []
              ).map((f) => (
                <div
                  key={f.id}
                  className="flex flex-wrap items-center justify-between gap-2 p-2.5 text-xs"
                >
                  <div>
                    <span className="font-mono font-semibold">{f.fieldKey}</span>{' '}
                    ({f.fieldType}) — {f.labelAr} / {f.labelEn}
                    {f.isRequired && ' • Required'}
                    {f.isFilterable && ' • Filterable'}
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusBadge status={f.isActive ? 'active' : 'inactive'} />
                    <PermissionGate permission="categories.update">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() =>
                          toggleFieldActive.mutate({
                            catId: fieldsCat.id,
                            fieldId: f.id,
                            isActive: !f.isActive,
                          })
                        }
                      >
                        {f.isActive ? 'Deactivate' : 'Activate'}
                      </Button>
                    </PermissionGate>
                  </div>
                </div>
              ))}
            </div>

            <PermissionGate permission="categories.update">
              <div className="rounded-lg border bg-muted/30 p-3 space-y-2">
                <h4 className="text-xs font-semibold">Add / Upsert Field</h4>
                <div className="grid gap-2 sm:grid-cols-3">
                  <Input
                    placeholder="fieldKey (e.g. rooms)"
                    value={fieldForm.fieldKey}
                    onChange={(e) =>
                      setFieldForm((s) => ({ ...s, fieldKey: e.target.value }))
                    }
                  />
                  <Input
                    placeholder="Label AR"
                    value={fieldForm.labelAr}
                    onChange={(e) =>
                      setFieldForm((s) => ({ ...s, labelAr: e.target.value }))
                    }
                  />
                  <Input
                    placeholder="Label EN"
                    value={fieldForm.labelEn}
                    onChange={(e) =>
                      setFieldForm((s) => ({ ...s, labelEn: e.target.value }))
                    }
                  />
                </div>
                <div className="flex flex-wrap items-center gap-3">
                  <Select
                    value={fieldForm.fieldType}
                    onChange={(e) =>
                      setFieldForm((s) => ({ ...s, fieldType: e.target.value }))
                    }
                    className="w-36"
                  >
                    <option value="text">text</option>
                    <option value="number">number</option>
                    <option value="select">select</option>
                    <option value="multi_select">multi_select</option>
                    <option value="boolean">boolean</option>
                  </Select>
                  <label className="flex items-center gap-1.5 text-xs">
                    <input
                      type="checkbox"
                      checked={fieldForm.isRequired}
                      onChange={(e) =>
                        setFieldForm((s) => ({
                          ...s,
                          isRequired: e.target.checked,
                        }))
                      }
                    />
                    Required
                  </label>
                  <label className="flex items-center gap-1.5 text-xs">
                    <input
                      type="checkbox"
                      checked={fieldForm.isFilterable}
                      onChange={(e) =>
                        setFieldForm((s) => ({
                          ...s,
                          isFilterable: e.target.checked,
                        }))
                      }
                    />
                    Filterable
                  </label>
                  <Button
                    size="sm"
                    onClick={() => upsertFieldMutation.mutate()}
                    disabled={
                      !fieldForm.fieldKey || upsertFieldMutation.isPending
                    }
                  >
                    Save Field
                  </Button>
                </div>
              </div>
            </PermissionGate>
          </div>
        )}
      </Modal>
    </div>
  );
}
