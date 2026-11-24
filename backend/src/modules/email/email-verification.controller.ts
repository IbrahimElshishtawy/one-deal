import {
  Controller,
  Post,
  Body,
  Req,
  Headers,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { FastifyRequest } from 'fastify';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';
import { RateLimit, RateLimitGuard } from '../../core/guards/rate-limit.guard';
import { EmailVerificationService } from './email-verification.service';
import { RequestEmailVerificationDto } from './dto/request-email-verification.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';

@ApiTags('Authentication')
@Controller('auth/email')
export class EmailVerificationController {
  constructor(
    private readonly emailVerificationService: EmailVerificationService,
  ) {}

  @Post('verification/request')
  @UseGuards(JwtAuthGuard, RateLimitGuard)
  @RateLimit(3, 900, { bucketKey: 'auth:email:verify-request' })
  @ApiBearerAuth('BearerAuth')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Request a single-use email verification link for the authenticated user',
  })
  @ApiResponse({
    status: 200,
    description:
      'Verification link dispatched (generic response to prevent enumeration)',
  })
  @ApiResponse({ status: 400, description: 'Missing or invalid email address' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 429,
    description: 'Rate limit or 60s cooldown active',
  })
  async requestVerification(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RequestEmailVerificationDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
    @Headers('x-request-id') requestId?: string,
  ) {
    return this.emailVerificationService.requestVerification(
      user.id,
      dto.email,
      req.ip,
      req.headers['user-agent'],
      requestId || traceId,
    );
  }

  @Post('verification/resend')
  @UseGuards(JwtAuthGuard, RateLimitGuard)
  @RateLimit(3, 900, { bucketKey: 'auth:email:verify-resend' })
  @ApiBearerAuth('BearerAuth')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Resend email verification link (invalidates prior active token, subject to cooldown)',
  })
  @ApiResponse({ status: 200, description: 'Verification link resent' })
  @ApiResponse({
    status: 429,
    description: 'Rate limit or 60s cooldown active',
  })
  async resendVerification(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RequestEmailVerificationDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.emailVerificationService.requestVerification(
      user.id,
      dto.email,
      req.ip,
      req.headers['user-agent'],
      traceId,
    );
  }

  @Post('verify')
  @UseGuards(RateLimitGuard)
  @RateLimit(10, 900, { anonymousLimit: 10, bucketKey: 'auth:email:verify' })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Verify an email address using a single-use verification token',
  })
  @ApiResponse({ status: 200, description: 'Email verified successfully' })
  @ApiResponse({
    status: 400,
    description: 'Invalid, expired, or already used token',
  })
  @ApiResponse({ status: 429, description: 'Too many verification attempts' })
  async verifyEmail(
    @Body() dto: VerifyEmailDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.emailVerificationService.verifyEmailToken(
      dto.token,
      req.ip,
      req.headers['user-agent'],
      traceId,
    );
  }
}
