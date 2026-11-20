import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { History, Plus, ToggleLeft, ToggleRight } from 'lucide-react';
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

interface FeatureFlagItem {
  key: string;
  name: string;
  description: string | null;
  isEnabled: boolean;
  environment: string;
  rolloutPercentage: number;
  isSystem: boolean;
  rules: {
    history?: Array<{
      changedAt: string;
      newIsEnabled: boolean;
      environment: string;
    }>;
  };
}

export function FeatureFlagsPage() {
  const { t } = useI18n();
  const qc = useQueryClient();

  const [createOpen, setCreateOpen] = useState(false);
  const [historyFlag, setHistoryFlag] = useState<FeatureFlagItem | null>(null);
  const [form, setForm] = useState({
    key: '',
    name: '',
    description: '',
    environment: 'all',
    rolloutPercentage: 100,
    isEnabled: false,
  });

  const query = useQuery({
    queryKey: ['admin-feature-flags'],
    queryFn: ({ signal }) =>
      apiClient.get<FeatureFlagItem[]>('/admin/feature-flags', undefined, {
        signal,
      }),
  });

  const createMutation = useMutation({
    mutationFn: () => apiClient.post('/admin/feature-flags', form),
    onSuccess: () => {
      setCreateOpen(false);
      setForm({
        key: '',
        name: '',
        description: '',
        environment: 'all',
        rolloutPercentage: 100,
        isEnabled: false,
      });
      void qc.invalidateQueries({ queryKey: ['admin-feature-flags'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({
      key,
      payload,
    }: {
      key: string;
      payload: Record<string, unknown>;
    }) => apiClient.patch(`/admin/feature-flags/${key}`, payload),
    onSuccess: () =>
      void qc.invalidateQueries({ queryKey: ['admin-feature-flags'] }),
  });

  if (query.isLoading) return <LoadingState />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">{t.nav.featureFlags}</h2>
        <PermissionGate permission="feature_flags.manage">
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="h-4 w-4" />
            Create Flag
          </Button>
        </PermissionGate>
      </div>

      <div className="space-y-3">
        {(query.data ?? []).map((flag) => (
          <Card
            key={flag.key}
            className="flex flex-wrap items-center justify-between gap-4 p-4"
          >
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-semibold">{flag.name}</h3>
                <code className="rounded bg-muted px-1.5 py-0.5 text-xs">
                  {flag.key}
                </code>
                <StatusBadge status={flag.isEnabled ? 'active' : 'inactive'} />
              </div>
              <p className="mt-1 text-xs text-muted-foreground">
                {flag.description || 'No description'} • Env: {flag.environment} •
                Rollout: {flag.rolloutPercentage}%
              </p>
            </div>

            <div className="flex items-center gap-2">
              <Button
                size="sm"
                variant="outline"
                onClick={() => setHistoryFlag(flag)}
              >
                <History className="h-3.5 w-3.5" />
                History
              </Button>
              <PermissionGate permission="feature_flags.manage">
                <Select
                  value={flag.environment}
                  onChange={(e) =>
                    updateMutation.mutate({
                      key: flag.key,
                      payload: { environment: e.target.value },
                    })
                  }
                  className="w-32 h-8 text-xs"
                >
                  <option value="all">all</option>
                  <option value="development">development</option>
                  <option value="staging">staging</option>
                  <option value="production">production</option>
                </Select>
                <Button
                  size="sm"
                  variant={flag.isEnabled ? 'primary' : 'outline'}
                  onClick={() =>
                    updateMutation.mutate({
                      key: flag.key,
                      payload: { isEnabled: !flag.isEnabled },
                    })
                  }
                >
                  {flag.isEnabled ? (
                    <ToggleRight className="h-4 w-4" />
                  ) : (
                    <ToggleLeft className="h-4 w-4" />
                  )}
                  {flag.isEnabled ? 'Enabled' : 'Disabled'}
                </Button>
              </PermissionGate>
            </div>
          </Card>
        ))}
      </div>

      <Modal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Create Feature Flag"
      >
        <div className="space-y-3 text-sm">
          <Input
            placeholder="Key (e.g. new_search_ui)"
            value={form.key}
            onChange={(e) => setForm((f) => ({ ...f, key: e.target.value }))}
          />
          <Input
            placeholder="Display Name"
            value={form.name}
            onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
          />
          <Input
            placeholder="Description"
            value={form.description}
            onChange={(e) =>
              setForm((f) => ({ ...f, description: e.target.value }))
            }
          />
          <div className="grid grid-cols-2 gap-3">
            <Select
              value={form.environment}
              onChange={(e) =>
                setForm((f) => ({ ...f, environment: e.target.value }))
              }
            >
              <option value="all">all</option>
              <option value="development">development</option>
              <option value="staging">staging</option>
              <option value="production">production</option>
            </Select>
            <Input
              type="number"
              min={0}
              max={100}
              value={form.rolloutPercentage}
              onChange={(e) =>
                setForm((f) => ({
                  ...f,
                  rolloutPercentage: Number(e.target.value),
                }))
              }
            />
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              {t.common.cancel}
            </Button>
            <Button onClick={() => createMutation.mutate()}>Create</Button>
          </div>
        </div>
      </Modal>

      <Modal
        open={Boolean(historyFlag)}
        onClose={() => setHistoryFlag(null)}
        title={`Change History — ${historyFlag?.key || ''}`}
      >
        <div className="divide-y text-xs">
          {(historyFlag?.rules?.history ?? []).map((h, i) => (
            <div key={i} className="flex justify-between py-2">
              <span>
                Enabled: <strong>{String(h.newIsEnabled)}</strong> ({h.environment})
              </span>
              <span className="text-muted-foreground">
                {new Date(h.changedAt).toLocaleString()}
              </span>
            </div>
          ))}
        </div>
      </Modal>
    </div>
  );
}
