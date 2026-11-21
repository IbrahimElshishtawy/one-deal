import { Test, TestingModule } from '@nestjs/testing';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { PrismaService } from '../../core/database/prisma.service';
import { BookingStatus, BookingType } from './bookings.enums';

describe('BookingsService', () => {
  let service: BookingsService;

  const mockTx = {
    booking: {
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    outboxEvent: {
      create: jest.fn(),
    },
  };

  const mockPrisma = {
    listing: { findUnique: jest.fn() },
    account: { findUnique: jest.fn() },
    booking: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    $transaction: jest.fn((cb: any) => cb(mockTx)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BookingsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<BookingsService>(BookingsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  const futureDate = '2028-06-15';
  const futureTime = '14:00';

  it('should create a booking for an eligible published listing', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue({
      id: 'list-1',
      title: 'شقة بالتجمع',
      accountId: 'acc-provider',
      categoryId: 'cat-re',
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      availabilityStatus: 'available',
      account: {
        id: 'acc-provider',
        ownerUserId: 'provider-user',
        isActive: true,
        deletedAt: null,
      },
    });
    mockTx.booking.findFirst.mockResolvedValue(null);
    mockTx.booking.create.mockResolvedValue({
      id: 'bk-1',
      reference: 'BK-20280615-ABC123',
      status: BookingStatus.PENDING,
    });

    const result = await service.createBooking('buyer-user', {
      listingId: 'list-1',
      bookingType: BookingType.PROPERTY_VIEWING,
      scheduledDate: futureDate,
      scheduledTime: futureTime,
    });

    expect(result.status).toBe(BookingStatus.PENDING);
    expect(mockTx.outboxEvent.create).toHaveBeenCalledTimes(1);
  });

  it('should reject past booking dates', async () => {
    await expect(
      service.createBooking('buyer-user', {
        listingId: 'list-1',
        bookingType: BookingType.PROPERTY_VIEWING,
        scheduledDate: '2020-01-01',
        scheduledTime: '10:00',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should reject missing listing', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue(null);

    await expect(
      service.createBooking('buyer-user', {
        listingId: 'missing',
        bookingType: BookingType.PROPERTY_VIEWING,
        scheduledDate: futureDate,
        scheduledTime: futureTime,
      }),
    ).rejects.toThrow(NotFoundException);
  });

  it('should prevent duplicate concurrent booking on same slot', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue({
      id: 'list-1',
      title: 'شقة',
      accountId: 'acc-provider',
      categoryId: 'cat-re',
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      availabilityStatus: 'available',
      account: {
        id: 'acc-provider',
        ownerUserId: 'provider-user',
        isActive: true,
        deletedAt: null,
      },
    });
    mockTx.booking.findFirst.mockResolvedValueOnce({ id: 'existing-bk' });

    await expect(
      service.createBooking('buyer-user', {
        listingId: 'list-1',
        bookingType: BookingType.PROPERTY_VIEWING,
        scheduledDate: futureDate,
        scheduledTime: futureTime,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('should forbid unauthorized user from updating booking status', async () => {
    mockPrisma.booking.findUnique.mockResolvedValue({
      id: 'bk-1',
      userId: 'buyer-user',
      providerAccountId: 'acc-provider',
      status: BookingStatus.PENDING,
    });
    mockPrisma.account.findUnique.mockResolvedValue({
      ownerUserId: 'provider-user',
      members: [],
    });

    await expect(
      service.updateBookingStatus('bk-1', 'attacker-user', {
        status: BookingStatus.CONFIRMED,
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should allow valid transition PENDING -> CONFIRMED by provider', async () => {
    mockPrisma.booking.findUnique.mockResolvedValue({
      id: 'bk-1',
      reference: 'BK-1',
      userId: 'buyer-user',
      providerAccountId: 'acc-provider',
      scheduledAt: new Date('2028-06-15T12:00:00Z'),
      status: BookingStatus.PENDING,
    });
    mockPrisma.account.findUnique.mockResolvedValue({
      ownerUserId: 'provider-user',
      members: [],
    });
    mockTx.booking.findFirst.mockResolvedValue(null);
    mockTx.booking.update.mockResolvedValue({
      id: 'bk-1',
      status: BookingStatus.CONFIRMED,
    });

    const updated = await service.updateBookingStatus('bk-1', 'provider-user', {
      status: BookingStatus.CONFIRMED,
    });
    expect(updated.status).toBe(BookingStatus.CONFIRMED);
    expect(mockTx.outboxEvent.create).toHaveBeenCalledTimes(1);
  });

  it('should reject invalid transition COMPLETED -> CONFIRMED', async () => {
    mockPrisma.booking.findUnique.mockResolvedValue({
      id: 'bk-1',
      userId: 'buyer-user',
      providerAccountId: 'acc-provider',
      status: BookingStatus.COMPLETED,
    });
    mockPrisma.account.findUnique.mockResolvedValue({
      ownerUserId: 'provider-user',
      members: [],
    });

    await expect(
      service.updateBookingStatus('bk-1', 'provider-user', {
        status: BookingStatus.CONFIRMED,
      }),
    ).rejects.toThrow(BadRequestException);
  });
});
