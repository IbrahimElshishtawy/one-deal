import { ConfigService } from '@nestjs/config';
import { MockSmsAdapter } from './mock-sms.adapter';
import { SmsMisrAdapter } from './sms-misr.adapter';
import { WhatsAppCloudAdapter } from './whatsapp-cloud.adapter';

describe('SMS & WhatsApp Gateway Adapters', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('MockSmsAdapter', () => {
    it('should deliver SMS in test/dev mode and record code in memory', async () => {
      const configService = {
        get: jest.fn((key: string) => {
          if (key === 'NODE_ENV') return 'test';
          return undefined;
        }),
      } as unknown as ConfigService;

      const adapter = new MockSmsAdapter(configService);
      const result = await adapter.sendOtp('+201012345678', '654321');

      expect(result.success).toBe(true);
      expect(result.provider).toBe('MOCK_DEV_GATEWAY');
      expect(result.messageId).toBeDefined();
      expect(adapter.getLastSentCode('+201012345678')).toBe('654321');
    });

    it('should refuse to deliver and fail safely in production mode', async () => {
      const configService = {
        get: jest.fn((key: string) => {
          if (key === 'NODE_ENV') return 'production';
          return undefined;
        }),
      } as unknown as ConfigService;

      const adapter = new MockSmsAdapter(configService);
      const result = await adapter.sendOtp('+201012345678', '654321');

      expect(result.success).toBe(false);
      expect(result.error).toContain(
        'Mock SMS provider cannot be used in production',
      );
    });
  });

  describe('SmsMisrAdapter', () => {
    it('should report unconfigured if username/password are empty', () => {
      const configService = {
        get: jest.fn(() => ''),
      } as unknown as ConfigService;

      const adapter = new SmsMisrAdapter(configService);
      expect(adapter.isConfigured()).toBe(false);
    });

    it('should fail safely if sendOtp is called when unconfigured', async () => {
      const configService = {
        get: jest.fn(() => ''),
      } as unknown as ConfigService;

      const adapter = new SmsMisrAdapter(configService);
      const result = await adapter.sendOtp('+201012345678', '123456');

      expect(result.success).toBe(false);
      expect(result.error).toContain('SMS gateway credentials missing');
    });
  });

  describe('WhatsAppCloudAdapter', () => {
    it('should fail safely when WhatsApp Cloud API credentials are missing', async () => {
      const configService = {
        get: jest.fn((_k: string, def?: any) => def ?? ''),
      } as unknown as ConfigService;

      const adapter = new WhatsAppCloudAdapter(configService);
      expect(adapter.isConfigured()).toBe(false);

      const res = await adapter.sendOtp('+201223070571', '123456');
      expect(res.success).toBe(false);
      expect(res.provider).toBe('WHATSAPP_CLOUD');
    });

    it('should send Meta Authentication template with body & copy_code button via Graph API', async () => {
      const configService = {
        get: jest.fn((key: string, def?: any) => {
          const map: Record<string, any> = {
            WHATSAPP_PHONE_NUMBER_ID: '109876543210',
            WHATSAPP_ACCESS_TOKEN: 'EAAG_REAL_TOKEN',
            WHATSAPP_TEMPLATE_NAME: 'deal_one_otp',
            WHATSAPP_TEMPLATE_LANG: 'en_US',
            WHATSAPP_API_VERSION: 'v21.0',
            WHATSAPP_INCLUDE_COPY_BUTTON: true,
            WHATSAPP_FALLBACK_TO_SMS: false,
          };
          return map[key] ?? def;
        }),
      } as unknown as ConfigService;

      const fetchSpy = jest.spyOn(global, 'fetch').mockResolvedValue({
        ok: true,
        status: 200,
        json: async () => ({
          messages: [{ id: 'wamid.HBgLMjAxMjIzMDcwNTcx' }],
        }),
      } as any);

      const adapter = new WhatsAppCloudAdapter(configService);
      const res = await adapter.sendOtp('+201223070571', '987654');

      expect(res.success).toBe(true);
      expect(res.provider).toBe('WHATSAPP_CLOUD');
      expect(res.messageId).toBe('wamid.HBgLMjAxMjIzMDcwNTcx');

      const [url, init] = fetchSpy.mock.calls[0];
      expect(url).toBe(
        'https://graph.facebook.com/v21.0/109876543210/messages',
      );
      const body = JSON.parse(String((init as RequestInit).body));
      expect(body.to).toBe('201223070571');
      expect(body.template.name).toBe('deal_one_otp');
      expect(body.template.components).toHaveLength(2);
      expect(body.template.components[1]).toEqual({
        type: 'button',
        sub_type: 'url',
        index: '0',
        parameters: [{ type: 'text', text: '987654' }],
      });
    });

    it('should fallback to SMS Misr when WHATSAPP_FALLBACK_TO_SMS=true and WhatsApp API fails', async () => {
      const configService = {
        get: jest.fn((key: string, def?: any) => {
          const map: Record<string, any> = {
            WHATSAPP_PHONE_NUMBER_ID: '109876543210',
            WHATSAPP_ACCESS_TOKEN: 'EAAG_REAL_TOKEN',
            WHATSAPP_FALLBACK_TO_SMS: true,
          };
          return map[key] ?? def;
        }),
      } as unknown as ConfigService;

      jest.spyOn(global, 'fetch').mockResolvedValue({
        ok: false,
        status: 400,
        json: async () => ({ error: { message: 'Recipient not on WhatsApp' } }),
      } as any);

      const mockSmsMisr = {
        isConfigured: jest.fn().mockReturnValue(true),
        isPlaceholder: jest.fn().mockReturnValue(false),
        sendOtp: jest.fn().mockResolvedValue({
          success: true,
          provider: 'SMS_MISR',
          messageId: 'sms-1',
        }),
      } as unknown as SmsMisrAdapter;

      const adapter = new WhatsAppCloudAdapter(configService, mockSmsMisr);
      const res = await adapter.sendOtp('+201223070571', '987654');

      expect(res.success).toBe(true);
      expect(res.provider).toBe('SMS_MISR');
      expect(mockSmsMisr.sendOtp).toHaveBeenCalledWith(
        '+201223070571',
        '987654',
      );
    });
  });
});
