import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminJwtAuthGuard } from '../../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../../admin-auth/guards/permissions.guard';
import {
  CurrentStaff,
  Permissions,
} from '../../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';
import { AdminDashboardAnalyticsService } from '../services/admin-dashboard-analytics.service';
import { AnalyticsQueryDto } from '../dto/admin-operations.dto';

@ApiTags('Admin / Analytics')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/analytics')
export class AdminAnalyticsController {
  constructor(private readonly service: AdminDashboardAnalyticsService) {}

  @Get('summary')
  @Permissions('analytics.read')
  @ApiOperation({
    summary: 'Get real aggregated V1 analytics across users, listings, moderation, verification, notifications, and categories',
  })
  getSummary(@Query() query: AnalyticsQueryDto) {
    return this.service.getAnalyticsSummary(query);
  }

  @Get('export')
  @Permissions('analytics.export')
  @ApiOperation({ summary: 'Export aggregated analytics with audit trail' })
  exportAnalytics(
    @Query() query: AnalyticsQueryDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.exportAnalytics(staff.id, query);
  }
}
