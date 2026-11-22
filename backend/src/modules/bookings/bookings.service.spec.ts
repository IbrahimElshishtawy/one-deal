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
      findUnique: jest.fn(),
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
    mockTx.booking.findUnique.mockResolvedValue({
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
    mockTx.booking.findUnique.mockResolvedValue({
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
    mockTx.booking.findUnique.mockResolvedValue({
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

  it('should block AccountMember from self-booking their own account listing (SEC-05)', async () => {
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
        ownerUserId: 'owner-user',
        isActive: true,
        deletedAt: null,
        members: [{ id: 'member-1' }],
      },
    });

    await expect(
      service.createBooking('manager-user', {
        listingId: 'list-1',
        bookingType: BookingType.PROPERTY_VIEWING,
        scheduledDate: futureDate,
        scheduledTime: futureTime,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should map Serializable conflict (P2034) on concurrent booking status update to ConflictException (BUG-03)', async () => {
    mockPrisma.$transaction.mockRejectedValueOnce({ code: 'P2034' });

    await expect(
      service.updateBookingStatus('bk-1', 'provider-user', {
        status: BookingStatus.CONFIRMED,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('should allow Enterprise Admin StaffUser to cancel booking with null cancelledByUserId (SEC-03)', async () => {
    mockTx.booking.findUnique.mockResolvedValue({
      id: 'bk-1',
      reference: 'BK-1',
      userId: 'buyer-user',
      providerAccountId: 'acc-provider',
      status: BookingStatus.PENDING,
      providerAccount: { ownerUserId: 'provider-user' },
    });
    mockTx.booking.update.mockResolvedValue({
      id: 'bk-1',
      status: BookingStatus.CANCELLED,
    });

    const updated = await service.cancelBooking(
      'bk-1',
      'staff-uuid-1',
      { reason: 'Admin moderation' },
      'SUPER_ADMIN',
      'staff',
    );
    expect(updated.status).toBe(BookingStatus.CANCELLED);
    expect(mockTx.booking.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ cancelledByUserId: null }),
      }),
    );
  });

  it('should reject bookingType mismatched with listing root category', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue({
      id: 'list-fashion-1',
      title: 'Jacket',
      accountId: 'acc-provider',
      categoryId: 'cat-fashion',
      category: { slug: 'fashion', parent: null },
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      availabilityStatus: 'available',
      account: {
        id: 'acc-provider',
        ownerUserId: 'provider-user',
        isActive: true,
        deletedAt: null,
        members: [],
      },
    });

    await expect(
      service.createBooking('buyer-user', {
        listingId: 'list-fashion-1',
        bookingType: BookingType.PLUMBING_SERVICE,
        scheduledDate: futureDate,
        scheduledTime: futureTime,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should resolve Africa/Cairo DST (+03:00 in summer, +02:00 in winter) accurately (BUG-14)', async () => {
    mockPrisma.listing.findUnique.mockResolvedValue({
      id: 'list-re-1',
      title: 'Apartment',
      accountId: 'acc-provider',
      categoryId: 'cat-re',
      category: { slug: 'apartments', parent: { slug: 'real-estate' } },
      deletedAt: null,
      publicationStatus: 'published',
      moderationStatus: 'approved',
      availabilityStatus: 'available',
      account: {
        id: 'acc-provider',
        ownerUserId: 'provider-user',
        isActive: true,
        deletedAt: null,
        members: [],
      },
    });
    mockTx.booking.findFirst.mockResolvedValue(null);
    mockTx.booking.create.mockImplementation((args: any) =>
      Promise.resolve({ id: 'bk-dst', ...args.data }),
    );

    // July in Egypt is DST (+03:00) -> 14:00 Cairo = 11:00 UTC
    const summer = await service.createBooking('buyer-user', {
      listingId: 'list-re-1',
      bookingType: BookingType.PROPERTY_VIEWING,
      scheduledDate: '2028-07-15',
      scheduledTime: '14:00',
    });
    expect(summer.scheduledAt.toISOString()).toBe('2028-07-15T11:00:00.000Z');

    // January in Egypt is standard (+02:00) -> 14:00 Cairo = 12:00 UTC
    const winter = await service.createBooking('buyer-user', {
      listingId: 'list-re-1',
      bookingType: BookingType.PROPERTY_VIEWING,
      scheduledDate: '2028-01-15',
      scheduledTime: '14:00',
    });
    expect(winter.scheduledAt.toISOString()).toBe('2028-01-15T12:00:00.000Z');
  });
});
