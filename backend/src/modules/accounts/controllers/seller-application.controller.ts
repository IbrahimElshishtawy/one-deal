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
  Put,
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
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../auth/decorators/current-user.decorator';
import { RateLimit, RateLimitGuard } from '../../../core/guards/rate-limit.guard';
import { SellerCapability } from '../../../core/enums/domain.enums';
import { SellerAuthorizationGuard } from '../guards/seller-authorization.guard';
import { RequireSellerCapability } from '../decorators/require-seller-capability.decorator';
import {
  RequestAuditContext,
  SellerApplicationService,
} from '../services/seller-application.service';
import {
  ConfirmVerificationDocumentDto,
  CreateBusinessUpgradeDto,
  CreateSellerApplicationDto,
  GetVerificationRequirementsQueryDto,
  ReplaceVerificationDocumentDto,
  RequestVerificationDocUploadUrlDto,
  ResubmitSellerApplicationDto,
  UpdateSellerApplicationDto,
} from '../dto/seller-application.dto';

@ApiTags('Seller Applications')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard)
@Controller('seller-applications')
export class SellerApplicationController {
  constructor(
    private readonly sellerApplicationService: SellerApplicationService,
  ) {}

  private extractContext(req: FastifyRequest): RequestAuditContext {
    return {
      requestId:
        (req.headers['x-request-id'] as string) || (req.id as string) || undefined,
      ipAddress: req.ip,
      userAgent: (req.headers['user-agent'] as string) || '',
    };
  }

  @Get('requirements')
  @ApiOperation({
    summary:
      'Get configurable seller verification requirements by seller type and marketplace section(s)',
  })
  @ApiResponse({
    status: 200,
    description: 'Applicable verification requirements returned',
  })
  async getVerificationRequirements(
    @Query() query: GetVerificationRequirementsQueryDto,
  ) {
    return this.sellerApplicationService.getVerificationRequirementsForUser(
      query,
    );
  }

