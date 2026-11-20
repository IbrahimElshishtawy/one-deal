import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class AdminLoginDto {
  @ApiProperty({ example: 'superadmin@dealone.eg' })
  @IsNotEmpty()
  @IsEmail()
  @MaxLength(255)
  email!: string;

  @ApiProperty({ example: 'SuperAdmin!2026' })
  @IsNotEmpty()
  @IsString()
  @MinLength(6)
  @MaxLength(128)
  password!: string;
}

export class VerifyMfaChallengeDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  mfaChallengeToken!: string;

  @ApiProperty({ example: '123456' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(32)
  code!: string;
}

export class EnableMfaDto {
  @ApiProperty({ example: '123456' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(12)
  code!: string;
}

export class DisableMfaDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  currentPassword!: string;

  @ApiProperty({ example: '123456' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(12)
  code!: string;
}

export class AdminRefreshDto {
  @ApiPropertyOptional({
    description:
      'Optional refresh token fallback for non-browser API tests; browsers use HttpOnly cookie',
  })
  @IsOptional()
  @IsString()
  refreshToken?: string;
}

export class AdminChangePasswordDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  currentPassword!: string;

  @ApiProperty({ minLength: 8 })
  @IsNotEmpty()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  newPassword!: string;
}

export class AdminForgotPasswordDto {
  @ApiProperty({ example: 'superadmin@dealone.eg' })
  @IsNotEmpty()
  @IsEmail()
  @MaxLength(255)
  email!: string;
}

export class AdminResetPasswordDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  token!: string;

  @ApiProperty({ minLength: 8 })
  @IsNotEmpty()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  newPassword!: string;
}
