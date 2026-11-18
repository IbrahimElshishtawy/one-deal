import {
  IsNotEmpty,
  Length,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResetPasswordDto {
  @ApiProperty({
    example: '+201012345678',
    description: 'Egyptian mobile phone number',
  })
  @IsNotEmpty({ message: 'Phone number is required' })
  @Matches(/^(?:\+20|0020|0)?(10|11|12|15)[0-9]{8}$/, {
    message: 'Phone number must be a valid Egyptian mobile number',
  })
  phone!: string;

  @ApiProperty({ example: '123456', description: '6-digit password reset OTP' })
  @IsNotEmpty({ message: 'OTP code is required' })
  @Length(6, 6, { message: 'OTP code must be exactly 6 digits' })
  @Matches(/^[0-9]{6}$/, { message: 'OTP code must be numeric' })
  code!: string;

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
