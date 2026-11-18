import {
  Controller,
  Get,
  Patch,
  Post,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { UserRole } from '../../core/enums/domain.enums';
import { StaffService } from './staff.service';
import { CreateStaffRoleDto } from './dto/create-staff-role.dto';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';
import { UpdateStaffUserDto } from './dto/update-staff-user.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('Admin / Staff Management')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN)
@Controller('admin/staff')
export class StaffController {
  constructor(private readonly staffService: StaffService) {}

  @Get('roles')
  @ApiOperation({ summary: 'List all administrative staff roles' })
  @ApiResponse({ status: 200, description: 'Staff roles returned' })
  async listRoles() {
    return this.staffService.listRoles();
  }

  @Post('roles')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new administrative staff role' })
  @ApiResponse({ status: 201, description: 'Staff role created' })
  async createRole(
    @Body() dto: CreateStaffRoleDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.staffService.createRole(dto, user.id);
  }

  @Get()
  @ApiOperation({ summary: 'List all administrative staff users' })
  @ApiResponse({ status: 200, description: 'Staff users returned' })
  async listStaffUsers() {
    return this.staffService.listStaffUsers();
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new administrative staff user' })
  @ApiResponse({ status: 201, description: 'Staff user created' })
  async createStaffUser(
    @Body() dto: CreateStaffUserDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.staffService.createStaffUser(dto, user.id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update staff user active status or role' })
  @ApiResponse({ status: 200, description: 'Staff user updated' })
  async updateStaffUser(
    @Param('id', ParseUUIDPipe) staffId: string,
    @Body() dto: UpdateStaffUserDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.staffService.updateStaffUser(staffId, dto, user.id);
  }
}
