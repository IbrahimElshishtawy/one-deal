import { SetMetadata } from '@nestjs/common';
import { SellerCapability } from '../../../core/enums/domain.enums';

export const SELLER_CAPABILITY_KEY = 'seller_capability';

export const RequireSellerCapability = (capability: SellerCapability) =>
  SetMetadata(SELLER_CAPABILITY_KEY, capability);
