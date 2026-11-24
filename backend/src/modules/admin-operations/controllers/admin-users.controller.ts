import {
  Body,
  Controller,
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
import { AdminMarketplaceService } from '../services/admin-marketplace.service';
import {
  AddUserNoteDto,
  AdminAccountsQueryDto,
  AdminUsersQueryDto,
  BanUserDto,
  OptionalAdminNotesDto,
  SuspendUserDto,
  UpdateAdminUserDto,
  UpdateSellerAccountStatusDto,
} from '../dto/admin-operations.dto';

@ApiTags('Admin / Users & Accounts')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin')
export class AdminUsersController {
  constructor(private readonly service: AdminMarketplaceService) {}

  @Get('users')
  @Permissions('users.read')
  @ApiOperation({
    summary: 'List marketplace users with search, filters, and pagination',
  })
  listUsers(@Query() query: AdminUsersQueryDto) {
    return this.service.listUsers(query);
  }

  @Get('users/:id')
  @Permissions('users.read')
  @ApiOperation({
    summary:
      'Get detailed marketplace user profile, listings, reports, and history',
  })
  getUserDetail(@Param('id', ParseUUIDPipe) id: string) {
    return this.service.getUserDetail(id);
  }

  @Patch('users/:id')
  @Permissions('users.update')
  @ApiOperation({ summary: 'Update permitted user fields' })
  updateUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAdminUserDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.updateUser(id, dto, staff.id);
  }

  @Post('users/:id/suspend')
  @Permissions('users.suspend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Suspend a marketplace user and revoke active sessions',
  })
  suspendUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SuspendUserDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.suspendUser(id, dto, staff.id, staff.staffId);
  }

  @Post('users/:id/unsuspend')
  @Permissions('users.suspend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Lift user suspension and restore active state' })
  unsuspendUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: OptionalAdminNotesDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.unsuspendUser(id, staff.id, body?.notes, staff.staffId);
  }

  @Post('users/:id/ban')
  @Permissions('users.ban')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Permanently ban user, hide active listings, and revoke sessions',
  })
  banUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: BanUserDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.banUser(id, dto, staff.id, staff.staffId);
  }

  @Post('users/:id/unban')
  @Permissions('users.ban')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unban user and restore active status' })
  unbanUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: OptionalAdminNotesDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.unbanUser(id, staff.id, body?.notes, staff.staffId);
  }

  @Post('users/:id/notes')
  @Permissions('users.update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Add internal administrative note to user account' })
  addUserNote(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddUserNoteDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.addUserNote(id, staff.id, staff.fullName, dto.note);
  }

  @Post('users/:id/revoke-sessions')
  @Permissions('users.suspend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Force-revoke all mobile sessions for a user' })
  revokeUserSessions(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.revokeUserSessions(id, staff.id);
  }

  @Get('accounts')
  @Permissions('users.read')
  @ApiOperation({
    summary: 'List seller accounts with filtering and pagination',
  })
  listAccounts(@Query() query: AdminAccountsQueryDto) {
    return this.service.listAccounts(query);
  }

  @Patch('accounts/:id/status')
  @Permissions('users.update')
  @ApiOperation({ summary: 'Activate or deactivate a seller account' })
  updateAccountStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSellerAccountStatusDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.updateAccountStatus(id, dto, staff.id);
  }
}
