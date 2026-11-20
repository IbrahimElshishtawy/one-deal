import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreateStaffRoleDto {
  @ApiProperty({ example: 'moderator' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(50)
  name!: string;

  @ApiPropertyOptional({ example: 'Content moderation specialist' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  description?: string;

  @ApiPropertyOptional({
    example: ['listings.read', 'listings.approve'],
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  permissions?: string[] = [];
}