  @Post()
  @UseGuards(SellerAuthorizationGuard, RateLimitGuard)
  @RequireSellerCapability(SellerCapability.CAN_SUBMIT_SELLER_APPLICATION)
  @RateLimit(10, 3600)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Request buyer-to-seller conversion (creates DRAFT application)',
  })
  @ApiResponse({ status: 201, description: 'Seller application draft created' })
  @ApiResponse({ status: 409, description: 'Duplicate active seller application' })
  async requestSellerConversion(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.requestSellerConversion(
      user.id,
      dto,
      this.extractContext(req),
    );
  }

  @Get('me')
  @ApiOperation({
    summary: 'Get current user seller status, capabilities, and active application details',
  })
  @ApiResponse({ status: 200, description: 'Seller application status returned' })
  async getMyApplication(@CurrentUser() user: AuthenticatedUser) {
    return this.sellerApplicationService.getMyApplication(user.id);
  }

  @Get('me/corrections')
  @ApiOperation({
    summary: 'Get active correction requests (affected fields and rejected documents)',
  })
  @ApiResponse({ status: 200, description: 'Correction requests returned' })
  async getMyCorrections(@CurrentUser() user: AuthenticatedUser) {
    return this.sellerApplicationService.getMyCorrections(user.id);
  }

  @Get('me/history')
  @ApiOperation({
    summary: 'Get chronological status history of current user seller applications',
  })
  @ApiResponse({ status: 200, description: 'Application history returned' })
  async getMyApplicationHistory(@CurrentUser() user: AuthenticatedUser) {
    return this.sellerApplicationService.getMyApplicationHistory(user.id);
  }

  @Patch('me')
  @UseGuards(RateLimitGuard)
  @RateLimit(30, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update current user seller application draft (or affected fields when NEEDS_CORRECTION)',
  })
  @ApiResponse({ status: 200, description: 'Seller application updated' })
  async updateDraft(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.updateDraft(
      user.id,
      dto,
      this.extractContext(req),
    );
  }

  @Post('me/documents/upload-url')
  @UseGuards(RateLimitGuard)
  @RateLimit(20, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Request a private presigned upload URL for a seller verification document',
  })
  @ApiResponse({
    status: 200,
    description: 'Private presigned upload URL generated',
  })
  async requestDocumentUploadUrl(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RequestVerificationDocUploadUrlDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.requestDocumentUploadUrl(
      user.id,
      dto,
      this.extractContext(req),
    );
  }

  @Post('me/documents')
  @UseGuards(RateLimitGuard)
  @RateLimit(20, 3600)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Confirm and attach an uploaded private verification document',
  })
  @ApiResponse({
    status: 201,
    description: 'Verification document registered',
  })
  async registerDocument(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ConfirmVerificationDocumentDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.registerDocument(
      user.id,
      dto,
      this.extractContext(req),
    );
  }

  @Put('me/documents/:documentId/replace')
  @UseGuards(RateLimitGuard)
  @RateLimit(20, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Replace a verification document (preserves previous version in audit history; enforces affected-doc restriction during NEEDS_CORRECTION)',
  })
  @ApiParam({ name: 'documentId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Verification document replaced with new version' })
  async replaceDocument(
    @CurrentUser() user: AuthenticatedUser,
    @Param('documentId', ParseUUIDPipe) documentId: string,
    @Body() dto: ReplaceVerificationDocumentDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.replaceDocument(
      user.id,
      documentId,
      dto,
      this.extractContext(req),
    );
  }

  @Get('me/documents/:documentId/access')
  @UseGuards(RateLimitGuard)
  @RateLimit(30, 3600)
  @ApiOperation({
    summary: 'Get a short-lived private signed access URL for own document',
  })
  @ApiParam({ name: 'documentId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Short-lived access URL returned' })
  @ApiResponse({ status: 403, description: 'Forbidden (not document owner)' })
  async getOwnDocumentAccessUrl(
    @CurrentUser() user: AuthenticatedUser,
    @Param('documentId', ParseUUIDPipe) documentId: string,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.getOwnDocumentAccessUrl(
      user.id,
      documentId,
      this.extractContext(req),
    );
  }

  @Delete('me/documents/:documentId')
  @UseGuards(RateLimitGuard)
  @RateLimit(20, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Remove an uploaded verification document from an editable draft',
  })
  @ApiParam({ name: 'documentId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Document removed' })
  async deleteDocument(
    @CurrentUser() user: AuthenticatedUser,
    @Param('documentId', ParseUUIDPipe) documentId: string,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.deleteDocument(
      user.id,
      documentId,
      this.extractContext(req),
    );
  }

  @Post('me/submit')
  @UseGuards(SellerAuthorizationGuard, RateLimitGuard)
  @RequireSellerCapability(SellerCapability.CAN_SUBMIT_SELLER_APPLICATION)
  @RateLimit(10, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Submit complete seller application for mandatory admin verification',
  })
  @ApiResponse({ status: 200, description: 'Application submitted (PENDING)' })
  @ApiResponse({ status: 400, description: 'Incomplete application or invalid state' })
  async submitApplication(
    @CurrentUser() user: AuthenticatedUser,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.submitApplication(
      user.id,
      this.extractContext(req),
    );
  }

  @Post('me/resubmit')
  @UseGuards(SellerAuthorizationGuard, RateLimitGuard)
  @RequireSellerCapability(SellerCapability.CAN_SUBMIT_SELLER_APPLICATION)
  @RateLimit(10, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Resubmit a corrected (NEEDS_CORRECTION), rejected, or expired seller application',
  })
  @ApiResponse({ status: 200, description: 'Application reopened or resubmitted' })
  async resubmitApplication(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ResubmitSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.resubmitApplication(
      user.id,
      dto,
      this.extractContext(req),
    );
  }

  @Get('dashboard')
  @UseGuards(SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @ApiOperation({
    summary: 'Seller dashboard summary (approved non-suspended sellers only)',
  })
  @ApiResponse({ status: 200, description: 'Seller dashboard metrics returned' })
  @ApiResponse({ status: 403, description: 'Approved seller status required' })
  async getSellerDashboard(@CurrentUser() user: AuthenticatedUser) {
    return this.sellerApplicationService.getSellerDashboard(user.id);
  }

  // =========================================================================
  // INDIVIDUAL-TO-BUSINESS UPGRADE WORKFLOW
  // =========================================================================

  @Post('me/business-upgrade')
  @UseGuards(SellerAuthorizationGuard, RateLimitGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @RateLimit(10, 3600)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Initiate a safe Individual-to-Business verification upgrade for an existing Identity-Verified seller (preserves account, listings, and conversations)',
  })
  @ApiResponse({
    status: 201,
    description: 'Business upgrade application draft created',
  })
  @ApiResponse({
    status: 409,
    description: 'Already business-verified or upgrade already in progress',
  })
  async requestBusinessUpgrade(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateBusinessUpgradeDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.requestBusinessUpgrade(
      user.id,
      dto,
      this.extractContext(req),
    );
  }

  @Get('me/business-upgrade')
  @UseGuards(SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @ApiOperation({
    summary:
      'Get current Individual-to-Business upgrade application status, required documents, and completeness',
  })
  @ApiResponse({
    status: 200,
    description: 'Business upgrade status returned',
  })
  async getMyBusinessUpgrade(@CurrentUser() user: AuthenticatedUser) {
    return this.sellerApplicationService.getMyBusinessUpgrade(user.id);
  }

  @Post('me/business-upgrade/submit')
  @UseGuards(SellerAuthorizationGuard, RateLimitGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @RateLimit(10, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Submit a complete Business Upgrade application for admin review (preserves active IDENTITY_VERIFIED status while pending)',
  })
  @ApiResponse({
    status: 200,
    description: 'Business upgrade application submitted (PENDING)',
  })
  async submitBusinessUpgrade(
    @CurrentUser() user: AuthenticatedUser,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.submitBusinessUpgrade(
      user.id,
      this.extractContext(req),
    );
  }

  @Post('me/business-upgrade/resubmit')
  @UseGuards(SellerAuthorizationGuard, RateLimitGuard)
  @RequireSellerCapability(SellerCapability.CAN_ACCESS_SELLER_DASHBOARD)
  @RateLimit(10, 3600)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Resubmit a rejected or NEEDS_CORRECTION Business Upgrade application',
  })
  @ApiResponse({
    status: 200,
    description: 'Business upgrade application reopened or resubmitted',
  })
  async resubmitBusinessUpgrade(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ResubmitSellerApplicationDto,
    @Req() req: FastifyRequest,
  ) {
    return this.sellerApplicationService.resubmitBusinessUpgrade(
      user.id,
      dto,
      this.extractContext(req),
    );
  }
}
