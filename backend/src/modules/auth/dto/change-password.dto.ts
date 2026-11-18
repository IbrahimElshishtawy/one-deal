import { IsNotEmpty, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ChangePasswordDto {
  @ApiProperty({
    example: 'CurrentPassword!2026',
    minLength: 8,
    maxLength: 128,
  })
  @IsNotEmpty({ message: 'Current password is required' })
  @MinLength(8, { message: 'Current password must be at least 8 characters' })
  @MaxLength(128, {
    message: 'Current password must not exceed 128 characters',
  })
  currentPassword!: string;

  @ApiProperty({
    example: 'NewStrongPassword!2026',
    minLength: 8,
    maxLength: 128,
  })
  @IsNotEmpty({ message: 'New password is required' })
  @MinLength(8, { message: 'New password must be at least 8 characters' })
  @MaxLength(128, { message: 'New password must not exceed 128 characters' })
  newPassword!: string;
}
