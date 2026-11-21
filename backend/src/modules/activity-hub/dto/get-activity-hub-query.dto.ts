import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export type ActivityHubSection = 'cart' | 'bookings' | 'rfqs' | 'favorites';

const VALID_SECTIONS: ActivityHubSection[] = [
  'cart',
  'bookings',
  'rfqs',
  'favorites',
];

export class GetActivityHubQueryDto {
  @ApiPropertyOptional({
    description:
      'Comma-separated list of sections to include: cart,bookings,rfqs,favorites. Defaults to all sections.',
    example: 'bookings,rfqs,favorites',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (!value) return undefined;
    const raw = Array.isArray(value) ? value : String(value).split(',');
    return raw.map((s) => String(s).trim().toLowerCase()).filter(Boolean);
  })
  @IsArray()
  @IsIn(VALID_SECTIONS, { each: true })
  include?: ActivityHubSection[];

  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 10, minimum: 1, maximum: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 10;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({
    description: 'Filter sections by category slug (e.g. real-estate)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  categorySlug?: string;
}
