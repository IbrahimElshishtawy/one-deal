import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUrl,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class CreateRfqItemDto {
  @ApiPropertyOptional({
    description: 'Optional linked catalog listing UUID',
    format: 'uuid',
  })
  @IsOptional()
  @IsUUID()
  listingId?: string;

  @ApiProperty({ example: 'حديد تسليح عز 16 مم' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  name!: string;

  @ApiPropertyOptional({ example: 'Grade B500B, 12m length' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  specification?: string;

  @ApiProperty({ example: 10, minimum: 0.001, maximum: 999999999 })
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
}

export class CreateRfqDto {
  @ApiProperty({ example: 'توريد حديد وأسمنت لمشروع التجمع الخامس' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  title!: string;

  @ApiProperty({
    example: 'مطلوب عرض سعر شامل النقل والتنزيل لموقع المشروع خلال أسبوع',
  })
  @IsString()
  @MinLength(5)
  @MaxLength(3000)
  description!: string;

  @ApiPropertyOptional({
    description: 'Category UUID (e.g. building-materials)',
    format: 'uuid',
  })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiProperty({ example: 'القاهرة الجديدة - التجمع الخامس - الحي الثالث' })
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  deliveryLocation!: string;

  @ApiPropertyOptional({
    description: 'Target delivery date in YYYY-MM-DD format',
    example: '2026-12-15',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'requiredByDate must be in YYYY-MM-DD format',
  })
  requiredByDate?: string;

  @ApiPropertyOptional({
    type: [String],
    description: 'Optional supporting image URLs (max 10)',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsUrl({ protocols: ['https'], require_protocol: true }, { each: true })
  supportingImages?: string[];

  @ApiPropertyOptional({ maxLength: 1000 })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  additionalNotes?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isDraft?: boolean = false;

  @ApiProperty({ type: [CreateRfqItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => CreateRfqItemDto)
  items!: CreateRfqItemDto[];
}
