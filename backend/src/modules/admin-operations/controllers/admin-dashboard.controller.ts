import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminJwtAuthGuard } from '../../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../../admin-auth/guards/permissions.guard';
import { Permissions } from '../../admin-auth/decorators/permissions.decorator';
import { AdminDashboardAnalyticsService } from '../services/admin-dashboard-analytics.service';

@ApiTags('Admin / Dashboard')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/dashboard')
export class AdminDashboardController {
  constructor(private readonly service: AdminDashboardAnalyticsService) {}

  @Get('overview')
  @Permissions('analytics.read')
  @ApiOperation({ summary: 'Get real-time platform overview KPIs and health' })
  getOverview() {
    return this.service.getOverview();
  }

  @Get('charts')
  @Permissions('analytics.read')
  @ApiOperation({ summary: 'Get activity time-series and category charts' })
  getCharts(@Query('days') days = 30) {
    return this.service.getCharts(Number(days) || 30);
  }
}
