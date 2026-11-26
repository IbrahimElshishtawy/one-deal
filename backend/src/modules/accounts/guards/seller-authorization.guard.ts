import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../../core/database/prisma.service';
import { SecurityAuditService } from '../../../core/security/security-audit.service';
import {
  SellerApplicationStatus,
  SellerCapability,
  VerificationStatus,
} from '../../../core/enums/domain.enums';
import { SELLER_CAPABILITY_KEY } from '../decorators/require-seller-capability.decorator';
import { AuthenticatedUser } from '../../auth/decorators/current-user.decorator';

/**
 * Centralized Seller Authorization Guard.
 *
 * Enforces mandatory seller verification server-side across all seller-only
 * operations (never trusts client-side flags or Flutter visibility).
 *
 * Capabilities:
 *  - canCreateListing:
 *      Authenticated + active user + sellerStatus === APPROVED + active approved seller Account.
 *  - canManageListing:
 *      Authorized admin/staff OR (approved non-suspended seller who owns / manages the target listing).
 *  - canAccessSellerDashboard:
 *      Authenticated + active user + sellerStatus === APPROVED.
 *  - canSubmitSellerApplication:
 *      Authenticated + active user + eligible for seller conversion (not already APPROVED or SUSPENDED).
 */
@Injectable()
export class SellerAuthorizationGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
    @Optional() private readonly securityAudit?: SecurityAuditService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const capability = this.reflector.getAllAndOverride<SellerCapability>(
      SELLER_CAPABILITY_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!capability) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user as AuthenticatedUser | undefined;
    const requestId =
      (request.headers?.['x-request-id'] as string) ||
      (request.id as string) ||
      undefined;
    const ipAddress = request.ip;
    const userAgent = (request.headers?.['user-agent'] as string) || '';

    if (!user || !user.id) {
      throw new UnauthorizedException('Authentication required');
    }

    // Authorized admin/staff bypass for listing management only
    if (
      capability === SellerCapability.CAN_MANAGE_LISTING &&
      (user.actorType === 'staff' || user.role === 'SUPER_ADMIN')
    ) {
      return true;
    }

    const dbUser = await this.prisma.user.findUnique({
      where: { id: user.id },
      select: {
        id: true,
        isActive: true,
        deletedAt: true,
        moderationStatus: true,
        sellerStatus: true,
        sellerSuspendedAt: true,
      },
    });

    if (
      !dbUser ||
      !dbUser.isActive ||
      dbUser.deletedAt ||
      dbUser.moderationStatus !== 'active'
    ) {
      await this.auditDenied(
        user.id,
        capability,
        dbUser?.sellerStatus ?? 'UNKNOWN',
        'USER_INACTIVE_OR_RESTRICTED',
        request,
        requestId,
        ipAddress,
        userAgent,
      );
      throw new ForbiddenException({
        code: 'ACCOUNT_INACTIVE',
        message: 'Your user account is inactive or restricted.',
      });
    }

    if (capability === SellerCapability.CAN_SUBMIT_SELLER_APPLICATION) {
      if (dbUser.sellerStatus === SellerApplicationStatus.APPROVED) {
        await this.auditDenied(
          user.id,
          capability,
          dbUser.sellerStatus,
          'ALREADY_APPROVED_SELLER',
          request,
          requestId,
          ipAddress,
          userAgent,
        );
        throw new ForbiddenException({
          code: 'ALREADY_APPROVED_SELLER',
          message: 'Your account is already an approved seller.',
        });
      }
      if (dbUser.sellerStatus === SellerApplicationStatus.SUSPENDED) {
        await this.auditDenied(
          user.id,
          capability,
          dbUser.sellerStatus,
          'SELLER_PRIVILEGES_SUSPENDED',
          request,
          requestId,
          ipAddress,
          userAgent,
        );
        throw new ForbiddenException({
          code: 'SELLER_SUSPENDED',
          message:
            'Your seller privileges are currently suspended. Contact support for review.',
        });
      }
      return true;
    }

    // All remaining seller capabilities require APPROVED, non-suspended seller status
    if (dbUser.sellerStatus !== SellerApplicationStatus.APPROVED) {
      await this.auditDenied(
        user.id,
        capability,
        dbUser.sellerStatus,
        `SELLER_STATUS_${dbUser.sellerStatus}`,
        request,
        requestId,
        ipAddress,
        userAgent,
      );

      const messageByStatus: Record<string, string> = {
        [SellerApplicationStatus.NOT_REQUESTED]:
          'Seller verification is required. Please submit a seller application to access seller features.',
        [SellerApplicationStatus.DRAFT]:
          'Your seller application is still a draft. Please submit it for admin verification.',
        [SellerApplicationStatus.PENDING]:
          'Your seller application is pending admin verification. Seller features are locked until approval.',
        [SellerApplicationStatus.UNDER_REVIEW]:
          'Your seller application is under admin review. Seller features are locked until approval.',
        [SellerApplicationStatus.NEEDS_CORRECTION]:
          'Your seller application requires corrections. Please update the requested items and resubmit.',
        [SellerApplicationStatus.REJECTED]:
          'Your seller application was rejected. Please review the reason and resubmit.',
        [SellerApplicationStatus.SUSPENDED]:
          'Your seller privileges have been suspended. Buyer features remain active.',
        [SellerApplicationStatus.EXPIRED]:
          'Your seller verification has expired. Please renew your verification to resume selling. Buyer features remain active.',
      };

      const codeByStatus: Record<string, string> = {
        [SellerApplicationStatus.SUSPENDED]: 'SELLER_SUSPENDED',
        [SellerApplicationStatus.EXPIRED]: 'SELLER_VERIFICATION_EXPIRED',
        [SellerApplicationStatus.NEEDS_CORRECTION]: 'SELLER_CORRECTION_REQUIRED',
      };

      throw new ForbiddenException({
        code:
          codeByStatus[dbUser.sellerStatus] || 'SELLER_VERIFICATION_REQUIRED',
        sellerStatus: dbUser.sellerStatus,
        message:
          messageByStatus[dbUser.sellerStatus] ||
          'Approved seller status is required for this operation.',
      });
    }

    if (capability === SellerCapability.CAN_ACCESS_SELLER_DASHBOARD) {
      return true;
    }

    if (capability === SellerCapability.CAN_CREATE_LISTING) {
      const approvedAccount = await this.prisma.account.findFirst({
        where: {
          isActive: true,
          deletedAt: null,
          verificationStatus: VerificationStatus.APPROVED,
          OR: [
            { ownerUserId: user.id },
            {
              members: {
                some: {
                  userId: user.id,
                  role: { in: ['owner', 'manager', 'lister'] },
                },
              },
            },
          ],
        },
        select: { id: true },
      });

      if (!approvedAccount) {
        await this.auditDenied(
          user.id,
          capability,
          dbUser.sellerStatus,
          'NO_ACTIVE_APPROVED_SELLER_ACCOUNT',
          request,
          requestId,
          ipAddress,
          userAgent,
        );
        throw new ForbiddenException({
          code: 'SELLER_ACCOUNT_NOT_APPROVED',
          message:
            'An active approved seller account is required to create or publish listings.',
        });
      }

      request.verifiedSellerAccountId = approvedAccount.id;
      return true;
    }

    if (capability === SellerCapability.CAN_MANAGE_LISTING) {
      const listingId = request.params?.id || request.body?.listingId;
      if (listingId && typeof listingId === 'string') {
        const listing = await this.prisma.listing.findUnique({
          where: { id: listingId },
          include: {
            account: {
              select: {
                id: true,
                ownerUserId: true,
                isActive: true,
                deletedAt: true,
                verificationStatus: true,
                members: {
                  where: {
                    userId: user.id,
                    role: { in: ['owner', 'manager', 'lister'] },
                  },
                  select: { id: true },
                },
              },
            },
          },
        });

        if (!listing || listing.deletedAt) {
          throw new NotFoundException('Listing not found');
        }

        const isOwnerOrMember =
          listing.account.ownerUserId === user.id ||
          listing.account.members.length > 0;

        if (!isOwnerOrMember) {
          await this.auditDenied(
            user.id,
            capability,
            dbUser.sellerStatus,
            'LISTING_OWNERSHIP_MISMATCH',
            request,
            requestId,
            ipAddress,
            userAgent,
            listingId,
          );
          throw new ForbiddenException(
            'You do not have permission to manage this listing',
          );
        }

        if (
          !listing.account.isActive ||
          listing.account.deletedAt ||
          listing.account.verificationStatus !== VerificationStatus.APPROVED
        ) {
          await this.auditDenied(
            user.id,
            capability,
            dbUser.sellerStatus,
            'LISTING_ACCOUNT_NOT_APPROVED',
            request,
            requestId,
            ipAddress,
            userAgent,
            listingId,
          );
          throw new ForbiddenException({
            code: 'SELLER_ACCOUNT_NOT_APPROVED',
            message:
              'The seller account associated with this listing is not approved or is suspended.',
          });
        }
      }

      return true;
    }

    return true;
  }

  private async auditDenied(
    userId: string,
    capability: SellerCapability,
    sellerStatus: string,
    reason: string,
    request: any,
    requestId?: string,
    ipAddress?: string,
    userAgent?: string,
    targetId?: string,
  ): Promise<void> {
    if (!this.securityAudit) return;
    await this.securityAudit.logEvent({
      action: 'UNAUTHORIZED_SELLER_OPERATION_ATTEMPTED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerAuthorization',
      targetId: targetId ?? userId,
      ipAddress,
      userAgent,
      correlationId: requestId,
      metadata: {
        requestId: requestId ?? null,
        userId,
        sellerStatus,
        requiredCapability: capability,
        reason,
        method: request?.method ?? null,
        path: request?.url ?? null,
        result: 'DENIED',
        timestamp: new Date().toISOString(),
      },
    });
  }
}
