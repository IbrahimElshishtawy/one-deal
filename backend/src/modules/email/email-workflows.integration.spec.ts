import { ModerationService } from '../moderation/moderation.service';
import { OutboxPublisherProcessor } from '../../workers/outbox-publisher.processor';

describe('Email Business Workflow Integration', () => {
  describe('ModerationService listing approval & rejection emails', () => {
    it('sends listing approved email when owner has an email', async () => {
      const emailService = {
        getAppPublicUrl: jest.fn().mockReturnValue('https://dealone.eg'),
        sendListingApprovedEmail: jest
          .fn()
          .mockResolvedValue({ success: true }),
        sendListingRejectedEmail: jest
          .fn()
          .mockResolvedValue({ success: true }),
      } as any;

      const prisma = {
        listing: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'listing-1',
            accountId: 'acc-1',
            title: 'Apartment in Maadi',
            moderationStatus: 'pending',
            publicationStatus: 'unpublished',
            deletedAt: null,
          }),
        },
        account: {
          findUnique: jest.fn().mockResolvedValue({
            owner: {
              email: 'seller@example.com',
              fullName: 'Seller Name',
              preferredLanguage: 'en',
            },
          }),
        },
        $transaction: jest.fn(async (cb: any) =>
          cb({
            listing: {
              update: jest.fn().mockResolvedValue({
                id: 'listing-1',
                moderationStatus: 'approved',
                publicationStatus: 'published',
              }),
            },
            moderationLog: { create: jest.fn().mockResolvedValue({}) },
            auditLog: { create: jest.fn().mockResolvedValue({}) },
          }),
        ),
      } as any;

      const service = new ModerationService(prisma, emailService);
      const updated = await service.adjudicateListing('listing-1', 'mod-1', {
        action: 'approve',
      } as any);

      expect(updated.moderationStatus).toBe('approved');
      // Allow non-blocking microtask to settle
      await new Promise((r) => setImmediate(r));
      expect(emailService.sendListingApprovedEmail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'seller@example.com',
          listingTitle: 'Apartment in Maadi',
          locale: 'en',
        }),
      );
    });

    it('sends listing rejected email with reason and never breaks moderation if email fails', async () => {
      const emailService = {
        getAppPublicUrl: jest.fn().mockReturnValue('https://dealone.eg'),
        sendListingApprovedEmail: jest.fn(),
        sendListingRejectedEmail: jest
          .fn()
          .mockRejectedValue(new Error('Resend outage')),
      } as any;

      const prisma = {
        listing: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'listing-2',
            accountId: 'acc-1',
            title: 'Car Ad',
            moderationStatus: 'pending',
            publicationStatus: 'unpublished',
            deletedAt: null,
          }),
        },
        account: {
          findUnique: jest.fn().mockResolvedValue({
            owner: {
              email: 'seller@example.com',
              fullName: 'بائع',
              preferredLanguage: 'ar',
            },
          }),
        },
        $transaction: jest.fn(async (cb: any) =>
          cb({
            listing: {
              update: jest.fn().mockResolvedValue({
                id: 'listing-2',
                moderationStatus: 'rejected',
              }),
            },
            moderationLog: { create: jest.fn().mockResolvedValue({}) },
            auditLog: { create: jest.fn().mockResolvedValue({}) },
          }),
        ),
      } as any;

      const service = new ModerationService(prisma, emailService);
      const updated = await service.adjudicateListing('listing-2', 'mod-1', {
        action: 'reject',
        reasonCode: 'MISSING_PHOTOS',
        notes: 'Please add clear photos',
      } as any);

      expect(updated.moderationStatus).toBe('rejected');
      await new Promise((r) => setImmediate(r));
      expect(emailService.sendListingRejectedEmail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'seller@example.com',
          reasonCode: 'MISSING_PHOTOS',
          reasonNotes: 'Please add clear photos',
          locale: 'ar',
        }),
      );
    });
  });

  describe('OutboxPublisherProcessor PAYMENT_SUCCEEDED receipt email', () => {
    it('sends payment receipt email on PAYMENT_SUCCEEDED outbox event without failing outbox on email error', async () => {
      const emailService = {
        sendPaymentReceiptEmail: jest
          .fn()
          .mockRejectedValue(new Error('Provider timeout')),
      } as any;

      const prisma = {
        outboxEvent: {
          findMany: jest.fn().mockResolvedValue([
            {
              id: 'evt-1',
              eventType: 'PAYMENT_SUCCEEDED',
              payload: { paymentId: 'pay-1', transactionId: 'tx-123' },
            },
          ]),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          update: jest.fn().mockResolvedValue({}),
        },
        payment: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'pay-1',
            amountEgp: 150,
            currency: 'EGP',
            gatewayTransactionId: 'tx-123',
            updatedAt: new Date('2026-11-19T12:00:00Z'),
            user: {
              email: 'payer@example.com',
              fullName: 'Payer',
              preferredLanguage: 'en',
            },
            package: { nameAr: 'مميز', nameEn: 'Featured' },
            listing: { title: 'Villa in Zayed' },
          }),
        },
      } as any;

      const notificationProcessor = {
        processNotificationJob: jest.fn(),
      } as any;
      const processor = new OutboxPublisherProcessor(
        prisma,
        notificationProcessor,
        emailService,
      );

      const res = await processor.publishPendingEvents(10);
      expect(res.publishedCount).toBe(1);
      expect(res.failedCount).toBe(0);
      expect(emailService.sendPaymentReceiptEmail).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'payer@example.com',
          amountEgp: '150',
          currency: 'EGP',
          idempotencyKey: 'payment-receipt-pay-1',
        }),
      );
    });
  });
});
