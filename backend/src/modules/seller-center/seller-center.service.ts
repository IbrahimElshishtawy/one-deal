import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { VerificationStatus } from '../../core/enums/domain.enums';
import {
  CreateSellerDealDto,
  SellerAnalyticsQueryDto,
  SellerConversationsQueryDto,
  SellerDealsQueryDto,
  SellerDealStatus,
  SellerInteractionsQueryDto,
  SellerListingsQueryDto,
  UpdateSellerDealDto,
} from './dto/seller-center.dto';

@Injectable()
export class SellerCenterService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly securityAudit?: SecurityAuditService,
  ) {}

  /**
   * Resolves all active approved seller account IDs owned or managed by `userId`.
   * Strictly enforces object-level seller isolation so a seller can NEVER read or
   * mutate another seller's management records.
   */
  async getAuthorizedSellerAccountIds(userId: string): Promise<string[]> {
    const accounts = await this.prisma.account.findMany({
      where: {
        isActive: true,
        deletedAt: null,
        verificationStatus: VerificationStatus.APPROVED,
        OR: [
          { ownerUserId: userId },
          {
            members: {
              some: {
                userId,
                role: { in: ['owner', 'manager', 'lister'] },
              },
            },
          },
        ],
      },
      select: { id: true },
    });

    if (accounts.length === 0) {
      throw new ForbiddenException({
        code: 'SELLER_ACCOUNT_NOT_APPROVED',
        message:
          'An active approved seller account is required to access the Seller Center.',
      });
    }

    return accounts.map((a) => a.id);
  }

  /**
   * Unified Seller Center Dashboard summary backed strictly by real database records.
   */
  async getDashboard(userId: string) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);

    const [
      listings,
      favoritesCount,
      conversations,
      pendingBookingsCount,
      deals,
    ] = await Promise.all([
      this.prisma.listing.findMany({
        where: { accountId: { in: accountIds }, deletedAt: null },
        select: {
          id: true,
          title: true,
          price: true,
          currency: true,
          publicationStatus: true,
          moderationStatus: true,
          availabilityStatus: true,
          viewsCount: true,
          contactRevealsCount: true,
          createdAt: true,
          media: {
            take: 1,
            orderBy: { sortOrder: 'asc' },
            select: { publicUrl: true },
          },
          _count: {
            select: { favorites: true, conversations: true },
          },
        },
        orderBy: { viewsCount: 'desc' },
      }),
      this.prisma.favorite.count({
        where: { listing: { accountId: { in: accountIds }, deletedAt: null } },
      }),
      this.prisma.conversation.findMany({
        where: { sellerAccountId: { in: accountIds } },
        orderBy: { lastMessageAt: 'desc' },
        take: 10,
        include: {
          listing: { select: { id: true, title: true, price: true } },
          buyer: { select: { id: true, fullName: true, avatarUrl: true } },
          messages: {
            where: { senderUserId: { not: userId }, status: { not: 'read' } },
            select: { id: true },
          },
        },
      }),
      this.prisma.booking.count({
        where: {
          providerAccountId: { in: accountIds },
          status: 'pending',
        },
      }),
      this.prisma.sellerDeal.findMany({
        where: { sellerAccountId: { in: accountIds } },
        orderBy: { updatedAt: 'desc' },
        take: 20,
        include: {
          listing: { select: { id: true, title: true } },
        },
      }),
    ]);

    const totalAds = listings.length;
    const activeAds = listings.filter(
      (l) =>
        l.publicationStatus === 'published' &&
        l.availabilityStatus === 'available',
    ).length;
    const totalViews = listings.reduce(
      (sum, l) => sum + (l.viewsCount || 0),
      0,
    );
    const totalContacts = listings.reduce(
      (sum, l) => sum + (l.contactRevealsCount || 0),
      0,
    );
    const unreadConversationsCount = conversations.filter(
      (c) => c.messages.length > 0,
    ).length;
    const completedDealsCount = deals.filter(
      (d) => d.status === SellerDealStatus.COMPLETED,
    ).length;

    const topListings = listings.slice(0, 5).map((l) => ({
      id: l.id,
      title: l.title,
      price: Number(l.price),
      currency: l.currency,
      publicationStatus: l.publicationStatus,
      availabilityStatus: l.availabilityStatus,
      viewsCount: l.viewsCount,
      favoritesCount: l._count.favorites,
      inquiriesCount: l._count.conversations + l.contactRevealsCount,
      thumbnailUrl: l.media[0]?.publicUrl ?? null,
    }));

    const recentConversations = conversations.slice(0, 5).map((c) => ({
      id: c.id,
      listingId: c.listingId,
      listingTitle: c.listing?.title ?? '',
      customerName: c.buyer?.fullName ?? 'Customer',
      customerAvatarUrl: c.buyer?.avatarUrl ?? null,
      lastMessageText: c.lastMessageText ?? '',
      lastMessageAt: c.lastMessageAt,
      unreadCount: c.messages.length,
    }));

    const recentActivities = [
      ...deals.slice(0, 5).map((d) => ({
        id: `deal-${d.id}`,
        type: 'deal',
        title: d.listing?.title ?? d.customerName,
        subtitle: `${d.customerName} • ${d.status}`,
        timestamp: d.updatedAt,
      })),
      ...recentConversations.slice(0, 3).map((c) => ({
        id: `conv-${c.id}`,
        type: 'inquiry',
        title: c.listingTitle,
        subtitle: `${c.customerName}: ${c.lastMessageText}`,
        timestamp: c.lastMessageAt ?? new Date(),
      })),
    ]
      .sort(
        (a, b) =>
          new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
      )
      .slice(0, 8);

    return {
      summary: {
        totalAds,
        activeAds,
        totalViews,
        totalFavorites: favoritesCount,
        totalContacts,
        totalConversations: conversations.length,
        unreadConversations: unreadConversationsCount,
        pendingInquiries: unreadConversationsCount + pendingBookingsCount,
        completedDealsCount,
        totalDealsCount: deals.length,
      },
      topListings,
      recentConversations,
      recentActivities,
      capabilities: {
        hasDedicatedSocialPosts: false,
        v1SalesCrmSellerReportedOnly: true,
      },
    };
  }

  /**
   * Paginated seller advertisements with real metrics & filters.
   */
  async getSellerListings(userId: string, query: SellerListingsQueryDto) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: any = {
      accountId: { in: accountIds },
      deletedAt: null,
    };

    if (query.status && query.status !== 'all') {
      if (['draft', 'pending', 'rejected'].includes(query.status)) {
        where.moderationStatus = query.status;
      } else {
        where.publicationStatus = query.status;
      }
    }

    if (query.availability && query.availability !== 'all') {
      where.availabilityStatus = query.availability;
    }

    if (query.search && query.search.trim().length > 0) {
      where.OR = [
        { title: { contains: query.search.trim(), mode: 'insensitive' } },
        { description: { contains: query.search.trim(), mode: 'insensitive' } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.listing.count({ where }),
      this.prisma.listing.findMany({
        where,
        skip,
        take: limit,
        orderBy: { updatedAt: 'desc' },
        include: {
          category: { select: { slug: true, nameAr: true, nameEn: true } },
          media: {
            take: 1,
            orderBy: { sortOrder: 'asc' },
            select: { publicUrl: true },
          },
          _count: {
            select: { favorites: true, conversations: true, bookings: true },
          },
        },
      }),
    ]);

    return {
      items: items.map((l) => ({
        id: l.id,
        title: l.title,
        price: Number(l.price),
        currency: l.currency,
        listingKind: l.listingKind,
        moderationStatus: l.moderationStatus,
        publicationStatus: l.publicationStatus,
        availabilityStatus: l.availabilityStatus,
        categorySlug: l.category?.slug ?? '',
        categoryNameAr: l.category?.nameAr ?? '',
        categoryNameEn: l.category?.nameEn ?? '',
        thumbnailUrl: l.media[0]?.publicUrl ?? null,
        viewsCount: l.viewsCount,
        favoritesCount: l._count.favorites,
        contactRevealsCount: l.contactRevealsCount,
        inquiriesCount: l._count.conversations + l._count.bookings,
        createdAt: l.createdAt,
        updatedAt: l.updatedAt,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Unified seller interactions center (inquiries, bookings, favorites)
   * exposing only safe, authorized customer display fields (zero private PII).
   */
  async getInteractions(userId: string, query: SellerInteractionsQueryDto) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const typeFilter = (query.type || 'all').toLowerCase();

    const dateFilter: any = {};
    if (query.from) {
      const parsed = new Date(query.from);
      if (!Number.isNaN(parsed.getTime())) dateFilter.gte = parsed;
    }
    if (query.to) {
      const parsed = new Date(query.to);
      if (!Number.isNaN(parsed.getTime())) dateFilter.lte = parsed;
    }
    const hasDateFilter = Object.keys(dateFilter).length > 0;

    const listingScope = {
      accountId: { in: accountIds },
      deletedAt: null,
      ...(query.listingId ? { id: query.listingId } : {}),
    };

    const [listingTotals, conversations, bookings, favorites] =
      await Promise.all([
        this.prisma.listing.aggregate({
          where: listingScope,
          _sum: { viewsCount: true, contactRevealsCount: true },
        }),
        typeFilter === 'all' || typeFilter === 'inquiry'
          ? this.prisma.conversation.findMany({
              where: {
                sellerAccountId: { in: accountIds },
                ...(query.listingId ? { listingId: query.listingId } : {}),
                ...(hasDateFilter ? { createdAt: dateFilter } : {}),
              },
              orderBy: { createdAt: 'desc' },
              take: 50,
              include: {
                listing: { select: { id: true, title: true } },
                buyer: { select: { fullName: true } },
              },
            })
          : Promise.resolve([]),
        typeFilter === 'all' || typeFilter === 'booking'
          ? this.prisma.booking.findMany({
              where: {
                providerAccountId: { in: accountIds },
                ...(query.listingId ? { listingId: query.listingId } : {}),
                ...(hasDateFilter ? { createdAt: dateFilter } : {}),
              },
              orderBy: { createdAt: 'desc' },
              take: 50,
              include: {
                listing: { select: { id: true, title: true } },
                user: { select: { fullName: true } },
              },
            })
          : Promise.resolve([]),
        typeFilter === 'all' || typeFilter === 'favorite'
          ? this.prisma.favorite.findMany({
              where: {
                listing: listingScope,
                ...(hasDateFilter ? { createdAt: dateFilter } : {}),
              },
              orderBy: { createdAt: 'desc' },
              take: 50,
              include: {
                listing: { select: { id: true, title: true } },
                user: { select: { fullName: true } },
              },
            })
          : Promise.resolve([]),
      ]);

    const combined = [
      ...conversations.map((c) => ({
        id: `inquiry-${c.id}`,
        type: 'inquiry',
        listingId: c.listingId,
        listingTitle: c.listing?.title ?? '',
        actorName: c.buyer?.fullName ?? 'Customer',
        summary: c.lastMessageText || 'Started a conversation',
        createdAt: c.lastMessageAt ?? c.createdAt,
      })),
      ...bookings.map((b) => ({
        id: `booking-${b.id}`,
        type: 'booking',
        listingId: b.listingId,
        listingTitle: b.listing?.title ?? b.reference,
        actorName: b.user?.fullName ?? 'Customer',
        summary: `Booking request (${b.status})`,
        createdAt: b.createdAt,
      })),
      ...favorites.map((f) => ({
        id: `favorite-${f.id}`,
        type: 'favorite',
        listingId: f.listingId,
        listingTitle: f.listing?.title ?? '',
        actorName: f.user?.fullName ?? 'Marketplace User',
        summary: 'Saved listing to favorites',
        createdAt: f.createdAt,
      })),
    ].sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );

    const start = (page - 1) * limit;
    const paged = combined.slice(start, start + limit);

    return {
      summary: {
        views: listingTotals._sum.viewsCount ?? 0,
        contactRequests: listingTotals._sum.contactRevealsCount ?? 0,
        favorites: favorites.length,
        inquiries: conversations.length,
        bookings: bookings.length,
        comments: 0,
        shares: 0,
      },
      items: paged,
      meta: {
        total: combined.length,
        page,
        limit,
        totalPages: Math.ceil(combined.length / limit),
      },
    };
  }

  /**
   * Seller-scoped inbox conversations with unread count, search, and listing filter.
   */
  async getSellerConversations(
    userId: string,
    query: SellerConversationsQueryDto,
  ) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const conversations = await this.prisma.conversation.findMany({
      where: {
        sellerAccountId: { in: accountIds },
        ...(query.listingId ? { listingId: query.listingId } : {}),
        ...(query.search && query.search.trim().length > 0
          ? {
              OR: [
                {
                  buyer: {
                    fullName: {
                      contains: query.search.trim(),
                      mode: 'insensitive',
                    },
                  },
                },
                {
                  listing: {
                    title: {
                      contains: query.search.trim(),
                      mode: 'insensitive',
                    },
                  },
                },
                {
                  lastMessageText: {
                    contains: query.search.trim(),
                    mode: 'insensitive',
                  },
                },
              ],
            }
          : {}),
      },
      orderBy: { lastMessageAt: 'desc' },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            media: {
              take: 1,
              orderBy: { sortOrder: 'asc' },
              select: { publicUrl: true },
            },
          },
        },
        buyer: { select: { id: true, fullName: true, avatarUrl: true } },
        messages: {
          where: { senderUserId: { not: userId }, status: { not: 'read' } },
          select: { id: true },
        },
      },
    });

    const mapped = conversations
      .map((c) => ({
        id: c.id,
        listingId: c.listingId,
        listingTitle: c.listing?.title ?? '',
        listingPrice: Number(c.listing?.price ?? 0),
        listingThumbnailUrl: c.listing?.media?.[0]?.publicUrl ?? null,
        customerUserId: c.buyerUserId,
        customerName: c.buyer?.fullName ?? 'Customer',
        customerAvatarUrl: c.buyer?.avatarUrl ?? null,
        lastMessageText: c.lastMessageText ?? '',
        lastMessageAt: c.lastMessageAt ?? c.createdAt,
        unreadCount: c.messages.length,
      }))
      .filter((c) => (query.unreadOnly === 'true' ? c.unreadCount > 0 : true));

    const start = (page - 1) * limit;
    return {
      items: mapped.slice(start, start + limit),
      meta: {
        total: mapped.length,
        page,
        limit,
        totalPages: Math.ceil(mapped.length / limit),
      },
    };
  }

  /**
   * Lists seller-managed CRM deals scoped strictly to the seller's approved accounts.
   */
  async getDeals(userId: string, query: SellerDealsQueryDto) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: any = {
      sellerAccountId: { in: accountIds },
      ...(query.status ? { status: query.status } : {}),
      ...(query.listingId ? { listingId: query.listingId } : {}),
      ...(query.search && query.search.trim().length > 0
        ? {
            OR: [
              {
                customerName: {
                  contains: query.search.trim(),
                  mode: 'insensitive',
                },
              },
              {
                customerReference: {
                  contains: query.search.trim(),
                  mode: 'insensitive',
                },
              },
              {
                listing: {
                  title: {
                    contains: query.search.trim(),
                    mode: 'insensitive',
                  },
                },
              },
            ],
          }
        : {}),
    };

    const [total, deals] = await Promise.all([
      this.prisma.sellerDeal.count({ where }),
      this.prisma.sellerDeal.findMany({
        where,
        skip,
        take: limit,
        orderBy: { updatedAt: 'desc' },
        include: {
          listing: {
            select: {
              id: true,
              title: true,
              price: true,
              currency: true,
              media: {
                take: 1,
                orderBy: { sortOrder: 'asc' },
                select: { publicUrl: true },
              },
            },
          },
        },
      }),
    ]);

    return {
      items: deals.map((d) => this.formatDeal(d)),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Creates a seller-managed CRM deal record after verifying listing ownership.
   */
  async createDeal(userId: string, dto: CreateSellerDealDto) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);

    const listing = await this.prisma.listing.findUnique({
      where: { id: dto.listingId },
      select: {
        id: true,
        accountId: true,
        price: true,
        currency: true,
        deletedAt: true,
      },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    if (!accountIds.includes(listing.accountId)) {
      throw new ForbiddenException(
        'You cannot create a sales record for a listing you do not own',
      );
    }

    const status = dto.status ?? SellerDealStatus.NEW_INQUIRY;
    const created = await this.prisma.sellerDeal.create({
      data: {
        sellerAccountId: listing.accountId,
        createdByUserId: userId,
        listingId: listing.id,
        customerUserId: dto.customerUserId ?? null,
        customerName: dto.customerName.trim(),
        customerReference: dto.customerReference?.trim() || null,
        conversationId: dto.conversationId ?? null,
        initialPrice: listing.price,
        agreedPrice: dto.agreedPrice ?? null,
        currency: listing.currency,
        status,
        sellerReportedOnly: true,
        notes: dto.notes?.trim() || null,
        completedAt: status === SellerDealStatus.COMPLETED ? new Date() : null,
      },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            currency: true,
            media: {
              take: 1,
              orderBy: { sortOrder: 'asc' },
              select: { publicUrl: true },
            },
          },
        },
      },
    });

    await this.securityAudit?.logEvent({
      action: 'SELLER_CRM_DEAL_CREATED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerDeal',
      targetId: created.id,
      metadata: {
        listingId: listing.id,
        status: created.status,
        sellerReportedOnly: true,
      },
    });

    return this.formatDeal(created);
  }

  /**
   * Updates a seller CRM deal record after strict object-level ownership check.
   */
  async updateDeal(userId: string, dealId: string, dto: UpdateSellerDealDto) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);
    const existing = await this.prisma.sellerDeal.findUnique({
      where: { id: dealId },
    });

    if (!existing) {
      throw new NotFoundException('Sales record not found');
    }

    if (!accountIds.includes(existing.sellerAccountId)) {
      throw new ForbiddenException(
        'You do not have permission to modify this sales record',
      );
    }

    const nextStatus = dto.status ?? (existing.status as SellerDealStatus);
    const completedAt =
      nextStatus === SellerDealStatus.COMPLETED
        ? (existing.completedAt ?? new Date())
        : null;

    const updated = await this.prisma.sellerDeal.update({
      where: { id: dealId },
      data: {
        ...(dto.status ? { status: dto.status, completedAt } : {}),
        ...(dto.agreedPrice !== undefined
          ? { agreedPrice: dto.agreedPrice }
          : {}),
        ...(dto.customerName !== undefined
          ? { customerName: dto.customerName.trim() }
          : {}),
        ...(dto.customerReference !== undefined
          ? { customerReference: dto.customerReference.trim() || null }
          : {}),
        ...(dto.notes !== undefined ? { notes: dto.notes.trim() || null } : {}),
      },
      include: {
        listing: {
          select: {
            id: true,
            title: true,
            price: true,
            currency: true,
            media: {
              take: 1,
              orderBy: { sortOrder: 'asc' },
              select: { publicUrl: true },
            },
          },
        },
      },
    });

    await this.securityAudit?.logEvent({
      action: 'SELLER_CRM_DEAL_UPDATED',
      actorType: 'user',
      actorId: userId,
      targetEntity: 'SellerDeal',
      targetId: dealId,
      metadata: {
        previousStatus: existing.status,
        newStatus: updated.status,
      },
    });

    return this.formatDeal(updated);
  }

  /**
   * Deletes a seller CRM deal record after strict object-level ownership check.
   */
  async deleteDeal(userId: string, dealId: string) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);
    const existing = await this.prisma.sellerDeal.findUnique({
      where: { id: dealId },
    });

    if (!existing) {
      throw new NotFoundException('Sales record not found');
    }

    if (!accountIds.includes(existing.sellerAccountId)) {
      throw new ForbiddenException(
        'You do not have permission to delete this sales record',
      );
    }

    await this.prisma.sellerDeal.delete({ where: { id: dealId } });
    return { deleted: true, id: dealId };
  }

  /**
   * Real backend seller analytics (zero synthetic/fake metrics).
   */
  async getAnalytics(userId: string, query: SellerAnalyticsQueryDto) {
    const accountIds = await this.getAuthorizedSellerAccountIds(userId);
    const range = (query.range || '30d').toLowerCase();
    const now = new Date();
    let since: Date | null = null;
    if (range === '7d') {
      since = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    } else if (range === '30d') {
      since = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    } else if (range === '90d') {
      since = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
    }

    const dateWhere = since ? { createdAt: { gte: since } } : {};

    const [listings, favoritesCount, conversations, bookingsCount, deals] =
      await Promise.all([
        this.prisma.listing.findMany({
          where: { accountId: { in: accountIds }, deletedAt: null },
          select: {
            id: true,
            title: true,
            price: true,
            currency: true,
            publicationStatus: true,
            availabilityStatus: true,
            viewsCount: true,
            contactRevealsCount: true,
            _count: { select: { favorites: true, conversations: true } },
          },
          orderBy: { viewsCount: 'desc' },
        }),
        this.prisma.favorite.count({
          where: {
            listing: { accountId: { in: accountIds }, deletedAt: null },
            ...dateWhere,
          },
        }),
        this.prisma.conversation.findMany({
          where: { sellerAccountId: { in: accountIds }, ...dateWhere },
          select: {
            id: true,
            createdAt: true,
            messages: {
              where: { senderUserId: userId },
              take: 1,
              select: { id: true },
            },
          },
        }),
        this.prisma.booking.count({
          where: { providerAccountId: { in: accountIds }, ...dateWhere },
        }),
        this.prisma.sellerDeal.findMany({
          where: { sellerAccountId: { in: accountIds }, ...dateWhere },
          select: { id: true, status: true, createdAt: true },
        }),
      ]);

    const totalAds = listings.length;
    const activeAds = listings.filter(
      (l) =>
        l.publicationStatus === 'published' &&
        l.availabilityStatus === 'available',
    ).length;
    const totalViews = listings.reduce(
      (sum, l) => sum + (l.viewsCount || 0),
      0,
    );
    const totalContacts = listings.reduce(
      (sum, l) => sum + (l.contactRevealsCount || 0),
      0,
    );
    const repliedConversations = conversations.filter(
      (c) => c.messages.length > 0,
    ).length;
    const responseRate =
      conversations.length > 0
        ? Math.round((repliedConversations / conversations.length) * 100)
        : 0;
    const completedDeals = deals.filter(
      (d) => d.status === SellerDealStatus.COMPLETED,
    ).length;

    // Group conversations + deals by day (YYYY-MM-DD) for real chart series
    const dayBuckets = new Map<
      string,
      { date: string; inquiries: number; deals: number }
    >();
    for (const c of conversations) {
      const key = new Date(c.createdAt).toISOString().slice(0, 10);
      const entry = dayBuckets.get(key) ?? {
        date: key,
        inquiries: 0,
        deals: 0,
      };
      entry.inquiries += 1;
      dayBuckets.set(key, entry);
    }
    for (const d of deals) {
      const key = new Date(d.createdAt).toISOString().slice(0, 10);
      const entry = dayBuckets.get(key) ?? {
        date: key,
        inquiries: 0,
        deals: 0,
      };
      entry.deals += 1;
      dayBuckets.set(key, entry);
    }
    const series = Array.from(dayBuckets.values()).sort((a, b) =>
      a.date.localeCompare(b.date),
    );

    return {
      range,
      metrics: {
        totalAds,
        activeAds,
        totalViews,
        totalFavorites: favoritesCount,
        customerInquiries: conversations.length + bookingsCount + totalContacts,
        conversationsCount: conversations.length,
        completedSellerReportedDeals: completedDeals,
        responseRatePercent: responseRate,
      },
      topPerformingAds: listings.slice(0, 5).map((l) => ({
        id: l.id,
        title: l.title,
        price: Number(l.price),
        currency: l.currency,
        viewsCount: l.viewsCount,
        favoritesCount: l._count.favorites,
        inquiriesCount: l._count.conversations + l.contactRevealsCount,
      })),
      dailySeries: series,
    };
  }

  private formatDeal(d: any) {
    return {
      id: d.id,
      sellerAccountId: d.sellerAccountId,
      listingId: d.listingId,
      listingTitle: d.listing?.title ?? '',
      listingThumbnailUrl: d.listing?.media?.[0]?.publicUrl ?? null,
      customerUserId: d.customerUserId ?? null,
      customerName: d.customerName,
      customerReference: d.customerReference ?? null,
      conversationId: d.conversationId ?? null,
      initialPrice: Number(d.initialPrice),
      agreedPrice:
        d.agreedPrice !== null && d.agreedPrice !== undefined
          ? Number(d.agreedPrice)
          : null,
      currency: d.currency,
      status: d.status,
      sellerReportedOnly: Boolean(d.sellerReportedOnly),
      notes: d.notes ?? null,
      completedAt: d.completedAt ?? null,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
    };
  }
}
