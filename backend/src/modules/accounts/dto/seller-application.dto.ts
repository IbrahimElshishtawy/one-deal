import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  AccountType,
  SellerApplicationStatus,
  SellerDocumentType,
} from '../../../core/enums/domain.enums';
import {
  ALLOWED_VERIFICATION_MIME_TYPES,
  MAX_VERIFICATION_DOC_SIZE_BYTES,
} from '../services/private-document-storage.service';

export class CreateSellerApplicationDto {
  @ApiPropertyOptional({
    enum: AccountType,
    default: AccountType.INDIVIDUAL,
    description: 'Type of seller account being requested',
  })
  @IsOptional()
  @IsEnum(AccountType)
  businessType?: AccountType;

  @ApiPropertyOptional({
    example: 'Al-Ahram Motors',
    description: 'Seller display or commercial business name',
  })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  businessName?: string;

  @ApiPropertyOptional({
    example: 'Certified used cars dealer in Cairo',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  businessDescription?: string;

  @ApiPropertyOptional({ example: '29501011234567' })
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(50)
  nationalIdNumber?: string;

  @ApiPropertyOptional({ example: 'TAX-987654321' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  taxIdNumber?: string;

  @ApiPropertyOptional({ example: 'CR-123456' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  commercialRegisterNumber?: string;

  @ApiPropertyOptional({ example: '+201012345678' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  contactPhone?: string;

  @ApiPropertyOptional({ example: 'seller@example.com' })
  @IsOptional()
  @IsEmail()
  @MaxLength(255)
  contactEmail?: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  cityId?: number;

  @ApiPropertyOptional({ example: '15 El-Tahrir St, Dokki, Giza' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  address?: string;
}

export class UpdateSellerApplicationDto extends CreateSellerApplicationDto {}

export class RequestVerificationDocUploadUrlDto {
  @ApiProperty({
    enum: SellerDocumentType,
    example: SellerDocumentType.NATIONAL_ID_FRONT,
  })
  @IsNotEmpty()
  @IsEnum(SellerDocumentType)
  documentType!: SellerDocumentType;

  @ApiProperty({ example: 'national-id-front.jpg' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(255)
  fileName!: string;

  @ApiProperty({
    enum: ALLOWED_VERIFICATION_MIME_TYPES,
    example: 'image/jpeg',
  })
  @IsNotEmpty()
  @IsIn(ALLOWED_VERIFICATION_MIME_TYPES)
  mimeType!: string;

  @ApiProperty({
    example: 524288,
    description: 'File size in bytes (max 10 MB)',
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_VERIFICATION_DOC_SIZE_BYTES)
  fileSizeBytes!: number;
}

export class ConfirmVerificationDocumentDto {
  @ApiProperty({
    enum: SellerDocumentType,
    example: SellerDocumentType.NATIONAL_ID_FRONT,
  })
  @IsNotEmpty()
  @IsEnum(SellerDocumentType)
  documentType!: SellerDocumentType;

  @ApiProperty({
    example:
      'private/seller-verification/user-uuid/app-uuid/doc-uuid.jpg',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(500)
  storageKey!: string;

  @ApiProperty({ example: 'national-id-front.jpg' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(255)
  originalFileName!: string;

  @ApiProperty({
    enum: ALLOWED_VERIFICATION_MIME_TYPES,
    example: 'image/jpeg',
  })
  @IsNotEmpty()
  @IsIn(ALLOWED_VERIFICATION_MIME_TYPES)
  mimeType!: string;

  @ApiProperty({ example: 524288 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_VERIFICATION_DOC_SIZE_BYTES)
  fileSizeBytes!: number;

  @ApiPropertyOptional({
    description: 'Optional SHA-256 hex checksum of the uploaded file',
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  checksumSha256?: string;
}

export class ResubmitSellerApplicationDto extends CreateSellerApplicationDto {
  @ApiPropertyOptional({
    default: false,
    description:
      'When true, immediately submits the application to PENDING if complete; otherwise reopens as DRAFT',
  })
  @IsOptional()
  @IsBoolean()
  submitImmediately?: boolean;
}

export class AdminSellerApplicationsQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional({
    description:
      'Filter by status (PENDING, UNDER_REVIEW, APPROVED, REJECTED, SUSPENDED, DRAFT, or all)',
    default: SellerApplicationStatus.PENDING,
  })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiPropertyOptional({ enum: AccountType })
  @IsOptional()
  @IsEnum(AccountType)
  businessType?: AccountType;

  @ApiPropertyOptional({ description: 'Search by business name, user name, or phone' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  q?: string;
}

export class AdminReviewSellerApplicationDto {
  @ApiPropertyOptional({ example: 'Assigned for KYC document check' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class AdminApproveSellerApplicationDto {
  @ApiPropertyOptional({ example: 'All KYC documents verified' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class AdminRejectSellerApplicationDto {
  @ApiProperty({
    example: 'National ID image is blurry and unreadable. Please upload a clear photo.',
    description: 'Mandatory rejection reason communicated to the applicant',
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(5, { message: 'Rejection reason must be at least 5 characters' })
  @MaxLength(1000)
  reason!: string;

  @ApiPropertyOptional({ example: 'Internal reviewer note' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class AdminSuspendSellerDto {
  @ApiProperty({
    example: 'Repeated policy violations on fraudulent listings',
    description: 'Mandatory reason for suspending seller privileges',
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(5, { message: 'Suspension reason must be at least 5 characters' })
  @MaxLength(1000)
  reason!: string;

  @ApiPropertyOptional({ example: 'Internal compliance reference #4821' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}
