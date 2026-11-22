import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { QuotationStatus } from '../rfq.enums';

export const ALLOWED_QUOTATION_MUTATION_STATUSES: QuotationStatus[] = [
  QuotationStatus.SHORTLISTED,
  QuotationStatus.ACCEPTED,
  QuotationStatus.REJECTED,
  QuotationStatus.WITHDRAWN,
];

export class UpdateQuotationStatusDto {
  @ApiProperty({
    enum: ALLOWED_QUOTATION_MUTATION_STATUSES,
  })
  @IsIn(ALLOWED_QUOTATION_MUTATION_STATUSES)
  status!: QuotationStatus;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
