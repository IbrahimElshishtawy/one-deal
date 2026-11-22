import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface AuthenticatedUser {
  id: string;
  phone?: string;
  email?: string;
  fullName: string;
  role: string;
  status?: string;
  actorType?: 'user' | 'staff';
  staffId?: string | null;
  permissions?: string[];
  sessionId?: string;
}

export const CurrentUser = createParamDecorator(
  (data: keyof AuthenticatedUser | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as AuthenticatedUser;

    return data ? user?.[data] : user;
  },
);
