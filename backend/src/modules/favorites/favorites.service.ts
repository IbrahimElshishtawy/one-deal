import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { normalizeArabicText } from '../search/arabic-normalizer';
import { GetFavoritesQueryDto } from './dto/get-favorites-query.dto';

@Injectable()
export class FavoritesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Validates that a listing exists and is eligible to be favorited.
   */
  private async assertListingEligible(listingId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      select: {
        id: true,
        deletedAt: true,
        publicationStatus: true,
        moderationStatus: true,
        availabilityStatus: true,
        expiresAt: true,
      },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

    if (
      listing.publicationStatus !== 'published' ||
      listing.moderationStatus !== 'approved'
    ) {
      throw new BadRequestException(
        'Listing is not published or available for favoriting',
      );
    }

    return listing;
  }

  /**
   * Retrieves paginated, filterable favorited listings for the authenticated user.
   */
  async getMyFavorites(userId: string, query: GetFavoritesQueryDto = {}) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;
    const includeUnavailable = query.includeUnavailable ?? false;

    const categoryFilter = query.categoryId
      ? {
          OR: [
            { categoryId: query.categoryId },
            { category: { parentId: query.categoryId } },
          ],
        }
      : query.categorySlug
        ? {
            OR: [
              { category: { slug: query.categorySlug } },
              { category: { parent: { slug: query.categorySlug } } },
            ],
          }
        : undefined;

    const trimmedSearch = query.search?.trim();
    const normalizedSearch = trimmedSearch
      ? normalizeArabicText(trimmedSearch)
      : undefined;

    const searchFilter = trimmedSearch
      ? {
          OR: [
            {
              title: { contains: trimmedSearch, mode: 'insensitive' as const },
            },
            {
              description: {
                contains: trimmedSearch,
                mode: 'insensitive' as const,
              },
            },
            ...(normalizedSearch
              ? [
                  {
                    searchNormalizedText: {
                      contains: normalizedSearch,
                      mode: 'insensitive' as const,
                    },
                  },
                ]
              : []),
          ],
        }
      : undefined;

    const listingWhere: Record<string, any> = {
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      ...(includeUnavailable ? {} : { availabilityStatus: 'available' }),
      ...(categoryFilter ? categoryFilter : {}),
      ...(searchFilter ? searchFilter : {}),
    };

    const where = {
      userId,
      listing: listingWhere,
    };

    const [total, favorites] = await Promise.all([
      this.prisma.favorite.count({ where }),
      this.prisma.favorite.findMany({
        where,
        include: {
          listing: {
            include: {
              media: {
                where: { mediaType: 'image' },
                orderBy: { sortOrder: 'asc' },
              },
              category: {
                select: {
                  id: true,
                  slug: true,
                  nameAr: true,
                  nameEn: true,
                  parentId: true,
                },
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
                  accountType: true,
                  logoUrl: true,
                  verificationStatus: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    const items = favorites.map((fav) => ({
      favoriteId: fav.id,
      savedAt: fav.createdAt,
      isAvailable:
        fav.listing.deletedAt === null &&
        fav.listing.publicationStatus === 'published' &&
        fav.listing.availabilityStatus === 'available',
      listing: {
        id: fav.listing.id,
        title: fav.listing.title,
        description: fav.listing.description,
        price: Number(fav.listing.price),
        currency: fav.listing.currency,
        listingKind: fav.listing.listingKind,
        availabilityStatus: fav.listing.availabilityStatus,
        category: fav.listing.category,
        governorateName: fav.listing.area.city.governorate.nameAr,
        cityName: fav.listing.area.city.nameAr,
        areaName: fav.listing.area.nameAr,
        primaryImageUrl: fav.listing.media[0]?.publicUrl ?? null,
        media: fav.listing.media,
        attributes: fav.listing.attributes,
        seller: fav.listing.account,
        isFavorite: true,
        refreshedAt: fav.listing.refreshedAt,
        createdAt: fav.listing.createdAt,
      },
    }));

    return {
      data: items,
      meta: {
        total,
        page,
        limit,
        totalPages: total === 0 ? 0 : Math.ceil(total / limit),
      },
    };
  }

  /**
   * Returns total active favorites count for Activity Hub summary.
   */
  async getFavoritesCount(userId: string): Promise<number> {
    return this.prisma.favorite.count({
      where: {
        userId,
        listing: {
          deletedAt: null,
          publicationStatus: 'published',
          moderationStatus: 'approved',
        },
      },
    });
  }

  /**
   * Checks whether a specific listing is favorited by the user.
   */
  async getFavoriteStatus(userId: string, listingId: string) {
    const favorite = await this.prisma.favorite.findUnique({
      where: {
        uq_user_favorite: {
          userId,
          listingId,
        },
      },
      select: {
        id: true,
        createdAt: true,
        listing: {
          select: {
            deletedAt: true,
            publicationStatus: true,
            availabilityStatus: true,
          },
        },
      },
    });

    const isFavorite = Boolean(favorite);
    const isListingAvailable = Boolean(
      favorite?.listing &&
      favorite.listing.deletedAt === null &&
      favorite.listing.publicationStatus === 'published' &&
      favorite.listing.availabilityStatus === 'available',
    );

    return {
      listingId,
      isFavorite,
      favoriteId: favorite?.id ?? null,
      savedAt: favorite?.createdAt ?? null,
      isListingAvailable,
    };
  }

  /**
   * Adds a listing to user's favorites idempotently.
   */
  async addFavorite(userId: string, listingId: string) {
    await this.assertListingEligible(listingId);

    const favorite = await this.prisma.favorite.upsert({
      where: {
        uq_user_favorite: {
          userId,
          listingId,
        },
      },
      update: {},
      create: {
        userId,
        listingId,
      },
    });

    return {
      success: true,
      favoriteId: favorite.id,
      listingId,
      isFavorite: true,
    };
  }

  /**
   * Removes a listing from user's favorites.
   */
  async removeFavorite(userId: string, listingId: string) {
    await this.prisma.favorite
      .delete({
        where: {
          uq_user_favorite: {
            userId,
            listingId,
          },
        },
      })
      .catch(() => {
        // Idempotent delete: ignore if already removed
      });

    return {
      success: true,
      listingId,
      isFavorite: false,
    };
  }

  /**
   * Toggles favorite status for a listing.
   */
  async toggleFavorite(userId: string, listingId: string) {
    const existing = await this.prisma.favorite.findUnique({
      where: {
        uq_user_favorite: {
          userId,
          listingId,
        },
      },
    });

    if (existing) {
      await this.prisma.favorite.delete({
        where: { id: existing.id },
      });
      return { success: true, listingId, isFavorite: false };
    }

    await this.assertListingEligible(listingId);

    const created = await this.prisma.favorite.create({
      data: { userId, listingId },
    });
    return {
      success: true,
      favoriteId: created.id,
      listingId,
      isFavorite: true,
    };
  }
}
