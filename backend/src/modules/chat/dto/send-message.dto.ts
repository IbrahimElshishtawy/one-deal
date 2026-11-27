import {
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SendMessageDto {
  @ApiProperty({ example: 'السلام عليكم، هل السعر قابل للتفاوض؟' })
  @IsNotEmpty({ message: 'Message text cannot be empty' })
  @IsString()
  @MinLength(1, { message: 'Message must have at least 1 character' })
  @MaxLength(2000, { message: 'Message cannot exceed 2000 characters' })
  text!: string;

  @ApiPropertyOptional({
    example: 'msg-550e8400-e29b-41d4-a716-446655440000',
    description:
      'Optional client-generated idempotency key scoped to (conversationId, senderUserId) to prevent duplicate messages on retry',
  })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  clientMessageId?: string;
}
