import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { FastifyRequest } from 'fastify';
import { PlatformSettingsService } from './platform-settings.service';
import { UpsertPlatformSettingDto } from './dto/upsert-platform-setting.dto';
import { SettingKeyPipe } from './pipes/setting-key.pipe';
import { AdminJwtAuthGuard } from '../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../admin-auth/guards/permissions.guard';
import {
  CurrentStaff,
  Permissions,
} from '../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../admin-auth/types/authenticated-staff.type';

@ApiTags('Admin / Platform Settings')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/settings')
export class PlatformSettingsController {
  constructor(private readonly settingsService: PlatformSettingsService) {}

  @Get()
  @Permissions('settings.read')
  @ApiOperation({ summary: 'List all platform settings' })
  @ApiResponse({ status: 200, description: 'Platform settings returned' })
  async listSettings() {
    return this.settingsService.listSettings();
  }

  @Get(':key')
  @Permissions('settings.read')
  @ApiOperation({ summary: 'Get a single platform setting by key' })
  @ApiResponse({ status: 200, description: 'Platform setting returned' })
  @ApiResponse({ status: 400, description: 'Invalid setting key format' })
  @ApiResponse({ status: 404, description: 'Setting not found' })
  async getSetting(@Param('key', SettingKeyPipe) key: string) {
    return this.settingsService.getSetting(key);
  }

  @Put(':key')
  @Permissions('settings.update')
  @ApiOperation({ summary: 'Create or update a platform setting' })
  @ApiResponse({ status: 200, description: 'Platform setting saved' })
  @ApiResponse({ status: 400, description: 'Invalid setting key format' })
  async upsertSetting(
    @Param('key', SettingKeyPipe) key: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: UpsertPlatformSettingDto,
    @Req() req: FastifyRequest,
  ) {
    return this.settingsService.upsertSetting(
      key,
      staff.id,
      dto,
      req.ip,
      req.headers['user-agent'] as string | undefined,
      staff.staffId,
    );
  }
}
