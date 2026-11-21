import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
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

  @ApiProperty({
    enum: BookingType,
    example: BookingType.PROPERTY_VIEWING,
  })
  @IsEnum(BookingType)
  bookingType!: BookingType;

  @ApiProperty({
    description: 'Scheduled date in YYYY-MM-DD format',
    example: '2026-12-01',
  })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'scheduledDate must be in YYYY-MM-DD format',
  })
  scheduledDate!: string;

  @ApiProperty({
    description: 'Scheduled time in 24-hour HH:mm format (Africa/Cairo)',
    example: '14:30',
  })
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'scheduledTime must be in 24-hour HH:mm format',
  })
  scheduledTime!: string;

  @ApiPropertyOptional({
    description: 'Address or service location',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  location?: string;

  @ApiPropertyOptional({
    description: 'Additional notes for the provider',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}
