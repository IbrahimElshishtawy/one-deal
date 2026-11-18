import {
  Controller,
  Get,
  Post,
  Body,
  Headers,
  Query,
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
import { VideoService } from './video.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('Video')
@Controller()
export class VideoController {
  constructor(private readonly videoService: VideoService) {}

  @Post('media/video/upload-token')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Request Cloudflare Stream direct-upload token (30s max limit)',
  })
  @ApiResponse({ status: 200, description: 'Direct upload token returned' })
  async getUploadToken(@CurrentUser() user: AuthenticatedUser) {
    return this.videoService.requestDirectUploadToken(user.id);
  }

  @Post('media/video/webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cloudflare Stream video processing webhook' })
  @ApiResponse({ status: 200, description: 'Webhook received' })
  async handleWebhook(
    @Body() payload: any,
    @Req() req: FastifyRequest,
    @Headers('webhook-signature') signature?: string,
  ) {
    const raw = (req as any).rawBody as Buffer | string | undefined;
    const rawBody = Buffer.isBuffer(raw) ? raw.toString('utf8') : raw;
    return this.videoService.handleWebhook(payload, signature, rawBody);
  }

  @Get('video-feed')
  @ApiOperation({ summary: 'Vertical swipe video feed for active listings' })
  @ApiResponse({ status: 200, description: 'Video feed items returned' })
  async getVideoFeed(
    @Query('cursor') cursor?: string,
    @Query('limit') limit = 10,
  ) {
    return this.videoService.getVideoFeed(cursor, Number(limit));
  }
}
