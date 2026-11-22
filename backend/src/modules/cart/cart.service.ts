import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';

@Injectable()
export class CartService {
  constructor(private readonly prisma: PrismaService) {}

  async getCart(
    userId: string,
    options: {
      page?: number;
      limit?: number;
      categoryId?: string;
      categorySlug?: string;
    } = {},
  ) {
    const page = options.page ?? 1;
    const limit = options.limit ?? 20;
    const skip = (page - 1) * limit;

    const categoryWhere = options.categoryId
      ? {
          listing: {
            OR: [
              { categoryId: options.categoryId },
              { category: { parentId: options.categoryId } },
            ],
          },
        }
      : options.categorySlug
        ? {
            listing: {
              OR: [
                { category: { slug: options.categorySlug } },
                { category: { parent: { slug: options.categorySlug } } },
              ],
            },
          }
        : {};

    const where = {
      userId,
      ...categoryWhere,
    };

    const [total, items] = await Promise.all([
      this.prisma.cartItem.count({ where }),
      this.prisma.cartItem.findMany({
        where,
        include: {
          listing: {
            select: {
              id: true,
              title: true,
              price: true,
              currency: true,
              listingKind: true,
              publicationStatus: true,
              availabilityStatus: true,
              deletedAt: true,
              category: {
                select: { id: true, slug: true, nameAr: true, nameEn: true },
              },
              account: {
                select: {
                  id: true,
                  displayName: true,
                  accountType: true,
                  verificationStatus: true,
                },
              },
              media: {
                where: { mediaType: 'image' },
                orderBy: { sortOrder: 'asc' },
                take: 1,
                select: { publicUrl: true },
              },
            },
          },
        },
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    const mapped = items.map((item) => {
      const livePrice = Number(item.listing.price);
      const snapshotPrice = Number(item.unitPriceSnapshot);
      const isAvailable =
        item.listing.deletedAt === null &&
        item.listing.publicationStatus === 'published' &&
        item.listing.availabilityStatus === 'available';

      return {
        id: item.id,
        listingId: item.listingId,
        quantity: item.quantity,
        variantKey: item.variantKey,
        variantAttributes: item.variantAttributes,
        unitPriceSnapshot: snapshotPrice,
        liveUnitPrice: livePrice,
        priceChanged: livePrice !== snapshotPrice,
        currency: item.currency,
        lineEstimate: Number((livePrice * item.quantity).toFixed(2)),
        isAvailable,
        notes: item.notes,
        listing: {
          id: item.listing.id,
          title: item.listing.title,
          listingKind: item.listing.listingKind,
          availabilityStatus: item.listing.availabilityStatus,
          category: item.listing.category,
          seller: item.listing.account,
          primaryImageUrl: item.listing.media[0]?.publicUrl ?? null,
        },
        updatedAt: item.updatedAt,
      };
    });

    const estimatedSubtotal = Number(
      mapped
        .filter((i) => i.isAvailable)
        .reduce((sum, i) => sum + i.lineEstimate, 0)
        .toFixed(2),
    );

    return {
      data: {
        commerceMode: 'V1_SAVED_BASKET',
        checkoutSupported: false,
        estimatedSubtotal,
        currency: 'EGP',
        items: mapped,
      },
      meta: {
        total,
        page,
        limit,
        totalPages: total === 0 ? 0 : Math.ceil(total / limit),
      },
    };
  }

  async getCartItemsCount(userId: string): Promise<number> {
    return this.prisma.cartItem.count({
      where: {
        userId,
        listing: {
          deletedAt: null,
          publicationStatus: 'published',
        },
      },
    });
  }

  async addItem(userId: string, dto: AddCartItemDto) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: dto.listingId },
      include: {
        account: {
          select: {
            ownerUserId: true,
            members: {
              where: { userId },
              select: { id: true },
            },
          },
        },
      },
    });

    if (
      !listing ||
      listing.deletedAt ||
      listing.publicationStatus !== 'published' ||
      listing.moderationStatus !== 'approved'
    ) {
      throw new NotFoundException('Listing not found or not published');
    }

    if (listing.availabilityStatus !== 'available') {
      throw new BadRequestException(
        `Listing is currently ${listing.availabilityStatus}`,
      );
    }

    if (
      listing.account.ownerUserId === userId ||
      (listing.account.members?.length ?? 0) > 0
    ) {
      throw new BadRequestException(
        'You cannot add your own listing to your saved basket',
      );
    }

    const variantKey = (dto.variantKey || 'default').trim();
    const quantityToAdd = dto.quantity ?? 1;

    const existing = await this.prisma.cartItem.findUnique({
      where: {
        uq_cart_user_listing_variant: {
          userId,
          listingId: dto.listingId,
          variantKey,
        },
      },
    });

    if (existing) {
      return this.prisma.cartItem.update({
        where: { id: existing.id },
        data: {
          quantity: Math.min(existing.quantity + quantityToAdd, 999),
          unitPriceSnapshot: listing.price,
          currency: listing.currency,
          ...(dto.notes !== undefined
            ? { notes: dto.notes.trim() || null }
            : {}),
        },
      });
    }

    return this.prisma.cartItem.create({
      data: {
        userId,
        listingId: dto.listingId,
        quantity: quantityToAdd,
        variantKey,
        variantAttributes: (dto.variantAttributes ?? {}) as any,
        unitPriceSnapshot: listing.price,
        currency: listing.currency,
        notes: dto.notes?.trim() || null,
      },
    });
  }

  async updateItem(userId: string, itemId: string, dto: UpdateCartItemDto) {
    const item = await this.prisma.cartItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new NotFoundException('Cart item not found');
    }

    if (item.userId !== userId) {
      throw new ForbiddenException('You do not own this cart item');
    }

    return this.prisma.cartItem.update({
      where: { id: item.id },
      data: {
        ...(dto.quantity !== undefined ? { quantity: dto.quantity } : {}),
        ...(dto.notes !== undefined ? { notes: dto.notes.trim() || null } : {}),
      },
    });
  }

  async removeItem(userId: string, itemId: string) {
    const item = await this.prisma.cartItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new NotFoundException('Cart item not found');
    }

    if (item.userId !== userId) {
      throw new ForbiddenException('You do not own this cart item');
    }

    await this.prisma.cartItem.delete({ where: { id: item.id } });
    return { success: true, deletedId: item.id };
  }

  async clearCart(userId: string) {
    const result = await this.prisma.cartItem.deleteMany({
      where: { userId },
    });
    return { success: true, deletedCount: result.count };
  }
}
