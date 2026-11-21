import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class AdjudicateVerificationDto {
  @ApiProperty({ enum: ['approve', 'reject', 'request_resubmission'] })
  @IsNotEmpty()
  @IsIn(['approve', 'reject', 'request_resubmission'])
  action!: 'approve' | 'reject' | 'request_resubmission';

  @ApiPropertyOptional({
    description: 'Required when action is reject or request_resubmission',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  rejectionReason?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}
