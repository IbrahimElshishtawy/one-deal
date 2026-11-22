import { Test, TestingModule } from '@nestjs/testing';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CartService } from './cart.service';
import { PrismaService } from '../../core/database/prisma.service';
import { GetCartQueryDto } from './dto/get-cart-query.dto';

describe('CartService', () => {
  let service: CartService;

  const mockPrisma = {
    listing: { findUnique: jest.fn() },
    cartItem: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CartService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<CartService>(CartService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should add item using authoritative server price snapshot', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue({
      id: 'list-1',
      price: 2500,
      currency: 'EGP',
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      availabilityStatus: 'available',
      account: { ownerUserId: 'seller-1' },
    });
    mockPrisma.cartItem.findUnique.mockResolvedValue(null);
    mockPrisma.cartItem.create.mockImplementation((args: any) =>
      Promise.resolve({ id: 'ci-1', ...args.data }),
    );

    const item = await service.addItem('buyer-1', {
      listingId: 'list-1',
      quantity: 2,
    });

    expect(item.unitPriceSnapshot).toBe(2500);
    expect(item.quantity).toBe(2);
  });

  it('should reject updating another user cart item', async () => {
    mockPrisma.cartItem.findUnique.mockResolvedValue({
      id: 'ci-1',
      userId: 'other-user',
    });

    await expect(
      service.updateItem('buyer-1', 'ci-1', { quantity: 3 }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should throw NotFoundException when removing missing cart item', async () => {
    mockPrisma.cartItem.findUnique.mockResolvedValue(null);

    await expect(service.removeItem('buyer-1', 'missing')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('should reject invalid categoryId and excessive limit in GetCartQueryDto (SEC-02)', async () => {
    const invalidDto = plainToInstance(GetCartQueryDto, {
      page: 0,
      limit: 500,
      categoryId: 'not-a-uuid',
    });
    const errors = await validate(invalidDto);
    const props = errors.map((e) => e.property);
    expect(props).toEqual(
      expect.arrayContaining(['page', 'limit', 'categoryId']),
    );

    const validDto = plainToInstance(GetCartQueryDto, {
      page: 1,
      limit: 20,
      categoryId: '550e8400-e29b-41d4-a716-446655440000',
    });
    expect(await validate(validDto)).toHaveLength(0);
  });

  it('should block AccountMember from adding their own account listing to cart (SEC-05)', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue({
      id: 'list-1',
      price: 2500,
      currency: 'EGP',
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      availabilityStatus: 'available',
      account: { ownerUserId: 'owner-1', members: [{ id: 'member-1' }] },
    });

    await expect(
      service.addItem('member-user-1', { listingId: 'list-1', quantity: 1 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should recover atomically from concurrent P2002 race on addItem (BUG-11)', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue({
      id: 'list-1',
      price: 100,
      currency: 'EGP',
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      availabilityStatus: 'available',
      account: { ownerUserId: 'seller-1', members: [] },
    });
    mockPrisma.cartItem.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'ci-concurrent', quantity: 2 });
    mockPrisma.cartItem.create.mockRejectedValueOnce({ code: 'P2002' });
    mockPrisma.cartItem.update.mockResolvedValueOnce({
      id: 'ci-concurrent',
      quantity: 3,
    });

    const res = await service.addItem('buyer-1', {
      listingId: 'list-1',
      quantity: 1,
    });
    expect(res.quantity).toBe(3);
  });

  it('should compute full-basket estimatedSubtotal across all pages (BUG-10)', async () => {
    mockPrisma.cartItem.count.mockResolvedValue(2);
    mockPrisma.cartItem.findMany
      .mockResolvedValueOnce([
        {
          id: 'ci-1',
          listingId: 'list-1',
          quantity: 1,
          variantKey: 'default',
          variantAttributes: {},
          unitPriceSnapshot: 100,
          currency: 'EGP',
          notes: null,
          updatedAt: new Date(),
          listing: {
            id: 'list-1',
            title: 'Item 1',
            price: 100,
            currency: 'EGP',
            listingKind: 'product',
            publicationStatus: 'published',
            availabilityStatus: 'available',
            deletedAt: null,
            category: { id: 'c1', slug: 's', nameAr: 'a', nameEn: 'e' },
            account: {
              id: 'a1',
              displayName: 'Seller',
              accountType: 'store',
              verificationStatus: 'approved',
            },
            media: [],
          },
        },
      ])
      .mockResolvedValueOnce([
        {
          quantity: 1,
          listing: {
            price: 100,
            deletedAt: null,
            publicationStatus: 'published',
            availabilityStatus: 'available',
          },
        },
        {
          quantity: 2,
          listing: {
            price: 250,
            deletedAt: null,
            publicationStatus: 'published',
            availabilityStatus: 'available',
          },
        },
      ]);

    const res = await service.getCart('buyer-1', { page: 1, limit: 1 });
    expect(res.data.items).toHaveLength(1);
    expect(res.data.estimatedSubtotal).toBe(600);
    expect(res.meta.total).toBe(2);
  });
});
