import {
  Controller,
  Post,
  Get,
  Body,
  Req,
  HttpCode,
  HttpStatus,
  UseGuards,
  Headers,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { FastifyRequest } from 'fastify';
import { AuthService } from './auth.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { ResendOtpDto } from './dto/resend-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { LoginPasswordDto } from './dto/login-password.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { SetPasswordDto } from './dto/set-password.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { ActiveSessionResponseDto } from './dto/session-response.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RateLimit, RateLimitGuard } from '../../core/guards/rate-limit.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from './decorators/current-user.decorator';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('otp/send')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Dispatch SMS OTP verification code' })
  @ApiResponse({
    status: 200,
    description: 'OTP dispatched successfully via SMS',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid Egyptian mobile phone number format',
  })
  @ApiResponse({
    status: 429,
    description:
      'Rate limit exceeded (Max 3 OTP per 15 min or active 60s cooldown)',
  })
  async sendOtp(
    @Body() dto: SendOtpDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;
    return this.authService.sendOtp(dto, ipAddress, userAgent, traceId);
  }

  @Post('otp/resend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Resend SMS OTP verification code subject to cooldown',
  })
  @ApiResponse({ status: 200, description: 'OTP code resent successfully' })
  @ApiResponse({
    status: 429,
    description: 'Cooldown active or rate limit exceeded',
  })
  async resendOtp(
    @Body() dto: ResendOtpDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;
    return this.authService.resendOtp(dto, ipAddress, userAgent, traceId);
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Verify OTP, provision User + default Individual Account, and issue JWT session pair',
  })
  @ApiResponse({
    status: 200,
    description:
      'Authenticated successfully with token pair and identity context',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid, expired, or already consumed OTP code',
  })
  @ApiResponse({
    status: 401,
    description: 'Account deactivated or suspended',
  })
  async verifyOtp(
    @Body() dto: VerifyOtpDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;
    return this.authService.verifyOtp(dto, userAgent, ipAddress, traceId);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Password login fallback' })
  @ApiResponse({ status: 200, description: 'Login successful' })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  async loginWithPassword(
    @Body() dto: LoginPasswordDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;
    return this.authService.loginWithPassword(
      dto,
      userAgent,
      ipAddress,
      traceId,
    );
  }

  @Post('password/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Password login alias' })
  async loginPasswordAlias(
    @Body() dto: LoginPasswordDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.loginWithPassword(dto, req, traceId);
  }

  @Post('password/set')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('BearerAuth')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Set an initial password for an OTP-registered user',
  })
  @ApiResponse({ status: 200, description: 'Password set successfully' })
  @ApiResponse({ status: 400, description: 'Password already set' })
  async setPassword(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SetPasswordDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.authService.setPassword(
      user.id,
      dto,
      req.ip,
      req.headers['user-agent'],
      traceId,
    );
  }

  @Post('password/change')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('BearerAuth')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Change current password and revoke other active sessions',
  })
  @ApiResponse({ status: 200, description: 'Password changed successfully' })
  @ApiResponse({ status: 401, description: 'Current password is incorrect' })
  async changePassword(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ChangePasswordDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.authService.changePassword(
      user.id,
      dto,
      user.sessionId,
      req.ip,
      req.headers['user-agent'],
      traceId,
    );
  }

  @Post('password/forgot')
  @UseGuards(RateLimitGuard)
  @RateLimit(3, 900, { anonymousLimit: 5 })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Request password reset OTP (always returns 200 to prevent enumeration)',
  })
  @ApiResponse({
    status: 200,
    description: 'Generic reset confirmation returned',
  })
  @ApiResponse({ status: 429, description: 'Too many requests' })
  async forgotPassword(
    @Body() dto: ForgotPasswordDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.authService.forgotPassword(
      dto,
      req.ip,
      req.headers['user-agent'],
      traceId,
    );
  }

  @Post('password/reset')
  @UseGuards(RateLimitGuard)
  @RateLimit(5, 900, { anonymousLimit: 10 })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reset password using PASSWORD_RESET OTP and revoke all sessions',
  })
  @ApiResponse({ status: 200, description: 'Password reset successfully' })
  @ApiResponse({ status: 400, description: 'Invalid or expired OTP' })
  @ApiResponse({ status: 429, description: 'Too many requests' })
  async resetPassword(
    @Body() dto: ResetPasswordDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.authService.resetPassword(
      dto,
      req.ip,
      req.headers['user-agent'],
      traceId,
    );
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Rotate refresh token and issue new token pair with reuse detection',
  })
  @ApiResponse({ status: 200, description: 'Tokens rotated successfully' })
  @ApiResponse({
    status: 401,
    description:
      'Invalid/expired token or reuse detected (all sessions terminated)',
  })
  async refreshToken(
    @Body() dto: RefreshTokenDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;
    return this.authService.refreshToken(dto, userAgent, ipAddress, traceId);
  }

  @Post('token/refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Rotate refresh token alias (OpenAPI compatibility)',
  })
  async refreshTokenAlias(
    @Body() dto: RefreshTokenDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.refreshToken(dto, req, traceId);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Revoke active refresh token session' })
  @ApiResponse({ status: 200, description: 'Session revoked successfully' })
  async logout(
    @Body() dto: RefreshTokenDto,
    @Req() req: FastifyRequest,
    @Headers('x-trace-id') traceId?: string,
  ) {
    const user = (req as any).user as AuthenticatedUser | undefined;
    return this.authService.logout(dto, user?.id, traceId);
  }

  @Post('sessions/terminate-all')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('BearerAuth')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Revoke all active sessions belonging to the authenticated user',
  })
  @ApiResponse({ status: 200, description: 'All active sessions revoked' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async terminateAllSessions(
    @CurrentUser() user: AuthenticatedUser,
    @Headers('x-trace-id') traceId?: string,
  ) {
    return this.authService.terminateAllSessions(user.id, traceId);
  }

  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('BearerAuth')
  @ApiOperation({
    summary: 'List active sessions for the authenticated user',
  })
  @ApiResponse({
    status: 200,
    description: 'List of active sessions returned',
    type: [ActiveSessionResponseDto],
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getActiveSessions(@CurrentUser() user: AuthenticatedUser) {
    return this.authService.getActiveSessions(user.id);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('BearerAuth')
  @ApiOperation({ summary: 'Get current authenticated identity and roles' })
  @ApiResponse({ status: 200, description: 'Authenticated user returned' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getCurrentIdentity(@CurrentUser() user: AuthenticatedUser) {
    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      role: user.role,
      status: user.status,
    };
  }
}
