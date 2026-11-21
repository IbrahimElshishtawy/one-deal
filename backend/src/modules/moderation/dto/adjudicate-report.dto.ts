import {
  IsNotEmpty,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReportStatus } from '../../../core/enums/domain.enums';

export class AdjudicateReportDto {
  @ApiProperty({
    enum: ['open', 'resolved', 'dismissed', 'escalated'],
    example: ReportStatus.RESOLVED,
  })
  @IsNotEmpty()
  @IsIn(['open', 'resolved', 'dismissed', 'escalated'])
  status!: ReportStatus | 'escalated';

  @ApiPropertyOptional({
    example:
      'تم حذف الإعلان وحظر المستخدم مؤقتاً بسبب تكرار نشر الإعلانات الوهمية',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  actionTaken?: string;

  @ApiPropertyOptional({ enum: ['low', 'medium', 'high', 'critical'] })
  @IsOptional()
  @IsIn(['low', 'medium', 'high', 'critical'])
  priority?: 'low' | 'medium' | 'high' | 'critical';
}
