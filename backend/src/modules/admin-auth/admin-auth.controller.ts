import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  Res,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { FastifyReply, FastifyRequest } from 'fastify';
import { RateLimit } from '../../core/guards/rate-limit.guard';
import { RateLimitGuard } from '../../core/guards/rate-limit.guard';
import { AdminAuthService } from './admin-auth.service';
import { StaffSessionService } from './services/staff-session.service';
import { AdminJwtAuthGuard } from './guards/admin-jwt-auth.guard';
import { CurrentStaff } from './decorators/permissions.decorator';
import { AuthenticatedStaff } from './types/authenticated-staff.type';
import {
  AdminChangePasswordDto,
  AdminForgotPasswordDto,
  AdminLoginDto,
  AdminRefreshDto,
  AdminResetPasswordDto,
  DisableMfaDto,
  EnableMfaDto,
  VerifyMfaChallengeDto,
} from './dto/admin-auth.dto';

@ApiTags('Admin / Authentication')
@Controller('admin/auth')
export class AdminAuthController {
  constructor(
    private readonly adminAuthService: AdminAuthService,
    private readonly staffSessionService: StaffSessionService,
    private readonly configService: ConfigService,
  ) {}

  private getCookieName(): string {
    return this.configService.get<string>(
      'ADMIN_COOKIE_NAME',
      'dealone_admin_rt',
    );
  }

  private setRefreshCookie(res: FastifyReply, refreshToken: string) {
    const isProd = this.configService.get<string>('NODE_ENV') === 'production';
    const domain =
      this.configService.get<string>('ADMIN_COOKIE_DOMAIN', '').trim() ||
      undefined;
    const sameSite = this.configService.get<'strict' | 'lax' | 'none'>(
      'ADMIN_COOKIE_SAMESITE',
      'strict',
    );
    const maxAgeSec =
      this.staffSessionService.getRefreshExpiryDays() * 24 * 60 * 60;

    (res as any).setCookie(this.getCookieName(), refreshToken, {
      httpOnly: true,
      secure: isProd || sameSite === 'none',
      sameSite,
      path: '/api/v1/admin/auth',
      maxAge: maxAgeSec,
      ...(domain ? { domain } : {}),
    });
  }

  private clearRefreshCookie(res: FastifyReply) {
    const isProd = this.configService.get<string>('NODE_ENV') === 'production';
    const domain =
      this.configService.get<string>('ADMIN_COOKIE_DOMAIN', '').trim() ||
      undefined;
    const sameSite = this.configService.get<'strict' | 'lax' | 'none'>(
      'ADMIN_COOKIE_SAMESITE',
      'strict',
    );

    (res as any).clearCookie(this.getCookieName(), {
      httpOnly: true,
      secure: isProd || sameSite === 'none',
      sameSite,
      path: '/api/v1/admin/auth',
      ...(domain ? { domain } : {}),
    });
  }

  private assertCsrfHeaderIfCookieUsed(
    req: FastifyRequest,
    hasCookie: boolean,
  ) {
    if (!hasCookie) return;
    const xRequestedWith = req.headers['x-requested-with'];
    const xCsrfToken = req.headers['x-csrf-token'];
    if (xRequestedWith !== 'dealone-admin-web' && !xCsrfToken) {
      throw new ForbiddenException(
        'Missing anti-CSRF header (X-Requested-With or X-CSRF-Token) for cookie-authenticated request.',
      );
    }
  }

  @Post('login')
  @UseGuards(RateLimitGuard)
  @RateLimit(10, 900, { anonymousLimit: 10 })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate an administrative staff account' })
  @ApiResponse({
    status: 200,
    description: 'Authenticated or MFA challenge issued',
  })
  async login(
    @Body() dto: AdminLoginDto,
    @Req() req: FastifyRequest,
    @Res({ passthrough: true }) res: FastifyReply,
  ) {
    const result = await this.adminAuthService.login(
      dto,
      req.ip,
      req.headers['user-agent'] as string | undefined,
      req.headers['x-trace-id'] as string | undefined,
    );

    if (
      !result.requiresMfa &&
      'refreshToken' in result &&
      result.refreshToken
    ) {
      this.setRefreshCookie(res, result.refreshToken);
      const { refreshToken: _omit, ...safeBody } = result;
      return safeBody;
    }

    return result;
  }

