import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class BatchPriceRefreshDto {
  @ApiProperty({
    description: 'List of listing UUIDs to refresh live prices for (max 50)',
    type: [String],
    example: ['550e8400-e29b-41d4-a716-446655440000'],
  })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @IsUUID('all', { each: true })
  ids!: string[];
}
