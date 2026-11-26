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
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { FastifyRequest } from 'fastify';
import { AdminJwtAuthGuard } from '../../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../../admin-auth/guards/permissions.guard';
import {
  AnyPermissions,
  CurrentStaff,
  Permissions,
} from '../../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';
import {
  RequestAuditContext,
  SellerApplicationService,
} from '../services/seller-application.service';
import { SellerVerificationRequirementsService } from '../services/seller-verification-requirements.service';
import {
  AdminApproveSellerApplicationDto,
  AdminCreateRequirementDto,
  AdminExpireSellerDto,
  AdminListRequirementsQueryDto,
  AdminRejectSellerApplicationDto,
  AdminRequestCorrectionDto,
  AdminReviewDocumentDto,
  AdminReviewSellerApplicationDto,
  AdminSellerApplicationsQueryDto,
  AdminSuspendSellerDto,
  AdminUpdateRequirementDto,
} from '../dto/seller-application.dto';

@ApiTags('Admin / Seller Verification')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/seller-applications')
export class AdminSellerApplicationsController {
  constructor(
    private readonly sellerApplicationService: SellerApplicationService,
    private readonly requirementsService: SellerVerificationRequirementsService,
  ) {}

  private extractContext(req: FastifyRequest): RequestAuditContext {
    return {
      requestId:
        (req.headers['x-request-id'] as string) || (req.id as string) || undefined,
      ipAddress: req.ip,
      userAgent: (req.headers['user-agent'] as string) || '',
    };
  }

  // =========================================================================
  // VERIFICATION REQUIREMENTS ENGINE MANAGEMENT
  // =========================================================================

  @Get('requirements')
  @Permissions('verification.read')
  @ApiOperation({
    summary: 'List configurable seller verification requirements',
  })
  @ApiResponse({ status: 200, description: 'Verification requirements returned' })
  async listRequirements(@Query() query: AdminListRequirementsQueryDto) {
    return this.requirementsService.listRequirementsForAdmin(query);
  }

