import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { I18nProvider, useI18n } from '../core/i18n/I18nContext';
import { ThemeProvider } from '../core/theme/ThemeContext';
import { AuthProvider } from '../core/auth/AuthContext';
import { PermissionGate, PagePermissionGuard } from '../core/auth/PermissionGate';
import { LoginPage } from '../features/auth/LoginPage';
import { apiClient, ApiClientError, setAccessToken } from '../core/api/client';

function I18nToggleTestHarness() {
  const { locale, dir, toggleLocale } = useI18n();
  return (
    <div>
      <span data-testid="locale-val">{locale}</span>
      <span data-testid="dir-val">{dir}</span>
      <button onClick={toggleLocale}>Switch</button>
    </div>
  );
}

describe('Deal One React Admin Dashboard — Core & Security UI Tests', () => {
  beforeEach(() => {
    localStorage.clear();
    setAccessToken(null);
    vi.restoreAllMocks();
  });

  it('switches cleanly between Arabic RTL and English LTR', () => {
    render(
      <I18nProvider>
        <I18nToggleTestHarness />
      </I18nProvider>,
    );

    expect(screen.getByTestId('locale-val')).toHaveTextContent('ar');
    expect(screen.getByTestId('dir-val')).toHaveTextContent('rtl');
    expect(document.documentElement.dir).toBe('rtl');

    fireEvent.click(screen.getByText('Switch'));
    expect(screen.getByTestId('locale-val')).toHaveTextContent('en');
    expect(screen.getByTestId('dir-val')).toHaveTextContent('ltr');
    expect(document.documentElement.dir).toBe('ltr');
  });

  it('validates LoginPage email/password and submits credentials through AuthContext', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockImplementation(
      async (input) => {
        const url = String(input);
        if (url.includes('/admin/auth/refresh')) {
          return new Response(JSON.stringify({ success: false }), {
            status: 401,
          });
        }
        if (url.includes('/admin/auth/login')) {
          return new Response(
            JSON.stringify({
              success: true,
              data: {
                requiresMfa: false,
                accessToken: 'jwt-test-token',
                admin: {
                  id: 'staff-1',
                  email: 'superadmin@dealone.eg',
                  fullName: 'Super Admin',
                  status: 'active',
                  isActive: true,
                  mfaEnabled: false,
                  role: { id: 1, name: 'super_admin' },
                  permissions: ['analytics.read'],
                },
              },
            }),
            { status: 200 },
          );
        }
        return new Response('{}', { status: 404 });
      },
    );

    const qc = new QueryClient();
    render(
      <QueryClientProvider client={qc}>
        <ThemeProvider>
          <I18nProvider>
            <AuthProvider>
              <MemoryRouter>
                <LoginPage />
              </MemoryRouter>
            </AuthProvider>
          </I18nProvider>
        </ThemeProvider>
      </QueryClientProvider>,
    );

    await waitFor(() =>
      expect(screen.getByPlaceholderText('superadmin@dealone.eg')).toBeInTheDocument(),
    );

    const emailInput = screen.getByPlaceholderText('superadmin@dealone.eg');
    const passwordInput = document.querySelector(
      'input[type="password"]',
    ) as HTMLInputElement;

    fireEvent.change(emailInput, { target: { value: 'superadmin@dealone.eg' } });
    fireEvent.change(passwordInput, { target: { value: 'SuperAdmin!2026' } });
    fireEvent.submit(emailInput.closest('form')!);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith(
        expect.stringContaining('/admin/auth/login'),
        expect.objectContaining({
          method: 'POST',
          credentials: 'include',
        }),
      );
    });
  });

  it('hides restricted UI actions with PermissionGate and blocks direct page access', async () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
      const url = String(input);
      if (url.includes('/admin/auth/refresh')) {
        return new Response(
          JSON.stringify({ success: true, data: { accessToken: 'tok' } }),
          { status: 200 },
        );
      }
      if (url.includes('/admin/auth/me')) {
        return new Response(
          JSON.stringify({
            success: true,
            data: {
              id: 'analyst-1',
              email: 'analyst@dealone.eg',
              fullName: 'Analyst',
              status: 'active',
              isActive: true,
              mfaEnabled: false,
              role: { id: 8, name: 'analyst' },
              permissions: ['analytics.read'],
            },
          }),
          { status: 200 },
        );
      }
      return new Response('{}', { status: 404 });
    });

    render(
      <I18nProvider>
        <AuthProvider>
          <PermissionGate permission="analytics.read">
            <span>Analytics Allowed</span>
          </PermissionGate>
          <PermissionGate permission="users.ban">
            <button>Ban User</button>
          </PermissionGate>
          <PagePermissionGuard permission="roles.update">
            <span>Role Editor</span>
          </PagePermissionGuard>
        </AuthProvider>
      </I18nProvider>,
    );

    await waitFor(() => {
      expect(screen.getByText('Analytics Allowed')).toBeInTheDocument();
    });
    expect(screen.queryByText('Ban User')).not.toBeInTheDocument();
    expect(screen.queryByText('Role Editor')).not.toBeInTheDocument();
    expect(screen.getByText('403 — Access Restricted')).toBeInTheDocument();
  });

  it('normalizes backend error envelopes into ApiClientError with trace_id', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: 'Missing required permission: listings.delete',
            trace_id: 'trace-xyz-123',
          },
        }),
        { status: 403 },
      ),
    );

    await expect(apiClient.delete('/admin/listings/123')).rejects.toMatchObject({
      name: 'ApiClientError',
      status: 403,
      code: 'FORBIDDEN',
      traceId: 'trace-xyz-123',
    });
  });
});
