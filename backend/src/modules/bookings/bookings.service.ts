import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import { UserRole } from '../../core/enums/domain.enums';
import { assertValidBookingTransition } from './bookings-state-machine';
import {
  ACTIVE_BOOKING_STATUSES,
  BookingStatus,
  BookingType,
} from './bookings.enums';

const BOOKING_TYPE_ROOT_CATEGORY_MAP: Record<BookingType, string> = {
  [BookingType.PROPERTY_VIEWING]: 'real-estate',
  [BookingType.PROPERTY_INSPECTION]: 'real-estate',
  [BookingType.GENERAL_INQUIRY]: 'real-estate',
  [BookingType.VEHICLE_INSPECTION]: 'cars',
  [BookingType.MAINTENANCE_APPOINTMENT]: 'cars',
  [BookingType.SERVICE_CENTER_BOOKING]: 'cars',
  [BookingType.PLUMBING_SERVICE]: 'services',
  [BookingType.ELECTRICAL_SERVICE]: 'services',
  [BookingType.AC_SERVICE]: 'services',
  [BookingType.CONSTRUCTION_SERVICE]: 'services',
  [BookingType.ENGINEERING_SERVICE]: 'services',
};

const KNOWN_ROOT_CATEGORY_SLUGS = new Set([
  'real-estate',
  'building-materials',
  'services',
  'home-appliances',
  'cars',
  'fashion',
]);
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { GetBookingsQueryDto } from './dto/get-bookings-query.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';

@Injectable()
export class BookingsService {
  constructor(private readonly prisma: PrismaService) {}

  private generateReference(): string {
    const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const randPart = crypto.randomBytes(3).toString('hex').toUpperCase();
    return `BK-${datePart}-${randPart}`;
  }

  /**
   * Resolves the exact UTC offset (+02:00 standard or +03:00 DST) for a calendar date
   * in the IANA Africa/Cairo timezone without external dependencies.
   */
  private getCairoOffsetForDate(
    scheduledDate: string,
    scheduledTime: string,
  ): string {
    try {
      const probeUtc = new Date(`${scheduledDate}T${scheduledTime}:00Z`);
      const parts = new Intl.DateTimeFormat('en-US', {
        timeZone: 'Africa/Cairo',
        timeZoneName: 'longOffset',
      }).formatToParts(probeUtc);
      const tzPart = parts.find((p) => p.type === 'timeZoneName')?.value ?? '';
      const match = tzPart.match(/GMT([+-]\d{2}:\d{2})/);
      if (match?.[1]) {
        return match[1];
      }
    } catch {
      // Fallback to Egypt standard time if Intl timezone data is unavailable
    }
    return '+02:00';
  }

  /**
   * Parses YYYY-MM-DD and HH:mm in Africa/Cairo (DST-aware) into an authoritative UTC Date
   * and rejects invalid or past slots.
   */
  private parseAndValidateSlot(
    scheduledDate: string,
    scheduledTime: string,
  ): { dateObj: Date; scheduledAt: Date } {
    const [year, month, day] = scheduledDate.split('-').map(Number);
    const dateObj = new Date(Date.UTC(year, month - 1, day));
    if (
      dateObj.getUTCFullYear() !== year ||
      dateObj.getUTCMonth() + 1 !== month ||
      dateObj.getUTCDate() !== day
    ) {
      throw new BadRequestException('Invalid scheduledDate calendar date');
    }

    const cairoOffset = this.getCairoOffsetForDate(
      scheduledDate,
      scheduledTime,
    );
    const scheduledAt = new Date(
      `${scheduledDate}T${scheduledTime}:00${cairoOffset}`,
    );
    if (Number.isNaN(scheduledAt.getTime())) {
      throw new BadRequestException('Invalid scheduledDate or scheduledTime');
    }

    if (scheduledAt.getTime() <= Date.now()) {
      throw new BadRequestException(
        'Booking date and time must be in the future',
      );
    }

    return { dateObj, scheduledAt };
  }

  private isAdminActor(
    userRole?: string,
    actorType?: 'user' | 'staff',
  ): boolean {
    const normalized = (userRole || '').toUpperCase();
    const hasAdminRole =
      normalized === UserRole.SUPER_ADMIN ||
      normalized === UserRole.MODERATOR ||
      normalized === 'ADMIN';
    if (!hasAdminRole) return false;
    if (actorType === 'staff') return true;
    return process.env.NODE_ENV !== 'production';
  }

