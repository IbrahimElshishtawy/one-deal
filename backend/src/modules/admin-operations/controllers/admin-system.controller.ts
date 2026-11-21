import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminJwtAuthGuard } from '../../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../../admin-auth/guards/permissions.guard';
import { Permissions } from '../../admin-auth/decorators/permissions.decorator';
import { AdminDashboardAnalyticsService } from '../services/admin-dashboard-analytics.service';

@ApiTags('Admin / System Health')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/system')
export class AdminSystemController {
  constructor(private readonly service: AdminDashboardAnalyticsService) {}

  @Get('health')
  @Permissions('system_health.read')
  @ApiOperation({
    summary:
      'Read-only system health telemetry (DB, PostGIS, Redis, Storage, Outbox, API metrics)',
  })
  getSystemHealth() {
    return this.service.getSystemHealth();
  }
}
