import { BadRequestException } from '@nestjs/common';
import { BookingStatus } from './bookings.enums';

const VALID_BOOKING_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  [BookingStatus.PENDING]: [
    BookingStatus.CONFIRMED,
    BookingStatus.REJECTED,
    BookingStatus.CANCELLED,
  ],
  [BookingStatus.CONFIRMED]: [BookingStatus.CANCELLED, BookingStatus.COMPLETED],
  [BookingStatus.REJECTED]: [],
  [BookingStatus.CANCELLED]: [],
  [BookingStatus.COMPLETED]: [],
};

export function isValidBookingTransition(
  from: BookingStatus,
  to: BookingStatus,
): boolean {
  return VALID_BOOKING_TRANSITIONS[from]?.includes(to) ?? false;
}

export function assertValidBookingTransition(
  from: string,
  to: BookingStatus,
): void {
  const current = from as BookingStatus;
  if (!isValidBookingTransition(current, to)) {
    throw new BadRequestException(
      `Invalid booking status transition from '${from}' to '${to}'`,
    );
  }
}
