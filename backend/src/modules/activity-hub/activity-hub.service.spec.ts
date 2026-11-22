import { Test, TestingModule } from '@nestjs/testing';
import { ActivityHubService } from './activity-hub.service';
import { CartService } from '../cart/cart.service';
import { BookingsService } from '../bookings/bookings.service';
import { RfqService } from '../rfq/rfq.service';
import { FavoritesService } from '../favorites/favorites.service';

describe('ActivityHubService', () => {
  let service: ActivityHubService;

  const mockCartService = {
    getCartItemsCount: jest.fn(),
    getCart: jest.fn(),
  };
  const mockBookingsService = {
    getActiveBookingsCount: jest.fn(),
    getBookings: jest.fn(),
  };
  const mockRfqService = {
    getActiveRfqCount: jest.fn(),
    getRfqs: jest.fn(),
  };
  const mockFavoritesService = {
    getFavoritesCount: jest.fn(),
    getMyFavorites: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ActivityHubService,
        { provide: CartService, useValue: mockCartService },
        { provide: BookingsService, useValue: mockBookingsService },
        { provide: RfqService, useValue: mockRfqService },
        { provide: FavoritesService, useValue: mockFavoritesService },
      ],
    }).compile();

    service = module.get<ActivityHubService>(ActivityHubService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should aggregate all sections and counts by default', async () => {
    mockCartService.getCartItemsCount.mockResolvedValue(2);
    mockBookingsService.getActiveBookingsCount.mockResolvedValue(1);
    mockRfqService.getActiveRfqCount.mockResolvedValue(3);
    mockFavoritesService.getFavoritesCount.mockResolvedValue(4);

    mockCartService.getCart.mockResolvedValue({
      data: {
        commerceMode: 'V1_SAVED_BASKET',
        checkoutSupported: false,
        estimatedSubtotal: 100,
        currency: 'EGP',
        items: [],
      },
      meta: { total: 2, page: 1, limit: 10, totalPages: 1 },
    });
    mockBookingsService.getBookings.mockResolvedValue({
      data: [{ id: 'bk-1' }],
      meta: { total: 1, page: 1, limit: 10, totalPages: 1 },
    });
    mockRfqService.getRfqs.mockResolvedValue({
      data: [{ id: 'rfq-1' }],
      meta: { total: 3, page: 1, limit: 10, totalPages: 1 },
    });
    mockFavoritesService.getMyFavorites.mockResolvedValue({
      data: [{ favoriteId: 'fav-1' }],
      meta: { total: 4, page: 1, limit: 10, totalPages: 1 },
    });

    const result = await service.getActivityHub('user-1');
    expect(result.summary).toEqual({
      cartItemsCount: 2,
      activeBookingsCount: 1,
      activeRfqCount: 3,
      favoritesCount: 4,
    });
    expect(result.bookings?.items).toHaveLength(1);
    expect(result.rfqs?.items).toHaveLength(1);
    expect(result.favorites?.items).toHaveLength(1);
    expect(result.cart?.commerceMode).toBe('V1_SAVED_BASKET');
    // Unfiltered full load reuses section totals without redundant count queries
    expect(mockCartService.getCartItemsCount).not.toHaveBeenCalled();
    expect(mockFavoritesService.getFavoritesCount).not.toHaveBeenCalled();
  });

  it('should only load requested sections when include filter is provided', async () => {
    mockCartService.getCartItemsCount.mockResolvedValue(0);
    mockBookingsService.getActiveBookingsCount.mockResolvedValue(1);
    mockRfqService.getActiveRfqCount.mockResolvedValue(0);
    mockFavoritesService.getFavoritesCount.mockResolvedValue(0);
    mockBookingsService.getBookings.mockResolvedValue({
      data: [{ id: 'bk-1' }],
      meta: { total: 1, page: 1, limit: 10, totalPages: 1 },
    });

    const result = await service.getActivityHub('user-1', {
      include: ['bookings'],
    });

    expect(result.bookings).toBeDefined();
    expect(result.cart).toBeUndefined();
    expect(result.rfqs).toBeUndefined();
    expect(result.favorites).toBeUndefined();
    expect(mockCartService.getCart).not.toHaveBeenCalled();
    expect(mockRfqService.getRfqs).not.toHaveBeenCalled();
    expect(mockFavoritesService.getMyFavorites).not.toHaveBeenCalled();
  });
});
