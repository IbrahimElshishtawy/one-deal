import { IsOptional, IsInt, IsString, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class HomeQueryDto {
  @ApiPropertyOptional({ description: 'Optional category slug filter' })
  @IsOptional()
  @IsString()
  categorySlug?: string;

  @ApiPropertyOptional({ description: 'Optional governorate ID filter' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  governorateId?: number;

  @ApiPropertyOptional({ description: 'Optional city ID filter' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  cityId?: number;

  @ApiPropertyOptional({ default: 10, minimum: 1, maximum: 30 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  limit?: number = 10;
}
