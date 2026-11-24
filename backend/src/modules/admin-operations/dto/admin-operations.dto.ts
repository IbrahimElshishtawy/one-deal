import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
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

export class AdminPaginationDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @IsString()
  sortBy?: string;

  @IsOptional()
  @IsIn(['asc', 'desc'])
  sortOrder?: 'asc' | 'desc' = 'desc';
}

export class AdminUsersQueryDto extends AdminPaginationDto {
  @IsOptional()
  @IsIn(['all', 'active', 'suspended', 'banned'])
  moderationStatus?: string;

  @IsOptional()
  @IsIn(['true', 'false'])
  isActive?: string;

  @IsOptional()
  @IsIn(['true', 'false'])
  isDemo?: string;
}

export class UpdateAdminUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  fullName?: string;

  @IsOptional()
  @IsIn(['ar', 'en'])
  preferredLanguage?: 'ar' | 'en';
}

export class SuspendUserDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(3)
  @MaxLength(1000)
  reason!: string;

  @IsOptional()
  @IsDateString()
  suspendedUntil?: string;
}

export class BanUserDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(3)
  @MaxLength(1000)
  reason!: string;
}

export class AddUserNoteDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(2)
  @MaxLength(1000)
  note!: string;
}

export class OptionalAdminNotesDto {
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class AdminAccountsQueryDto extends AdminPaginationDto {
  @IsOptional()
  @IsString()
  verificationStatus?: string;

  @IsOptional()
  @IsString()
  accountType?: string;
}

export class UpdateSellerAccountStatusDto {
  @IsBoolean()
  isActive!: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

export class AdminListingsQueryDto extends AdminPaginationDto {
  @IsOptional()
  @IsString()
  moderationStatus?: string;

  @IsOptional()
  @IsString()
  publicationStatus?: string;

  @IsOptional()
  @IsString()
  availabilityStatus?: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsUUID()
  accountId?: string;

  @IsOptional()
  @IsString()
  listingKind?: string;

  @IsOptional()
  @IsIn(['true', 'false'])
  isDemo?: string;
}

export class ListingActionReasonDto {
  @IsOptional()
  @IsString()
  @MaxLength(50)
  reasonCode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class BulkListingDecisionDto {
  @IsArray()
  @IsUUID('all', { each: true })
  listingIds!: string[];

  @IsNotEmpty()
  @IsIn(['approve', 'reject', 'hide', 'archive'])
  action!: 'approve' | 'reject' | 'hide' | 'archive';

  @IsOptional()
  @IsString()
  @MaxLength(50)
  reasonCode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}

export class MessagingConversationMessagesQueryDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(5)
  @MaxLength(500)
  reason!: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 30;
}

export class UpdateConversationStatusDto {
  @IsNotEmpty()
  @IsIn(['open', 'closed', 'archived'])
  status!: 'open' | 'closed' | 'archived';

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

export class AudiencePreviewDto {
  @IsNotEmpty()
  @IsIn(['all', 'verified', 'new_users', 'category'])
  audienceType!: 'all' | 'verified' | 'new_users' | 'category';

  @IsOptional()
  @IsObject()
  audienceFilter?: Record<string, unknown>;
}

export class CreateNotificationCampaignDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(200)
  titleAr!: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(200)
  titleEn!: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(2000)
  bodyAr!: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(2000)
  bodyEn!: string;

  @IsNotEmpty()
  @IsIn(['all', 'verified', 'new_users', 'category'])
  audienceType!: 'all' | 'verified' | 'new_users' | 'category';

  @IsOptional()
  @IsObject()
  audienceFilter?: Record<string, unknown>;

  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  @IsOptional()
  @IsBoolean()
  submitForApproval?: boolean;
}

export class CreateCmsItemDto {
  @IsNotEmpty()
  @IsIn(['banner', 'home_section', 'page', 'faq', 'terms', 'privacy'])
  type!: 'banner' | 'home_section' | 'page' | 'faq' | 'terms' | 'privacy';

  @IsNotEmpty()
  @IsString()
  @MaxLength(150)
  slug!: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(255)
  titleAr!: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(255)
  titleEn!: string;

  @IsOptional()
  @IsString()
  bodyAr?: string;

  @IsOptional()
  @IsString()
  bodyEn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  imageUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  targetUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  placement?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsIn(['draft', 'published', 'scheduled', 'archived'])
  status?: 'draft' | 'published' | 'scheduled' | 'archived';

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsDateString()
  startsAt?: string;

  @IsOptional()
  @IsDateString()
  endsAt?: string;
}

export class UpdateCmsItemDto {
  @IsOptional()
  @IsString()
  @MaxLength(255)
  titleAr?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  titleEn?: string;

  @IsOptional()
  @IsString()
  bodyAr?: string | null;

  @IsOptional()
  @IsString()
  bodyEn?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  imageUrl?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  targetUrl?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  placement?: string | null;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsIn(['draft', 'published', 'scheduled', 'archived'])
  status?: 'draft' | 'published' | 'scheduled' | 'archived';

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsDateString()
  startsAt?: string | null;

  @IsOptional()
  @IsDateString()
  endsAt?: string | null;
}

export class CreateFeatureFlagDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  key!: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(150)
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean = false;

  @IsOptional()
  @IsIn(['all', 'development', 'staging', 'production'])
  environment?: string = 'all';

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100)
  rolloutPercentage?: number = 100;
}

export class UpdateFeatureFlagDto {
  @IsOptional()
  @IsString()
  @MaxLength(150)
  name?: string;

  @IsOptional()
  @IsString()
  description?: string | null;

  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;

  @IsOptional()
  @IsIn(['all', 'development', 'staging', 'production'])
  environment?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100)
  rolloutPercentage?: number;
}

export class AnalyticsQueryDto {
  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;

  @IsOptional()
  @IsIn(['json', 'csv'])
  format?: 'json' | 'csv';
}
