import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
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
});
