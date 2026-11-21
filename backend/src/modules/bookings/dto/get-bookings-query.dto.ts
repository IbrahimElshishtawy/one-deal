import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { BookingStatus, BookingType } from '../bookings.enums';

export class GetBookingsQueryDto {
  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional({ enum: BookingStatus })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @ApiPropertyOptional({ enum: BookingType })
  @IsOptional()
  @IsEnum(BookingType)
  bookingType?: BookingType;

  @ApiPropertyOptional({ description: 'Filter by category UUID' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({ description: 'Filter by category slug' })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  categorySlug?: string;

  @ApiPropertyOptional({
    enum: ['requester', 'provider'],
    default: 'requester',
    description:
      'View bookings created by the user (requester) or assigned to accounts managed by the user (provider)',
  })
  @IsOptional()
  @IsIn(['requester', 'provider'])
  role?: 'requester' | 'provider' = 'requester';
}
