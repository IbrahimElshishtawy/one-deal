import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Edit, KeyRound, Plus, ShieldOff, UserCheck, UserX } from 'lucide-react';
import { apiClient, ApiClientError } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import { DataTable, PaginationMeta } from '../../components/DataTable';
import { Button, Input, Modal, Select, StatusBadge } from '../../components/ui';

interface StaffRow {
  id: string;
  email: string;
  fullName: string;
  department: string | null;
  jobTitle: string | null;
  status: string;
  isActive: boolean;
  mfaEnabled: boolean;
  lastLoginAt: string | null;
  roleId: number;
  role: { id: number; name: string; permissions: string[] };
}

interface RoleOption {
  id: number;
  name: string;
  description: string | null;
  permissions: string[];
}

export function AdminAccountsPage() {
  const { t } = useI18n();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [q, setQ] = useState('');
  const [inviteOpen, setInviteOpen] = useState(false);
  const [editingStaff, setEditingStaff] = useState<StaffRow | null>(null);
  const [errMsg, setErrMsg] = useState<string | null>(null);

  const [inviteForm, setInviteForm] = useState({
    email: '',
    fullName: '',
    password: '',
    department: '',
    jobTitle: '',
    roleId: 0,
  });

  const [editForm, setEditForm] = useState({
    roleId: 0,
    department: '',
    jobTitle: '',
    status: 'active',
  });

  const staffQuery = useQuery({
    queryKey: ['admin-staff-users', page, q],
    queryFn: ({ signal }) =>
      apiClient.get<{ items: StaffRow[]; meta: PaginationMeta }>(
        '/admin/staff',
        { page, limit: 20, q },
        { signal },
      ),
  });

  const rolesQuery = useQuery({
    queryKey: ['admin-staff-roles'],
    queryFn: ({ signal }) =>
      apiClient.get<RoleOption[]>('/admin/staff/roles', undefined, { signal }),
  });

  const inviteMutation = useMutation({
    mutationFn: () =>
      apiClient.post('/admin/staff/invitations', {
        ...inviteForm,
        roleId: Number(inviteForm.roleId),
        password: inviteForm.password || undefined,
      }),
    onSuccess: () => {
      setInviteOpen(false);
      void qc.invalidateQueries({ queryKey: ['admin-staff-users'] });
    },
    onError: (err) =>
      setErrMsg(err instanceof ApiClientError ? err.message : 'Failed'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Record<string, unknown> }) =>
      apiClient.patch(`/admin/staff/${id}`, payload),
    onSuccess: () => {
      setEditingStaff(null);
      void qc.invalidateQueries({ queryKey: ['admin-staff-users'] });
    },
    onError: (err) =>
      setErrMsg(err instanceof ApiClientError ? err.message : 'Update failed'),
  });

  const revokeMutation = useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/admin/staff/${id}/revoke-sessions`),
    onSuccess: () => void qc.invalidateQueries({ queryKey: ['admin-staff-users'] }),
  });

  const resetMfaMutation = useMutation({
    mutationFn: (id: string) => apiClient.post(`/admin/staff/${id}/reset-mfa`),
    onSuccess: () => void qc.invalidateQueries({ queryKey: ['admin-staff-users'] }),
  });

  const roles = rolesQuery.data ?? [];
  const selectedRolePreview = roles.find(
    (r) => r.id === Number(inviteForm.roleId),
  );

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">{t.nav.admins}</h2>
        <PermissionGate permission="admins.create">
          <Button
            onClick={() => {
              setErrMsg(null);
              setInviteForm({
                email: '',
                fullName: '',
                password: '',
                department: '',
                jobTitle: '',
                roleId: roles[0]?.id ?? 1,
              });
              setInviteOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            Invite Admin
          </Button>
        </PermissionGate>
      </div>

      <DataTable
        rowKey={(r) => r.id}
        data={staffQuery.data?.items ?? []}
        meta={staffQuery.data?.meta}
        isLoading={staffQuery.isLoading}
        onPageChange={setPage}
        search={q}
        onSearchChange={(val) => {
          setPage(1);
          setQ(val);
        }}
        columns={[
          {
            key: 'admin',
            header: 'Administrator',
            render: (s) => (
              <div>
                <p className="font-medium">{s.fullName}</p>
                <p className="text-xs font-mono text-muted-foreground">
                  {s.email} {s.department ? `• ${s.department}` : ''}
                </p>
              </div>
            ),
          },
          {
            key: 'role',
            header: 'Role',
            render: (s) => (
              <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
                {s.role.name}
              </span>
            ),
          },
          {
            key: 'status',
            header: t.common.status,
            render: (s) => <StatusBadge status={s.status} />,
          },
          {
            key: 'mfa',
            header: 'MFA',
            render: (s) => (
              <StatusBadge status={s.mfaEnabled ? 'active' : 'pending'} />
            ),
          },
          {
            key: 'actions',
            header: t.common.actions,
            render: (s) => (
              <div className="flex flex-wrap gap-1">
                <PermissionGate permission="admins.update">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      setErrMsg(null);
                      setEditingStaff(s);
                      setEditForm({
                        roleId: s.roleId,
                        department: s.department || '',
                        jobTitle: s.jobTitle || '',
                        status: s.status,
                      });
                    }}
                  >
                    <Edit className="h-3.5 w-3.5" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      updateMutation.mutate({
                        id: s.id,
                        payload: {
                          isActive: !s.isActive,
                          status: s.isActive ? 'suspended' : 'active',
                        },
                      })
                    }
                    title={s.isActive ? 'Suspend' : 'Activate'}
                  >
                    {s.isActive ? (
                      <UserX className="h-3.5 w-3.5 text-amber-600" />
                    ) : (
                      <UserCheck className="h-3.5 w-3.5 text-emerald-600" />
                    )}
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => revokeMutation.mutate(s.id)}
                    title="Revoke All Sessions"
                  >
                    <KeyRound className="h-3.5 w-3.5" />
                  </Button>
                  {s.mfaEnabled && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => resetMfaMutation.mutate(s.id)}
                      title="Reset MFA"
                    >
                      <ShieldOff className="h-3.5 w-3.5 text-rose-600" />
                    </Button>
                  )}
                </PermissionGate>
              </div>
            ),
          },
        ]}
      />

      <Modal
        open={inviteOpen}
        onClose={() => setInviteOpen(false)}
        title="Invite / Create Admin Account"
      >
        <div className="space-y-3 text-sm">
          {errMsg && (
            <div className="rounded border border-destructive/40 bg-destructive/10 p-2 text-xs text-destructive">
              {errMsg}
            </div>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            <Input
              placeholder="Full Name"
              value={inviteForm.fullName}
              onChange={(e) =>
                setInviteForm((f) => ({ ...f, fullName: e.target.value }))
              }
            />
            <Input
              type="email"
              placeholder="Work Email"
              value={inviteForm.email}
              onChange={(e) =>
                setInviteForm((f) => ({ ...f, email: e.target.value }))
              }
            />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <Input
              placeholder="Department"
              value={inviteForm.department}
              onChange={(e) =>
                setInviteForm((f) => ({ ...f, department: e.target.value }))
              }
            />
            <Input
              placeholder="Job Title"
              value={inviteForm.jobTitle}
              onChange={(e) =>
                setInviteForm((f) => ({ ...f, jobTitle: e.target.value }))
              }
            />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <Select
              value={inviteForm.roleId}
              onChange={(e) =>
                setInviteForm((f) => ({
                  ...f,
                  roleId: Number(e.target.value),
                }))
              }
            >
              {roles.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name} ({r.permissions.length} perms)
                </option>
              ))}
            </Select>
            <Input
              type="password"
              placeholder="Initial Password (optional)"
              value={inviteForm.password}
              onChange={(e) =>
                setInviteForm((f) => ({ ...f, password: e.target.value }))
              }
            />
          </div>

          {selectedRolePreview && (
            <div className="rounded-lg border bg-muted/30 p-3 text-xs">
              <p className="font-semibold mb-1">
                Role Permissions Preview ({selectedRolePreview.permissions.length})
              </p>
              <div className="flex flex-wrap gap-1 max-h-24 overflow-y-auto">
                {selectedRolePreview.permissions.map((p) => (
                  <span key={p} className="rounded bg-card px-1.5 py-0.5 font-mono">
                    {p}
                  </span>
                ))}
              </div>
            </div>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" onClick={() => setInviteOpen(false)}>
              {t.common.cancel}
            </Button>
            <Button
              onClick={() => inviteMutation.mutate()}
              disabled={inviteMutation.isPending}
            >
              Create Account
            </Button>
          </div>
        </div>
      </Modal>

      <Modal
        open={Boolean(editingStaff)}
        onClose={() => setEditingStaff(null)}
        title={`Edit Staff — ${editingStaff?.fullName || ''}`}
      >
        {editingStaff && (
          <div className="space-y-3 text-sm">
            {errMsg && (
              <div className="rounded border border-destructive/40 bg-destructive/10 p-2 text-xs text-destructive">
                {errMsg}
              </div>
            )}
            <Select
              value={editForm.roleId}
              onChange={(e) =>
                setEditForm((f) => ({ ...f, roleId: Number(e.target.value) }))
              }
            >
              {roles.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name}
                </option>
              ))}
            </Select>
            <Select
              value={editForm.status}
              onChange={(e) =>
                setEditForm((f) => ({ ...f, status: e.target.value }))
              }
            >
              <option value="active">active</option>
              <option value="suspended">suspended</option>
              <option value="disabled">disabled</option>
            </Select>
            <div className="grid gap-3 sm:grid-cols-2">
              <Input
                placeholder="Department"
                value={editForm.department}
                onChange={(e) =>
                  setEditForm((f) => ({ ...f, department: e.target.value }))
                }
              />
              <Input
                placeholder="Job Title"
                value={editForm.jobTitle}
                onChange={(e) =>
                  setEditForm((f) => ({ ...f, jobTitle: e.target.value }))
                }
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" onClick={() => setEditingStaff(null)}>
                {t.common.cancel}
              </Button>
              <Button
                onClick={() =>
                  updateMutation.mutate({
                    id: editingStaff.id,
                    payload: {
                      roleId: editForm.roleId,
                      status: editForm.status,
                      isActive: editForm.status === 'active',
                      department: editForm.department,
                      jobTitle: editForm.jobTitle,
                    },
                  })
                }
                disabled={updateMutation.isPending}
              >
                {t.common.save}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
