import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FastifyRequest } from 'fastify';
import { AdminJwtAuthGuard } from '../../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../../admin-auth/guards/permissions.guard';
import {
  CurrentStaff,
  Permissions,
} from '../../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../../admin-auth/types/authenticated-staff.type';
import { AdminMarketplaceService } from '../services/admin-marketplace.service';
import {
  AdminPaginationDto,
  MessagingConversationMessagesQueryDto,
  UpdateConversationStatusDto,
} from '../dto/admin-operations.dto';

@ApiTags('Admin / Messaging Oversight')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/chat')
export class AdminMessagingController {
  constructor(private readonly service: AdminMarketplaceService) {}

  @Get('complaints')
  @Permissions('messaging.complaints.read')
  @ApiOperation({
    summary: 'List conversation reports and technical delivery summaries (no message bodies)',
  })
  listComplaints(@Query() query: AdminPaginationDto) {
    return this.service.listMessagingComplaints(query);
  }

  @Get('conversations/:id/messages')
  @Permissions('chat.oversight.read')
  @ApiOperation({
    summary: 'Audited limited access to conversation messages (requires reason)',
  })
  getConversationMessages(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: MessagingConversationMessagesQueryDto,
    @CurrentStaff() staff: AuthenticatedStaff,
    @Req() req: FastifyRequest,
  ) {
    return this.service.getAuditedConversationMessages(
      id,
      staff.id,
      query,
      req.ip,
    );
  }

  @Patch('conversations/:id/status')
  @Permissions('messaging.support.resolve')
  @ApiOperation({ summary: 'Update conversation status or escalate case' })
  updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateConversationStatusDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.service.updateConversationStatus(id, dto, staff.id);
  }
}
