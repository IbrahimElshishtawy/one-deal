import React from 'react';
import { ChevronLeft, ChevronRight, Search } from 'lucide-react';
import {
  Button,
  Card,
  EmptyState,
  ErrorState,
  Input,
  LoadingState,
} from './ui';
import { useI18n } from '../core/i18n/I18nContext';

export interface Column<T> {
  key: string;
  header: string;
  render: (row: T) => React.ReactNode;
  className?: string;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  rowKey: (row: T) => string;
  isLoading?: boolean;
  error?: string | null;
  onRetry?: () => void;
  meta?: PaginationMeta;
  onPageChange?: (page: number) => void;
  search?: string;
  onSearchChange?: (val: string) => void;
  searchPlaceholder?: string;
  filters?: React.ReactNode;
  actions?: React.ReactNode;
}

export function DataTable<T>({
  columns,
  data,
  rowKey,
  isLoading,
  error,
  onRetry,
  meta,
  onPageChange,
  search,
  onSearchChange,
  searchPlaceholder,
  filters,
  actions,
}: DataTableProps<T>) {
  const { t, dir } = useI18n();

  return (
    <Card className="overflow-hidden">
      {(onSearchChange || filters || actions) && (
        <div className="flex flex-wrap items-center justify-between gap-3 border-b p-4">
          <div className="flex flex-wrap items-center gap-2">
            {onSearchChange && (
              <div className="relative w-64 max-w-full">
                <Search className="pointer-events-none absolute top-2.5 h-4 w-4 text-muted-foreground ltr:left-3 rtl:right-3" />
                <Input
                  value={search ?? ''}
                  onChange={(e) => onSearchChange(e.target.value)}
                  placeholder={searchPlaceholder || t.common.search}
                  className="ltr:pl-9 rtl:pr-9"
                />
              </div>
            )}
            {filters}
          </div>
          {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
        </div>
      )}

      {isLoading ? (
        <LoadingState />
      ) : error ? (
        <div className="p-4">
          <ErrorState message={error} onRetry={onRetry} />
        </div>
      ) : data.length === 0 ? (
        <div className="p-6">
          <EmptyState />
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b bg-muted/50 text-xs font-semibold uppercase text-muted-foreground">
              <tr>
                {columns.map((col) => (
                  <th
                    key={col.key}
                    className={`px-4 py-3 text-start ${col.className || ''}`}
                  >
                    {col.header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y">
              {data.map((row) => (
                <tr key={rowKey(row)} className="hover:bg-muted/30">
                  {columns.map((col) => (
                    <td
                      key={col.key}
                      className={`px-4 py-3 align-middle ${col.className || ''}`}
                    >
                      {col.render(row)}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {meta && meta.totalPages > 0 && onPageChange && (
        <div className="flex flex-wrap items-center justify-between gap-3 border-t px-4 py-3 text-xs text-muted-foreground">
          <span>
            {t.common.total}: <strong>{meta.total}</strong> • {t.common.page}{' '}
            <strong>{meta.page}</strong> {t.common.of}{' '}
            <strong>{Math.max(meta.totalPages, 1)}</strong>
          </span>
          <div className="flex items-center gap-1.5">
            <Button
              variant="outline"
              size="sm"
              disabled={meta.page <= 1}
              onClick={() => onPageChange(meta.page - 1)}
            >
              {dir === 'rtl' ? (
                <ChevronRight className="h-4 w-4" />
              ) : (
                <ChevronLeft className="h-4 w-4" />
              )}
              {t.common.prev}
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={meta.page >= meta.totalPages}
              onClick={() => onPageChange(meta.page + 1)}
            >
              {t.common.next}
              {dir === 'rtl' ? (
                <ChevronLeft className="h-4 w-4" />
              ) : (
                <ChevronRight className="h-4 w-4" />
              )}
            </Button>
          </div>
        </div>
      )}
    </Card>
  );
}
