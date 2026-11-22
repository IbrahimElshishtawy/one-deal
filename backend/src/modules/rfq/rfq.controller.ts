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
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { RateLimit, RateLimitGuard } from '../../core/guards/rate-limit.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminJwtAuthGuard } from '../admin-auth/guards/admin-jwt-auth.guard';
import { CancelBookingDto } from '../bookings/dto/cancel-booking.dto';
import { CreateQuotationDto } from './dto/create-quotation.dto';
import { CreateRfqDto } from './dto/create-rfq.dto';
import { UpdateRfqDto } from './dto/update-rfq.dto';
import { GetRfqsQueryDto } from './dto/get-rfqs-query.dto';
import { UpdateQuotationStatusDto } from './dto/update-quotation-status.dto';
import { RfqService } from './rfq.service';

@ApiTags('RFQ & Quotations')
@ApiBearerAuth('BearerAuth')
@Controller()
export class RfqController {
  constructor(private readonly rfqService: RfqService) {}

  @Post('rfqs')
  @UseGuards(JwtAuthGuard, RateLimitGuard)
  @RateLimit(10, 60)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a Request for Quotation (RFQ)',
    description:
      'Used for building materials, electrical supplies, and construction requirements.',
  })
  @ApiResponse({ status: 201, description: 'RFQ created' })
  async createRfq(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateRfqDto,
  ) {
    return this.rfqService.createRfq(user.id, dto);
  }

  @Get('rfqs')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'List paginated RFQs (user own RFQs or open RFQs for suppliers)',
  })
  @ApiResponse({ status: 200, description: 'Paginated RFQs returned' })
  async getRfqs(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: GetRfqsQueryDto,
  ) {
    return this.rfqService.getRfqs(user.id, query);
  }

  @Get('rfqs/:id')
  @UseGuards(AdminJwtAuthGuard)
  @ApiOperation({ summary: 'Get RFQ details by ID' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'RFQ details returned' })
  async getRfqById(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.rfqService.getRfqById(id, user.id, user.role, user.actorType);
  }

  @Patch('rfqs/:id')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Edit a DRAFT RFQ owned by the authenticated user' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Draft RFQ updated' })
  @ApiResponse({ status: 400, description: 'Only DRAFT RFQs can be edited' })
  async updateDraftRfq(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateRfqDto,
  ) {
    return this.rfqService.updateDraftRfq(id, user.id, dto);
  }

  @Patch('rfqs/:id/submit')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Submit a DRAFT RFQ so suppliers can view and quote on it',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Draft RFQ submitted' })
  @ApiResponse({ status: 400, description: 'Invalid RFQ status transition' })
  async submitDraftRfq(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.rfqService.submitDraftRfq(id, user.id);
  }

  @Patch('rfqs/:id/cancel')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel an active or draft RFQ' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'RFQ cancelled' })
  async cancelRfq(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CancelBookingDto,
  ) {
    return this.rfqService.cancelRfq(
      id,
      user.id,
      dto.reason,
      user.role,
      user.actorType,
    );
  }

  @Post('rfqs/:id/quotations')
  @UseGuards(JwtAuthGuard, RateLimitGuard)
  @RateLimit(15, 60)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Submit a supplier quotation for an open RFQ',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 201, description: 'Quotation submitted' })
  async submitQuotation(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateQuotationDto,
  ) {
    return this.rfqService.submitQuotation(id, user.id, dto);
  }

  @Get('rfqs/:id/quotations')
  @UseGuards(AdminJwtAuthGuard)
  @ApiOperation({
    summary: 'List and compare quotations for an RFQ (RFQ owner only)',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiQuery({
    name: 'sortBy',
    required: false,
    enum: ['totalAmount', 'estimatedDeliveryDays', 'createdAt'],
  })
  @ApiResponse({ status: 200, description: 'Quotations returned' })
  async getQuotationsForRfq(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Query('sortBy')
    sortBy?: 'totalAmount' | 'estimatedDeliveryDays' | 'createdAt',
  ) {
    return this.rfqService.getQuotationsForRfq(
      id,
      user.id,
      sortBy,
      user.role,
      user.actorType,
    );
  }

  @Get('quotations/:id')
  @UseGuards(AdminJwtAuthGuard)
  @ApiOperation({
    summary: 'Get quotation details (RFQ owner or submitting supplier only)',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Quotation details returned' })
  async getQuotationById(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.rfqService.getQuotationById(
      id,
      user.id,
      user.role,
      user.actorType,
    );
  }

  @Patch('quotations/:id/status')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Update quotation status (shortlist/accept/reject by RFQ owner, or withdraw by supplier). Accepting does not create a paid order in V1.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Quotation status updated' })
  async updateQuotationStatus(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateQuotationStatusDto,
  ) {
    return this.rfqService.updateQuotationStatus(
      id,
      user.id,
      dto,
      user.role,
      user.actorType,
    );
  }
}
