import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDefined, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpsertPlatformSettingDto {
  @ApiProperty({
    description: 'JSON value for the platform setting',
    example: { enabled: true, maxDailyReveals: 5 },
  })
  @IsDefined({ message: 'Setting value is required' })
  value!: unknown;

  @ApiPropertyOptional({
    description: 'Human-readable description of this setting',
    example: 'Maximum daily contact reveals per account',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}
