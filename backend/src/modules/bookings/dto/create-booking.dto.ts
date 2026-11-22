import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { BookingType } from '../bookings.enums';

const FLUTTER_BOOKING_TYPE_ALIASES: Record<string, BookingType> = {
  agent_contact: BookingType.GENERAL_INQUIRY,
  maintenance: BookingType.MAINTENANCE_APPOINTMENT,
  maintenance_booking: BookingType.MAINTENANCE_APPOINTMENT,
  service_center: BookingType.SERVICE_CENTER_BOOKING,
  plumbing: BookingType.PLUMBING_SERVICE,
  electricity: BookingType.ELECTRICAL_SERVICE,
  electrical: BookingType.ELECTRICAL_SERVICE,
  ac: BookingType.AC_SERVICE,
  air_conditioning: BookingType.AC_SERVICE,
  construction: BookingType.CONSTRUCTION_SERVICE,
  engineering: BookingType.ENGINEERING_SERVICE,
};

export function normalizeBookingTypeInput(value: unknown): unknown {
  if (typeof value !== 'string') return value;
  const key = value.trim().toLowerCase();
  return FLUTTER_BOOKING_TYPE_ALIASES[key] ?? key;
}

export function normalizeDateInput(value: unknown): unknown {
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  const isoMatch = trimmed.match(/^(\d{4}-\d{2}-\d{2})/);
  return isoMatch ? isoMatch[1] : trimmed;
}

export function normalizeTimeSlotInput(value: unknown): unknown {
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  const ampm = trimmed.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (!ampm) return trimmed;
  let hours = Number(ampm[1]);
  const minutes = ampm[2];
  const meridiem = ampm[3].toUpperCase();
  if (meridiem === 'PM' && hours < 12) hours += 12;
  if (meridiem === 'AM' && hours === 12) hours = 0;
  return `${String(hours).padStart(2, '0')}:${minutes}`;
}

export class CreateBookingDto {
  @ApiPropertyOptional({
    description:
      'Target listing UUID (required unless providerAccountId is specified for direct service booking)',
    format: 'uuid',
  })
  @IsOptional()
  @IsUUID()
  listingId?: string;

  @ApiPropertyOptional({
    description:
      'Provider account UUID (used when booking a service provider directly without a listing; ignored when listingId is provided)',
    format: 'uuid',
  })
  @ValidateIf((o) => !o.listingId)
  @IsUUID()
  providerAccountId?: string;

  @ApiPropertyOptional({
    enum: BookingType,
    example: BookingType.PROPERTY_VIEWING,
    description:
      'Canonical booking type or Flutter alias (e.g. agent_contact, maintenance_booking, plumbing, electricity, ac)',
  })
  @ValidateIf((o) => !o.type)
  @Transform(({ value }) => normalizeBookingTypeInput(value))
  @IsEnum(BookingType)
  bookingType?: BookingType;

  @ApiPropertyOptional({
    description: 'Flutter alias for bookingType',
  })
  @IsOptional()
  @Transform(({ value }) => normalizeBookingTypeInput(value))
  @IsEnum(BookingType)
  type?: BookingType;

  @ApiPropertyOptional({
    description: 'Scheduled date in YYYY-MM-DD or ISO-8601 format',
    example: '2026-12-01',
  })
  @ValidateIf((o) => !o.bookingDate && !o.date)
  @Transform(({ value }) => normalizeDateInput(value))
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'scheduledDate must be in YYYY-MM-DD format',
  })
  scheduledDate?: string;

  @ApiPropertyOptional({
    description: 'Flutter alias for scheduledDate (YYYY-MM-DD or ISO-8601)',
  })
  @IsOptional()
  @Transform(({ value }) => normalizeDateInput(value))
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'bookingDate must be in YYYY-MM-DD format',
  })
  bookingDate?: string;

  @ApiPropertyOptional({
    description: 'Flutter alias for scheduledDate (YYYY-MM-DD or ISO-8601)',
  })
  @IsOptional()
  @Transform(({ value }) => normalizeDateInput(value))
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'date must be in YYYY-MM-DD format',
  })
  date?: string;

  @ApiPropertyOptional({
    description:
      'Scheduled time in 24-hour HH:mm or 12-hour slot format (e.g. "14:30" or "02:00 PM", Africa/Cairo)',
    example: '14:30',
  })
  @ValidateIf((o) => !o.bookingTime && !o.timeSlot)
  @Transform(({ value }) => normalizeTimeSlotInput(value))
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'scheduledTime must be in 24-hour HH:mm format',
  })
  scheduledTime?: string;

  @ApiPropertyOptional({
    description: 'Flutter alias for scheduledTime',
  })
  @IsOptional()
  @Transform(({ value }) => normalizeTimeSlotInput(value))
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'bookingTime must be in 24-hour HH:mm format',
  })
  bookingTime?: string;

  @ApiPropertyOptional({
    description: 'Flutter alias for scheduledTime (e.g. "02:00 PM")',
  })
  @IsOptional()
  @Transform(({ value }) => normalizeTimeSlotInput(value))
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'timeSlot must be in 24-hour HH:mm or 12-hour hh:mm AM/PM format',
  })
  timeSlot?: string;

  @ApiPropertyOptional({
    description: 'Address or service location',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  location?: string;

  @ApiPropertyOptional({
    description: 'Flutter alias for location',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  address?: string;

  @ApiPropertyOptional({
    description: 'Additional notes for the provider',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}
