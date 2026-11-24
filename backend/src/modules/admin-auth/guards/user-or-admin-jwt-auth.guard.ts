import { Injectable } from '@nestjs/common';
import { AdminJwtAuthGuard } from './admin-jwt-auth.guard';

/**
 * Dual-audience JWT guard for user-facing endpoints that also permit
 * authorized administrative staff oversight (e.g. Bookings & RFQ detail/actions).
 *
 * Delegates token verification to AdminJwtAuthGuard (supporting both mobile
 * user JWTs and staff admin JWTs) while returning a user-appropriate 401
 * message when authentication is missing or invalid.
 */
@Injectable()
export class UserOrAdminJwtAuthGuard extends AdminJwtAuthGuard {
  protected override getUnauthorizedMessage(): string {
    return 'Authentication token is missing, invalid, or expired';
  }
}
