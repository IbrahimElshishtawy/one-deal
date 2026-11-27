import {
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum SellerDealStatus {
  NEW_INQUIRY = 'NEW_INQUIRY',
  CONTACTED = 'CONTACTED',
  NEGOTIATING = 'NEGOTIATING',
  AGREED = 'AGREED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export class SellerListingsQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(30)
  status?: string; // published, unpublished, hidden, archived, expired, pending, draft, rejected

  @IsOptional()
  @IsString()
  @MaxLength(30)
  availability?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}

export class SellerInteractionsQueryDto {
  @IsOptional()
  @IsUUID()
  listingId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  type?: string; // inquiry | booking | favorite | all

  @IsOptional()
  @IsString()
  from?: string;

  @IsOptional()
  @IsString()
  to?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}

export class SellerConversationsQueryDto {
  @IsOptional()
  @IsUUID()
  listingId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @IsOptional()
  @IsString()
  unreadOnly?: string; // 'true' | 'false'

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}

export class SellerDealsQueryDto {
  @IsOptional()
  @IsEnum(SellerDealStatus)
  status?: SellerDealStatus;

  @IsOptional()
  @IsUUID()
  listingId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}

export class CreateSellerDealDto {
  @IsUUID()
  listingId!: string;

  @IsString()
  @MaxLength(150)
  customerName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(150)
  customerReference?: string;

  @IsOptional()
  @IsUUID()
  customerUserId?: string;

  @IsOptional()
  @IsUUID()
  conversationId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  agreedPrice?: number;

  @IsOptional()
  @IsEnum(SellerDealStatus)
  status?: SellerDealStatus;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}

export class UpdateSellerDealDto {
  @IsOptional()
  @IsEnum(SellerDealStatus)
  status?: SellerDealStatus;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  agreedPrice?: number;

  @IsOptional()
  @IsString()
  @MaxLength(150)
  customerName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(150)
  customerReference?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}

export class SellerAnalyticsQueryDto {
  @IsOptional()
  @IsString()
  range?: string = '30d'; // 7d | 30d | 90d | all
}
