import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEmail,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  AccountType,
  MarketplaceSection,
  SellerApplicationStatus,
  SellerDocumentReviewDecision,
  SellerDocumentType,
  SellerType,
} from '../../../core/enums/domain.enums';
import {
  ALLOWED_VERIFICATION_MIME_TYPES,
  MAX_VERIFICATION_DOC_SIZE_BYTES,
} from '../services/private-document-storage.service';

export class GetVerificationRequirementsQueryDto {
  @ApiPropertyOptional({
    enum: SellerType,
    example: SellerType.INDIVIDUAL,
    description: 'Seller type to resolve verification requirements for',
  })
  @IsOptional()
  @IsEnum(SellerType)
  sellerType?: SellerType;

  @ApiPropertyOptional({
    enum: MarketplaceSection,
    example: MarketplaceSection.REAL_ESTATE,
    description: 'Single marketplace section slug',
  })
  @IsOptional()
  @IsEnum(MarketplaceSection)
  marketplaceSection?: MarketplaceSection;

  @ApiPropertyOptional({
    example: 'real-estate,cars',
    description: 'Comma-separated list of marketplace section slugs',
  })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  marketplaceSections?: string;
}

export class CreateSellerApplicationDto {
  @ApiPropertyOptional({
    enum: SellerType,
    default: SellerType.INDIVIDUAL,
    description: 'Configurable seller type (INDIVIDUAL, BUSINESS, SERVICE_PROVIDER)',
  })
  @IsOptional()
  @IsEnum(SellerType)
  sellerType?: SellerType;

  @ApiPropertyOptional({
    enum: AccountType,
    default: AccountType.INDIVIDUAL,
    description: 'Account classification (individual, company, factory, office, store)',
  })
  @IsOptional()
  @IsEnum(AccountType)
  businessType?: AccountType;

  @ApiPropertyOptional({
    enum: MarketplaceSection,
    isArray: true,
    example: [MarketplaceSection.REAL_ESTATE],
    description: 'Deal One marketplace sections the seller intends to operate in',
  })
  @IsOptional()
  @IsArray()
  @IsEnum(MarketplaceSection, { each: true })
  marketplaceSections?: MarketplaceSection[];

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

