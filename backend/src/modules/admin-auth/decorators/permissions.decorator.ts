import {
  SetMetadata,
  createParamDecorator,
  ExecutionContext,
} from '@nestjs/common';
import { AuthenticatedStaff } from '../types/authenticated-staff.type';

export const PERMISSIONS_KEY = 'admin_permissions';
export const ANY_PERMISSIONS_KEY = 'admin_any_permissions';

/**
 * Requires all listed granular permissions.
 */
export const Permissions = (...permissions: string[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);

/**
 * Requires at least one of the listed granular permissions.
 */
export const AnyPermissions = (...permissions: string[]) =>
  SetMetadata(ANY_PERMISSIONS_KEY, permissions);

export const CurrentStaff = createParamDecorator(
  (data: keyof AuthenticatedStaff | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const staff = request.user as AuthenticatedStaff;
    return data ? staff?.[data] : staff;
  },
);
