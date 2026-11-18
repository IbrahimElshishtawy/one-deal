import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';

export class SubmitVerificationDto {
  @ApiProperty({
    example: 'commercial_register',
    description:
      'Verification document type (e.g. commercial_register, tax_card, national_id)',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(50)
  documentType!: string;

  @ApiPropertyOptional({ example: 'CR-123456' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  documentNumber?: string;

  @ApiProperty({ example: 'https://cdn.marketspace.eg/verifications/doc.pdf' })
  @IsNotEmpty()
  @IsUrl({ require_tld: false })
  @MaxLength(500)
  fileUrl!: string;
}
