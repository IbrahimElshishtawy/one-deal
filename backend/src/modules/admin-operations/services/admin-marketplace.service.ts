import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../../../core/database/prisma.service';
import { RedisService } from '../../../core/redis/redis.service';
import {
  AdminListingsQueryDto,
  AdminPaginationDto,
  AdminUsersQueryDto,
  BanUserDto,
  BulkListingDecisionDto,
  ListingActionReasonDto,
  MessagingConversationMessagesQueryDto,
  SuspendUserDto,
  UpdateAdminUserDto,
  UpdateConversationStatusDto,
  UpdateSellerAccountStatusDto,
} from '../dto/admin-operations.dto';

@Injectable()
export class AdminMarketplaceService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  // =========================================================================
  // USERS & SELLER ACCOUNTS MANAGEMENT
  // =========================================================================

  async listUsers(query: AdminUsersQueryDto) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: any = {
      deletedAt: null,
      ...(query.moderationStatus && query.moderationStatus !== 'all'
        ? { moderationStatus: query.moderationStatus }
        : {}),
      ...(query.isActive !== undefined
        ? { isActive: query.isActive === 'true' }
        : {}),
      ...(query.isDemo !== undefined
        ? { isDemo: query.isDemo === 'true' }
        : {}),
      ...(query.q
        ? {
            OR: [
              { fullName: { contains: query.q.trim(), mode: 'insensitive' } },
              { phone: { contains: query.q.trim(), mode: 'insensitive' } },
              { email: { contains: query.q.trim(), mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const allowedSort = new Set(['createdAt', 'fullName', 'moderationStatus']);
    const sortBy = allowedSort.has(query.sortBy || '')
      ? query.sortBy!
      : 'createdAt';
    const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';

    const [total, items] = await Promise.all([
      this.prisma.user.count({ where }),
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        select: {
          id: true,
          fullName: true,
          phone: true,
          email: true,
          avatarUrl: true,
          isPhoneVerified: true,
          isEmailVerified: true,
          isActive: true,
          moderationStatus: true,
          suspendedUntil: true,
          bannedAt: true,
          preferredLanguage: true,
          isDemo: true,
          createdAt: true,
          _count: {
            select: {
              ownedAccounts: true,
              reportsFiled: true,
              sessions: true,
            },
          },
          ownedAccounts: {
            select: {
              id: true,
              displayName: true,
              accountType: true,
              verificationStatus: true,
              _count: { select: { listings: true } },
            },
            take: 3,
          },
        },
      }),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getUserDetail(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        phone: true,
        email: true,
        avatarUrl: true,
        isPhoneVerified: true,
        isEmailVerified: true,
        isActive: true,
        moderationStatus: true,
        suspendedUntil: true,
        suspensionReason: true,
        bannedAt: true,
        banReason: true,
        internalNotes: true,
        preferredLanguage: true,
        isDemo: true,
        createdAt: true,
        updatedAt: true,
        deletedAt: true,
        ownedAccounts: {
          include: {
            verifications: { orderBy: { createdAt: 'desc' }, take: 10 },
            _count: { select: { listings: true, reportsAgainst: true } },
          },
        },
        reportsFiled: {
          orderBy: { createdAt: 'desc' },
          take: 15,
          select: {
            id: true,
            reason: true,
            status: true,
            createdAt: true,
            listingId: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Marketplace user not found');
    }

    const accountIds = user.ownedAccounts.map((a) => a.id);

    const [listings, reportsAgainst, activeSessionCount, accountHistory] =
      await Promise.all([
        this.prisma.listing.findMany({
          where: { accountId: { in: accountIds }, deletedAt: null },
          orderBy: { createdAt: 'desc' },
          take: 30,
          select: {
            id: true,
            title: true,
            price: true,
            currency: true,
            moderationStatus: true,
            publicationStatus: true,
            availabilityStatus: true,
            createdAt: true,
          },
        }),
        accountIds.length > 0
          ? this.prisma.report.findMany({
              where: { reportedAccountId: { in: accountIds } },
              orderBy: { createdAt: 'desc' },
              take: 20,
            })
          : Promise.resolve([]),
        this.prisma.userSession.count({
          where: {
            userId,
            isRevoked: false,
            expiresAt: { gt: new Date() },
          },
        }),
        this.prisma.auditLog.findMany({
          where: { targetEntity: 'user', targetId: userId },
          orderBy: { createdAt: 'desc' },
          take: 25,
        }),
      ]);

    return {
      user,
      listings,
      reportsAgainst,
      activeSessionCount,
      accountHistory,
    };
  }

  async updateUser(
    userId: string,
    dto: UpdateAdminUserDto,
    actorId: string,
  ) {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!existing) {
      throw new NotFoundException('Marketplace user not found');
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.user.update({
        where: { id: userId },
        data: {
          ...(dto.fullName !== undefined
            ? { fullName: dto.fullName.trim() }
            : {}),
          ...(dto.preferredLanguage !== undefined
            ? { preferredLanguage: dto.preferredLanguage }
            : {}),
        },
        select: {
          id: true,
          fullName: true,
          phone: true,
          email: true,
          preferredLanguage: true,
          isActive: true,
          moderationStatus: true,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'USER_UPDATED',
          targetEntity: 'user',
          targetId: userId,
          diffPayload: {
            previous: {
              fullName: existing.fullName,
              preferredLanguage: existing.preferredLanguage,
            },
            next: updated,
          },
        },
      });

      return updated;
    });
  }

  async suspendUser(
    userId: string,
    dto: SuspendUserDto,
    actorId: string,
    staffId?: string | null,
  ) {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!existing || existing.deletedAt) {
      throw new NotFoundException('Marketplace user not found');
    }

    const activeSessions = await this.prisma.userSession.findMany({
      where: { userId, isRevoked: false },
      select: { id: true },
    });

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.user.update({
        where: { id: userId },
        data: {
          isActive: false,
          moderationStatus: 'suspended',
          suspensionReason: dto.reason.trim(),
          suspendedUntil: dto.suspendedUntil
            ? new Date(dto.suspendedUntil)
            : null,
        },
      });

      await tx.userSession.updateMany({
        where: { userId, isRevoked: false },
        data: { isRevoked: true },
      });

      await tx.moderationLog.create({
        data: {
          ...(staffId ? { staffId } : {}),
          targetType: 'account',
          targetId: userId,
          action: 'suspend',
          notes: dto.reason.trim(),
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'USER_SUSPENDED',
          targetEntity: 'user',
          targetId: userId,
          diffPayload: {
            previousStatus: existing.moderationStatus,
            newStatus: 'suspended',
            reason: dto.reason.trim(),
            suspendedUntil: dto.suspendedUntil ?? null,
          },
        },
      });

      return next;
    });

    await this.denylistMobileUserTokens(
      userId,
      activeSessions.map((s) => s.id),
    );
    return {
      id: updated.id,
      isActive: updated.isActive,
      moderationStatus: updated.moderationStatus,
      suspendedUntil: updated.suspendedUntil,
    };
  }

  async unsuspendUser(
    userId: string,
    actorId: string,
    notes?: string,
    staffId?: string | null,
  ) {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!existing || existing.deletedAt) {
      throw new NotFoundException('Marketplace user not found');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.user.update({
        where: { id: userId },
        data: {
          isActive: true,
          moderationStatus: 'active',
          suspensionReason: null,
          suspendedUntil: null,
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(staffId ? { staffId } : {}),
          targetType: 'account',
          targetId: userId,
          action: 'unsuspend',
          notes: notes?.trim() || 'Suspension lifted',
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'USER_UNSUSPENDED',
          targetEntity: 'user',
          targetId: userId,
          diffPayload: {
            previousStatus: existing.moderationStatus,
            newStatus: 'active',
            notes: notes?.trim() || null,
          },
        },
      });

      return next;
    });

    return {
      id: updated.id,
      isActive: updated.isActive,
      moderationStatus: updated.moderationStatus,
    };
  }

  async banUser(
    userId: string,
    dto: BanUserDto,
    actorId: string,
    staffId?: string | null,
  ) {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { ownedAccounts: { select: { id: true } } },
    });
    if (!existing || existing.deletedAt) {
      throw new NotFoundException('Marketplace user not found');
    }

    const accountIds = existing.ownedAccounts.map((a) => a.id);
    const activeSessions = await this.prisma.userSession.findMany({
      where: { userId, isRevoked: false },
      select: { id: true },
    });

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.user.update({
        where: { id: userId },
        data: {
          isActive: false,
          moderationStatus: 'banned',
          bannedAt: new Date(),
          banReason: dto.reason.trim(),
        },
      });

      await tx.userSession.updateMany({
        where: { userId, isRevoked: false },
        data: { isRevoked: true },
      });

      if (accountIds.length > 0) {
        await tx.listing.updateMany({
          where: {
            accountId: { in: accountIds },
            publicationStatus: 'published',
          },
          data: { publicationStatus: 'hidden' },
        });
      }

      await tx.moderationLog.create({
        data: {
          ...(staffId ? { staffId } : {}),
          targetType: 'account',
          targetId: userId,
          action: 'ban',
          notes: dto.reason.trim(),
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'USER_BANNED',
          targetEntity: 'user',
          targetId: userId,
          diffPayload: {
            previousStatus: existing.moderationStatus,
            newStatus: 'banned',
            reason: dto.reason.trim(),
          },
        },
      });

      return next;
    });

    await Promise.all([
      this.denylistMobileUserTokens(
        userId,
        activeSessions.map((s) => s.id),
      ),
      this.invalidateFeedCache(),
    ]);

    return {
      id: updated.id,
      isActive: updated.isActive,
      moderationStatus: updated.moderationStatus,
      bannedAt: updated.bannedAt,
    };
  }

  async unbanUser(
    userId: string,
    actorId: string,
    notes?: string,
    staffId?: string | null,
  ) {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!existing || existing.deletedAt) {
      throw new NotFoundException('Marketplace user not found');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.user.update({
        where: { id: userId },
        data: {
          isActive: true,
          moderationStatus: 'active',
          bannedAt: null,
          banReason: null,
          suspensionReason: null,
          suspendedUntil: null,
        },
      });

      await tx.moderationLog.create({
        data: {
          ...(staffId ? { staffId } : {}),
          targetType: 'account',
          targetId: userId,
          action: 'unban',
          notes: notes?.trim() || 'Ban lifted',
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'USER_UNBANNED',
          targetEntity: 'user',
          targetId: userId,
          diffPayload: {
            previousStatus: existing.moderationStatus,
            newStatus: 'active',
            notes: notes?.trim() || null,
          },
        },
      });

      return next;
    });

    return {
      id: updated.id,
      isActive: updated.isActive,
      moderationStatus: updated.moderationStatus,
    };
  }

  async addUserNote(
    userId: string,
    actorId: string,
    actorName: string,
    note: string,
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Marketplace user not found');
    }

    const notes = Array.isArray(user.internalNotes)
      ? (user.internalNotes as Array<Record<string, unknown>>)
      : [];
    const entry = {
      id: `${Date.now()}`,
      authorId: actorId,
      authorName: actorName,
      note: note.trim(),
      createdAt: new Date().toISOString(),
    };

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.user.update({
        where: { id: userId },
        data: { internalNotes: [...notes, entry] as any },
        select: { id: true, internalNotes: true },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'USER_NOTE_ADDED',
          targetEntity: 'user',
          targetId: userId,
          diffPayload: { noteLength: note.trim().length },
        },
      });
      return next;
    });

    return updated;
  }

  async revokeUserSessions(userId: string, actorId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Marketplace user not found');

    const activeSessions = await this.prisma.userSession.findMany({
      where: { userId, isRevoked: false },
      select: { id: true },
    });

    const result = await this.prisma.userSession.updateMany({
      where: { userId, isRevoked: false },
      data: { isRevoked: true },
    });
    await this.denylistMobileUserTokens(
      userId,
      activeSessions.map((s) => s.id),
    );

    await this.prisma.auditLog.create({
      data: {
        actorType: 'staff',
        actorId,
        action: 'USER_SESSIONS_REVOKED',
        targetEntity: 'user',
        targetId: userId,
        diffPayload: { revokedCount: result.count },
      },
    });

    return { success: true, revokedCount: result.count };
  }

  async listAccounts(query: AdminPaginationDto & { verificationStatus?: string; accountType?: string }) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: any = {
      deletedAt: null,
      ...(query.verificationStatus
        ? { verificationStatus: query.verificationStatus }
        : {}),
      ...(query.accountType ? { accountType: query.accountType } : {}),
      ...(query.q
        ? {
            OR: [
              { displayName: { contains: query.q.trim(), mode: 'insensitive' } },
              { slug: { contains: query.q.trim(), mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [total, items] = await Promise.all([
      this.prisma.account.count({ where }),
      this.prisma.account.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          owner: { select: { id: true, fullName: true, phone: true } },
          _count: { select: { listings: true, branches: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateAccountStatus(
    accountId: string,
    dto: UpdateSellerAccountStatusDto,
    actorId: string,
  ) {
    const account = await this.prisma.account.findUnique({
      where: { id: accountId },
    });
    if (!account) throw new NotFoundException('Seller account not found');

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.account.update({
        where: { id: accountId },
        data: { isActive: dto.isActive },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'SELLER_ACCOUNT_STATUS_UPDATED',
          targetEntity: 'account',
          targetId: accountId,
          diffPayload: {
            previousIsActive: account.isActive,
            newIsActive: dto.isActive,
            reason: dto.reason ?? null,
          },
        },
      });
      return updated;
    });
  }

  // =========================================================================
  // LISTINGS MANAGEMENT
  // =========================================================================

  async listListings(query: AdminListingsQueryDto) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: any = {
      deletedAt: null,
      ...(query.moderationStatus && query.moderationStatus !== 'all'
        ? { moderationStatus: query.moderationStatus }
        : {}),
      ...(query.publicationStatus && query.publicationStatus !== 'all'
        ? { publicationStatus: query.publicationStatus }
        : {}),
      ...(query.availabilityStatus && query.availabilityStatus !== 'all'
        ? { availabilityStatus: query.availabilityStatus }
        : {}),
      ...(query.categoryId ? { categoryId: query.categoryId } : {}),
      ...(query.accountId ? { accountId: query.accountId } : {}),
      ...(query.listingKind ? { listingKind: query.listingKind } : {}),
      ...(query.isDemo !== undefined
        ? { isDemo: query.isDemo === 'true' }
        : {}),
      ...(query.q
        ? {
            OR: [
              { title: { contains: query.q.trim(), mode: 'insensitive' } },
              {
                description: {
                  contains: query.q.trim(),
                  mode: 'insensitive',
                },
              },
              {
                account: {
                  displayName: {
                    contains: query.q.trim(),
                    mode: 'insensitive',
                  },
                },
              },
            ],
          }
        : {}),
    };

    const allowedSort = new Set([
      'createdAt',
      'updatedAt',
      'price',
      'viewsCount',
      'title',
    ]);
    const sortBy = allowedSort.has(query.sortBy || '')
      ? query.sortBy!
      : 'createdAt';
    const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';

    const [total, items] = await Promise.all([
      this.prisma.listing.count({ where }),
      this.prisma.listing.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          category: {
            select: { id: true, nameAr: true, nameEn: true, slug: true },
          },
          area: {
            select: {
              id: true,
              nameAr: true,
              nameEn: true,
              city: {
                select: {
                  id: true,
                  nameAr: true,
                  nameEn: true,
                  governorate: { select: { nameAr: true, nameEn: true } },
                },
              },
            },
          },
          account: {
            select: {
              id: true,
              displayName: true,
              accountType: true,
              verificationStatus: true,
              owner: { select: { id: true, fullName: true, phone: true } },
            },
          },
          media: { orderBy: { sortOrder: 'asc' }, take: 3 },
          _count: { select: { reports: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async getListingDetail(listingId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      include: {
        category: { include: { parent: true } },
        area: {
          include: { city: { include: { governorate: true } } },
        },
        account: {
          include: {
            owner: {
              select: {
                id: true,
                fullName: true,
                phone: true,
                email: true,
                moderationStatus: true,
              },
            },
          },
        },
        media: { orderBy: { sortOrder: 'asc' } },
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          include: {
            reporter: { select: { id: true, fullName: true } },
          },
        },
      },
    });
    if (!listing) throw new NotFoundException('Listing not found');

    const moderationHistory = await this.prisma.moderationLog.findMany({
      where: { targetType: 'listing', targetId: listingId },
      orderBy: { createdAt: 'desc' },
      include: { staff: { select: { id: true, fullName: true, email: true } } },
    });

    return { listing, moderationHistory };
  }

  async transitionListing(
    listingId: string,
    action:
      | 'approve'
      | 'reject'
      | 'request_changes'
      | 'hide'
      | 'restore'
      | 'archive'
      | 'delete',
    actorId: string,
    dto?: ListingActionReasonDto,
    staffId?: string | null,
  ) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
    });
    if (!listing) throw new NotFoundException('Listing not found');

    if (
      (action === 'reject' || action === 'request_changes') &&
      !dto?.notes?.trim() &&
      !dto?.reasonCode?.trim()
    ) {
      throw new BadRequestException(
        'A reason code or notes are required for this action.',
      );
    }

    const updateData: Record<string, unknown> = {};
    if (action === 'approve') {
      updateData.moderationStatus = 'approved';
      updateData.publicationStatus = 'published';
      updateData.approvedAt = listing.approvedAt ?? new Date();
    } else if (action === 'reject') {
      updateData.moderationStatus = 'rejected';
      updateData.publicationStatus = 'unpublished';
    } else if (action === 'request_changes') {
      updateData.moderationStatus = 'pending';
      updateData.publicationStatus = 'unpublished';
    } else if (action === 'hide') {
      updateData.publicationStatus = 'hidden';
    } else if (action === 'restore') {
      updateData.deletedAt = null;
      updateData.publicationStatus =
        listing.moderationStatus === 'approved' ? 'published' : 'unpublished';
    } else if (action === 'archive') {
      updateData.publicationStatus = 'archived';
    } else if (action === 'delete') {
      updateData.publicationStatus = 'archived';
      updateData.deletedAt = new Date();
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.listing.update({
        where: { id: listingId },
        data: updateData,
      });

      await tx.moderationLog.create({
        data: {
          ...(staffId ? { staffId } : {}),
          targetType: 'listing',
          targetId: listingId,
          action,
          reasonCode: dto?.reasonCode ?? null,
          notes: dto?.notes ?? null,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: `ADMIN_LISTING_${action.toUpperCase()}`,
          targetEntity: 'listing',
          targetId: listingId,
          diffPayload: {
            previousModerationStatus: listing.moderationStatus,
            newModerationStatus: next.moderationStatus,
            previousPublicationStatus: listing.publicationStatus,
            newPublicationStatus: next.publicationStatus,
            reasonCode: dto?.reasonCode ?? null,
            notes: dto?.notes ?? null,
          },
        },
      });

      return next;
    });

    await this.invalidateFeedCache();
    return updated;
  }

  async bulkListingDecision(
    dto: BulkListingDecisionDto,
    actorId: string,
    staffId?: string | null,
  ) {
    if (dto.listingIds.length === 0 || dto.listingIds.length > 50) {
      throw new BadRequestException('Select between 1 and 50 listings.');
    }

    const results = [];
    for (const id of dto.listingIds) {
      const res = await this.transitionListing(
        id,
        dto.action,
        actorId,
        { reasonCode: dto.reasonCode, notes: dto.notes },
        staffId,
      );
      results.push({ id: res.id, moderationStatus: res.moderationStatus, publicationStatus: res.publicationStatus });
    }
    return { updatedCount: results.length, items: results };
  }

  // =========================================================================
  // MESSAGING OVERSIGHT (PRIVACY-CONSTRAINED & AUDITED)
  // =========================================================================

  async listMessagingComplaints(query: AdminPaginationDto) {
    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: any = {
      ...(query.q
        ? {
            OR: [
              {
                listing: {
                  title: { contains: query.q.trim(), mode: 'insensitive' },
                },
              },
              {
                buyer: {
                  fullName: { contains: query.q.trim(), mode: 'insensitive' },
                },
              },
              {
                sellerAccount: {
                  displayName: {
                    contains: query.q.trim(),
                    mode: 'insensitive',
                  },
                },
              },
            ],
          }
        : {}),
    };

    const [total, conversations, messagingReports] = await Promise.all([
      this.prisma.conversation.count({ where }),
      this.prisma.conversation.findMany({
        where,
        skip,
        take: limit,
        orderBy: { lastMessageAt: 'desc' },
        select: {
          id: true,
          status: true,
          lastMessageAt: true,
          createdAt: true,
          listing: {
            select: {
              id: true,
              title: true,
              _count: { select: { reports: true } },
            },
          },
          buyer: { select: { id: true, fullName: true } },
          sellerAccount: { select: { id: true, displayName: true } },
          _count: { select: { messages: true } },
        },
      }),
      this.prisma.report.findMany({
        where: {
          reason: { in: ['scam', 'inappropriate', 'other'] },
        },
        orderBy: { createdAt: 'desc' },
        take: 20,
        include: {
          reporter: { select: { id: true, fullName: true } },
          listing: { select: { id: true, title: true } },
          reportedAccount: { select: { id: true, displayName: true } },
        },
      }),
    ]);

    // Attach technical delivery stats per conversation without exposing raw message body
    const convIds = conversations.map((c) => c.id);
    const msgStats =
      convIds.length > 0
        ? await this.prisma.message.groupBy({
            by: ['conversationId', 'status'],
            where: { conversationId: { in: convIds } },
            _count: { _all: true },
          })
        : [];

    const statsByConv = new Map<string, Record<string, number>>();
    for (const s of msgStats) {
      const current = statsByConv.get(s.conversationId) || {
        sent: 0,
        delivered: 0,
        read: 0,
      };
      current[s.status] = s._count._all;
      statsByConv.set(s.conversationId, current);
    }

    return {
      conversations: conversations.map((c) => ({
        ...c,
        deliveryStats: statsByConv.get(c.id) || {
          sent: 0,
          delivered: 0,
          read: 0,
        },
      })),
      relatedComplaints: messagingReports,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async getAuditedConversationMessages(
    conversationId: string,
    actorId: string,
    query: MessagingConversationMessagesQueryDto,
    ipAddress?: string,
  ) {
    if (!query.reason || query.reason.trim().length < 5) {
      throw new ForbiddenException(
        'An explicit operational reason is required to inspect conversation messages.',
      );
    }

    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      select: {
        id: true,
        status: true,
        listingId: true,
        buyer: { select: { id: true, fullName: true } },
        sellerAccount: { select: { id: true, displayName: true } },
      },
    });
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const page = Math.max(Number(query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit) || 30, 1), 100);
    const skip = (page - 1) * limit;

    await this.prisma.auditLog.create({
      data: {
        actorType: 'staff',
        actorId,
        action: 'CHAT_OVERSIGHT_VIEWED',
        targetEntity: 'conversation',
        targetId: conversationId,
        ipAddress: ipAddress?.slice(0, 50),
        diffPayload: {
          reason: query.reason.trim(),
          page,
          limit,
        },
      },
    });

    const [total, messages] = await Promise.all([
      this.prisma.message.count({ where: { conversationId } }),
      this.prisma.message.findMany({
        where: { conversationId },
        skip,
        take: limit,
        orderBy: { sentAt: 'desc' },
        select: {
          id: true,
          senderUserId: true,
          body: true,
          status: true,
          sentAt: true,
          deliveredAt: true,
          readAt: true,
        },
      }),
    ]);

    return {
      conversation,
      items: messages,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateConversationStatus(
    conversationId: string,
    dto: UpdateConversationStatusDto,
    actorId: string,
  ) {
    const existing = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });
    if (!existing) throw new NotFoundException('Conversation not found');

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.conversation.update({
        where: { id: conversationId },
        data: { status: dto.status },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CONVERSATION_STATUS_UPDATED',
          targetEntity: 'conversation',
          targetId: conversationId,
          diffPayload: {
            previousStatus: existing.status,
            newStatus: dto.status,
            reason: dto.reason ?? null,
          },
        },
      });
      return updated;
    });
  }

  private async denylistMobileUserTokens(
    userId: string,
    sessionIds: string[] = [],
  ) {
    if (!this.redis) return;
    const nowEpoch = Math.floor(Date.now() / 1000);
    await Promise.all([
      this.redis
        .set(`auth:revoked:user_before:${userId}`, nowEpoch, 900)
        .catch(() => undefined),
      ...sessionIds.map((sid) =>
        this.redis!.set(`auth:revoked:sid:${sid}`, '1', 900).catch(
          () => undefined,
        ),
      ),
    ]);
  }

  private async invalidateFeedCache() {
    await Promise.all([
      this.redis?.incr?.('listings:feed:ver').catch(() => undefined),
      this.redis?.incr?.('home:feed:ver').catch(() => undefined),
    ]);
  }
}
