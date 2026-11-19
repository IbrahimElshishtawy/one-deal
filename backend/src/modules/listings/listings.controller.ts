import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Param,
  Query,
  Body,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FastifyRequest } from 'fastify';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { ListingsService } from './listings.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { UpdateAvailabilityDto } from './dto/update-availability.dto';
import { FilterListingsDto } from './dto/filter-listings.dto';
import { BatchPriceRefreshDto } from './dto/batch-price-refresh.dto';
import { UpdateListingStatusDto } from './dto/update-listing-status.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('Listings')
@Controller('listings')
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  @Get()
  @ApiOperation({
    summary: 'Public listings feed with multi-filtering and cursor pagination',
  })
  @ApiResponse({ status: 200, description: 'Feed items returned' })
  async getFeed(@Query() filters: FilterListingsDto) {
    return this.listingsService.getListingsFeed(filters);
  }

  @Post('prices/batch')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Batch refresh live authoritative prices and availability for up to 50 listings',
  })
  @ApiResponse({ status: 200, description: 'Batch price snapshot returned' })
  async getBatchPrices(@Body() dto: BatchPriceRefreshDto) {
    return this.listingsService.getBatchPrices(dto.ids);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get detailed listing by ID' })
  @ApiResponse({ status: 200, description: 'Listing details returned' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  async getById(@Param('id') id: string) {
    return this.listingsService.getListingById(id);
  }

  @Post()
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Publish a new listing' })
  @ApiResponse({ status: 201, description: 'Listing created successfully' })
  @ApiResponse({ status: 400, description: 'Validation failed' })
  async createListing(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateListingDto,
  ) {
    return this.listingsService.createListing(user.id, dto);
  }

  @Put(':id')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update existing listing details' })
  @ApiResponse({ status: 200, description: 'Listing updated successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden (Not the owner)' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  async updateListing(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateListingDto,
  ) {
    return this.listingsService.updateListing(id, user.id, dto, user.role);
  }

  @Delete(':id')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Soft-delete a listing (archived state)' })
  @ApiResponse({ status: 200, description: 'Listing deleted successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden (Not the owner)' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  async deleteListing(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.listingsService.deleteListing(id, user.id, user.role);
  }

  @Patch(':id/availability')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update listing operational availability status' })
  @ApiResponse({ status: 200, description: 'Availability updated' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async updateAvailability(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateAvailabilityDto,
  ) {
    return this.listingsService.updateAvailability(
      id,
      user.id,
      dto.availabilityStatus,
      user.role,
    );
  }

  @Post(':id/submit')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Submit a draft listing for moderation review' })
  @ApiResponse({ status: 200, description: 'Listing submitted for review' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async submitForModeration(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.listingsService.submitForModeration(id, user.id);
  }

  @Patch(':id/status')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update listing publication status (HIDDEN, PUBLISHED, ARCHIVED)',
  })
  @ApiResponse({ status: 200, description: 'Publication status updated' })
  @ApiResponse({ status: 403, description: 'Forbidden (Not the owner)' })
  async updateStatus(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateListingStatusDto,
  ) {
    return this.listingsService.updateListingStatus(
      id,
      user.id,
      dto.status,
      user.role,
    );
  }

  @Post(':id/contact')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Record buyer contact action and reveal seller phone number (Enforces Cairo daily quota)',
  })
  @ApiResponse({ status: 200, description: 'Phone number revealed' })
  @ApiResponse({
    status: 403,
    description: 'Daily contact reveal quota exceeded (5/day in Cairo)',
  })
  async contactSeller(
    @Param('id') id: string,
    @Req() req: FastifyRequest,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    const ip = req.ip;
    const ua = (req.headers['user-agent'] as string) || '';
    return this.listingsService.recordContactAction(id, ip, ua, user.id);
  }

  @Post(':id/reveal-contact')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Alias: Record buyer contact action and reveal seller phone number (Enforces Cairo daily quota)',
  })
  @ApiResponse({ status: 200, description: 'Phone number revealed' })
  @ApiResponse({
    status: 403,
    description: 'Daily contact reveal quota exceeded (5/day in Cairo)',
  })
  async revealContactAlias(
    @Param('id') id: string,
    @Req() req: FastifyRequest,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    const ip = req.ip;
    const ua = (req.headers['user-agent'] as string) || '';
    return this.listingsService.recordContactAction(id, ip, ua, user.id);
  }
}
