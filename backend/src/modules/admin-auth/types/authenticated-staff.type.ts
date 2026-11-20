export interface AuthenticatedStaff {
  id: string;
  staffId: string | null;
  actorType: 'staff' | 'user';
  email: string;
  fullName: string;
  roleId: number | null;
  role: string;
  permissions: string[];
  sessionId?: string;
  mfaVerified: boolean;
}
