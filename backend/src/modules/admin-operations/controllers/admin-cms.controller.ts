import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
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
import { CreateCmsItemDto, UpdateCmsItemDto } from '../dto/admin-operations.dto';

@ApiTags('Admin / CMS')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/cms')
export class AdminCmsController {
  constructor(private readonly service: AdminGrowthPlatformService) {}

  @Get()
  @Permissions('cms.read')
  @ApiOperation({ summary: 'List all CMS items (banners, pages, FAQs, legal)' })
  listCms(
    @Query('type') type?: string,
    @Query('status') status?: string,
    @Query('q') q?: string,
  ) {
    return this.service.listCmsItems(type, status, q);
  }

  @Get(':id')
  @Permissions('cms.read')
  @ApiOperation({ summary: 'Get CMS item details including revision history' })
  getCmsItem(@Param('id', ParseUUIDPipe) id: string) {
    return this.service.getCmsItem(id);
  }

  @Post()
  @Permissions('cms.manage')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a CMS item' })
  createCms(
    @Body() dto: CreateCmsItemDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.createCmsItem(dto, staff.id);
  }

  @Patch(':id')
  @Permissions('cms.manage')
  @ApiOperation({ summary: 'Update CMS item and append revision snapshot' })
  updateCms(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCmsItemDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.updateCmsItem(id, dto, staff.id);
  }

  @Post(':id/publish')
  @Permissions('cms.manage')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Publish CMS item to mobile and web clients' })
  publishCms(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.changeCmsStatus(id, 'published', staff.id);
  }

  @Post(':id/unpublish')
  @Permissions('cms.manage')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unpublish CMS item back to draft' })
  unpublishCms(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.changeCmsStatus(id, 'draft', staff.id);
  }

  @Post(':id/archive')
  @Permissions('cms.manage')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Archive CMS item' })
  archiveCms(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.changeCmsStatus(id, 'archived', staff.id);
  }

  @Delete(':id')
  @Permissions('cms.manage')
  @ApiOperation({ summary: 'Delete CMS item' })
  deleteCms(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.deleteCmsItem(id, staff.id);
  }
}

@ApiTags('CMS (Public)')
@Controller('cms/public')
export class CmsPublicController {
  constructor(private readonly service: AdminGrowthPlatformService) {}

  @Get()
  @ApiOperation({ summary: 'Get active published CMS content for Flutter app' })
  listPublicCms(@Query('type') type?: string) {
    return this.service.getPublicCmsItems(type);
  }

  @Get(':slug')
  @ApiOperation({ summary: 'Get single published CMS document by slug' })
  getPublicCmsBySlug(@Param('slug') slug: string) {
    return this.service.getPublicCmsBySlug(slug);
  }
}
