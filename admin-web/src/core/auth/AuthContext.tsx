import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  apiClient,
  refreshAdminAccessToken,
  setAccessToken,
  setOnUnauthorized,
} from '../api/client';

export interface AdminIdentity {
  id: string;
  email: string;
  fullName: string;
  phone?: string | null;
  department?: string | null;
  jobTitle?: string | null;
  status: string;
  isActive: boolean;
  mfaEnabled: boolean;
  lastLoginAt?: string | null;
  role: {
    id: number;
    name: string;
    description?: string | null;
  };
  permissions: string[];
}

export interface LoginResponse {
  requiresMfa: boolean;
  mfaChallengeToken?: string;
  admin: AdminIdentity;
  accessToken?: string;
  expiresIn?: number;
}

interface AuthContextValue {
  admin: AdminIdentity | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  permissionsSet: Set<string>;
  hasPermission: (perm: string) => boolean;
  hasAnyPermission: (perms: string[]) => boolean;
  login: (email: string, password: string) => Promise<LoginResponse>;
  verifyMfa: (mfaChallengeToken: string, code: string) => Promise<LoginResponse>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [admin, setAdmin] = useState<AdminIdentity | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const handleUnauthorized = useCallback(() => {
    setAccessToken(null);
    setAdmin(null);
  }, []);

  useEffect(() => {
    setOnUnauthorized(handleUnauthorized);
    return () => setOnUnauthorized(null);
  }, [handleUnauthorized]);

  const bootstrapSession = useCallback(async () => {
    setIsLoading(true);
    try {
      const token = await refreshAdminAccessToken();
      if (token) {
        const profile = await apiClient.get<AdminIdentity>('/admin/auth/me');
        setAdmin(profile);
      } else {
        setAdmin(null);
      }
    } catch {
      setAdmin(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void bootstrapSession();
  }, [bootstrapSession]);

  const login = useCallback(async (email: string, password: string) => {
    const res = await apiClient.post<LoginResponse>(
      '/admin/auth/login',
      { email, password },
      { skipAuth: true },
    );
    if (!res.requiresMfa && res.accessToken) {
      setAccessToken(res.accessToken);
      setAdmin(res.admin);
    }
    return res;
  }, []);

  const verifyMfa = useCallback(
    async (mfaChallengeToken: string, code: string) => {
      const res = await apiClient.post<LoginResponse>(
        '/admin/auth/mfa/verify',
        { mfaChallengeToken, code },
        { skipAuth: true },
      );
      if (res.accessToken) {
        setAccessToken(res.accessToken);
        setAdmin(res.admin);
      }
      return res;
    },
    [],
  );

  const logout = useCallback(async () => {
    try {
      await apiClient.post('/admin/auth/logout');
    } catch {
      // Ignore network errors on logout
    } finally {
      setAccessToken(null);
      setAdmin(null);
    }
  }, []);

  const refreshProfile = useCallback(async () => {
    const profile = await apiClient.get<AdminIdentity>('/admin/auth/me');
    setAdmin(profile);
  }, []);

  const permissionsSet = useMemo(
    () => new Set(admin?.permissions ?? []),
    [admin],
  );

  const hasPermission = useCallback(
    (perm: string) => permissionsSet.has(perm),
    [permissionsSet],
  );

  const hasAnyPermission = useCallback(
    (perms: string[]) => perms.some((p) => permissionsSet.has(p)),
    [permissionsSet],
  );

  return (
    <AuthContext.Provider
      value={{
        admin,
        isLoading,
        isAuthenticated: Boolean(admin),
        permissionsSet,
        hasPermission,
        hasAnyPermission,
        login,
        verifyMfa,
        logout,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
