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
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CartService } from './cart.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';

@ApiTags('Cart (V1 Saved Basket)')
@ApiBearerAuth('BearerAuth')
@UseGuards(JwtAuthGuard)
@Controller('cart')
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get()
  @ApiOperation({
    summary: 'Get user V1 non-transactional saved product basket',
    description:
      'Returns saved basket items with authoritative server-side price snapshots. V1 does not expose online checkout or payment processing.',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'categoryId', required: false, type: String })
  @ApiQuery({ name: 'categorySlug', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Saved basket returned' })
  async getCart(
    @CurrentUser() user: AuthenticatedUser,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('categoryId') categoryId?: string,
    @Query('categorySlug') categorySlug?: string,
  ) {
    return this.cartService.getCart(user.id, {
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 20,
      categoryId,
      categorySlug,
    });
  }

  @Post('items')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Add a listing to the V1 saved product basket',
  })
  @ApiResponse({ status: 201, description: 'Item added to saved basket' })
  async addItem(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: AddCartItemDto,
  ) {
    return this.cartService.addItem(user.id, dto);
  }

  @Patch('items/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update quantity or notes for a saved basket item' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Saved basket item updated' })
  async updateItem(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: UpdateCartItemDto,
  ) {
    return this.cartService.updateItem(user.id, id, dto);
  }

  @Delete('items/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Remove an item from the saved basket' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 200, description: 'Saved basket item removed' })
  async removeItem(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    return this.cartService.removeItem(user.id, id);
  }

  @Delete()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Clear all items from the saved basket' })
  @ApiResponse({ status: 200, description: 'Saved basket cleared' })
  async clearCart(@CurrentUser() user: AuthenticatedUser) {
    return this.cartService.clearCart(user.id);
  }
}
