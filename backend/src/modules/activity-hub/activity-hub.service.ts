import { Injectable } from '@nestjs/common';
import { BookingsService } from '../bookings/bookings.service';
import { CartService } from '../cart/cart.service';
import { FavoritesService } from '../favorites/favorites.service';
import { RfqService } from '../rfq/rfq.service';
import {
  ActivityHubSection,
  GetActivityHubQueryDto,
} from './dto/get-activity-hub-query.dto';

const ALL_SECTIONS: ActivityHubSection[] = [
  'cart',
  'bookings',
  'rfqs',
  'favorites',
];

@Injectable()
export class ActivityHubService {
  constructor(
    private readonly cartService: CartService,
    private readonly bookingsService: BookingsService,
    private readonly rfqService: RfqService,
    private readonly favoritesService: FavoritesService,
  ) {}

  /**
   * Aggregates the authenticated user's activity across independent domain services
   * without duplicating business logic or performing unnecessary section queries.
   */
  async getActivityHub(userId: string, query: GetActivityHubQueryDto = {}) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 10;
    const includeSet = new Set<ActivityHubSection>(
      query.include && query.include.length > 0 ? query.include : ALL_SECTIONS,
    );

    const [
      cartItemsCount,
      activeBookingsCount,
      activeRfqCount,
      favoritesCount,
      cartResult,
      bookingsResult,
      rfqsResult,
      favoritesResult,
    ] = await Promise.all([
      this.cartService.getCartItemsCount(userId),
      this.bookingsService.getActiveBookingsCount(userId),
      this.rfqService.getActiveRfqCount(userId),
      this.favoritesService.getFavoritesCount(userId),
      includeSet.has('cart')
        ? this.cartService.getCart(userId, {
            page,
            limit,
            categoryId: query.categoryId,
            categorySlug: query.categorySlug,
          })
        : Promise.resolve(null),
      includeSet.has('bookings')
        ? this.bookingsService.getBookings(userId, {
            page,
            limit,
            categoryId: query.categoryId,
            categorySlug: query.categorySlug,
            role: 'requester',
          })
        : Promise.resolve(null),
      includeSet.has('rfqs')
        ? this.rfqService.getRfqs(userId, {
            page,
            limit,
            categoryId: query.categoryId,
            categorySlug: query.categorySlug,
            scope: 'mine',
          })
        : Promise.resolve(null),
      includeSet.has('favorites')
        ? this.favoritesService.getMyFavorites(userId, {
            page,
            limit,
            categoryId: query.categoryId,
            categorySlug: query.categorySlug,
          })
        : Promise.resolve(null),
    ]);

    return {
      summary: {
        cartItemsCount,
        activeBookingsCount,
        activeRfqCount,
        favoritesCount,
      },
      ...(cartResult
        ? {
            cart: {
              ...cartResult.data,
              pagination: cartResult.meta,
            },
          }
        : {}),
      ...(bookingsResult
        ? {
            bookings: {
              items: bookingsResult.data,
              pagination: bookingsResult.meta,
            },
          }
        : {}),
      ...(rfqsResult
        ? {
            rfqs: {
              items: rfqsResult.data,
              pagination: rfqsResult.meta,
            },
          }
        : {}),
      ...(favoritesResult
        ? {
            favorites: {
              items: favoritesResult.data,
              pagination: favoritesResult.meta,
            },
          }
        : {}),
    };
  }
}
