import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';

export type QuotationSortBy =
  'totalAmount' | 'estimatedDeliveryDays' | 'createdAt';

export class GetRfqQuotationsQueryDto {
  @ApiPropertyOptional({
    enum: ['totalAmount', 'estimatedDeliveryDays', 'createdAt'],
    default: 'totalAmount',
  })
  @IsOptional()
  @IsIn(['totalAmount', 'estimatedDeliveryDays', 'createdAt'])
  sortBy?: QuotationSortBy = 'totalAmount';

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
}
