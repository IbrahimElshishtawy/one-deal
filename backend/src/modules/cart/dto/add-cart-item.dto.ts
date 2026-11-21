import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class AddCartItemDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  listingId!: string;

  @ApiPropertyOptional({ default: 1, minimum: 1, maximum: 999 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(999)
  quantity?: number = 1;

  @ApiPropertyOptional({
    default: 'default',
    description: 'Future-ready product variant identifier',
    maxLength: 100,
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  variantKey?: string = 'default';

  @ApiPropertyOptional({
    description: 'Optional variant attributes (e.g. size, color)',
  })
  @IsOptional()
  @IsObject()
  variantAttributes?: Record<string, unknown>;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
