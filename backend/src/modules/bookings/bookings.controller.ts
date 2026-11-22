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
import { BookingsService } from './bookings.service';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { GetBookingsQueryDto } from './dto/get-bookings-query.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';

@ApiTags('Bookings & Appointments')
@ApiBearerAuth('BearerAuth')
@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RateLimitGuard)
  @RateLimit(15, 60)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a booking or appointment request',
    description:
      'Supports Real Estate viewings/inspections, Cars & Maintenance appointments, and Services & Engineering bookings.',
  })
  @ApiResponse({ status: 201, description: 'Booking created in PENDING state' })
  @ApiResponse({
    status: 400,
    description: 'Invalid date or listing ineligible',
  })
  @ApiResponse({ status: 409, description: 'Time slot conflict' })
  async createBooking(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateBookingDto,
  ) {
    return this.bookingsService.createBooking(user.id, dto);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'List paginated bookings for the authenticated user',
    description:
      'Filter by role (requester | provider), status, bookingType, categoryId, or categorySlug.',
  })
  @ApiResponse({ status: 200, description: 'Paginated bookings returned' })
  async getBookings(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: GetBookingsQueryDto,
  ) {
    return this.bookingsService.getBookings(user.id, query);
  }

  @Get(':id')
  @UseGuards(AdminJwtAuthGuard)
  @ApiOperation({ summary: 'Get booking details by ID' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Booking details returned' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async getBookingById(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.bookingsService.getBookingById(
      id,
      user.id,
      user.role,
      user.actorType,
    );
  }

  @Patch(':id/cancel')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel a PENDING or CONFIRMED booking' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Booking cancelled' })
  @ApiResponse({ status: 400, description: 'Invalid status transition' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async cancelBooking(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CancelBookingDto,
  ) {
    return this.bookingsService.cancelBooking(
      id,
      user.id,
      dto,
      user.role,
      user.actorType,
    );
  }

  @Patch(':id/status')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update booking status (provider or admin only)',
    description:
      'Enforces valid transitions: PENDING -> CONFIRMED | REJECTED, CONFIRMED -> COMPLETED.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Booking status updated' })
  @ApiResponse({ status: 400, description: 'Invalid status transition' })
  @ApiResponse({ status: 403, description: 'Provider authorization required' })
  @ApiResponse({ status: 409, description: 'Slot conflict on confirmation' })
  async updateBookingStatus(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateBookingStatusDto,
  ) {
    return this.bookingsService.updateBookingStatus(
      id,
      user.id,
      dto,
      user.role,
      user.actorType,
    );
  }
}
