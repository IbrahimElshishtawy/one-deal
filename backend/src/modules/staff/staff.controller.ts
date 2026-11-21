import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { StaffService } from './staff.service';
import { CreateStaffRoleDto } from './dto/create-staff-role.dto';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';
import { UpdateStaffUserDto } from './dto/update-staff-user.dto';
import {
  CloneStaffRoleDto,
  InviteStaffUserDto,
  StaffListQueryDto,
  UpdateStaffRoleDto,
} from './dto/staff-admin.dto';
import { AdminJwtAuthGuard } from '../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../admin-auth/guards/permissions.guard';
import {
  CurrentStaff,
  Permissions,
} from '../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../admin-auth/types/authenticated-staff.type';

@ApiTags('Admin / Staff Management')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/staff')
export class StaffController {
  constructor(private readonly staffService: StaffService) {}

  @Get('permissions')
  @Permissions('roles.read')
  @ApiOperation({
    summary: 'List authoritative granular admin permissions catalog',
  })
  getPermissionCatalog() {
    return this.staffService.getPermissionCatalog();
  }

  @Get('roles')
  @Permissions('roles.read')
  @ApiOperation({ summary: 'List all administrative staff roles' })
  @ApiResponse({ status: 200, description: 'Staff roles returned' })
  async listRoles() {
    return this.staffService.listRoles();
  }

  @Post('roles')
  @Permissions('roles.create')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new administrative staff role' })
  @ApiResponse({ status: 201, description: 'Staff role created' })
  async createRole(
    @Body() dto: CreateStaffRoleDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.createRole(dto, staff.id, {
      role: staff.role,
      permissions: staff.permissions,
    });
  }

  @Patch('roles/:roleId')
  @Permissions('roles.update')
  @ApiOperation({
    summary: 'Update a staff role name, description, or permissions',
  })
  async updateRole(
    @Param('roleId', ParseIntPipe) roleId: number,
    @Body() dto: UpdateStaffRoleDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.updateRole(roleId, dto, staff.id, {
      role: staff.role,
      permissions: staff.permissions,
    });
  }

  @Post('roles/:roleId/clone')
  @Permissions('roles.create')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Clone an existing role with its permissions' })
  async cloneRole(
    @Param('roleId', ParseIntPipe) roleId: number,
    @Body() dto: CloneStaffRoleDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.cloneRole(roleId, dto, staff.id, {
      role: staff.role,
      permissions: staff.permissions,
    });
  }

  @Delete('roles/:roleId')
  @Permissions('roles.delete')
  @ApiOperation({
    summary: 'Delete a custom non-system role with zero assignees',
  })
  async deleteRole(
    @Param('roleId', ParseIntPipe) roleId: number,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.deleteRole(roleId, staff.id);
  }

  @Get()
  @Permissions('admins.read')
  @ApiOperation({
    summary: 'List administrative staff users with filtering & pagination',
  })
  @ApiResponse({ status: 200, description: 'Staff users returned' })
  async listStaffUsers(@Query() query: StaffListQueryDto) {
    return this.staffService.listStaffUsers(query);
  }

  @Get(':id')
  @Permissions('admins.read')
  @ApiOperation({
    summary:
      'Get staff user profile, active sessions, and recent audit activity',
  })
  async getStaffUserDetail(@Param('id', ParseUUIDPipe) staffId: string) {
    return this.staffService.getStaffUserDetail(staffId);
  }

  @Post()
  @Permissions('admins.create')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new administrative staff user' })
  @ApiResponse({ status: 201, description: 'Staff user created' })
  async createStaffUser(
    @Body() dto: CreateStaffUserDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.createStaffUser(dto, staff.id, {
      role: staff.role,
      permissions: staff.permissions,
    });
  }

  @Post('invitations')
  @Permissions('admins.create')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Invite a new administrative staff user' })
  async inviteStaffUser(
    @Body() dto: InviteStaffUserDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.inviteStaffUser(dto, staff.id, {
      role: staff.role,
      permissions: staff.permissions,
    });
  }

  @Patch(':id')
  @Permissions('admins.update')
  @ApiOperation({
    summary: 'Update staff user status, role, or profile metadata',
  })
  @ApiResponse({ status: 200, description: 'Staff user updated' })
  async updateStaffUser(
    @Param('id', ParseUUIDPipe) staffId: string,
    @Body() dto: UpdateStaffUserDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.updateStaffUser(staffId, dto, staff.id, {
      role: staff.role,
      permissions: staff.permissions,
    });
  }

  @Post(':id/revoke-sessions')
  @Permissions('admins.update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Force-revoke all active sessions of target admin' })
  async revokeSessions(
    @Param('id', ParseUUIDPipe) staffId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.revokeStaffSessions(staffId, staff.id);
  }

  @Post(':id/reset-mfa')
  @Permissions('admins.update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset MFA configuration for a locked-out admin' })
  async resetMfa(
    @Param('id', ParseUUIDPipe) staffId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.staffService.resetStaffMfa(staffId, staff.id);
  }
}
