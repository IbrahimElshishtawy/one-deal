import { IsEmail, IsOptional, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class RequestEmailVerificationDto {
  @ApiPropertyOptional({
    description:
      'Email address to bind and verify for the authenticated user. Omit to verify the user’s existing unverified email.',
    example: 'user@example.com',
  })
  @IsOptional()
  @IsEmail()
  @MaxLength(255)
  email?: string;
}
