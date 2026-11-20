import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { FastifyRequest } from 'fastify';
import { ModerationService } from './moderation.service';
import { CreateReportDto } from './dto/create-report.dto';
import { AdjudicateReportDto } from './dto/adjudicate-report.dto';
import { AdjudicateListingDto } from './dto/adjudicate-listing.dto';
import { AdjudicateVerificationDto } from './dto/adjudicate-verification.dto';
import {
  AddReportNoteDto,
  AssignReportDto,
  AssignVerificationDto,
  AuditLogQueryDto,
  ModerationQueueQueryDto,
  VerificationQueueQueryDto,
} from './dto/moderation-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../auth/decorators/current-user.decorator';
import { AdminJwtAuthGuard } from '../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../admin-auth/guards/permissions.guard';
import {
  AnyPermissions,
  CurrentStaff,
  Permissions,
} from '../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../admin-auth/types/authenticated-staff.type';

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
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('listings.read')
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
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @AnyPermissions('listings.approve', 'listings.reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Approve, reject, or request changes on pending listing with audit logging',
  })
  @ApiResponse({ status: 200, description: 'Moderation decision recorded' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  async adjudicateListing(
    @Param('id', ParseUUIDPipe) listingId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdjudicateListingDto,
    @Req() req: FastifyRequest,
  ) {
    const required =
      dto.action === 'approve' ? 'listings.approve' : 'listings.reject';
    if (!staff.permissions.includes(required)) {
      throw new ForbiddenException(
        `Access denied. Missing required permission: [${required}]`,
      );
    }
    return this.moderationService.adjudicateListing(
      listingId,
      staff.id,
      dto,
      req.ip,
      (req.headers['user-agent'] as string) || '',
      staff.staffId,
    );
  }

  @Get('admin/moderation/queue')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('reports.read')
  @ApiOperation({ summary: 'Get moderation reports queue with filtering' })
  @ApiResponse({ status: 200, description: 'Moderation items returned' })
  async getQueue(@Query() query: ModerationQueueQueryDto) {
    const pagination = this.normalizePagination(query.page, query.limit, 20);
    return this.moderationService.getModerationQueue(
      pagination.page,
      pagination.limit,
      query,
    );
  }

  @Get('admin/moderation/reports/:id')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('reports.read')
  @ApiOperation({ summary: 'Get single report details and moderation history' })
  async getReportDetail(@Param('id', ParseUUIDPipe) reportId: string) {
    return this.moderationService.getReportDetail(reportId);
  }

  @Post('admin/moderation/reports/:id/assign')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('reports.assign')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Assign report to a staff reviewer and/or set priority' })
  async assignReport(
    @Param('id', ParseUUIDPipe) reportId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AssignReportDto,
  ) {
    return this.moderationService.assignReport(
      reportId,
      staff.id,
      dto,
      staff.staffId,
    );
  }

  @Post('admin/moderation/reports/:id/notes')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('reports.resolve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Add an internal moderation note to a report' })
  async addReportNote(
    @Param('id', ParseUUIDPipe) reportId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AddReportNoteDto,
  ) {
    return this.moderationService.addReportNote(
      reportId,
      staff.id,
      staff.fullName,
      dto.note,
    );
  }

  @Patch('admin/moderation/reports/:id')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('reports.resolve')
  @ApiOperation({ summary: 'Adjudicate abuse report and record audit trail' })
  @ApiResponse({ status: 200, description: 'Report adjudicated' })
  async adjudicate(
    @Param('id', ParseUUIDPipe) reportId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdjudicateReportDto,
    @Req() req: FastifyRequest,
  ) {
    return this.moderationService.adjudicateReport(
      reportId,
      staff.id,
      dto,
      req.ip,
      req.headers['user-agent'] as string | undefined,
      staff.staffId,
    );
  }

  @Get('admin/moderation/logs')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('reports.read')
  @ApiOperation({ summary: 'List moderation decision logs across entities' })
  async getModerationLogs(
    @Query('page') page = 1,
    @Query('limit') limit = 30,
    @Query('targetType') targetType?: string,
  ) {
    const pagination = this.normalizePagination(page, limit, 30);
    return this.moderationService.getModerationLogs(
      pagination.page,
      pagination.limit,
      targetType,
    );
  }

  @Get('admin/audit-logs')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('audit_logs.read')
  @ApiOperation({ summary: 'Retrieve immutable platform audit logs with filtering' })
  @ApiResponse({ status: 200, description: 'Audit logs returned' })
  async getAuditLogs(@Query() query: AuditLogQueryDto) {
    const pagination = this.normalizePagination(query.page, query.limit, 50);
    return this.moderationService.getAuditLogs(
      pagination.page,
      pagination.limit,
      query,
    );
  }

  @Get('admin/audit-logs/export')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('audit_logs.export')
  @ApiOperation({ summary: 'Export audit logs (CSV/JSON) with mandatory audit record' })
  async exportAuditLogs(
    @Query() query: AuditLogQueryDto,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Req() req: FastifyRequest,
  ) {
    return this.moderationService.exportAuditLogs(staff.id, query, req.ip);
  }

  @Get('admin/audit-logs/:id')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('audit_logs.read')
  @ApiOperation({ summary: 'Get detailed audit log entry including diffPayload' })
  async getAuditLogById(@Param('id', ParseUUIDPipe) id: string) {
    return this.moderationService.getAuditLogById(id);
  }

  @Get('admin/moderation/verifications')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('verification.read')
  @ApiOperation({ summary: 'List seller account verifications with filtering' })
  @ApiResponse({ status: 200, description: 'Verifications returned' })
  async getPendingVerifications(
    @Query() query: VerificationQueueQueryDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    const pagination = this.normalizePagination(query.page, query.limit, 20);
    const canReadDocs = staff.permissions.includes(
      'verification.documents.read',
    );
    return this.moderationService.getPendingVerifications(
      pagination.page,
      pagination.limit,
      query,
      canReadDocs,
    );
  }

  @Get('admin/moderation/verifications/:id')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('verification.read')
  @ApiOperation({ summary: 'Get verification request details and history' })
  async getVerificationDetail(
    @Param('id', ParseUUIDPipe) verificationId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    const canReadDocs = staff.permissions.includes(
      'verification.documents.read',
    );
    return this.moderationService.getVerificationDetail(
      verificationId,
      canReadDocs,
    );
  }

  @Get('admin/moderation/verifications/:id/document')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('verification.documents.read')
  @ApiOperation({
    summary: 'Audited access to sensitive verification document URL & number',
  })
  async getVerificationDocument(
    @Param('id', ParseUUIDPipe) verificationId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Req() req: FastifyRequest,
  ) {
    return this.moderationService.getVerificationDocument(
      verificationId,
      staff.id,
      req.ip,
      req.headers['user-agent'] as string | undefined,
    );
  }

  @Post('admin/moderation/verifications/:id/assign')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @Permissions('verification.approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Assign a reviewer to a verification request' })
  async assignVerification(
    @Param('id', ParseUUIDPipe) verificationId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AssignVerificationDto,
  ) {
    return this.moderationService.assignVerification(
      verificationId,
      staff.id,
      dto.staffId,
    );
  }

  @Post('admin/moderation/verifications/:id/decision')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard, PermissionsGuard)
  @AnyPermissions('verification.approve', 'verification.reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Approve, reject, or request resubmission for account verification',
  })
  @ApiResponse({ status: 200, description: 'Verification decision recorded' })
  async adjudicateVerification(
    @Param('id', ParseUUIDPipe) verificationId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdjudicateVerificationDto,
    @Req() req: FastifyRequest,
  ) {
    const required =
      dto.action === 'approve'
        ? 'verification.approve'
        : 'verification.reject';
    if (!staff.permissions.includes(required)) {
      throw new ForbiddenException(
        `Access denied. Missing required permission: [${required}]`,
      );
    }
    return this.moderationService.adjudicateVerification(
      verificationId,
      staff.id,
      dto,
      req.ip,
      req.headers['user-agent'] as string | undefined,
      staff.staffId,
    );
  }
}