  private async isProviderAuthorized(
    providerAccountId: string,
    userId: string,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ): Promise<boolean> {
    if (this.isAdminActor(userRole, actorType)) {
      return true;
    }

    if (actorType === 'staff') {
      return false;
    }

    const account = await this.prisma.account.findUnique({
      where: { id: providerAccountId },
      select: {
        ownerUserId: true,
        members: {
          where: {
            userId,
            role: { in: ['owner', 'manager', 'responder'] },
          },
          select: { id: true },
        },
      },
    });

    if (!account) return false;
    return account.ownerUserId === userId || account.members.length > 0;
  }

  private bookingInclude() {
    return {
      listing: {
        select: {
          id: true,
          title: true,
          price: true,
          currency: true,
          listingKind: true,
          media: {
            where: { mediaType: 'image' },
            orderBy: { sortOrder: 'asc' as const },
            take: 1,
            select: { publicUrl: true },
          },
        },
      },
      providerAccount: {
        select: {
          id: true,
          displayName: true,
          accountType: true,
          logoUrl: true,
          verificationStatus: true,
          ownerUserId: true,
        },
      },
      category: {
        select: {
          id: true,
          slug: true,
          nameAr: true,
          nameEn: true,
        },
      },
    };
  }

  async createBooking(userId: string, dto: CreateBookingDto) {
    if (!dto.listingId && !dto.providerAccountId) {
      throw new BadRequestException(
        'Either listingId or providerAccountId is required',
      );
    }

    const { dateObj, scheduledAt } = this.parseAndValidateSlot(
      dto.scheduledDate,
      dto.scheduledTime,
    );

    let providerAccountId: string;
    let providerOwnerUserId: string;
    let categoryId: string | null = null;
    let listingTitle: string | null = null;

    if (dto.listingId) {
      const listing = await this.prisma.listing.findUnique({
        where: { id: dto.listingId },
        include: {
          category: {
            select: {
              slug: true,
              parent: { select: { slug: true } },
            },
          },
          account: {
            select: {
              id: true,
              ownerUserId: true,
              isActive: true,
              deletedAt: true,
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
        throw new NotFoundException(
          'Listing not found or not available for booking',
        );
      }

      if (listing.availabilityStatus !== 'available') {
        throw new BadRequestException(
          `Listing is currently ${listing.availabilityStatus} and cannot be booked`,
        );
      }

      if (!listing.account.isActive || listing.account.deletedAt) {
        throw new BadRequestException('Provider account is not active');
      }

      if (
        listing.account.ownerUserId === userId ||
        (listing.account.members?.length ?? 0) > 0
      ) {
        throw new BadRequestException(
          'You cannot create a booking on your own listing',
        );
      }

      const rootCategorySlug =
        listing.category?.parent?.slug ?? listing.category?.slug;
      if (rootCategorySlug && KNOWN_ROOT_CATEGORY_SLUGS.has(rootCategorySlug)) {
        const expectedRootSlug =
          BOOKING_TYPE_ROOT_CATEGORY_MAP[dto.bookingType];
        if (expectedRootSlug && expectedRootSlug !== rootCategorySlug) {
          throw new BadRequestException(
            `Booking type '${dto.bookingType}' is not supported for category '${rootCategorySlug}'`,
          );
        }
      }

      providerAccountId = listing.accountId;
      providerOwnerUserId = listing.account.ownerUserId;
      categoryId = listing.categoryId;
      listingTitle = listing.title;
    } else {
      const account = await this.prisma.account.findUnique({
        where: { id: dto.providerAccountId! },
        select: {
          id: true,
          ownerUserId: true,
          isActive: true,
          deletedAt: true,
          members: {
            where: { userId },
            select: { id: true },
          },
        },
      });

      if (!account || !account.isActive || account.deletedAt) {
        throw new NotFoundException('Provider account not found or inactive');
      }

      if (
        account.ownerUserId === userId ||
        (account.members?.length ?? 0) > 0
      ) {
        throw new BadRequestException(
          'You cannot create a booking with your own account',
        );
      }

      providerAccountId = account.id;
      providerOwnerUserId = account.ownerUserId;
    }

    try {
      return await this.prisma.$transaction(
        async (tx) => {
          // Prevent duplicate active booking by same user for same slot/listing
          const duplicateByUser = await tx.booking.findFirst({
            where: {
              userId,
              providerAccountId,
              ...(dto.listingId ? { listingId: dto.listingId } : {}),
              scheduledAt,
              status: { in: ACTIVE_BOOKING_STATUSES },
            },
            select: { id: true },
          });

          if (duplicateByUser) {
            throw new ConflictException(
              'You already have an active booking for this time slot',
            );
          }

          // Prevent double-booking a confirmed slot on the same provider
          const confirmedConflict = await tx.booking.findFirst({
            where: {
              providerAccountId,
              scheduledAt,
              status: BookingStatus.CONFIRMED,
            },
            select: { id: true },
          });

          if (confirmedConflict) {
            throw new ConflictException(
              'Selected time slot is already confirmed for another booking',
            );
          }

          const booking = await tx.booking.create({
            data: {
              reference: this.generateReference(),
              userId,
              listingId: dto.listingId ?? null,
              providerAccountId,
              categoryId,
              bookingType: dto.bookingType,
              scheduledDate: dateObj,
              scheduledTime: dto.scheduledTime,
              scheduledAt,
              location: dto.location?.trim() || null,
              notes: dto.notes?.trim() || null,
              status: BookingStatus.PENDING,
            },
            include: this.bookingInclude(),
          });

          await tx.outboxEvent.create({
            data: {
              aggregateType: 'Booking',
              aggregateId: booking.id,
              eventType: 'PUSH_NOTIFICATION',
              payload: {
                targetUserId: providerOwnerUserId,
                title: 'New Booking Request',
                body: listingTitle
                  ? `New ${dto.bookingType} request for "${listingTitle}" on ${dto.scheduledDate} at ${dto.scheduledTime}`
                  : `New ${dto.bookingType} request on ${dto.scheduledDate} at ${dto.scheduledTime}`,
                dataPayload: {
                  type: 'BOOKING_SUBMITTED',
                  bookingId: booking.id,
                  reference: booking.reference,
                },
              },
            },
          });

          return booking;
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (err: any) {
      if (err?.code === 'P2034') {
        throw new ConflictException(
          'Concurrent booking conflict detected. Please retry or choose another time slot.',
        );
      }
      throw err;
    }
  }

  async getBookings(userId: string, query: GetBookingsQueryDto = {}) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;
    const role = query.role ?? 'requester';

    const ownershipWhere: Prisma.BookingWhereInput =
      role === 'provider'
        ? {
            providerAccount: {
              OR: [
                { ownerUserId: userId },
                {
                  members: {
                    some: {
                      userId,
                      role: { in: ['owner', 'manager', 'responder'] },
                    },
                  },
                },
              ],
            },
          }
        : { userId };

    const categoryWhere: Prisma.BookingWhereInput = query.categoryId
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
        : {};

    const where: Prisma.BookingWhereInput = {
      ...ownershipWhere,
      ...(query.status ? { status: query.status } : {}),
      ...(query.bookingType ? { bookingType: query.bookingType } : {}),
      ...categoryWhere,
    };

    const [total, items] = await Promise.all([
      this.prisma.booking.count({ where }),
      this.prisma.booking.findMany({
        where,
        include: this.bookingInclude(),
        orderBy: { scheduledAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

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

  async getActiveBookingsCount(userId: string): Promise<number> {
    return this.prisma.booking.count({
      where: {
        userId,
        status: { in: ACTIVE_BOOKING_STATUSES },
      },
    });
  }

  async getBookingById(
    bookingId: string,
    userId: string,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: this.bookingInclude(),
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    const isRequester = actorType !== 'staff' && booking.userId === userId;
    const isProvider = await this.isProviderAuthorized(
      booking.providerAccountId,
      userId,
      userRole,
      actorType,
    );

    if (!isRequester && !isProvider) {
      throw new ForbiddenException(
        'You do not have permission to access this booking',
      );
    }

    return booking;
  }

  async cancelBooking(
    bookingId: string,
    userId: string,
    dto: CancelBookingDto,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    try {
      return await this.prisma.$transaction(
        async (tx) => {
          const booking = await tx.booking.findUnique({
            where: { id: bookingId },
            include: {
              providerAccount: { select: { ownerUserId: true } },
            },
          });

          if (!booking) {
            throw new NotFoundException('Booking not found');
          }

          const isRequester =
            actorType !== 'staff' && booking.userId === userId;
          const isProvider = await this.isProviderAuthorized(
            booking.providerAccountId,
            userId,
            userRole,
            actorType,
          );

          if (!isRequester && !isProvider) {
            throw new ForbiddenException(
              'You do not have permission to cancel this booking',
            );
          }

          assertValidBookingTransition(booking.status, BookingStatus.CANCELLED);

          const notifyUserId = isRequester
            ? booking.providerAccount.ownerUserId
            : booking.userId;

          const updated = await tx.booking.update({
            where: { id: booking.id },
            data: {
              status: BookingStatus.CANCELLED,
              cancellationReason: dto.reason?.trim() || null,
              cancelledByUserId: actorType === 'staff' ? null : userId,
              cancelledAt: new Date(),
            },
            include: this.bookingInclude(),
          });

          await tx.outboxEvent.create({
            data: {
              aggregateType: 'Booking',
              aggregateId: booking.id,
              eventType: 'PUSH_NOTIFICATION',
              payload: {
                targetUserId: notifyUserId,
                title: 'Booking Cancelled',
                body: `Booking ${booking.reference} has been cancelled.`,
                dataPayload: {
                  type: 'BOOKING_CANCELLED',
                  bookingId: booking.id,
                  reference: booking.reference,
                },
              },
            },
          });

          return updated;
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (err: any) {
      if (err?.code === 'P2034') {
        throw new ConflictException(
          'Concurrent booking update detected. Please retry.',
        );
      }
      throw err;
    }
  }

  async updateBookingStatus(
    bookingId: string,
    userId: string,
    dto: UpdateBookingStatusDto,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    if (dto.status === BookingStatus.CANCELLED) {
      throw new BadRequestException(
        'Use PATCH /bookings/:id/cancel to cancel a booking',
      );
    }

    try {
      return await this.prisma.$transaction(
        async (tx) => {
          const booking = await tx.booking.findUnique({
            where: { id: bookingId },
          });

          if (!booking) {
            throw new NotFoundException('Booking not found');
          }

          const isProvider = await this.isProviderAuthorized(
            booking.providerAccountId,
            userId,
            userRole,
            actorType,
          );

          if (!isProvider) {
            throw new ForbiddenException(
              'Only the assigned provider or an administrator can update booking status',
            );
          }

          assertValidBookingTransition(booking.status, dto.status);

          if (dto.status === BookingStatus.CONFIRMED) {
            const slotConflict = await tx.booking.findFirst({
              where: {
                id: { not: booking.id },
                providerAccountId: booking.providerAccountId,
                scheduledAt: booking.scheduledAt,
                status: BookingStatus.CONFIRMED,
              },
              select: { id: true },
            });

            if (slotConflict) {
              throw new ConflictException(
                'Another booking is already confirmed for this time slot',
              );
            }
          }

          const now = new Date();
          const updated = await tx.booking.update({
            where: { id: booking.id },
            data: {
              status: dto.status,
              ...(dto.status === BookingStatus.CONFIRMED
                ? { confirmedAt: now }
                : {}),
              ...(dto.status === BookingStatus.COMPLETED
                ? { completedAt: now }
                : {}),
              ...(dto.status === BookingStatus.REJECTED && dto.reason
                ? { cancellationReason: dto.reason.trim() }
                : {}),
            },
            include: this.bookingInclude(),
          });

          const eventType =
            dto.status === BookingStatus.CONFIRMED
              ? 'BOOKING_CONFIRMED'
              : dto.status === BookingStatus.REJECTED
                ? 'BOOKING_REJECTED'
                : 'BOOKING_COMPLETED';

          await tx.outboxEvent.create({
            data: {
              aggregateType: 'Booking',
              aggregateId: booking.id,
              eventType: 'PUSH_NOTIFICATION',
              payload: {
                targetUserId: booking.userId,
                title: `Booking ${dto.status}`,
                body: `Your booking ${booking.reference} is now ${dto.status.toLowerCase()}.`,
                dataPayload: {
                  type: eventType,
                  bookingId: booking.id,
                  reference: booking.reference,
                  status: dto.status,
                },
              },
            },
          });

          return updated;
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (err: any) {
      if (err?.code === 'P2034' || err?.code === 'P2002') {
        throw new ConflictException(
          'Concurrent status update or slot conflict detected. Please retry.',
        );
      }
      throw err;
    }
  }
}