  @ApiPropertyOptional({
    example: 'Ahmed Hassan',
    description: 'Authorized legal representative name (for BUSINESS sellers)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  authorizedRepresentativeName?: string;

  @ApiPropertyOptional({
    example: '29001011234567',
    description: 'Authorized representative national ID (encrypted at rest)',
  })
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(50)
  authorizedRepresentativeId?: string;

  @ApiPropertyOptional({
    example: 'Engineering & AC Maintenance',
    description: 'Primary service specialty (for SERVICE_PROVIDER sellers)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  serviceCategory?: string;

  @ApiPropertyOptional({
    example: 7,
    description: 'Years of professional experience (for SERVICE_PROVIDER sellers)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(80)
  yearsOfExperience?: number;

  @ApiPropertyOptional({
    example: 'B.Sc. Mechanical Engineering, Syndicate Member #44210',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  qualifications?: string;

  @ApiPropertyOptional({ example: 'ENG-LIC-2026-8812' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  professionalLicenseNumber?: string;

  @ApiPropertyOptional({ example: 'https://portfolio.example.com/ahmed' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  portfolioUrl?: string;

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

export class CreateBusinessUpgradeDto {
  @ApiPropertyOptional({
    enum: [
      AccountType.COMPANY,
      AccountType.OFFICE,
      AccountType.STORE,
      AccountType.FACTORY,
    ],
    default: AccountType.COMPANY,
    description: 'Target commercial account classification for the business upgrade',
  })
  @IsOptional()
  @IsIn([
    AccountType.COMPANY,
    AccountType.OFFICE,
    AccountType.STORE,
    AccountType.FACTORY,
  ])
  businessType?: AccountType;

  @ApiPropertyOptional({
    enum: MarketplaceSection,
    isArray: true,
    example: [MarketplaceSection.REAL_ESTATE],
    description: 'Deal One marketplace sections the business operates in',
  })
  @IsOptional()
  @IsArray()
  @IsEnum(MarketplaceSection, { each: true })
  marketplaceSections?: MarketplaceSection[];

  @ApiProperty({
    example: 'El-Nile Real Estate Office',
    description: 'Registered commercial company or office name',
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  businessName!: string;

  @ApiPropertyOptional({
    example: 'Licensed real estate brokerage and property management office',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  businessDescription?: string;

  @ApiProperty({ example: 'CR-789012' })
  @IsNotEmpty()
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  commercialRegisterNumber!: string;

  @ApiPropertyOptional({ example: 'TAX-123456789' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  taxIdNumber?: string;

  @ApiPropertyOptional({ example: 'Ahmed Hassan' })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  authorizedRepresentativeName?: string;

  @ApiPropertyOptional({ example: '29001011234567' })
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(50)
  authorizedRepresentativeId?: string;

  @ApiPropertyOptional({ example: '+201012345678' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  contactPhone?: string;

  @ApiPropertyOptional({ example: 'office@example.com' })
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

  @ApiPropertyOptional({ example: '24 Gameat El-Dewal St, Mohandessin, Giza' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  address?: string;
}

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
    description: 'File size in bytes (max 10 MB or requirement limit)',
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(25 * 1024 * 1024)
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
  @Max(25 * 1024 * 1024)
  fileSizeBytes!: number;

  @ApiPropertyOptional({
    description: 'Optional SHA-256 hex checksum of the uploaded file',
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  checksumSha256?: string;

  @ApiPropertyOptional({
    description:
      'Optional base64-encoded first 16+ bytes of the file for magic-byte content signature validation',
  })
  @IsOptional()
  @IsString()
  @MaxLength(256)
  fileHeaderBase64?: string;

  @ApiPropertyOptional({
    example: '2028-12-31T23:59:59.000Z',
    description: 'Document expiration date (mandatory when requirement requires expiration)',
  })
  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @ApiPropertyOptional({
    format: 'uuid',
    description: 'Optional linked verification requirement ID',
  })
  @IsOptional()
  @IsUUID()
  requirementId?: string;
}

export class ReplaceVerificationDocumentDto {
  @ApiProperty({
    example: 'private/seller-verification/user-uuid/app-uuid/new-doc-uuid.jpg',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(500)
  storageKey!: string;

  @ApiProperty({ example: 'national-id-front-clear.jpg' })
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
  @Max(25 * 1024 * 1024)
  fileSizeBytes!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(64)
  checksumSha256?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(256)
  fileHeaderBase64?: string;

  @ApiPropertyOptional({ example: '2028-12-31T23:59:59.000Z' })
  @IsOptional()
  @IsDateString()
  expiresAt?: string;
}

export class ResubmitSellerApplicationDto extends CreateSellerApplicationDto {
  @ApiPropertyOptional({
    default: false,
    description:
      'When true (or when resubmitting from NEEDS_CORRECTION), submits the application to PENDING if complete; otherwise reopens as DRAFT',
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
      'Filter by status (PENDING, UNDER_REVIEW, NEEDS_CORRECTION, APPROVED, REJECTED, SUSPENDED, EXPIRED, DRAFT, or all)',
    default: SellerApplicationStatus.PENDING,
  })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiPropertyOptional({ enum: SellerType })
  @IsOptional()
  @IsEnum(SellerType)
  sellerType?: SellerType;

  @ApiPropertyOptional({ enum: AccountType })
  @IsOptional()
  @IsEnum(AccountType)
  businessType?: AccountType;

  @ApiPropertyOptional({
    enum: MarketplaceSection,
    description: 'Filter applications targeting a specific Deal One marketplace section',
  })
  @IsOptional()
  @IsEnum(MarketplaceSection)
  marketplaceSection?: MarketplaceSection;

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

export class AdminReviewDocumentDto {
  @ApiProperty({
    enum: SellerDocumentReviewDecision,
    example: SellerDocumentReviewDecision.APPROVED,
  })
  @IsNotEmpty()
  @IsEnum(SellerDocumentReviewDecision)
  decision!: SellerDocumentReviewDecision;

  @ApiPropertyOptional({
    example: 'Document corner is cropped and unreadable',
    description: 'Mandatory when decision is REJECTED or CORRECTION_REQUIRED',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;

  @ApiPropertyOptional({ example: 'Internal reviewer note' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class AdminRequestCorrectionDto {
  @ApiProperty({
    example: 'Please upload a clearer photo of your National ID front and update your address.',
    description: 'Mandatory user-facing correction reason',
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(5)
  @MaxLength(1000)
  reason!: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['address', 'businessName'],
    description: 'Specific profile fields the user is requested to correct',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  affectedFields?: string[];

  @ApiPropertyOptional({
    type: [String],
    description: 'IDs of submitted documents that are rejected and must be replaced',
  })
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  rejectedDocumentIds?: string[];

  @ApiPropertyOptional({ example: 'Internal reviewer note' })
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

  @ApiPropertyOptional({
    example: '2027-11-26T00:00:00.000Z',
    description: 'Optional verification expiration timestamp (defaults to 365 days)',
  })
  @IsOptional()
  @IsDateString()
  verificationExpiresAt?: string;
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

export class AdminExpireSellerDto {
  @ApiPropertyOptional({
    example: 'Annual seller verification credentials expired',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;

  @ApiPropertyOptional({ example: 'Automated or compliance-triggered expiry' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class AdminListRequirementsQueryDto {
  @ApiPropertyOptional({ enum: [...Object.values(SellerType), 'ALL'] })
  @IsOptional()
  @IsString()
  sellerType?: string;

  @ApiPropertyOptional({ enum: MarketplaceSection })
  @IsOptional()
  @IsEnum(MarketplaceSection)
  marketplaceSection?: MarketplaceSection;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  isActive?: boolean;
}

export class AdminCreateRequirementDto {
  @ApiProperty({ enum: [...Object.values(SellerType), 'ALL'] })
  @IsNotEmpty()
  @IsIn([...Object.values(SellerType), 'ALL'])
  sellerType!: SellerType | 'ALL';

  @ApiPropertyOptional({ enum: MarketplaceSection })
  @IsOptional()
  @IsEnum(MarketplaceSection)
  marketplaceSection?: MarketplaceSection;

  @ApiProperty({ enum: SellerDocumentType })
  @IsNotEmpty()
  @IsEnum(SellerDocumentType)
  documentType!: SellerDocumentType;

  @ApiProperty({ example: 'Real Estate Brokerage License' })
  @IsNotEmpty()
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  displayName!: string;

  @ApiPropertyOptional({ example: 'ترخيص مزاولة نشاط عقاري' })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  displayNameAr?: string;

  @ApiPropertyOptional({ example: 'Valid brokerage license issued by local authority' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isRequired?: boolean;

  @ApiPropertyOptional({
    type: [String],
    example: ['application/pdf', 'image/jpeg', 'image/png'],
  })
  @IsOptional()
  @IsArray()
  @IsIn(ALLOWED_VERIFICATION_MIME_TYPES, { each: true })
  acceptedMimeTypes?: string[];

  @ApiPropertyOptional({
    default: MAX_VERIFICATION_DOC_SIZE_BYTES,
    example: 5242880,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1024)
  @Max(25 * 1024 * 1024)
  maxFileSizeBytes?: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  requiresExpiration?: boolean;

  @ApiPropertyOptional({ example: { minDaysUntilExpiry: 30 } })
  @IsOptional()
  @IsObject()
  verificationRules?: Record<string, unknown>;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ default: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(10000)
  sortOrder?: number;
}

export class AdminUpdateRequirementDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  displayName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(150)
  displayNameAr?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isRequired?: boolean;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsIn(ALLOWED_VERIFICATION_MIME_TYPES, { each: true })
  acceptedMimeTypes?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1024)
  @Max(25 * 1024 * 1024)
  maxFileSizeBytes?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  requiresExpiration?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsObject()
  verificationRules?: Record<string, unknown>;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(10000)
  sortOrder?: number;
}
