import { IsNotEmpty, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ForgotPasswordDto {
  @ApiProperty({
    example: '+201012345678',
    description: 'Egyptian mobile phone number',
  })
  @IsNotEmpty({ message: 'Phone number is required' })
  @Matches(/^(?:\+20|0020|0)?(10|11|12|15)[0-9]{8}$/, {
    message: 'Phone number must be a valid Egyptian mobile number',
  })
  phone!: string;
}
