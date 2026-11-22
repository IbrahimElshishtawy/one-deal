import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { CreateRfqItemDto } from './create-rfq.dto';

export class UpdateRfqDto {
  @ApiPropertyOptional({ example: 'توريد حديد وأسمنت لمشروع التجمع الخامس' })
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  title?: string;

  @ApiPropertyOptional({
    example: 'مطلوب عرض سعر شامل النقل والتنزيل لموقع المشروع خلال أسبوع',
  })
  @IsOptional()
  @IsString()
  @MinLength(5)
  @MaxLength(3000)
  description?: string;

  @ApiPropertyOptional({
    description: 'Category UUID (e.g. building-materials)',
    format: 'uuid',
  })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({
    example: 'القاهرة الجديدة - التجمع الخامس - الحي الثالث',
  })
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  deliveryLocation?: string;

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

  @ApiPropertyOptional({ type: [CreateRfqItemDto] })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => CreateRfqItemDto)
  items?: CreateRfqItemDto[];
}