  @Post('requirements')
  @AnyPermissions('verification.requirements.manage', 'settings.update')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a configurable seller verification requirement',
  })
  @ApiResponse({ status: 201, description: 'Verification requirement created' })
  async createRequirement(
    @Body() dto: AdminCreateRequirementDto,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Req() req: FastifyRequest,
  ) {
    return this.requirementsService.createRequirement(
      dto,
      staff,
      this.extractContext(req),
    );
  }

  @Patch('requirements/:requirementId')
  @AnyPermissions('verification.requirements.manage', 'settings.update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update a verification requirement (automatically increments version)',
  })
  @ApiParam({ name: 'requirementId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Verification requirement updated' })
  async updateRequirement(
    @Param('requirementId', ParseUUIDPipe) requirementId: string,
    @Body() dto: AdminUpdateRequirementDto,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Req() req: FastifyRequest,
  ) {
    return this.requirementsService.updateRequirement(
      requirementId,
      dto,
      staff,
      this.extractContext(req),
    );
  }

  @Delete('requirements/:requirementId')
  @AnyPermissions('verification.requirements.manage', 'settings.update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Deactivate (soft-delete) a verification requirement',
  })
  @ApiParam({ name: 'requirementId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Verification requirement deactivated' })
  async deactivateRequirement(
    @Param('requirementId', ParseUUIDPipe) requirementId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Req() req: FastifyRequest,
  ) {
    return this.requirementsService.deactivateRequirement(
      requirementId,
      staff,
      this.extractContext(req),
    );
  }

  // =========================================================================
  // SELLER APPLICATIONS REVIEW & DECISIONS
  // =========================================================================

  @Get()
  @Permissions('verification.read')
  @ApiOperation({
    summary:
      'List seller applications with status, seller type, and marketplace section filtering',
  })
  @ApiResponse({ status: 200, description: 'Seller applications returned' })
  async listApplications(
    @Query() query: AdminSellerApplicationsQueryDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    const canReadDocs = staff.permissions.includes(
      'verification.documents.read',
    );
    return this.sellerApplicationService.listApplicationsForAdmin(
      query,
      canReadDocs,
    );
  }

  @Get(':id')
  @Permissions('verification.read')
  @ApiOperation({
    summary:
      'Get seller application details, completeness, missing documents, document versions/reviews, and history',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Application detail returned' })
  async getApplicationDetail(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    const canReadDocs = staff.permissions.includes(
      'verification.documents.read',
    );
    return this.sellerApplicationService.getApplicationDetailForAdmin(
      id,
      canReadDocs,
    );
  }

  @Get(':id/history')
  @Permissions('verification.read')
  @ApiOperation({ summary: 'Review chronological status history for an application' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Application history returned' })
  async getApplicationHistory(@Param('id', ParseUUIDPipe) id: string) {
    return this.sellerApplicationService.getApplicationHistoryForAdmin(id);
  }

  @Get(':id/documents/:documentId')
  @Permissions('verification.documents.read')
  @ApiOperation({
    summary: 'Audited short-lived private signed access URL for verification document',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiParam({ name: 'documentId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Signed access URL returned' })
  async getDocumentAccess(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('documentId', ParseUUIDPipe) documentId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.getDocumentAccessForAdmin(
      id,
      documentId,
      staff,
      this.extractContext(req),
    );
  }

  @Post(':id/documents/:documentId/review')
  @AnyPermissions('verification.approve', 'verification.reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Accept or reject an individual submitted verification document',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiParam({ name: 'documentId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Document review decision recorded' })
  async reviewDocument(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('documentId', ParseUUIDPipe) documentId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminReviewDocumentDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.reviewDocument(
      id,
      documentId,
      staff,
      dto,
      this.extractContext(req),
    );
  }

  @Post(':id/review')
  @AnyPermissions('verification.approve', 'verification.reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Transition a PENDING seller application to UNDER_REVIEW',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Application marked UNDER_REVIEW' })
  async startReview(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminReviewSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.startReview(
      id,
      staff,
      dto,
      this.extractContext(req),
    );
  }

  @Post(':id/request-correction')
  @AnyPermissions('verification.reject', 'verification.approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Request corrections on an UNDER_REVIEW application (UNDER_REVIEW -> NEEDS_CORRECTION)',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Correction request issued' })
  async requestCorrection(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminRequestCorrectionDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.requestCorrection(
      id,
      staff,
      dto,
      this.extractContext(req),
    );
  }

  @Post(':id/approve')
  @Permissions('verification.approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Approve a complete seller application and grant seller permissions transactionally',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Application approved and seller activated' })
  async approveApplication(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminApproveSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.approveApplication(
      id,
      staff,
      dto,
      this.extractContext(req),
    );
  }

  @Post(':id/reject')
  @Permissions('verification.reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reject a seller application with a mandatory rejection reason',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Application rejected' })
  async rejectApplication(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminRejectSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.rejectApplication(
      id,
      staff,
      dto,
      this.extractContext(req),
    );
  }

  @Post(':id/suspend')
  @AnyPermissions('verification.reject', 'users.suspend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Suspend an approved seller (revokes seller privileges immediately while preserving buyer permissions)',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Seller privileges suspended' })
  async suspendSeller(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminSuspendSellerDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.suspendSeller(
      id,
      staff,
      dto,
      this.extractContext(req),
    );
  }

  @Post(':id/expire')
  @AnyPermissions('verification.reject', 'verification.approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Expire an approved seller verification (revokes seller-only permissions while preserving buyer permissions and data)',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Seller verification marked EXPIRED' })
  async expireSeller(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminExpireSellerDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.expireSellerVerification(
      id,
      staff,
      dto,
      this.extractContext(req),
    );
  }

  @Post(':id/reinstate')
  @Permissions('verification.approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reinstate a suspended seller back to APPROVED status',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Seller privileges reinstated' })
  async reinstateSeller(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminApproveSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.reinstateSeller(
      id,
      staff,
      dto,
      this.extractContext(req),
    );
  }
}
