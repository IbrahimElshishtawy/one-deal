import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  Sse,
  MessageEvent,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { StartConversationDto } from './dto/start-conversation.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('Chat & Messages')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard)
@Controller('conversations')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Sse('stream')
  @ApiOperation({
    summary: 'Real-time SSE stream for incoming chat messages (Redis Pub/Sub)',
  })
  streamMessages(
    @CurrentUser() user: AuthenticatedUser,
  ): Observable<MessageEvent> {
    return this.chatService.subscribeToUserStream(user.id);
  }

  @Get()
  @ApiOperation({ summary: 'List user active conversations' })
  @ApiResponse({ status: 200, description: 'Conversations returned' })
  async getMyConversations(@CurrentUser() user: AuthenticatedUser) {
    return this.chatService.getUserConversations(user.id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Start or get an existing conversation for a listing',
  })
  @ApiResponse({
    status: 201,
    description: 'Conversation started or retrieved',
  })
  async startConversation(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: StartConversationDto,
  ) {
    return this.chatService.getOrCreateConversation(dto.listingId, user.id);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Get paginated message history for a conversation' })
  @ApiResponse({ status: 200, description: 'Messages returned' })
  @ApiResponse({ status: 403, description: 'Forbidden (Not a participant)' })
  async getMessages(
    @Param('id') conversationId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Query('page') page = 1,
    @Query('limit') limit = 30,
  ) {
    return this.chatService.getMessages(
      conversationId,
      user.id,
      Number(page),
      Number(limit),
    );
  }

  @Post(':id/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Send text message inside conversation' })
  @ApiResponse({ status: 201, description: 'Message sent' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async sendMessage(
    @Param('id') conversationId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(conversationId, user.id, dto.text);
  }
}
