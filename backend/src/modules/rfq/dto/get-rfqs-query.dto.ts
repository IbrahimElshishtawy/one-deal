import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
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
import { RfqStatus } from '../rfq.enums';

export class GetRfqsQueryDto {
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

  @ApiPropertyOptional({ enum: RfqStatus })
  @IsOptional()
  @IsEnum(RfqStatus)
  status?: RfqStatus;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(150)
  categorySlug?: string;

  @ApiPropertyOptional({
    enum: ['mine', 'open_for_suppliers'],
    default: 'mine',
    description:
      'mine: RFQs created by current user; open_for_suppliers: open RFQs available to quote',
  })
  @IsOptional()
  @IsIn(['mine', 'open_for_suppliers'])
  scope?: 'mine' | 'open_for_suppliers' = 'mine';
}
