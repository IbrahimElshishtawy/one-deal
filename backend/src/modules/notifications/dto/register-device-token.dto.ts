import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class RegisterDeviceTokenDto {
  @ApiProperty({
    description: 'FCM registration token for the mobile device',
    maxLength: 1024,
  })
  @IsString()
  @IsNotEmpty({ message: 'Device token is required' })
  @MaxLength(1024, { message: 'Device token must not exceed 1024 characters' })
  token!: string;

  @ApiPropertyOptional({
    enum: ['ios', 'android'],
    default: 'android',
  })
  @IsOptional()
  @IsIn(['ios', 'android'], {
    message: 'Platform must be either ios or android',
  })
  platform?: 'ios' | 'android' = 'android';
}
