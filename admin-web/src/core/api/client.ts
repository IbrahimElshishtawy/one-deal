export interface StandardApiSuccess<T> {
  success: true;
  data: T;
  meta?: Record<string, unknown>;
}

export interface StandardApiError {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
    trace_id?: string;
  };
}

export class ApiClientError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details: unknown;
  readonly traceId?: string;

  constructor(
    status: number,
    code: string,
    message: string,
    details?: unknown,
    traceId?: string,
  ) {
    super(message);
    this.name = 'ApiClientError';
    this.status = status;
    this.code = code;
    this.details = details ?? null;
    this.traceId = traceId;
  }
}

const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || '/api/v1'
).replace(/\/+$/, '');

// Strictly in-memory token storage (never localStorage or sessionStorage)
let inMemoryAccessToken: string | null = null;
let refreshPromise: Promise<string | null> | null = null;
let onUnauthorizedCallback: (() => void) | null = null;

export function setAccessToken(token: string | null) {
  inMemoryAccessToken = token;
}

export function getAccessToken(): string | null {
  return inMemoryAccessToken;
}

export function setOnUnauthorized(cb: (() => void) | null) {
  onUnauthorizedCallback = cb;
}

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  params?: Record<string, string | number | boolean | undefined | null>;
  signal?: AbortSignal;
  timeoutMs?: number;
  skipAuth?: boolean;
  retrySafe?: boolean;
}

function buildUrl(
  path: string,
  params?: Record<string, string | number | boolean | undefined | null>,
): string {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  const base = `${API_BASE_URL}${normalizedPath}`;
  if (!params) return base;

  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') {
      qs.set(k, String(v));
    }
  }
  const queryStr = qs.toString();
  return queryStr ? `${base}?${queryStr}` : base;
}

export async function refreshAdminAccessToken(): Promise<string | null> {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    try {
      const res = await fetch(buildUrl('/admin/auth/refresh'), {
        method: 'POST',
        credentials: 'include',
        headers: {
          'X-Requested-With': 'dealone-admin-web',
        },
      });
      if (!res.ok) {
        setAccessToken(null);
        return null;
      }
      const json = (await res.json()) as StandardApiSuccess<{
        accessToken: string;
      }>;
      const token = json?.data?.accessToken ?? null;
      setAccessToken(token);
      return token;
    } catch {
      setAccessToken(null);
      return null;
    } finally {
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

async function executeFetch<T>(
  path: string,
  options: RequestOptions,
  isRetryAfterRefresh = false,
): Promise<T> {
  const method = options.method ?? 'GET';
  const controller = new AbortController();
  const timeoutMs = options.timeoutMs ?? 25_000;
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  const onExternalAbort = () => controller.abort();
  if (options.signal) {
    if (options.signal.aborted) {
      clearTimeout(timer);
      throw new DOMException('Request aborted', 'AbortError');
    }
    options.signal.addEventListener('abort', onExternalAbort, { once: true });
  }

  const headers: Record<string, string> = {
    'X-Requested-With': 'dealone-admin-web',
  };

  if (options.body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }
  if (!options.skipAuth && inMemoryAccessToken) {
    headers['Authorization'] = `Bearer ${inMemoryAccessToken}`;
  }

  try {
    const response = await fetch(buildUrl(path, options.params), {
      method,
      credentials: 'include',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
      signal: controller.signal,
    });

    if (
      response.status === 401 &&
      !options.skipAuth &&
      !isRetryAfterRefresh &&
      !path.startsWith('/admin/auth/login') &&
      !path.startsWith('/admin/auth/refresh')
    ) {
      const nextToken = await refreshAdminAccessToken();
      if (nextToken) {
        return executeFetch<T>(path, options, true);
      }
      onUnauthorizedCallback?.();
    }

    const text = await response.text();
    let parsed: unknown = null;
    if (text) {
      try {
        parsed = JSON.parse(text);
      } catch {
        parsed = text;
      }
    }

    if (!response.ok) {
      const errObj = (parsed as StandardApiError | null)?.error;
      throw new ApiClientError(
        response.status,
        errObj?.code || `HTTP_${response.status}`,
        errObj?.message || response.statusText || 'Request failed',
        errObj?.details,
        errObj?.trace_id,
      );
    }

    if (
      parsed &&
      typeof parsed === 'object' &&
      'success' in parsed &&
      'data' in parsed
    ) {
      return (parsed as StandardApiSuccess<T>).data;
    }

    return parsed as T;
  } finally {
    clearTimeout(timer);
    options.signal?.removeEventListener('abort', onExternalAbort);
  }
}

export const apiClient = {
  get<T>(
    path: string,
    params?: Record<string, string | number | boolean | undefined | null>,
    options?: Omit<RequestOptions, 'method' | 'params'>,
  ): Promise<T> {
    return executeFetch<T>(path, { ...options, method: 'GET', params });
  },
  post<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>,
  ): Promise<T> {
    return executeFetch<T>(path, { ...options, method: 'POST', body });
  },
  put<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>,
  ): Promise<T> {
    return executeFetch<T>(path, { ...options, method: 'PUT', body });
  },
  patch<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, 'method' | 'body'>,
  ): Promise<T> {
    return executeFetch<T>(path, { ...options, method: 'PATCH', body });
  },
  delete<T>(
    path: string,
    options?: Omit<RequestOptions, 'method'>,
  ): Promise<T> {
    return executeFetch<T>(path, { ...options, method: 'DELETE' });
  },
};
