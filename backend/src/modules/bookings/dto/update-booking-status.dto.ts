import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { BookingStatus } from '../bookings.enums';

export class UpdateBookingStatusDto {
  @ApiProperty({
    enum: [
      BookingStatus.CONFIRMED,
      BookingStatus.REJECTED,
      BookingStatus.COMPLETED,
    ],
    description: 'New booking status (provider/admin transition)',
  })
  @IsEnum(BookingStatus)
  status!: BookingStatus;

  @ApiPropertyOptional({
    description: 'Optional reason or note (e.g. rejection reason)',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
