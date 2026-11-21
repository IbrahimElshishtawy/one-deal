import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class AddFavoriteDto {
  @ApiProperty({
    description: 'UUID of the listing to add to favorites',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  listingId!: string;
}
