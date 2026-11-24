import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import { AccountContext } from '../decorators/current-account.decorator';
import { AuthenticatedUser } from '../decorators/current-user.decorator';

@Injectable()
export class AccountTenantGuard implements CanActivate {
  private readonly uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user as AuthenticatedUser;

    if (!user || !user.id) {
      // Must be authenticated first via JwtAuthGuard
      return false;
    }

    const rawAccountId =
      request.headers['x-account-id'] || request.headers['X-Account-ID'];

    // If no account header is specified, proceed without tenant context
    if (!rawAccountId) {
      return true;
    }

    const accountId = String(rawAccountId).trim();
    if (!this.uuidRegex.test(accountId)) {
      throw new BadRequestException(
        'Invalid format for X-Account-ID header (must be UUID).',
      );
    }

    // 1. Check Redis Cache for active membership
    const cacheKey = `account:membership:${user.id}:${accountId}`;
    const cached = await this.redis.get<AccountContext>(cacheKey);

    if (cached) {
      request.accountContext = {
        ...cached,
        permissions: new Set(Array.from(cached.permissions || [])),
      };
      return true;
    }

    // 2. Query PostgreSQL with relational joins
    const membership = await this.prisma.accountMember.findUnique({
      where: {
        uq_account_user: {
          accountId,
          userId: user.id,
        },
      },
      include: {
        account: true,
      },
    });

    if (
      !membership ||
      !membership.account ||
      !membership.account.isActive ||
      membership.account.deletedAt ||
      membership.account.verificationStatus === 'suspended'
    ) {
      throw new ForbiddenException(
        'Access denied. You are not an active authorized member of the specified account.',
      );
    }

    // 3. Assemble AccountContext
    const accountContext: AccountContext = {
      accountId: membership.accountId,
      userId: user.id,
      accountType: membership.account.accountType as any,
      memberRole: membership.role as any,
      permissions: this.resolveRolePermissions(membership.role),
    };

    // 4. Cache in Redis (5 minutes TTL)
    await this.redis.set(
      cacheKey,
      {
        ...accountContext,
        permissions: Array.from(accountContext.permissions),
      },
      300,
    );

    request.accountContext = accountContext;
    return true;
  }

  private resolveRolePermissions(role: string): Set<string> {
    const permissions = new Set<string>();

    switch (role.toLowerCase()) {
      case 'owner':
        permissions.add('*');
        permissions.add('account:manage');
        permissions.add('team:manage');
        permissions.add('listings:manage');
        permissions.add('chat:respond');
        break;
      case 'manager':
        permissions.add('team:view');
        permissions.add('listings:manage');
        permissions.add('chat:respond');
        break;
      case 'lister':
        permissions.add('listings:create');
        permissions.add('listings:edit');
        break;
      case 'responder':
        permissions.add('chat:respond');
        break;
      default:
        break;
    }

    return permissions;
  }
}
