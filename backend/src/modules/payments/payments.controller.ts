import {
  Controller,
  Get,
  Post,
  Body,
  Query,
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
import { PaymentsService } from './payments.service';
import { CheckoutDto } from './dto/checkout.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';
import { SellerCapability } from '../../core/enums/domain.enums';
import { SellerAuthorizationGuard } from '../accounts/guards/seller-authorization.guard';
import { RequireSellerCapability } from '../accounts/decorators/require-seller-capability.decorator';

@ApiTags('Payments & Promotions')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Get('packages')
  @ApiOperation({ summary: 'List available promotion packages' })
  @ApiResponse({ status: 200, description: 'Packages returned' })
  async getPackages() {
    return this.paymentsService.getPromotionPackages();
  }

  @Post('checkout')
  @ApiBearerAuth('BearerAuth')
  @UseGuards(JwtAuthGuard, SellerAuthorizationGuard)
  @RequireSellerCapability(SellerCapability.CAN_MANAGE_LISTING)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Initiate Paymob payment session for a promotion' })
  @ApiResponse({ status: 200, description: 'Checkout session created' })
  async checkout(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CheckoutDto,
  ) {
    return this.paymentsService.initiateCheckout(user.id, dto);
  }

  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Paymob payment transaction callback webhook' })
  @ApiResponse({ status: 200, description: 'Webhook processed' })
  async webhook(@Body() payload: any, @Query('hmac') hmac?: string) {
    return this.paymentsService.handlePaymobWebhook(payload, hmac);
  }
}
