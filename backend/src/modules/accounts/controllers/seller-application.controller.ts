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
  CreateSellerApplicationDto,
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
    summary: 'Get current user seller status, capabilities, and active application',
  })
  @ApiResponse({ status: 200, description: 'Seller application status returned' })
  async getMyApplication(@CurrentUser() user: AuthenticatedUser) {
    return this.sellerApplicationService.getMyApplication(user.id);
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
  @ApiOperation({ summary: 'Update current user seller application draft' })
  @ApiResponse({ status: 200, description: 'Seller application draft updated' })
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
    summary: 'Delete an uploaded verification document while editable',
  })
  @ApiParam({ name: 'documentId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Document deleted' })
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
    summary: 'Reopen or resubmit a rejected seller application',
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
}
