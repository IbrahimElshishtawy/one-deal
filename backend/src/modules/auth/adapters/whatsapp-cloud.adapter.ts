import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ISmsGatewayAdapter, SmsDeliveryResult } from './sms-gateway.interface';
import { SmsMisrAdapter } from './sms-misr.adapter';

/**
 * Meta WhatsApp Business Cloud API adapter for OTP verification.
 * Sends pre-approved Authentication templates (body + optional copy_code button)
 * via Graph API (`https://graph.facebook.com/{version}/{phoneNumberId}/messages`).
 */
@Injectable()
export class WhatsAppCloudAdapter implements ISmsGatewayAdapter {
  readonly providerName = 'WHATSAPP_CLOUD';
  private readonly logger = new Logger(WhatsAppCloudAdapter.name);

  private readonly phoneNumberId: string;
  private readonly accessToken: string;
  private readonly templateName: string;
  private readonly templateLang: string;
  private readonly apiVersion: string;
  private readonly includeCopyButton: boolean;
  private readonly fallbackToSms: boolean;

  constructor(
    private readonly configService: ConfigService,
    @Optional() private readonly smsMisrFallback?: SmsMisrAdapter,
  ) {
    this.phoneNumberId =
      this.configService.get<string>('WHATSAPP_PHONE_NUMBER_ID') || '';
    this.accessToken =
      this.configService.get<string>('WHATSAPP_ACCESS_TOKEN') || '';
    this.templateName =
      this.configService.get<string>('WHATSAPP_TEMPLATE_NAME') || 'auth_otp';
    this.templateLang =
      this.configService.get<string>('WHATSAPP_TEMPLATE_LANG') || 'en_US';
    this.apiVersion =
      this.configService.get<string>('WHATSAPP_API_VERSION') || 'v21.0';
    this.includeCopyButton =
      this.configService.get<boolean>('WHATSAPP_INCLUDE_COPY_BUTTON', true) ??
      true;
    this.fallbackToSms =
      this.configService.get<boolean>('WHATSAPP_FALLBACK_TO_SMS', false) ??
      false;
  }

  isConfigured(): boolean {
    return Boolean(this.phoneNumberId && this.accessToken);
  }

  isPlaceholder(): boolean {
    return (
      this.phoneNumberId.includes('placeholder') ||
      this.accessToken.includes('placeholder')
    );
  }

  async sendOtp(phone: string, code: string): Promise<SmsDeliveryResult> {
    if (!this.isConfigured() || this.isPlaceholder()) {
      this.logger.error(
        'WhatsApp Cloud API credentials (WHATSAPP_PHONE_NUMBER_ID / WHATSAPP_ACCESS_TOKEN) are missing.',
      );
      return this.tryFallbackOrFail(
        phone,
        code,
        'WhatsApp Cloud API credentials missing.',
      );
    }

    const recipient = phone.replace(/^\+/, '');
    const endpoint = `https://graph.facebook.com/${this.apiVersion}/${this.phoneNumberId}/messages`;

    const components: Array<Record<string, unknown>> = [
      {
        type: 'body',
        parameters: [{ type: 'text', text: code }],
      },
    ];

    if (this.includeCopyButton) {
      components.push({
        type: 'button',
        sub_type: 'url',
        index: '0',
        parameters: [{ type: 'text', text: code }],
      });
    }

    const payload = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: recipient,
      type: 'template',
      template: {
        name: this.templateName,
        language: { code: this.templateLang },
        components,
      },
    };

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      const data = (await response.json()) as {
        messages?: Array<{ id?: string }>;
        error?: { message?: string; code?: number };
      };

      if (!response.ok || !data?.messages?.[0]?.id) {
        const errMsg =
          data?.error?.message || `WhatsApp API HTTP ${response.status}`;
        this.logger.error(
          `WhatsApp Cloud API delivery failed (${response.status}): ${errMsg}`,
        );
        return this.tryFallbackOrFail(phone, code, errMsg);
      }

      return {
        success: true,
        provider: this.providerName,
        messageId: data.messages[0].id,
      };
    } catch (err: any) {
      this.logger.error(
        `Failed to reach WhatsApp Cloud API endpoint: ${err.message}`,
      );
      return this.tryFallbackOrFail(
        phone,
        code,
        `Network failure connecting to WhatsApp Cloud API: ${err.message}`,
      );
    }
  }

  private async tryFallbackOrFail(
    phone: string,
    code: string,
    reason: string,
  ): Promise<SmsDeliveryResult> {
    if (
      this.fallbackToSms &&
      this.smsMisrFallback?.isConfigured() &&
      !this.smsMisrFallback.isPlaceholder()
    ) {
      this.logger.warn(
        `WhatsApp OTP failed (${reason}); falling back to SMS Misr for ${phone}`,
      );
      return this.smsMisrFallback.sendOtp(phone, code);
    }

    return {
      success: false,
      provider: this.providerName,
      error: reason,
    };
  }
}
