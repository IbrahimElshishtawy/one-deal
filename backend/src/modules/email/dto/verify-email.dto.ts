import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VerifyEmailDto {
  @ApiProperty({
    description: 'Single-use email verification token received via email link',
    example: 'base64url-verification-token',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(16)
  @MaxLength(256)
  token!: string;
}
