import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { QuotationStatus } from '../rfq.enums';

export class UpdateQuotationStatusDto {
  @ApiProperty({
    enum: [
      QuotationStatus.SHORTLISTED,
      QuotationStatus.ACCEPTED,
      QuotationStatus.REJECTED,
      QuotationStatus.WITHDRAWN,
    ],
  })
  @IsEnum(QuotationStatus)
  status!: QuotationStatus;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
