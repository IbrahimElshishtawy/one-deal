import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import {
  ModerationStatus,
  PublicationStatus,
} from '../../core/enums/domain.enums';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { SecurityAuditService } from '../../core/security/security-audit.service';
import { normalizeArabicText } from '../search/arabic-normalizer';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { FilterListingsDto } from './dto/filter-listings.dto';
import {
  assertValidModerationTransition,
  assertValidPublicationTransition,
} from './listings-state-machine';

@Injectable()
export class ListingsService {
  private readonly publicCdnDomain: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly redis: RedisService,
    private readonly securityAudit: SecurityAuditService,
  ) {
    this.publicCdnDomain = this.configService.get<string>(
      'R2_PUBLIC_DOMAIN',
      'https://cdn.marketspace.eg',
    );
  }

  /**
   * Creates a new listing with validated attributes, ownership-isolated media, and 30-day lifecycle.
   */
  async createListing(userId: string, dto: CreateListingDto) {
    // 1. Validate Category and dynamic attributes
    const category = await this.prisma.category.findUnique({
      where: { id: dto.categoryId },
      include: { fields: { where: { isActive: true } } },
    });

    if (!category || !category.isActive) {
      throw new BadRequestException(
        'Selected category does not exist or is inactive',
      );
    }

    // Validate required dynamic attributes
    const dynamicAttrs = dto.attributes || {};
    for (const field of category.fields) {
      if (
        field.isRequired &&
        (dynamicAttrs[field.fieldKey] === undefined ||
          dynamicAttrs[field.fieldKey] === null)
      ) {
        throw new BadRequestException(
          `Required attribute '${field.labelAr} (${field.fieldKey})' is missing`,
        );
      }
    }

    // 2. Validate City
    const city = await this.prisma.city.findUnique({
      where: { id: dto.cityId },
    });
    if (!city || !city.isActive) {
      throw new BadRequestException(
        'Selected city does not exist or is inactive',
      );
    }

    // 3. Media Ownership Security Check
    // Verifies that every mediaKey belongs to the requesting user's folder
    for (const key of dto.mediaKeys) {
      if (!key.includes(`/${userId}/`)) {
        throw new ForbiddenException(
          `Unauthorized media key: ${key}. You can only attach your own uploaded media.`,
        );
      }
    }

    // 4. Calculate Expiration (30 Days)
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    // 5. Database Transaction to insert listing and media items
    return this.prisma.$transaction(async (tx) => {
      // Find or create account for individual user
      let account = await tx.account.findFirst({
        where: { ownerUserId: userId },
      });
      if (!account) {
        account = await tx.account.create({
          data: {
            ownerUserId: userId,
            accountType: 'individual',
            displayName: `User ${userId.substring(0, 6)}`,
            slug: `user-${userId.substring(0, 8)}`,
          },
        });
      }

      // Find an area in this city or fallback
      let area = await tx.area.findFirst({
        where: { cityId: dto.cityId },
      });
      if (!area) {
        area = await tx.area.findFirst();
      }

      if (!area) {
        throw new BadRequestException('No geographic area found for this city');
      }

      const autoApprove =
        this.configService.get<boolean>('AUTO_APPROVE_LISTINGS', false) ===
        true;
      const moderationStatus = autoApprove
        ? ModerationStatus.APPROVED
        : ModerationStatus.PENDING;
      const publicationStatus = autoApprove
        ? PublicationStatus.PUBLISHED
        : PublicationStatus.UNPUBLISHED;

      const listing = await tx.listing.create({
        data: {
          accountId: account.id,
          categoryId: dto.categoryId,
          areaId: area.id,
          title: dto.title,
          description: dto.description,
          searchNormalizedText: normalizeArabicText(
            `${dto.title} ${dto.description}`,
          ),
          price: dto.price,
          currency: 'EGP',
          listingKind: 'sale',
          contactChannel: 'in_app',
          moderationStatus,
          publicationStatus,
          availabilityStatus: 'available',
          attributes: (dynamicAttrs as any) ?? {},
          expiresAt,
        },
      });

      if ((tx as any).outboxEvent?.create) {
        await (tx as any).outboxEvent.create({
          data: {
            aggregateType: 'Listing',
            aggregateId: listing.id,
            eventType: autoApprove
              ? 'LISTING_PUBLISHED'
              : 'LISTING_SUBMITTED_FOR_MODERATION',
            payload: {
              listingId: listing.id,
              accountId: account.id,
              moderationStatus,
              publicationStatus,
            },
          },
        });
      }

      // Insert image media records
      const mediaRecords = dto.mediaKeys.map((key, index) => ({
        listingId: listing.id,
        mediaType: 'image',
        storageKey: key,
        publicUrl: `${this.publicCdnDomain}/${key}`,
        sortOrder: index,
        processingStatus: 'ready',
      }));

      // Insert optional Cloudflare Stream video record if provided
      if (dto.videoStreamUid) {
        mediaRecords.push({
          listingId: listing.id,
          mediaType: 'video',
          storageKey: `cloudflare-stream/${dto.videoStreamUid}`,
          publicUrl: `https://videodelivery.net/${dto.videoStreamUid}/manifest/video.m3u8`,
          sortOrder: dto.mediaKeys.length,
          processingStatus: 'ready',
        });
      }

      await tx.listingMedia.createMany({
        data: mediaRecords,
      });

      await this.invalidateFeedCache();

      return tx.listing.findUnique({
        where: { id: listing.id },
        include: {
          media: { orderBy: { sortOrder: 'asc' } },
          category: {
            select: { id: true, nameAr: true, nameEn: true, slug: true },
          },
          area: {
            include: {
              city: {
                include: { governorate: true },
              },
            },
          },
        },
      });
    });
  }

  /**
   * Retrieves public listings feed with cursor-based pagination, dynamic attribute filtering, and spatial radius search.
   */
  async getListingsFeed(filters: FilterListingsDto) {
    const feedVersion =
      (await this.redis?.get?.<number>('listings:feed:ver')) ?? 1;
    const filterHash = crypto
      .createHash('sha1')
      .update(JSON.stringify(filters))
      .digest('hex');
    const cacheKey = `listings:feed:v${feedVersion}:${filterHash}`;
    const cachedFeed = await this.redis?.get?.<any>(cacheKey);
    if (cachedFeed) {
      return cachedFeed;
    }

    const {
      categoryId,
      categorySlug,
      category_slug,
      q,
      sort,
      sort_by,
      governorateId,
      cityId,
      minPrice,
      maxPrice,
      condition,
      listingKind,
      featured,
      size,
      color,
      lat,
      latitude,
      lng,
      longitude,
      radiusKm,
      radius_km,
      rooms,
      baths,
      finishing,
      furnished,
      brand,
      make,
      model,
      year,
      transmission,
      fuelType,
      fuel_type,
      unitType,
      unit_type,
      attributes,
      isDemo,
      cursor,
      limit = 20,
    } = filters;

    const where: any = {
      publicationStatus: 'published',
      deletedAt: null,
    };

    if (listingKind) {
      where.listingKind = listingKind;
    }

    if (featured === true) {
      where.promotedUntil = { gt: new Date() };
    }

    const isProd =
      this.configService.get<string>('NODE_ENV', 'development') ===
      'production';
    const enableDemo =
      this.configService.get<boolean>('ENABLE_DEMO_DATA', false) === true;

    if (isProd && !enableDemo) {
      where.isDemo = false;
    } else if (isDemo !== undefined) {
      where.isDemo = isDemo;
    }

    // Category resolution with hierarchical subcategory inclusion
    const targetSlug = categorySlug || category_slug;
    if (targetSlug && !categoryId) {
      const hyphenSlug = targetSlug.toLowerCase().replace(/_/g, '-');
      const underscoreSlug = targetSlug.toLowerCase().replace(/-/g, '_');
      const category = await this.prisma.category.findFirst({
        where: {
          OR: [
            { slug: hyphenSlug },
            { slug: underscoreSlug },
            { slug: targetSlug },
          ],
        },
        include: { children: { select: { id: true } } },
      });

      if (category) {
        const categoryIds = [
          category.id,
          ...category.children.map((c) => c.id),
        ];
        where.categoryId = { in: categoryIds };
      }
    } else if (categoryId) {
      const category = await this.prisma.category.findUnique({
        where: { id: categoryId },
        include: { children: { select: { id: true } } },
      });
      if (category) {
        const categoryIds = [
          category.id,
          ...category.children.map((c) => c.id),
        ];
        where.categoryId = { in: categoryIds };
      } else {
        where.categoryId = categoryId;
      }
    }

    if (cityId) where.area = { cityId };
    if (governorateId) where.area = { city: { governorateId } };

    if (minPrice !== undefined || maxPrice !== undefined) {
      where.price = {};
      if (minPrice !== undefined) where.price.gte = minPrice;
      if (maxPrice !== undefined) where.price.lte = maxPrice;
    }

    if (cursor) {
      where.refreshedAt = { lt: new Date(cursor) };
    }

    const searchTerm = (q || filters.query || '').trim();
    if (searchTerm.length > 0) {
      where.OR = [
        { title: { contains: searchTerm, mode: 'insensitive' } },
        { description: { contains: searchTerm, mode: 'insensitive' } },
      ];
    }

    // Dynamic Category Attribute Filters inside JSONB
    const andFilters: any[] = [];
    if (condition) {
      andFilters.push({
        attributes: { path: ['condition'], equals: condition },
      });
    }
    if (size) {
      andFilters.push({
        attributes: { path: ['size'], equals: size },
      });
    }
    if (color) {
      andFilters.push({
        attributes: { path: ['color'], equals: color },
      });
    }
    if (rooms !== undefined) {
      andFilters.push({
        attributes: { path: ['rooms'], equals: Number(rooms) },
      });
    }
    if (baths !== undefined) {
      andFilters.push({
        attributes: { path: ['baths'], equals: Number(baths) },
      });
    }
    if (finishing) {
      andFilters.push({
        attributes: { path: ['finishing'], equals: finishing },
      });
    }
    if (furnished !== undefined) {
      andFilters.push({
        attributes: { path: ['furnished'], equals: Boolean(furnished) },
      });
    }
    const brandVal = brand || make;
    if (brandVal) {
      andFilters.push({
        OR: [
          { attributes: { path: ['brand'], equals: brandVal } },
          { attributes: { path: ['make'], equals: brandVal } },
        ],
      });
    }
    if (model) {
      andFilters.push({ attributes: { path: ['model'], equals: model } });
    }
    if (year !== undefined) {
      andFilters.push({ attributes: { path: ['year'], equals: Number(year) } });
    }
    if (transmission) {
      andFilters.push({
        attributes: { path: ['transmission'], equals: transmission },
      });
    }
    const fuelVal = fuelType || fuel_type;
    if (fuelVal) {
      andFilters.push({ attributes: { path: ['fuel_type'], equals: fuelVal } });
    }
    const unitVal = unitType || unit_type;
    if (unitVal) {
      andFilters.push({ attributes: { path: ['unit_type'], equals: unitVal } });
    }
    if (attributes) {
      try {
        const parsed =
          typeof attributes === 'string' ? JSON.parse(attributes) : attributes;
        if (parsed && typeof parsed === 'object') {
          for (const [key, val] of Object.entries(parsed)) {
            if (val !== undefined && val !== null && val !== '') {
              andFilters.push({ attributes: { path: [key], equals: val } });
            }
          }
        }
      } catch {}
    }
    if (andFilters.length > 0) {
      where.AND = andFilters;
    }

    // Geographic spatial radius filtering via PostGIS
    const targetLat = lat ?? latitude;
    const targetLng = lng ?? longitude;
    const targetRadius = (radiusKm ?? radius_km ?? 25) * 1000;
    if (targetLat !== undefined && targetLng !== undefined) {
      try {
        const nearbyListings = await this.prisma.$queryRaw<
          Array<{ id: string }>
        >`
          SELECT id FROM listings
          WHERE publication_status = 'published'
            AND deleted_at IS NULL
            AND ST_DWithin(
              display_location,
              ST_SetSRID(ST_MakePoint(${targetLng}, ${targetLat}), 4326)::geography,
              ${targetRadius}
            )
          ORDER BY display_location <-> ST_SetSRID(ST_MakePoint(${targetLng}, ${targetLat}), 4326) ASC
          LIMIT 300;
        `;
        where.id = { in: nearbyListings.map((r) => r.id) };
      } catch {}
    }

    // Ordering logic
    const sortVal = sort || sort_by;
    let orderBy: any = [{ refreshedAt: 'desc' }];
    if (sortVal === 'price_asc') {
      orderBy = [{ price: 'asc' }, { refreshedAt: 'desc' }];
    } else if (sortVal === 'price_desc') {
      orderBy = [{ price: 'desc' }, { refreshedAt: 'desc' }];
    }

    const items = await this.prisma.listing.findMany({
      where,
      take: limit + 1,
      orderBy,
      include: {
        category: {
          select: {
            id: true,
            slug: true,
            nameAr: true,
            nameEn: true,
            parentId: true,
          },
        },
        media: {
          where: { mediaType: 'image' },
          orderBy: { sortOrder: 'asc' },
          take: 5,
        },
        area: {
          include: {
            city: {
              include: { governorate: true },
            },
          },
        },
        account: {
          select: {
            id: true,
            displayName: true,
            slug: true,
            accountType: true,
            logoUrl: true,
            verificationStatus: true,
          },
        },
        _count: {
          select: { favorites: true },
        },
      },
    });

    let nextCursor: string | null = null;
    let results = items;

    if (items.length > limit) {
      const nextItem = items[items.length - 1];
      nextCursor = nextItem.refreshedAt.toISOString();
      results = items.slice(0, limit);
    }

    const now = new Date();
    const mappedData = results.map((item) => {
      const attrs = (item.attributes as any) || {};
      return {
        id: item.id,
        title: item.title,
        description: item.description,
        price: Number(item.price),
        currency: item.currency || 'EGP',
        condition: attrs.condition || 'USED',
        listingKind: item.listingKind,
        contactChannel: item.contactChannel,
        moderationStatus: item.moderationStatus,
        publicationStatus: item.publicationStatus,
        availabilityStatus: item.availabilityStatus,
        isDemo: item.isDemo,
        isFeatured: Boolean(item.promotedUntil && item.promotedUntil > now),
        categoryId: item.categoryId,
        category: item.category,
        governorateName: item.area.city.governorate.nameAr,
        cityName: item.area.city.nameAr,
        areaName: item.area.nameAr,
        location: `${item.area.city.nameAr}، ${item.area.city.governorate.nameAr}`,
        primaryImageUrl: item.media[0]?.publicUrl ?? null,
        imageUrl: item.media[0]?.publicUrl ?? null,
        thumbnail: item.media[0]?.thumbnailUrl ?? item.media[0]?.publicUrl ?? null,
        media: item.media,
        attributes: attrs,
        viewsCount: item.viewsCount,
        favoritesCount: (item as any)._count?.favorites ?? 0,
        contactRevealsCount: item.contactRevealsCount,
        account: {
          id: item.account.id,
          displayName: item.account.displayName,
          slug: item.account.slug,
          accountType: item.account.accountType,
          logoUrl: item.account.logoUrl,
          verificationStatus: item.account.verificationStatus,
        },
        sellerName: item.account.displayName,
        sellerPhone: null,
        sellerType: item.account.accountType,
        isVerified: item.account.verificationStatus === 'approved',
        refreshedAt: item.refreshedAt,
        createdAt: item.createdAt,
      };
    });

    const feedResponse = {
      data: mappedData,
      meta: {
        nextCursor,
        next_cursor: nextCursor,
        limit,
        hasMore: !!nextCursor,
      },
    };

    await this.redis?.set?.(cacheKey, feedResponse, 30);
    return feedResponse;
  }

  /**
   * Retrieves listing details by ID and increments view count atomically.
   */
  async getListingById(id: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: {
        media: { orderBy: { sortOrder: 'asc' } },
        category: {
          select: { id: true, nameAr: true, nameEn: true, slug: true },
        },
        area: {
          include: {
            city: {
              include: { governorate: true },
            },
          },
        },
        account: {
          include: {
            owner: {
              select: {
                id: true,
                fullName: true,
                avatarUrl: true,
                createdAt: true,
              },
            },
          },
        },
        _count: {
          select: { favorites: true },
        },
      },
    });

    if (!listing || listing.publicationStatus === 'archived') {
      throw new NotFoundException('Listing not found or has been removed');
    }

    // Atomically increment views in background
    this.prisma.listing
      .update({
        where: { id },
        data: { viewsCount: { increment: 1 } },
      })
      .catch(() => {});

    const attrs = (listing.attributes as any) || {};
    return {
      ...listing,
      price: Number(listing.price),
      condition: attrs.condition || 'USED',
      isFeatured: Boolean(
        listing.promotedUntil && listing.promotedUntil > new Date(),
      ),
      favoritesCount: (listing as any)._count?.favorites ?? 0,
      governorateName: listing.area?.city?.governorate?.nameAr ?? '',
      cityName: listing.area?.city?.nameAr ?? '',
      areaName: listing.area?.nameAr ?? '',
      location: listing.area?.city
        ? `${listing.area.city.nameAr}، ${listing.area.city.governorate?.nameAr ?? ''}`
        : '',
      sellerName: listing.account?.displayName ?? '',
      sellerType: listing.account?.accountType ?? 'individual',
      isVerified: listing.account?.verificationStatus === 'approved',
      primaryImageUrl: listing.media?.[0]?.publicUrl ?? null,
    };
  }

  /**
   * Updates listing lifecycle status enforcing state-machine and ownership rules.
   */
  async updateListingStatus(
    id: string,
    userId: string,
    targetStatus: PublicationStatus,
    userRole?: string,
  ) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: { account: true },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    // Ownership check (IDOR Protection)
    if (listing.account.ownerUserId !== userId && userRole !== 'SUPER_ADMIN') {
      throw new ForbiddenException(
        'You do not have permission to modify this listing',
      );
    }

    // Enforce publication state machine transitions
    assertValidPublicationTransition(
      listing.publicationStatus as PublicationStatus,
      targetStatus,
    );

    const updated = await this.prisma.listing.update({
      where: { id },
      data: { publicationStatus: targetStatus },
    });
    await this.invalidateFeedCache();

    // Record immutable security audit log
    await this.securityAudit.logEvent({
      action: 'LISTING_STATUS_UPDATED',
      targetEntity: 'Listing',
      targetId: id,
      actorId: userId,
      actorType: userRole === 'SUPER_ADMIN' ? 'staff' : 'user',
      metadata: {
        previousStatus: listing.publicationStatus,
        newStatus: targetStatus,
      },
    });

    return updated;
  }

  /**
   * Records contact action (Call / WhatsApp click) and reveals seller phone number.
   * Enforces IP rate limiting against phone scraping and logs security audit trail.
   */
  async recordContactAction(
    id: string,
    ipAddress?: string,
    userAgent?: string,
    userId?: string,
  ) {
    // 1. Rate Limiting (Anti-Scraping): prefer userId when authenticated (CGNAT-safe), fallback to IP
    const rateLimitScope = userId
      ? `user:${userId}`
      : ipAddress
        ? `ip:${ipAddress}`
        : null;
    const rateLimitMax = userId ? 30 : 60;
    if (rateLimitScope) {
      const rateLimitKey = `contact:ratelimit:${rateLimitScope}`;
      const { allowed } = await this.redis.checkRateLimit(
        rateLimitKey,
        rateLimitMax,
        3600,
      );
      if (!allowed) {
        await this.securityAudit.logEvent({
          action: 'CONTACT_REVEAL_RATE_LIMIT_EXCEEDED',
          targetEntity: 'Listing',
          targetId: id,
          ipAddress,
          userAgent,
          actorId: userId,
          metadata: { ipAddress, scope: userId ? 'user' : 'ip' },
        });
        throw new HttpException(
          'Too many contact requests. Please wait before retrying.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }

    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: {
        account: {
          include: {
            owner: { select: { phone: true, fullName: true } },
          },
        },
      },
    });

    if (
      !listing ||
      listing.publicationStatus !== 'published' ||
      listing.deletedAt
    ) {
      throw new NotFoundException('Listing not available for contact');
    }

    // Prevent owner from revealing contact for their own listing
    if (userId && listing.account.ownerUserId === userId) {
      throw new BadRequestException(
        'Cannot reveal contact info for your own listing',
      );
    }

    const DAILY_LIMIT = 5;
    let remainingDailyQuota = DAILY_LIMIT;

    // Enforce daily quota in Africa/Cairo timezone if authenticated
    if (userId) {
      const cairoDateStr = new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Africa/Cairo',
      }).format(new Date());
      const usageDate = new Date(`${cairoDateStr}T00:00:00.000Z`);

      const callerAccount = await this.prisma.account.findFirst({
        where: {
          OR: [{ ownerUserId: userId }, { members: { some: { userId } } }],
        },
        orderBy: { createdAt: 'asc' },
      });

      if (callerAccount) {
        const existingQuota = await this.prisma.dailyQuota.findUnique({
          where: {
            uq_account_quota_date: {
              accountId: callerAccount.id,
              quotaType: 'contact_reveal',
              usageDate,
            },
          },
        });

        if (existingQuota && existingQuota.usedCount >= DAILY_LIMIT) {
          throw new HttpException(
            {
              statusCode: HttpStatus.FORBIDDEN,
              message:
                'Daily contact reveal quota exceeded (5/5). Resets at midnight Cairo time.',
              code: 'DAILY_QUOTA_EXCEEDED',
              remainingDailyQuota: 0,
              dailyLimit: DAILY_LIMIT,
            },
            HttpStatus.FORBIDDEN,
          );
        }

        const updatedQuota = await this.prisma.dailyQuota.upsert({
          where: {
            uq_account_quota_date: {
              accountId: callerAccount.id,
              quotaType: 'contact_reveal',
              usageDate,
            },
          },
          create: {
            accountId: callerAccount.id,
            quotaType: 'contact_reveal',
            usageDate,
            usedCount: 1,
            limitSnapshot: DAILY_LIMIT,
          },
          update: {
            usedCount: { increment: 1 },
          },
        });

        remainingDailyQuota = Math.max(0, DAILY_LIMIT - updatedQuota.usedCount);
      }
    }

    // Atomically increment contact reveals count
    await this.prisma.listing.update({
      where: { id },
      data: { contactRevealsCount: { increment: 1 } },
    });

    // Record security audit event
    await this.securityAudit.logEvent({
      action: 'CONTACT_REVEALED',
      targetEntity: 'Listing',
      targetId: id,
      ipAddress,
      userAgent,
      actorId: userId,
      metadata: {
        sellerAccountId: listing.accountId,
        remainingDailyQuota,
      },
    });

    const phone = listing.account.owner.phone;
    const cleanDigits = phone.replace(/[^0-9]/g, '');
    const whatsappUrl = `https://wa.me/${cleanDigits}`;

    return {
      phone,
      sellerName: listing.account.displayName || listing.account.owner.fullName,
      whatsapp: whatsappUrl,
      whatsappUrl,
      remainingDailyQuota,
      dailyLimit: DAILY_LIMIT,
    };
  }

  /**
   * Updates an existing listing (title, description, price, attributes, media).
   */
  async updateListing(
    id: string,
    userId: string,
    dto: UpdateListingDto,
    userRole?: string,
  ) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: { account: true, media: true },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.account.ownerUserId !== userId && userRole !== 'SUPER_ADMIN') {
      throw new ForbiddenException(
        'You do not have permission to edit this listing',
      );
    }

    const updateData: any = {};
    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.title !== undefined || dto.description !== undefined) {
      updateData.searchNormalizedText = normalizeArabicText(
        `${dto.title ?? listing.title} ${dto.description ?? listing.description}`,
      );
    }
    if (dto.price !== undefined) updateData.price = dto.price;
    if (dto.condition !== undefined) updateData.condition = dto.condition;
    if (dto.attributes !== undefined) {
      updateData.attributes = {
        ...((listing.attributes as any) || {}),
        ...dto.attributes,
      };
    }

    return this.prisma.$transaction(async (tx) => {
      if (dto.mediaKeys && dto.mediaKeys.length > 0) {
        for (const key of dto.mediaKeys) {
          if (!key.includes(`/${userId}/`)) {
            throw new ForbiddenException(
              `Forbidden: Media asset '${key}' belongs to another user`,
            );
          }
        }

        await tx.listingMedia.deleteMany({ where: { listingId: id } });
        const mediaRecords = dto.mediaKeys.map((key, index) => ({
          listingId: id,
          mediaType: 'image',
          storageKey: key,
          publicUrl: `${this.publicCdnDomain}/${key}`,
          sortOrder: index,
          processingStatus: 'ready',
        }));
        await tx.listingMedia.createMany({ data: mediaRecords });
      }

      const updated = await tx.listing.update({
        where: { id },
        data: updateData,
        include: {
          media: { orderBy: { sortOrder: 'asc' } },
          category: {
            select: { id: true, nameAr: true, nameEn: true, slug: true },
          },
          area: {
            include: {
              city: { include: { governorate: true } },
            },
          },
        },
      });

      await this.securityAudit.logEvent({
        action: 'LISTING_UPDATED',
        targetEntity: 'Listing',
        targetId: id,
        actorId: userId,
        actorType: userRole === 'SUPER_ADMIN' ? 'staff' : 'user',
        metadata: { updatedFields: Object.keys(updateData) },
      });

      await this.invalidateFeedCache();
      return updated;
    });
  }

  /**
   * Soft-deletes a listing (sets deletedAt and updates publication status to archived).
   */
  async deleteListing(id: string, userId: string, userRole?: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: { account: true },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.account.ownerUserId !== userId && userRole !== 'SUPER_ADMIN') {
      throw new ForbiddenException(
        'You do not have permission to delete this listing',
      );
    }

    await this.prisma.listing.update({
      where: { id },
      data: {
        deletedAt: new Date(),
        publicationStatus: 'archived',
      },
    });

    await this.securityAudit.logEvent({
      action: 'LISTING_DELETED',
      targetEntity: 'Listing',
      targetId: id,
      actorId: userId,
      actorType: userRole === 'SUPER_ADMIN' ? 'staff' : 'user',
    });

    await this.invalidateFeedCache();
    return { success: true, message: 'Listing successfully deleted' };
  }

  /**
   * Updates availability status (available, reserved, sold).
   */
  async updateAvailability(
    id: string,
    userId: string,
    availabilityStatus: string,
    userRole?: string,
  ) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: { account: true },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.account.ownerUserId !== userId && userRole !== 'SUPER_ADMIN') {
      throw new ForbiddenException(
        'You do not have permission to modify this listing',
      );
    }

    const updated = await this.prisma.listing.update({
      where: { id },
      data: { availabilityStatus },
    });

    await this.securityAudit.logEvent({
      action: 'LISTING_AVAILABILITY_UPDATED',
      targetEntity: 'Listing',
      targetId: id,
      actorId: userId,
      metadata: { availabilityStatus },
    });

    await this.invalidateFeedCache();
    return updated;
  }

  /**
   * Submits a draft or rejected listing for moderation review.
   */
  async submitForModeration(id: string, userId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: { account: true },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    if (listing.account.ownerUserId !== userId) {
      throw new ForbiddenException(
        'You do not have permission to submit this listing',
      );
    }

    assertValidModerationTransition(
      listing.moderationStatus as ModerationStatus,
      ModerationStatus.PENDING,
    );

    const updated = await this.prisma.$transaction(async (tx) => {
      const saved = await tx.listing.update({
        where: { id },
        data: {
          moderationStatus: ModerationStatus.PENDING,
        },
      });

      if ((tx as any).outboxEvent?.create) {
        await (tx as any).outboxEvent.create({
          data: {
            aggregateType: 'Listing',
            aggregateId: id,
            eventType: 'LISTING_SUBMITTED_FOR_MODERATION',
            payload: { listingId: id, userId },
          },
        });
      }

      return saved;
    });

    await this.securityAudit.logEvent({
      action: 'LISTING_SUBMITTED_FOR_MODERATION',
      targetEntity: 'Listing',
      targetId: id,
      actorId: userId,
    });

    await this.invalidateFeedCache();
    return updated;
  }

  private async invalidateFeedCache(): Promise<void> {
    await this.redis?.incr?.('listings:feed:ver').catch(() => undefined);
  }
}
