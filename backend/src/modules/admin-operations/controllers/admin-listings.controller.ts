import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
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
  AnyPermissions,
  CurrentStaff,
  Permissions,
} from '../../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';
import { AdminMarketplaceService } from '../services/admin-marketplace.service';
import {
  AdminListingsQueryDto,
  BulkListingDecisionDto,
  ListingActionReasonDto,
} from '../dto/admin-operations.dto';

@ApiTags('Admin / Listings')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/listings')
export class AdminListingsController {
  constructor(private readonly service: AdminMarketplaceService) {}

  @Get()
  @Permissions('listings.read')
  @ApiOperation({
    summary: 'List all marketplace listings with advanced filtering & sorting',
  })
  listListings(@Query() query: AdminListingsQueryDto) {
    return this.service.listListings(query);
  }

  @Get(':id')
  @Permissions('listings.read')
  @ApiOperation({
    summary: 'Get full listing detail, media, owner, and moderation history',
  })
  getListingDetail(@Param('id', ParseUUIDPipe) id: string) {
    return this.service.getListingDetail(id);
  }

  @Post(':id/approve')
  @Permissions('listings.approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Approve and publish listing' })
  approveListing(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ListingActionReasonDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.transitionListing(
      id,
      'approve',
      staff.id,
      dto,
      staff.staffId,
    );
  }

  @Post(':id/reject')
  @Permissions('listings.reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reject listing with reason' })
  rejectListing(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ListingActionReasonDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.transitionListing(
      id,
      'reject',
      staff.id,
      dto,
      staff.staffId,
    );
  }

  @Post(':id/request-changes')
  @Permissions('listings.reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request modifications from listing owner' })
  requestChanges(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ListingActionReasonDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.transitionListing(
      id,
      'request_changes',
      staff.id,
      dto,
      staff.staffId,
    );
  }

  @Patch(':id/hide')
  @Permissions('listings.hide')
  @ApiOperation({ summary: 'Hide listing from marketplace search' })
  hideListing(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ListingActionReasonDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.transitionListing(
      id,
      'hide',
      staff.id,
      dto,
      staff.staffId,
    );
  }

  @Patch(':id/restore')
  @Permissions('listings.approve')
  @ApiOperation({ summary: 'Restore hidden or deleted listing' })
  restoreListing(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ListingActionReasonDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.transitionListing(
      id,
      'restore',
      staff.id,
      dto,
      staff.staffId,
    );
  }

  @Patch(':id/archive')
  @Permissions('listings.hide')
  @ApiOperation({ summary: 'Archive listing' })
  archiveListing(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ListingActionReasonDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.transitionListing(
      id,
      'archive',
      staff.id,
      dto,
      staff.staffId,
    );
  }

  @Delete(':id')
  @Permissions('listings.delete')
  @ApiOperation({ summary: 'Soft-delete listing' })
  deleteListing(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.transitionListing(
      id,
      'delete',
      staff.id,
      undefined,
      staff.staffId,
    );
  }

  @Post('bulk-decision')
  @AnyPermissions('listings.approve', 'listings.reject', 'listings.hide')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Bulk approve, reject, hide, or archive up to 50 listings',
  })
  bulkDecision(
    @Body() dto: BulkListingDecisionDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    const requiredPerm =
      dto.action === 'approve'
        ? 'listings.approve'
        : dto.action === 'reject'
          ? 'listings.reject'
          : 'listings.hide';
    if (!staff.permissions.includes(requiredPerm)) {
      throw new ForbiddenException(
        `Access denied. Missing required permission: [${requiredPerm}]`,
      );
    }
    return this.service.bulkListingDecision(dto, staff.id, staff.staffId);
  }
}
