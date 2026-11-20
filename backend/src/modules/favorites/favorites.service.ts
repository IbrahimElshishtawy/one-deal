import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Retrieves list of active favorited listings for the authenticated user.
   */
  async getMyFavorites(userId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: {
        userId,
        listing: {
          publicationStatus: 'published',
          deletedAt: null,
        },
      },
      include: {
        listing: {
          include: {
            media: {
              where: { mediaType: 'image' },
              orderBy: { sortOrder: 'asc' },
            },
            category: {
              select: { id: true, slug: true, nameAr: true, nameEn: true },
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
      take: 100,
    });

    return favorites.map((fav) => ({
      favoriteId: fav.id,
      savedAt: fav.createdAt,
      listing: {
        id: fav.listing.id,
        title: fav.listing.title,
        description: fav.listing.description,
        price: Number(fav.listing.price),
        currency: fav.listing.currency,
        listingKind: fav.listing.listingKind,
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
  }

  /**
   * Adds a listing to user's favorites idempotently.
   */
  async addFavorite(userId: string, listingId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
    });

    if (!listing || listing.deletedAt) {
      throw new NotFoundException('Listing not found');
    }

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
      return { success: true, isFavorite: false };
    } else {
      const listing = await this.prisma.listing.findUnique({
        where: { id: listingId },
      });
      if (!listing || listing.deletedAt) {
        throw new NotFoundException('Listing not found');
      }

      await this.prisma.favorite.create({
        data: { userId, listingId },
      });
      return { success: true, isFavorite: true };
    }
  }
}
