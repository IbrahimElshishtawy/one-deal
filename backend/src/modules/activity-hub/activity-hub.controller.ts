import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ActivityHubService } from './activity-hub.service';
import { GetActivityHubQueryDto } from './dto/get-activity-hub-query.dto';

@ApiTags('Unified Activity Hub')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard)
@Controller('activity-hub')
export class ActivityHubController {
  constructor(private readonly activityHubService: ActivityHubService) {}

  @Get()
  @ApiOperation({
    summary:
      'Get aggregated user activity hub (Summary, Cart, Bookings, RFQs, Favorites)',
    description:
      'Aggregates counts and paginated records from independent domain services. Use ?include=bookings,rfqs to selectively load sections.',
  })
  @ApiResponse({
    status: 200,
    description: 'Aggregated user activity returned',
  })
  async getActivityHub(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: GetActivityHubQueryDto,
  ) {
    return this.activityHubService.getActivityHub(user.id, query);
  }
}