  @Post('mfa/verify')
  @UseGuards(RateLimitGuard)
  @RateLimit(10, 900, { anonymousLimit: 10 })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Verify TOTP MFA or recovery code to complete admin login',
  })
  async verifyMfa(
    @Body() dto: VerifyMfaChallengeDto,
    @Req() req: FastifyRequest,
    @Res({ passthrough: true }) res: FastifyReply,
  ) {
    const result = await this.adminAuthService.verifyMfaChallenge(
      dto,
      req.ip,
      req.headers['user-agent'] as string | undefined,
      req.headers['x-trace-id'] as string | undefined,
    );

    this.setRefreshCookie(res, result.refreshToken);
    const { refreshToken: _omit, ...safeBody } = result;
    return safeBody;
  }

  @Post('refresh')
  @UseGuards(RateLimitGuard)
  @RateLimit(30, 900, { anonymousLimit: 30 })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Rotate admin HttpOnly refresh cookie and return new access token',
  })
  async refresh(
    @Req() req: FastifyRequest,
    @Res({ passthrough: true }) res: FastifyReply,
  ) {
    const cookieToken = (req as any).cookies?.[this.getCookieName()] as
      string | undefined;

    if (cookieToken) {
      this.assertCsrfHeaderIfCookieUsed(req, true);
    }

    const bodyToken = (req.body as AdminRefreshDto | undefined)?.refreshToken;
    const token = cookieToken || bodyToken;
    if (!token) {
      throw new UnauthorizedException('Admin refresh cookie is missing.');
    }

    const result = await this.adminAuthService.refresh(
      token,
      req.ip,
      req.headers['user-agent'] as string | undefined,
      req.headers['x-trace-id'] as string | undefined,
    );

    this.setRefreshCookie(res, result.refreshToken);
    const { refreshToken: _omit, ...safeBody } = result;
    return safeBody;
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Revoke admin session, denylist access token, and clear cookie',
  })
  async logout(
    @Req() req: FastifyRequest,
    @Res({ passthrough: true }) res: FastifyReply,
  ) {
    const cookieToken = (req as any).cookies?.[this.getCookieName()] as
      string | undefined;
    if (cookieToken) {
      this.assertCsrfHeaderIfCookieUsed(req, true);
    }

    const authHeader = req.headers.authorization;
    const rawAccessToken = authHeader?.replace(/^Bearer\s+/i, '').trim();

    await this.adminAuthService.logout(cookieToken, rawAccessToken);
    this.clearRefreshCookie(res);
    return { success: true };
  }

  @Get('me')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard)
  @ApiOperation({
    summary: 'Get authenticated staff identity and effective permissions',
  })
  async me(@CurrentStaff() staff: AuthenticatedStaff) {
    if (!staff.staffId) {
      return {
        id: staff.id,
        email: staff.email,
        fullName: staff.fullName,
        status: 'active',
        isActive: true,
        mfaEnabled: staff.mfaVerified,
        role: { id: staff.roleId, name: staff.role },
        permissions: staff.permissions,
      };
    }
    return this.adminAuthService.getMe(staff.staffId);
  }

  @Get('sessions')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard)
  @ApiOperation({ summary: 'List active sessions for current admin' })
  async listSessions(@CurrentStaff() staff: AuthenticatedStaff) {
    if (!staff.staffId) return [];
    return this.staffSessionService.getStaffActiveSessions(
      staff.staffId,
      staff.sessionId,
    );
  }

  @Delete('sessions/:sessionId')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard)
  @ApiOperation({
    summary: 'Revoke a specific active session for current admin',
  })
  async revokeSession(
    @Param('sessionId', ParseUUIDPipe) sessionId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    if (!staff.staffId) {
      throw new NotFoundException('Session not found');
    }
    const revoked = await this.staffSessionService.revokeSessionById(
      staff.staffId,
      sessionId,
      staff.staffId,
    );
    if (!revoked) {
      throw new NotFoundException('Active admin session not found');
    }
    return { success: true };
  }

  @Post('mfa/setup')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Generate TOTP secret and otpauth URI for current admin',
  })
  async setupMfa(@CurrentStaff() staff: AuthenticatedStaff) {
    if (!staff.staffId) {
      throw new ForbiddenException('Only staff accounts can manage MFA');
    }
    return this.adminAuthService.setupMfa(staff.staffId);
  }

  @Post('mfa/enable')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Verify TOTP code and enable MFA with recovery codes',
  })
  async enableMfa(
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: EnableMfaDto,
  ) {
    if (!staff.staffId) {
      throw new ForbiddenException('Only staff accounts can manage MFA');
    }
    return this.adminAuthService.enableMfa(staff.staffId, dto);
  }

  @Post('mfa/disable')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Disable MFA after password and TOTP verification' })
  async disableMfa(
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: DisableMfaDto,
  ) {
    if (!staff.staffId) {
      throw new ForbiddenException('Only staff accounts can manage MFA');
    }
    return this.adminAuthService.disableMfa(staff.staffId, dto);
  }

  @Post('password/change')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(AdminJwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Change current admin password and revoke other sessions',
  })
  async changePassword(
    @CurrentStaff() staff: AuthenticatedStaff,
    @Body() dto: AdminChangePasswordDto,
  ) {
    if (!staff.staffId) {
      throw new ForbiddenException(
        'Only staff accounts can change admin password',
      );
    }
    return this.adminAuthService.changePassword(
      staff.staffId,
      dto,
      staff.sessionId,
    );
  }

  @Post('password/forgot')
  @UseGuards(RateLimitGuard)
  @RateLimit(5, 900, { anonymousLimit: 5 })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request admin password reset link via email' })
  async forgotPassword(@Body() dto: AdminForgotPasswordDto) {
    return this.adminAuthService.forgotPassword(dto);
  }

  @Post('password/reset')
  @UseGuards(RateLimitGuard)
  @RateLimit(5, 900, { anonymousLimit: 5 })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reset admin password using single-use reset token',
  })
  async resetPassword(@Body() dto: AdminResetPasswordDto) {
    return this.adminAuthService.resetPassword(dto);
  }
}
