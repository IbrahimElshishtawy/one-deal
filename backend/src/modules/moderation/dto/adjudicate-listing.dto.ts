import {
  IsNotEmpty,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AdjudicateListingDto {
  @ApiProperty({
    example: 'approve',
    enum: ['approve', 'reject', 'request_changes'],
    description: 'Moderator decision action',
  })
  @IsNotEmpty()
  @IsIn(['approve', 'reject', 'request_changes'], {
    message: "Action must be 'approve', 'reject', or 'request_changes'",
  })
  action!: 'approve' | 'reject' | 'request_changes';

  @ApiPropertyOptional({
    example: 'PROHIBITED_COMMODITY',
    description: 'Standard rejection reason code if rejecting',
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  reasonCode?: string;

  @ApiPropertyOptional({
    example: 'Listing complies with marketplace community safety guidelines',
    description: 'Internal moderator adjudication notes',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}
