import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  Req,
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
import { FastifyRequest } from 'fastify';
import { UserRole } from '../../core/enums/domain.enums';
import { ModerationService } from './moderation.service';
import { CreateReportDto } from './dto/create-report.dto';
import { AdjudicateReportDto } from './dto/adjudicate-report.dto';
import { AdjudicateListingDto } from './dto/adjudicate-listing.dto';
import { AdjudicateVerificationDto } from './dto/adjudicate-verification.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('Trust & Safety / Moderation')
@Controller()
export class ModerationController {
  constructor(private readonly moderationService: ModerationService) {}

  private normalizePagination(
    page: number | string | undefined,
    limit: number | string | undefined,
    defaultLimit = 20,
  ) {
    const parsedPage = Math.max(Number(page) || 1, 1);
    const parsedLimit = Math.min(
      Math.max(Number(limit) || defaultLimit, 1),
      100,
    );
    return { page: parsedPage, limit: parsedLimit };
  }

  @Post('reports')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Submit an abuse report against a listing or user' })
  @ApiResponse({ status: 201, description: 'Report filed successfully' })
  async fileReport(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateReportDto,
  ) {
    return this.moderationService.fileReport(user.id, dto);
  }

  @Get('admin/moderation/listings')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.SUPER_ADMIN)
  @ApiOperation({
    summary: 'Get pending listings awaiting human moderation review',
  })
  @ApiResponse({ status: 200, description: 'Pending listings returned' })
  async getPendingListings(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    const pagination = this.normalizePagination(page, limit, 20);
    return this.moderationService.getPendingListings(
      pagination.page,
      pagination.limit,
    );
  }

  @Post('admin/moderation/listings/:id/decision')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.SUPER_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Approve or reject pending listing with audit logging',
  })
  @ApiResponse({ status: 200, description: 'Moderation decision recorded' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  async adjudicateListing(
    @Param('id') listingId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: AdjudicateListingDto,
    @Req() req: FastifyRequest,
  ) {
    const ip = req.ip;
    const ua = (req.headers['user-agent'] as string) || '';
    return this.moderationService.adjudicateListing(
      listingId,
      user.id,
      dto,
      ip,
      ua,
    );
  }

  @Get('admin/moderation/queue')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Get pending moderation queue' })
  @ApiResponse({ status: 200, description: 'Moderation items returned' })
  async getQueue(@Query('page') page = 1, @Query('limit') limit = 20) {
    const pagination = this.normalizePagination(page, limit, 20);
    return this.moderationService.getModerationQueue(
      pagination.page,
      pagination.limit,
    );
  }

  @Patch('admin/moderation/reports/:id')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Adjudicate abuse report and record audit trail' })
  @ApiResponse({ status: 200, description: 'Report resolved' })
  async adjudicate(
    @Param('id') reportId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: AdjudicateReportDto,
    @Req() req: FastifyRequest,
  ) {
    const ip = req.ip;
    const ua = req.headers['user-agent'];
    return this.moderationService.adjudicateReport(
      reportId,
      user.id,
      dto,
      ip,
      ua,
    );
  }

  @Get('admin/audit-logs')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Retrieve immutable platform audit logs' })
  @ApiResponse({ status: 200, description: 'Audit logs returned' })
  async getAuditLogs(@Query('page') page = 1, @Query('limit') limit = 50) {
    const pagination = this.normalizePagination(page, limit, 50);
    return this.moderationService.getAuditLogs(
      pagination.page,
      pagination.limit,
    );
  }

  @Get('admin/moderation/verifications')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'List pending seller account verifications' })
  @ApiResponse({ status: 200, description: 'Pending verifications returned' })
  async getPendingVerifications(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    const pagination = this.normalizePagination(page, limit, 20);
    return this.moderationService.getPendingVerifications(
      pagination.page,
      pagination.limit,
    );
  }

  @Post('admin/moderation/verifications/:id/decision')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.SUPER_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Approve or reject seller account verification' })
  @ApiResponse({ status: 200, description: 'Verification decision recorded' })
  async adjudicateVerification(
    @Param('id', ParseUUIDPipe) verificationId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: AdjudicateVerificationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.moderationService.adjudicateVerification(
      verificationId,
      user.id,
      dto,
      req.ip,
      req.headers['user-agent'] as string | undefined,
    );
  }
}
