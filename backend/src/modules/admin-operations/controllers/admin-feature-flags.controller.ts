import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
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
  CreateFeatureFlagDto,
  UpdateFeatureFlagDto,
} from '../dto/admin-operations.dto';

@ApiTags('Admin / Feature Flags')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/feature-flags')
export class AdminFeatureFlagsController {
  constructor(private readonly service: AdminGrowthPlatformService) {}

  @Get()
  @Permissions('feature_flags.read')
  @ApiOperation({ summary: 'List all feature flags and change history' })
  listFlags() {
    return this.service.listFeatureFlags();
  }

  @Post()
  @Permissions('feature_flags.manage')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a feature flag' })
  createFlag(
    @Body() dto: CreateFeatureFlagDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.createFeatureFlag(dto, staff.id);
  }

  @Patch(':key')
  @Permissions('feature_flags.manage')
  @ApiOperation({ summary: 'Update or toggle feature flag' })
  updateFlag(
    @Param('key') key: string,
    @Body() dto: UpdateFeatureFlagDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.updateFeatureFlag(key, dto, staff.id);
  }

  @Delete(':key')
  @Permissions('feature_flags.manage')
  @ApiOperation({ summary: 'Delete non-system feature flag' })
  deleteFlag(
    @Param('key') key: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.deleteFeatureFlag(key, staff.id);
  }
}
