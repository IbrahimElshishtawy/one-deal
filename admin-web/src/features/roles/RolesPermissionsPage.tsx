import React, { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Copy, Edit, Plus, Shield, Trash2 } from 'lucide-react';
import { apiClient, ApiClientError } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import {
  Button,
  Card,
  Input,
  LoadingState,
  Modal,
  StatusBadge,
} from '../../components/ui';

interface RoleItem {
  id: number;
  name: string;
  description: string | null;
  isSystem: boolean;
  permissions: string[];
  _count?: { staffUsers: number };
}

interface PermissionCatalogItem {
  key: string;
  module: string;
  labelEn: string;
  labelAr: string;
  isSensitive?: boolean;
}

export function RolesPermissionsPage() {
  const { t, locale } = useI18n();
  const qc = useQueryClient();

  const [modalOpen, setModalOpen] = useState(false);
  const [editingRole, setEditingRole] = useState<RoleItem | null>(null);
  const [cloneSource, setCloneSource] = useState<RoleItem | null>(null);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [selectedPerms, setSelectedPerms] = useState<Set<string>>(new Set());
  const [errMsg, setErrMsg] = useState<string | null>(null);

  const rolesQuery = useQuery({
    queryKey: ['admin-roles'],
    queryFn: ({ signal }) =>
      apiClient.get<RoleItem[]>('/admin/staff/roles', undefined, { signal }),
  });

  const catalogQuery = useQuery({
    queryKey: ['admin-permissions-catalog'],
    queryFn: ({ signal }) =>
      apiClient.get<{ permissions: PermissionCatalogItem[] }>(
        '/admin/staff/permissions',
        undefined,
        { signal },
      ),
  });

  const groupedCatalog = useMemo(() => {
    const groups = new Map<string, PermissionCatalogItem[]>();
    for (const p of catalogQuery.data?.permissions ?? []) {
      const arr = groups.get(p.module) ?? [];
      arr.push(p);
      groups.set(p.module, arr);
    }
    return Array.from(groups.entries());
  }, [catalogQuery.data]);

  const saveMutation = useMutation({
    mutationFn: () => {
      if (cloneSource) {
        return apiClient.post(`/admin/staff/roles/${cloneSource.id}/clone`, {
          name,
          description,
        });
      }
      if (editingRole) {
        return apiClient.patch(`/admin/staff/roles/${editingRole.id}`, {
          name,
          description,
          permissions: Array.from(selectedPerms),
        });
      }
      return apiClient.post('/admin/staff/roles', {
        name,
        description,
        permissions: Array.from(selectedPerms),
      });
    },
    onSuccess: () => {
      setModalOpen(false);
      setEditingRole(null);
      setCloneSource(null);
      void qc.invalidateQueries({ queryKey: ['admin-roles'] });
    },
    onError: (err) =>
      setErrMsg(err instanceof ApiClientError ? err.message : 'Save failed'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiClient.delete(`/admin/staff/roles/${id}`),
    onSuccess: () => void qc.invalidateQueries({ queryKey: ['admin-roles'] }),
    onError: (err) =>
      setErrMsg(err instanceof ApiClientError ? err.message : 'Delete failed'),
  });

  if (rolesQuery.isLoading) return <LoadingState />;

  const togglePerm = (key: string) => {
    setSelectedPerms((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">{t.nav.roles}</h2>
        <PermissionGate permission="roles.create">
          <Button
            onClick={() => {
              setErrMsg(null);
              setEditingRole(null);
              setCloneSource(null);
              setName('');
              setDescription('');
              setSelectedPerms(new Set());
              setModalOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            Create Role
          </Button>
        </PermissionGate>
      </div>

      {errMsg && (
        <div className="rounded-lg border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive">
          {errMsg}
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {(rolesQuery.data ?? []).map((role) => (
          <Card key={role.id} className="p-5 flex flex-col justify-between gap-4">
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Shield className="h-4 w-4 text-primary" />
                  <h3 className="font-bold font-mono text-sm">{role.name}</h3>
                </div>
                <StatusBadge status={role.isSystem ? 'active' : 'draft'} />
              </div>
              <p className="text-xs text-muted-foreground">
                {role.description || 'Custom administrative role'}
              </p>
              <p className="text-xs">
                <strong>{role.permissions.length}</strong> permissions •{' '}
                <strong>{role._count?.staffUsers ?? 0}</strong> staff assigned
              </p>
              <div className="flex flex-wrap gap-1 max-h-24 overflow-y-auto pt-1">
                {role.permissions.slice(0, 12).map((p) => (
                  <span
                    key={p}
                    className="rounded bg-muted px-1.5 py-0.5 text-[10px] font-mono"
                  >
                    {p}
                  </span>
                ))}
                {role.permissions.length > 12 && (
                  <span className="text-[10px] text-muted-foreground">
                    +{role.permissions.length - 12} more
                  </span>
                )}
              </div>
            </div>

            <div className="flex flex-wrap gap-2 border-t pt-3">
              <PermissionGate permission="roles.update">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setErrMsg(null);
                    setCloneSource(null);
                    setEditingRole(role);
                    setName(role.name);
                    setDescription(role.description || '');
                    setSelectedPerms(new Set(role.permissions));
                    setModalOpen(true);
                  }}
                >
                  <Edit className="h-3.5 w-3.5" />
                  Edit
                </Button>
              </PermissionGate>
              <PermissionGate permission="roles.create">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setErrMsg(null);
                    setEditingRole(null);
                    setCloneSource(role);
                    setName(`${role.name}_copy`);
                    setDescription(`Cloned from ${role.name}`);
                    setSelectedPerms(new Set(role.permissions));
                    setModalOpen(true);
                  }}
                >
                  <Copy className="h-3.5 w-3.5" />
                  Clone
                </Button>
              </PermissionGate>
              <PermissionGate permission="roles.delete">
                {!role.isSystem && (
                  <Button
                    size="sm"
                    variant="destructive"
                    onClick={() => deleteMutation.mutate(role.id)}
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                )}
              </PermissionGate>
            </div>
          </Card>
        ))}
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={
          cloneSource
            ? `Clone Role: ${cloneSource.name}`
            : editingRole
              ? `Edit Role: ${editingRole.name}`
              : 'Create Role'
        }
        maxWidth="max-w-4xl"
      >
        <div className="space-y-4 text-sm">
          {errMsg && (
            <div className="rounded border border-destructive/40 bg-destructive/10 p-2 text-xs text-destructive">
              {errMsg}
            </div>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            <Input
              placeholder="Role slug (e.g. regional_moderator)"
              value={name}
              disabled={Boolean(editingRole?.isSystem)}
              onChange={(e) => setName(e.target.value)}
            />
            <Input
              placeholder="Description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>

          {!cloneSource && (
            <div className="space-y-3 max-h-[50vh] overflow-y-auto rounded-lg border p-3">
              {groupedCatalog.map(([mod, items]) => (
                <div key={mod} className="space-y-1.5 border-b pb-2 last:border-b-0">
                  <h4 className="text-xs font-bold uppercase text-primary">
                    {mod}
                  </h4>
                  <div className="grid gap-2 sm:grid-cols-2">
                    {items.map((perm) => (
                      <label
                        key={perm.key}
                        className="flex items-start gap-2 rounded border p-2 text-xs hover:bg-muted/40 cursor-pointer"
                      >
                        <input
                          type="checkbox"
                          checked={selectedPerms.has(perm.key)}
                          onChange={() => togglePerm(perm.key)}
                          className="mt-0.5"
                        />
                        <div>
                          <p className="font-medium">
                            {locale === 'ar' ? perm.labelAr : perm.labelEn}{' '}
                            {perm.isSensitive && (
                              <span className="text-[10px] text-rose-600 font-bold">
                                (Sensitive)
                              </span>
                            )}
                          </p>
                          <p className="font-mono text-[10px] text-muted-foreground">
                            {perm.key}
                          </p>
                        </div>
                      </label>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}

          <div className="flex justify-end gap-2">
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
    </div>
  );
}
