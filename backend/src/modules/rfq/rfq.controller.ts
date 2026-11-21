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
import { CancelBookingDto } from '../bookings/dto/cancel-booking.dto';
import { CreateQuotationDto } from './dto/create-quotation.dto';
import { CreateRfqDto } from './dto/create-rfq.dto';
import { GetRfqsQueryDto } from './dto/get-rfqs-query.dto';
import { UpdateQuotationStatusDto } from './dto/update-quotation-status.dto';
import { RfqService } from './rfq.service';

@ApiTags('RFQ & Quotations')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard)
@Controller()
export class RfqController {
  constructor(private readonly rfqService: RfqService) {}

  @Post('rfqs')
  @UseGuards(RateLimitGuard)
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
  @ApiOperation({ summary: 'Get RFQ details by ID' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'RFQ details returned' })
  async getRfqById(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.rfqService.getRfqById(id, user.id, user.role);
  }

  @Patch('rfqs/:id/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel an active or draft RFQ' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'RFQ cancelled' })
  async cancelRfq(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CancelBookingDto,
  ) {
    return this.rfqService.cancelRfq(id, user.id, dto.reason);
  }

  @Post('rfqs/:id/quotations')
  @UseGuards(RateLimitGuard)
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
    return this.rfqService.getQuotationsForRfq(id, user.id, sortBy, user.role);
  }

  @Get('quotations/:id')
  @ApiOperation({
    summary: 'Get quotation details (RFQ owner or submitting supplier only)',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Quotation details returned' })
  async getQuotationById(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.rfqService.getQuotationById(id, user.id, user.role);
  }

  @Patch('quotations/:id/status')
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
    return this.rfqService.updateQuotationStatus(id, user.id, dto);
  }
}
