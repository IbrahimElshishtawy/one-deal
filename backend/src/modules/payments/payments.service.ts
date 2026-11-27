import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  UnauthorizedException,
  BadRequestException,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PaymentStatus, PromoType } from '../../core/enums/domain.enums';
import { PrismaService } from '../../core/database/prisma.service';
import { CheckoutDto } from './dto/checkout.dto';

const STATIC_PACKAGES = [
  {
    id: 'BUMP_UP',
    nameAr: 'رفع الإعلان إلى المقدمة',
    nameEn: 'Bump to Top',
    type: PromoType.BUMP_UP,
    priceEgp: 35.0,
    durationDays: 0,
    isActive: true,
  },
  {
    id: 'FEATURED_7_DAYS',
    nameAr: 'إعلان مميز لمدة 7 أيام',
    nameEn: 'Featured Ad (7 Days)',
    type: PromoType.FEATURED_7_DAYS,
    priceEgp: 120.0,
    durationDays: 7,
    isActive: true,
  },
  {
    id: 'FEATURED_14_DAYS',
    nameAr: 'إعلان مميز لمدة 14 يوماً',
    nameEn: 'Featured Ad (14 Days)',
    type: PromoType.FEATURED_14_DAYS,
    priceEgp: 200.0,
    durationDays: 14,
    isActive: true,
  },
];

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private readonly hmacSecret: string;
  private readonly apiKey: string;
  private readonly integrationIdCard: number;
  private readonly iframeId: string;
  private readonly nodeEnv: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.hmacSecret = this.configService.get<string>(
      'PAYMOB_HMAC_SECRET',
      'test_hmac_secret',
    );
    this.apiKey = this.configService.get<string>('PAYMOB_API_KEY', '');
    this.integrationIdCard = Number(
      this.configService.get<number>('PAYMOB_INTEGRATION_ID_CARD', 0),
    );
    this.iframeId = this.configService.get<string>('PAYMOB_IFRAME_ID', '12345');
    this.nodeEnv = this.configService.get<string>('NODE_ENV', 'development');
  }

  private hasRealPaymobCredentials(): boolean {
    return (
      !!this.apiKey &&
      !this.apiKey.startsWith('placeholder') &&
      this.integrationIdCard > 0
    );
  }

  /**
   * Retrieves active promotion packages and their prices in EGP.
   */
  async getPromotionPackages() {
    if (this.prisma.promotionPackage?.findMany) {
      const dbPackages = await this.prisma.promotionPackage.findMany({
        where: { isActive: true },
        orderBy: { priceEgp: 'asc' },
      });
      if (dbPackages.length > 0) {
        return dbPackages;
      }
    }
    return STATIC_PACKAGES.filter((p) => p.isActive);
  }

  /**
   * Initiates payment checkout with authoritative server pricing and Paymob 3-step tokenization.
   */
  async initiateCheckout(userId: string, dto: CheckoutDto) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: dto.listingId },
      include: { account: { include: { owner: true } } },
    });

    if (!listing) {
      throw new NotFoundException('Listing not found');
    }

    const ownerId = listing.account?.ownerUserId ?? (listing as any).userId;
    if (ownerId && ownerId !== userId) {
      throw new ForbiddenException(
        'You can only purchase promotions for your own listings',
      );
    }

    let pkg: any = null;
    if (this.prisma.promotionPackage?.findUnique) {
      pkg = await this.prisma.promotionPackage.findUnique({
        where: { id: dto.packageId },
      });
    }
    if (!pkg) {
      pkg = STATIC_PACKAGES.find((p) => p.id === dto.packageId);
    }

    if (!pkg || !pkg.isActive) {
      throw new BadRequestException(
        'Selected promotion package is invalid or inactive',
      );
    }

    let paymentId: string = crypto.randomUUID();
    if (this.prisma.payment?.create) {
      const created = await this.prisma.payment.create({
        data: {
          userId,
          listingId: listing.id,
          packageId: pkg.id,
          amountEgp: pkg.priceEgp,
          status: PaymentStatus.PENDING,
        },
      });
      paymentId = created.id;
    }

    let checkoutUrl: string;
    if (this.hasRealPaymobCredentials()) {
      checkoutUrl = await this.createPaymobIframeUrl(
        paymentId,
        Math.round(Number(pkg.priceEgp) * 100),
        listing.account?.owner?.phone || '+201000000000',
        listing.account?.owner?.fullName || 'DealOne User',
      );
    } else if (this.nodeEnv === 'production') {
      throw new InternalServerErrorException(
        'Paymob API credentials are missing in production environment',
      );
    } else {
      const mockOrderToken = crypto.randomBytes(16).toString('hex');
      checkoutUrl = `https://accept.paymob.com/api/acceptance/iframes/${this.iframeId}?payment_token=${mockOrderToken}&order_id=${paymentId}`;
    }

    return {
      paymentId,
      amountEgp: Number(pkg.priceEgp),
      packageName: pkg.nameAr,
      checkoutUrl,
    };
  }

  private async createPaymobIframeUrl(
    merchantOrderId: string,
    amountCents: number,
    phone: string,
    fullName: string,
  ): Promise<string> {
    const authRes = await fetch('https://accept.paymob.com/api/auth/tokens', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: this.apiKey }),
    });
    const authData = (await authRes.json()) as { token?: string };
    if (!authRes.ok || !authData.token) {
      throw new InternalServerErrorException('Paymob authentication failed');
    }

    const orderRes = await fetch(
      'https://accept.paymob.com/api/ecommerce/orders',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          auth_token: authData.token,
          delivery_needed: 'false',
          amount_cents: amountCents,
          currency: 'EGP',
          merchant_order_id: merchantOrderId,
          items: [],
        }),
      },
    );
    const orderData = (await orderRes.json()) as { id?: number };
    if (!orderRes.ok || !orderData.id) {
      throw new InternalServerErrorException(
        'Paymob order registration failed',
      );
    }

    const [firstName, ...rest] = fullName.split(' ');
    const keyRes = await fetch(
      'https://accept.paymob.com/api/acceptance/payment_keys',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          auth_token: authData.token,
          amount_cents: amountCents,
          expiration: 3600,
          order_id: orderData.id,
          currency: 'EGP',
          integration_id: this.integrationIdCard,
          billing_data: {
            first_name: firstName || 'DealOne',
            last_name: rest.join(' ') || 'User',
            phone_number: phone,
            email: 'noreply@marketspace.eg',
            apartment: 'NA',
            floor: 'NA',
            street: 'NA',
            building: 'NA',
            shipping_method: 'NA',
            postal_code: 'NA',
            city: 'Cairo',
            country: 'EG',
            state: 'Cairo',
          },
        }),
      },
    );
    const keyData = (await keyRes.json()) as { token?: string };
    if (!keyRes.ok || !keyData.token) {
      throw new InternalServerErrorException('Paymob payment key failed');
    }

    return `https://accept.paymob.com/api/acceptance/iframes/${this.iframeId}?payment_token=${keyData.token}`;
  }

  /**
   * Verifies Paymob HMAC signature, processes callback idempotently, and applies promotion entitlements.
   */
  async handlePaymobWebhook(payload: any, incomingHmac?: string) {
    const obj = payload?.obj || payload;
    const hasRealSecret =
      !!this.hmacSecret &&
      this.hmacSecret !== 'test_hmac_secret' &&
      !this.hmacSecret.startsWith('placeholder');

    if (hasRealSecret || this.nodeEnv === 'production') {
      if (!incomingHmac || !hasRealSecret) {
        throw new UnauthorizedException('Missing Paymob HMAC signature');
      }
      const isValid = this.verifyHmac(obj, incomingHmac);
      if (!isValid) {
        throw new UnauthorizedException('Invalid Paymob HMAC signature');
      }
    } else if (incomingHmac) {
      const isValid = this.verifyHmac(obj, incomingHmac);
      if (!isValid) {
        throw new UnauthorizedException('Invalid Paymob HMAC signature');
      }
    }

    const transactionId = String(obj?.id || payload?.id);
    const isSuccess = Boolean(obj?.success ?? payload?.success);
    const orderId = String(
      obj?.order?.merchant_order_id ||
        obj?.order?.id ||
        payload?.order_id ||
        '',
    );

    if (this.prisma.payment?.findFirst) {
      const existingPayment = await this.prisma.payment.findFirst({
        where: { gatewayTransactionId: transactionId },
      });

      if (existingPayment && existingPayment.status === PaymentStatus.SUCCESS) {
        this.logger.log(
          `Payment transaction ${transactionId} already processed (Idempotency check).`,
        );
        return { success: true, processed: false };
      }

      const payment = await this.prisma.payment.findFirst({
        where: {
          OR: [
            { gatewayTransactionId: transactionId },
            ...(orderId.length === 36 ? [{ id: orderId }] : []),
          ],
        },
        include: { package: true },
      });

      if (!payment) {
        this.logger.warn(`No pending payment found for order: ${orderId}`);
        return { success: false, processed: false };
      }

      if (!isSuccess) {
        await this.prisma.payment.update({
          where: { id: payment.id },
          data: {
            status: PaymentStatus.FAILED,
            gatewayTransactionId: transactionId,
            rawResponse: obj as any,
          },
        });
        return { success: false, status: 'FAILED', processed: false };
      }

      const durationDays = payment.package?.durationDays ?? 0;
      const now = new Date();
      const promotedUntil =
        durationDays > 0
          ? new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000)
          : undefined;

      const processedInTx = await this.prisma.$transaction(async (tx) => {
        // Atomic idempotency guard: only transition PENDING -> SUCCESS once
        if (typeof tx.payment?.updateMany === 'function') {
          const claimed = await tx.payment.updateMany({
            where: {
              id: payment.id,
              status: PaymentStatus.PENDING,
            },
            data: {
              status: PaymentStatus.SUCCESS,
              gatewayTransactionId: transactionId,
              rawResponse: obj as any,
            },
          });
          if (claimed.count === 0) {
            return false;
          }
        } else {
          await tx.payment.update({
            where: { id: payment.id },
            data: {
              status: PaymentStatus.SUCCESS,
              gatewayTransactionId: transactionId,
              rawResponse: obj as any,
            },
          });
        }

        await tx.listing.update({
          where: { id: payment.listingId },
          data: {
            refreshedAt: now,
            ...(promotedUntil ? { promotedUntil } : {}),
          },
        });

        if ((tx as any).outboxEvent?.create) {
          await (tx as any).outboxEvent.create({
            data: {
              aggregateType: 'Payment',
              aggregateId: payment.id,
              eventType: 'PAYMENT_SUCCEEDED',
              payload: {
                paymentId: payment.id,
                listingId: payment.listingId,
                packageId: payment.packageId,
                transactionId,
              },
            },
          });
        }

        return true;
      });

      if (!processedInTx) {
        this.logger.log(
          `Payment ${payment.id} already transitioned from PENDING (atomic idempotency guard).`,
        );
        return { success: true, processed: false };
      }
    }

    this.logger.log(
      `✅ Payment transaction ${transactionId} processed successfully`,
    );
    return { success: true, processed: true };
  }

  verifyHmac(obj: any, incomingHmac: string): boolean {
    const fields = [
      obj.amount_cents,
      obj.created_at,
      obj.currency,
      obj.error_occured,
      obj.has_parent_transaction,
      obj.id,
      obj.integration_id,
      obj.is_3d_secure,
      obj.is_auth,
      obj.is_capture,
      obj.is_refunded,
      obj.is_standalone_payment,
      obj.is_voided,
      obj.order?.id,
      obj.owner,
      obj.pending,
      obj.source_data?.pan,
      obj.source_data?.sub_type,
      obj.source_data?.type,
      obj.success,
    ];

    const concatenated = fields
      .map((f) => (f !== undefined && f !== null ? String(f) : ''))
      .join('');
    const calculated = crypto
      .createHmac('sha512', this.hmacSecret)
      .update(concatenated)
      .digest('hex');

    const expectedBuf = Buffer.from(calculated, 'hex');
    const actualBuf = Buffer.from(incomingHmac, 'hex');
    return (
      expectedBuf.length === actualBuf.length &&
      crypto.timingSafeEqual(expectedBuf, actualBuf)
    );
  }
}
