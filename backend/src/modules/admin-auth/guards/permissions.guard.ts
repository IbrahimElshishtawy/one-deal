import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import {
  ANY_PERMISSIONS_KEY,
  PERMISSIONS_KEY,
} from '../decorators/permissions.decorator';
import { AuthenticatedStaff } from '../types/authenticated-staff.type';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredAll = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    const requiredAny = this.reflector.getAllAndOverride<string[]>(
      ANY_PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (
      (!requiredAll || requiredAll.length === 0) &&
      (!requiredAny || requiredAny.length === 0)
    ) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const staff = request.user as AuthenticatedStaff | undefined;

    if (!staff) {
      throw new ForbiddenException('Admin authentication context is missing');
    }

    const granted = new Set(
      Array.isArray(staff.permissions) ? staff.permissions : [],
    );

    if (requiredAll && requiredAll.length > 0) {
      const missing = requiredAll.filter((perm) => !granted.has(perm));
      if (missing.length > 0) {
        throw new ForbiddenException(
          `Access denied. Missing required permission(s): [${missing.join(', ')}]`,
        );
      }
    }

    if (requiredAny && requiredAny.length > 0) {
      const hasAny = requiredAny.some((perm) => granted.has(perm));
      if (!hasAny) {
        throw new ForbiddenException(
          `Access denied. Requires one of permissions: [${requiredAny.join(', ')}]`,
        );
      }
    }

    return true;
  }
}
