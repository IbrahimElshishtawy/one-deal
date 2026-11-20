import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Edit, Plus } from 'lucide-react';
import { apiClient, ApiClientError } from '../../core/api/client';
import { useI18n } from '../../core/i18n/I18nContext';
import { PermissionGate } from '../../core/auth/PermissionGate';
import {
  Button,
  Card,
  Input,
  LoadingState,
  Modal,
  Textarea,
} from '../../components/ui';

interface SettingItem {
  key: string;
  value: unknown;
  description: string | null;
  updatedAt: string;
}

export function PlatformSettingsPage() {
  const { t } = useI18n();
  const qc = useQueryClient();

  const [editingKey, setEditingKey] = useState<string | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [keyInput, setKeyInput] = useState('');
  const [jsonInput, setJsonInput] = useState('');
  const [descInput, setDescInput] = useState('');
  const [errMsg, setErrMsg] = useState<string | null>(null);

  const query = useQuery({
    queryKey: ['admin-settings'],
    queryFn: ({ signal }) =>
      apiClient.get<SettingItem[]>('/admin/settings', undefined, { signal }),
  });

  const saveMutation = useMutation({
    mutationFn: () => {
      let parsedValue: unknown;
      try {
        parsedValue = JSON.parse(jsonInput);
      } catch {
        throw new Error('Value must be valid JSON (e.g. true, 30, {"ar":"..."})');
      }
      return apiClient.put(`/admin/settings/${keyInput.trim()}`, {
        value: parsedValue,
        description: descInput || undefined,
      });
    },
    onSuccess: () => {
      setEditingKey(null);
      setIsNew(false);
      void qc.invalidateQueries({ queryKey: ['admin-settings'] });
    },
    onError: (err) =>
      setErrMsg(
        err instanceof ApiClientError || err instanceof Error
          ? err.message
          : 'Failed to save setting',
      ),
  });

  if (query.isLoading) return <LoadingState />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">{t.nav.settings}</h2>
          <p className="text-xs text-muted-foreground">
            Operational business settings only. Infrastructure secrets are never exposed.
          </p>
        </div>
        <PermissionGate permission="settings.update">
          <Button
            onClick={() => {
              setErrMsg(null);
              setIsNew(true);
              setEditingKey('new');
              setKeyInput('');
              setJsonInput('{}');
              setDescInput('');
            }}
          >
            <Plus className="h-4 w-4" />
            Add Setting
          </Button>
        </PermissionGate>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {(query.data ?? []).map((item) => (
          <Card key={item.key} className="p-4 space-y-2">
            <div className="flex items-start justify-between gap-2">
              <div>
                <h3 className="font-mono text-sm font-bold">{item.key}</h3>
                <p className="text-xs text-muted-foreground">
                  {item.description || 'Operational configuration'}
                </p>
              </div>
              <PermissionGate permission="settings.update">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setErrMsg(null);
                    setIsNew(false);
                    setEditingKey(item.key);
                    setKeyInput(item.key);
                    setJsonInput(JSON.stringify(item.value, null, 2));
                    setDescInput(item.description || '');
                  }}
                >
                  <Edit className="h-3.5 w-3.5" />
                </Button>
              </PermissionGate>
            </div>
            <pre className="overflow-x-auto rounded border bg-muted/40 p-2.5 font-mono text-xs">
              {JSON.stringify(item.value, null, 2)}
            </pre>
            <p className="text-[11px] text-muted-foreground">
              Updated: {new Date(item.updatedAt).toLocaleString()}
            </p>
          </Card>
        ))}
      </div>

      <Modal
        open={Boolean(editingKey)}
        onClose={() => setEditingKey(null)}
        title={isNew ? 'Create Setting' : `Edit Setting — ${keyInput}`}
      >
        <div className="space-y-3 text-sm">
          {errMsg && (
            <div className="rounded border border-destructive/40 bg-destructive/10 p-2 text-xs text-destructive">
              {errMsg}
            </div>
          )}
          <Input
            placeholder="Setting key (e.g. listings.default_expiry_days)"
            value={keyInput}
            disabled={!isNew}
            onChange={(e) => setKeyInput(e.target.value)}
          />
          <Input
            placeholder="Description"
            value={descInput}
            onChange={(e) => setDescInput(e.target.value)}
          />
          <div>
            <label className="mb-1 block text-xs font-medium">
              JSON Value
            </label>
            <Textarea
              className="font-mono text-xs min-h-[120px]"
              value={jsonInput}
              onChange={(e) => setJsonInput(e.target.value)}
            />
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setEditingKey(null)}>
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
