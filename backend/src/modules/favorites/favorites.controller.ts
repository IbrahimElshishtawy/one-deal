import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../auth/decorators/current-user.decorator';
import { AddFavoriteDto } from './dto/add-favorite.dto';
import { GetFavoritesQueryDto } from './dto/get-favorites-query.dto';

@ApiTags('Favorites')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard)
@Controller()
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get('favorites')
  @ApiOperation({
    summary: 'Get paginated saved/favorite listings for current user',
    description:
      'Supports pagination, category filtering (by ID or slug), keyword search, and optional unavailable listing inclusion.',
  })
  @ApiResponse({ status: 200, description: 'Paginated favorite listings returned' })
  async getMyFavorites(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: GetFavoritesQueryDto,
  ) {
    return this.favoritesService.getMyFavorites(user.id, query);
  }

  @Post('favorites')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Add a listing to favorites via request body' })
  @ApiResponse({ status: 200, description: 'Listing favorited' })
  @ApiResponse({ status: 400, description: 'Listing not published/eligible' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  async addFavoriteBody(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: AddFavoriteDto,
  ) {
    return this.favoritesService.addFavorite(user.id, dto.listingId);
  }

  @Post('favorites/:listingId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Add listing to favorites by path parameter' })
  @ApiParam({ name: 'listingId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Listing favorited' })
  async addFavorite(
    @CurrentUser() user: AuthenticatedUser,
    @Param('listingId', new ParseUUIDPipe()) listingId: string,
  ) {
    return this.favoritesService.addFavorite(user.id, listingId);
  }

  @Get('favorites/:listingId/status')
  @ApiOperation({ summary: 'Check whether a listing is favorited by the user' })
  @ApiParam({ name: 'listingId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Favorite status returned' })
  async getFavoriteStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('listingId', new ParseUUIDPipe()) listingId: string,
  ) {
    return this.favoritesService.getFavoriteStatus(user.id, listingId);
  }

  @Delete('favorites/:listingId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Remove listing from favorites' })
  @ApiParam({ name: 'listingId', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Listing unfavorited' })
  async removeFavorite(
    @CurrentUser() user: AuthenticatedUser,
    @Param('listingId', new ParseUUIDPipe()) listingId: string,
  ) {
    return this.favoritesService.removeFavorite(user.id, listingId);
  }

  // Mobile Aliases for complete Flutter compatibility
  @Get('listings/favorites')
  @ApiOperation({ summary: 'Alias: Get current user saved listings' })
  async getMyFavoritesAlias(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: GetFavoritesQueryDto,
  ) {
    return this.favoritesService.getMyFavorites(user.id, query);
  }

  @Post('listings/:listingId/favorite')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Alias: Toggle favorite status for listing' })
  @ApiParam({ name: 'listingId', format: 'uuid' })
  async toggleFavoriteAlias(
    @CurrentUser() user: AuthenticatedUser,
    @Param('listingId', new ParseUUIDPipe()) listingId: string,
  ) {
    return this.favoritesService.toggleFavorite(user.id, listingId);
  }
}
