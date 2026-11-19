import {
  IsOptional,
  IsUUID,
  IsInt,
  IsNumber,
  IsEnum,
  Min,
  Max,
  IsString,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { ListingCondition } from '../../../core/enums/domain.enums';

export class FilterListingsDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({
    description: 'Category slug (e.g. real-estate, cars)',
  })
  @IsOptional()
  @IsString()
  categorySlug?: string;

  @ApiPropertyOptional({ description: 'Category slug snake_case alias' })
  @IsOptional()
  @IsString()
  category_slug?: string;

  @ApiPropertyOptional({ description: 'Search term for title/description' })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({
    description: 'Search term alias for title/description',
  })
  @IsOptional()
  @IsString()
  query?: string;

  @ApiPropertyOptional({
    enum: ['newest', 'latest', 'price_asc', 'price_desc', 'nearest'],
    default: 'newest',
  })
  @IsOptional()
  @IsString()
  sort?: string;

  @ApiPropertyOptional({ description: 'Sort alias snake_case' })
  @IsOptional()
  @IsString()
  sort_by?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  governorateId?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  cityId?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  minPrice?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  maxPrice?: number;

  @ApiPropertyOptional({ enum: ListingCondition })
  @IsOptional()
  @IsEnum(ListingCondition)
  condition?: ListingCondition;

  @ApiPropertyOptional({
    enum: ['sale', 'rent', 'buy', 'service', 'product'],
    description: 'Listing kind (sale, rent, service, product)',
  })
  @IsOptional()
  @IsString()
  listingKind?: string;

  @ApiPropertyOptional({ description: 'Return only featured/promoted listings' })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  featured?: boolean;

  @ApiPropertyOptional({ description: 'Clothing or product size' })
  @IsOptional()
  @IsString()
  size?: string;

  @ApiPropertyOptional({ description: 'Product or vehicle color' })
  @IsOptional()
  @IsString()
  color?: string;

  // Geographic spatial filtering
  @ApiPropertyOptional({ description: 'User latitude coordinate (-90 to 90)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat?: number;

  @ApiPropertyOptional({ description: 'Latitude alias' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @ApiPropertyOptional({
    description: 'User longitude coordinate (-180 to 180)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  lng?: number;

  @ApiPropertyOptional({ description: 'Longitude alias' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @ApiPropertyOptional({
    description: 'Spatial search radius in kilometers (default: 25km)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.5)
  @Max(500)
  radiusKm?: number;

  @ApiPropertyOptional({ description: 'Radius in km snake_case alias' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.5)
  @Max(500)
  radius_km?: number;

  // Dynamic Category Attribute Filters
  @ApiPropertyOptional({ description: 'Number of bedrooms/rooms' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  rooms?: number;

  @ApiPropertyOptional({ description: 'Number of bathrooms' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  baths?: number;

  @ApiPropertyOptional({ description: 'Property finishing type' })
  @IsOptional()
  @IsString()
  finishing?: string;

  @ApiPropertyOptional({ description: 'Furnished property flag' })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  furnished?: boolean;

  @ApiPropertyOptional({ description: 'Automotive brand/make' })
  @IsOptional()
  @IsString()
  brand?: string;

  @ApiPropertyOptional({ description: 'Make alias' })
  @IsOptional()
  @IsString()
  make?: string;

  @ApiPropertyOptional({ description: 'Automotive model' })
  @IsOptional()
  @IsString()
  model?: string;

  @ApiPropertyOptional({ description: 'Manufacturing year' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  year?: number;

  @ApiPropertyOptional({ description: 'Vehicle transmission type' })
  @IsOptional()
  @IsString()
  transmission?: string;

  @ApiPropertyOptional({ description: 'Vehicle fuel type' })
  @IsOptional()
  @IsString()
  fuelType?: string;

  @ApiPropertyOptional({ description: 'Fuel type snake_case alias' })
  @IsOptional()
  @IsString()
  fuel_type?: string;

  @ApiPropertyOptional({ description: 'Unit type (e.g. commercial, office)' })
  @IsOptional()
  @IsString()
  unitType?: string;

  @ApiPropertyOptional({ description: 'Unit type snake_case alias' })
  @IsOptional()
  @IsString()
  unit_type?: string;

  @ApiPropertyOptional({
    description: 'JSON-encoded dynamic category attributes string',
  })
  @IsOptional()
  @IsString()
  attributes?: string;

  @ApiPropertyOptional({ description: 'Filter synthetic demo listings' })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isDemo?: boolean;

  @ApiPropertyOptional({ example: '2026-10-10T15:00:00.000Z' })
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit: number = 20;
}
