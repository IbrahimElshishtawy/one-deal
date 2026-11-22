import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class CreateQuotationItemDto {
  @ApiPropertyOptional({
    description: 'Matching RfqItem UUID if quoting a specific requested item',
    format: 'uuid',
  })
  @IsOptional()
  @IsUUID()
  rfqItemId?: string;

  @ApiProperty({ example: 'حديد تسليح عز 16 مم' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  name!: string;

  @ApiProperty({ example: 10, maximum: 999999999 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 3 })
  @IsPositive()
  @Max(999999999)
  quantity!: number;

  @ApiProperty({ example: 'ton' })
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  unit!: string;

  @ApiProperty({ example: 38500, maximum: 999999999999 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Max(999999999999)
  unitPrice!: number;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}

export class CreateQuotationDto {
  @ApiPropertyOptional({
    description:
      'Supplier Account UUID owned/managed by the authenticated user. Defaults to user primary active account.',
    format: 'uuid',
  })
  @IsOptional()
  @IsUUID()
  supplierAccountId?: string;

  @ApiPropertyOptional({ example: 2500, minimum: 0, maximum: 9999999999 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(9999999999)
  deliveryFee?: number = 0;

  @ApiProperty({ example: 3, minimum: 1, maximum: 365 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  estimatedDeliveryDays!: number;

  @ApiPropertyOptional({
    description: 'Quotation validity in days from submission (default 14)',
    default: 14,
    minimum: 1,
    maximum: 90,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(90)
  validityDays?: number = 14;

  @ApiPropertyOptional({ maxLength: 1000 })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @ApiProperty({ type: [CreateQuotationItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => CreateQuotationItemDto)
  items!: CreateQuotationItemDto[];
}
