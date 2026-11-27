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
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../auth/decorators/current-user.decorator';
import { SellerAuthorizationGuard } from '../accounts/guards/seller-authorization.guard';
import { RequireSellerCapability } from '../accounts/decorators/require-seller-capability.decorator';
import { SellerCapability } from '../../core/enums/domain.enums';
import { SellerCenterService } from './seller-center.service';
import {
  CreateSellerDealDto,
  SellerAnalyticsQueryDto,
  SellerConversationsQueryDto,
  SellerDealsQueryDto,
  SellerInteractionsQueryDto,
  SellerListingsQueryDto,
  UpdateSellerDealDto,
} from './dto/seller-center.dto';

@ApiTags('Seller Center')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
@RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
@Controller('seller-center')
export class SellerCenterController {
  constructor(private readonly sellerCenterService: SellerCenterService) {}

  @Get('dashboard')
  @ApiOperation({
    summary: 'Get Seller Center dashboard KPIs and recent activity',
  })
  @ApiResponse({ status: 200, description: 'Dashboard data returned' })
  @ApiResponse({ status: 403, description: 'Approved seller status required' })
  async getDashboard(@CurrentUser() user: AuthenticatedUser) {
    return this.sellerCenterService.getDashboard(user.id);
  }

  @Get('listings')
  @ApiOperation({
    summary: 'List seller advertisements with status, search & pagination',
  })
  async getListings(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SellerListingsQueryDto,
  ) {
    return this.sellerCenterService.getSellerListings(user.id, query);
  }

  @Get('interactions')
  @ApiOperation({
    summary: 'List seller interactions (views, favorites, inquiries, bookings)',
  })
  async getInteractions(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SellerInteractionsQueryDto,
  ) {
    return this.sellerCenterService.getInteractions(user.id, query);
  }

  @Get('conversations')
  @ApiOperation({
    summary: 'List seller inbox conversations with unread & listing filters',
  })
  async getConversations(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SellerConversationsQueryDto,
  ) {
    return this.sellerCenterService.getSellerConversations(user.id, query);
  }

  @Get('deals')
  @ApiOperation({ summary: 'List seller-managed CRM sales records' })
  async getDeals(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SellerDealsQueryDto,
  ) {
    return this.sellerCenterService.getDeals(user.id, query);
  }

  @Post('deals')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a seller-managed CRM sales record' })
  async createDeal(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSellerDealDto,
  ) {
    return this.sellerCenterService.createDeal(user.id, dto);
  }

  @Patch('deals/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update a seller-managed CRM sales record status or notes',
  })
  async updateDeal(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSellerDealDto,
  ) {
    return this.sellerCenterService.updateDeal(user.id, id, dto);
  }

  @Delete('deals/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete a seller-managed CRM sales record' })
  async deleteDeal(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.sellerCenterService.deleteDeal(user.id, id);
  }

  @Get('analytics')
  @ApiOperation({
    summary: 'Get real seller performance analytics by date range',
  })
  async getAnalytics(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SellerAnalyticsQueryDto,
  ) {
    return this.sellerCenterService.getAnalytics(user.id, query);
  }
}
