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
import { UserRole } from '../../core/enums/domain.enums';
import { PlatformSettingsService } from './platform-settings.service';
import { UpsertPlatformSettingDto } from './dto/upsert-platform-setting.dto';
import { SettingKeyPipe } from './pipes/setting-key.pipe';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('Admin / Platform Settings')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN)
@Controller('admin/settings')
export class PlatformSettingsController {
  constructor(private readonly settingsService: PlatformSettingsService) {}

  @Get()
  @ApiOperation({ summary: 'List all platform settings' })
  @ApiResponse({ status: 200, description: 'Platform settings returned' })
  async listSettings() {
    return this.settingsService.listSettings();
  }

  @Get(':key')
  @ApiOperation({ summary: 'Get a single platform setting by key' })
  @ApiResponse({ status: 200, description: 'Platform setting returned' })
  @ApiResponse({ status: 400, description: 'Invalid setting key format' })
  @ApiResponse({ status: 404, description: 'Setting not found' })
  async getSetting(@Param('key', SettingKeyPipe) key: string) {
    return this.settingsService.getSetting(key);
  }

  @Put(':key')
  @ApiOperation({ summary: 'Create or update a platform setting' })
  @ApiResponse({ status: 200, description: 'Platform setting saved' })
  @ApiResponse({ status: 400, description: 'Invalid setting key format' })
  async upsertSetting(
    @Param('key', SettingKeyPipe) key: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpsertPlatformSettingDto,
    @Req() req: FastifyRequest,
  ) {
    return this.settingsService.upsertSetting(
      key,
      user.id,
      dto,
      req.ip,
      req.headers['user-agent'] as string | undefined,
    );
  }
}
