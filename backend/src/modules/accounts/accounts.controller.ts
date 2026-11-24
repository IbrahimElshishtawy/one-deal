import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
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
import { AccountsService } from './accounts.service';
import { CreateAccountDto } from './dto/create-account.dto';
import { CreateBranchDto } from './dto/create-branch.dto';
import { InviteMemberDto } from './dto/invite-member.dto';
import { UpdateBranchDto } from './dto/update-branch.dto';
import { UpsertServiceAreaDto } from './dto/upsert-service-area.dto';
import { SubmitVerificationDto } from './dto/submit-verification.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';
import { SellerCapability } from '../../core/enums/domain.enums';
import { SellerAuthorizationGuard } from './guards/seller-authorization.guard';
import { RequireSellerCapability } from './decorators/require-seller-capability.decorator';

@ApiTags('Accounts')
@Controller('accounts')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Post()
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register an additional commercial seller account (approved sellers only)' })
  @ApiResponse({ status: 201, description: 'Seller account created' })
  async createAccount(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateAccountDto,
  ) {
    return this.accountsService.createAccount(user.id, dto);
  }

  @Post(':id/branches')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a branch to seller account' })
  @ApiResponse({ status: 201, description: 'Branch added' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async createBranch(
    @Param('id') accountId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateBranchDto,
  ) {
    return this.accountsService.createBranch(accountId, user.id, dto);
  }

  @Get('my-accounts')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'List All Seller Accounts for Current User' })
  @ApiResponse({
    status: 200,
    description: 'List of accessible accounts returned successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getMyAccounts(@CurrentUser() user: AuthenticatedUser) {
    return this.accountsService.getMyAccounts(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get Public Seller Account Details' })
  @ApiResponse({ status: 200, description: 'Seller profile returned' })
  @ApiResponse({ status: 404, description: 'Seller account not found' })
  async getAccountById(@Param('id') id: string) {
    return this.accountsService.getAccountById(id);
  }

  @Get(':id/branches')
  @ApiOperation({ summary: 'Get Branches for Seller Account' })
  @ApiResponse({ status: 200, description: 'Branches returned' })
  async getAccountBranches(@Param('id') id: string) {
    return this.accountsService.getAccountBranches(id);
  }

  @Put(':id/branches/:branchId')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @ApiOperation({ summary: 'Update branch details' })
  @ApiResponse({ status: 200, description: 'Branch updated successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Branch not found' })
  async updateBranch(
    @Param('id') accountId: string,
    @Param('branchId') branchId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateBranchDto,
  ) {
    return this.accountsService.updateBranch(accountId, branchId, user.id, dto);
  }

  @Delete(':id/branches/:branchId')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @ApiOperation({ summary: 'Delete a branch from seller account' })
  @ApiResponse({ status: 200, description: 'Branch deleted successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Branch not found' })
  async deleteBranch(
    @Param('id') accountId: string,
    @Param('branchId') branchId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.accountsService.deleteBranch(accountId, branchId, user.id);
  }

  @Get(':id/members')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @ApiOperation({ summary: 'List all team members of seller account' })
  @ApiResponse({ status: 200, description: 'Members returned successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async getAccountMembers(
    @Param('id') accountId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.accountsService.getAccountMembers(accountId, user.id);
  }

  @Post(':id/members/invite')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Invite/add team member to seller account' })
  @ApiResponse({ status: 201, description: 'Member invited successfully' })
  @ApiResponse({ status: 400, description: 'User already a member' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async inviteMember(
    @Param('id') accountId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: InviteMemberDto,
  ) {
    return this.accountsService.inviteMember(accountId, user.id, dto);
  }

  @Delete(':id/members/:userId')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @ApiOperation({ summary: 'Remove team member from seller account' })
  @ApiResponse({ status: 200, description: 'Member removed successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Member not found' })
  async removeMember(
    @Param('id') accountId: string,
    @Param('userId') targetUserId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.accountsService.removeMember(accountId, user.id, targetUserId);
  }

  @Get(':id/service-areas')
  @ApiOperation({ summary: 'List geographic service areas covered by account' })
  @ApiResponse({ status: 200, description: 'Service areas returned' })
  async getServiceAreas(@Param('id', ParseUUIDPipe) accountId: string) {
    return this.accountsService.getServiceAreas(accountId);
  }

  @Post(':id/service-areas')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Add or update a service area for seller account' })
  @ApiResponse({ status: 200, description: 'Service area saved' })
  async upsertServiceArea(
    @Param('id', ParseUUIDPipe) accountId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpsertServiceAreaDto,
  ) {
    return this.accountsService.upsertServiceArea(accountId, user.id, dto);
  }

  @Delete(':id/service-areas/:serviceAreaId')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @ApiOperation({ summary: 'Remove a service area from seller account' })
  @ApiResponse({ status: 200, description: 'Service area removed' })
  async removeServiceArea(
    @Param('id', ParseUUIDPipe) accountId: string,
    @Param('serviceAreaId', ParseUUIDPipe) serviceAreaId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.accountsService.removeServiceArea(
      accountId,
      serviceAreaId,
      user.id,
    );
  }

  @Get(':id/verifications')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'List verification submissions for seller account' })
  @ApiResponse({ status: 200, description: 'Verification requests returned' })
  async getAccountVerifications(
    @Param('id', ParseUUIDPipe) accountId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.accountsService.getAccountVerifications(accountId, user.id);
  }

  @Post(':id/verifications')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Submit verification document for seller account' })
  @ApiResponse({ status: 201, description: 'Verification submitted' })
  async submitVerification(
    @Param('id', ParseUUIDPipe) accountId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SubmitVerificationDto,
  ) {
    return this.accountsService.submitVerification(accountId, user.id, dto);
  }
}
