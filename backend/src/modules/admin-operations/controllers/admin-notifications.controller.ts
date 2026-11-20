import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminJwtAuthGuard } from '../../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../../admin-auth/guards/permissions.guard';
import {
  CurrentStaff,
  Permissions,
} from '../../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';
import { AdminGrowthPlatformService } from '../services/admin-growth-platform.service';
import {
  AudiencePreviewDto,
  CreateNotificationCampaignDto,
} from '../dto/admin-operations.dto';

@ApiTags('Admin / Notifications')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/notifications')
export class AdminNotificationsController {
  constructor(private readonly service: AdminGrowthPlatformService) {}

  @Get('campaigns')
  @Permissions('notifications.read')
  @ApiOperation({ summary: 'List notification campaigns and delivery statistics' })
  listCampaigns(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('status') status?: string,
  ) {
    return this.service.listCampaigns(page, limit, status);
  }

  @Post('audience-preview')
  @Permissions('notifications.read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Preview recipient count for a target audience segment' })
  previewAudience(@Body() dto: AudiencePreviewDto) {
    return this.service.previewAudience(dto);
  }

  @Post('campaigns')
  @Permissions('notifications.create')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a notification campaign' })
  createCampaign(
    @Body() dto: CreateNotificationCampaignDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.createCampaign(dto, staff.id);
  }

  @Post('campaigns/:id/approve')
  @Permissions('notifications.approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Approve a notification campaign for sending' })
  approveCampaign(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.approveCampaign(id, staff.id);
  }

  @Post('campaigns/:id/send')
  @Permissions('notifications.send')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Dispatch an approved notification campaign' })
  sendCampaign(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.sendCampaign(id, staff.id);
  }

  @Post('campaigns/:id/cancel')
  @Permissions('notifications.create')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel an unsent notification campaign' })
  cancelCampaign(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.cancelCampaign(id, staff.id);
  }
}
