import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { SellerCenterService } from './seller-center.service';
import { SellerDealStatus } from './dto/seller-center.dto';

describe('SellerCenterService (Security, CRM & Analytics)', () => {
  const sellerAUserId = '11111111-1111-4111-8111-111111111111';
  const sellerAAccountId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const sellerBAccountId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

  it('rejects users without an active approved seller account', async () => {
    const mockPrisma: any = {
      account: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const svc = new SellerCenterService(mockPrisma);

    await expect(svc.getDashboard(sellerAUserId)).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('blocks creating a CRM deal on another seller listing (object-level isolation)', async () => {
    const mockPrisma: any = {
      account: {
        findMany: jest.fn().mockResolvedValue([{ id: sellerAAccountId }]),
      },
      listing: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'listing-b',
          accountId: sellerBAccountId,
          price: 100000,
          currency: 'EGP',
          deletedAt: null,
        }),
      },
    };
    const svc = new SellerCenterService(mockPrisma);

    await expect(
      svc.createDeal(sellerAUserId, {
        listingId: 'listing-b',
        customerName: 'Ahmed',
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('blocks updating or deleting another seller CRM deal', async () => {
    const mockPrisma: any = {
      account: {
        findMany: jest.fn().mockResolvedValue([{ id: sellerAAccountId }]),
      },
      sellerDeal: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'deal-b',
          sellerAccountId: sellerBAccountId,
          status: SellerDealStatus.NEW_INQUIRY,
        }),
      },
    };
    const svc = new SellerCenterService(mockPrisma);

    await expect(
      svc.updateDeal(sellerAUserId, 'deal-b', {
        status: SellerDealStatus.COMPLETED,
      }),
    ).rejects.toThrow(ForbiddenException);

    await expect(svc.deleteDeal(sellerAUserId, 'deal-b')).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('creates and updates seller-reported CRM deal with completedAt and audit log', async () => {
    const auditMock: any = { logEvent: jest.fn().mockResolvedValue(undefined) };
    const mockPrisma: any = {
      account: {
        findMany: jest.fn().mockResolvedValue([{ id: sellerAAccountId }]),
      },
      listing: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'listing-a',
          accountId: sellerAAccountId,
          price: 2500000,
          currency: 'EGP',
          deletedAt: null,
        }),
      },
      sellerDeal: {
        create: jest.fn().mockResolvedValue({
          id: 'deal-1',
          sellerAccountId: sellerAAccountId,
          listingId: 'listing-a',
          customerName: 'Mostafa',
          initialPrice: 2500000,
          agreedPrice: 2400000,
          currency: 'EGP',
          status: SellerDealStatus.NEGOTIATING,
          sellerReportedOnly: true,
          notes: 'Buyer requested viewing',
          completedAt: null,
          createdAt: new Date(),
          updatedAt: new Date(),
          listing: { id: 'listing-a', title: 'Luxury Flat', media: [] },
        }),
        findUnique: jest.fn().mockResolvedValue({
          id: 'deal-1',
          sellerAccountId: sellerAAccountId,
          status: SellerDealStatus.NEGOTIATING,
          completedAt: null,
        }),
        update: jest.fn().mockResolvedValue({
          id: 'deal-1',
          sellerAccountId: sellerAAccountId,
          listingId: 'listing-a',
          customerName: 'Mostafa',
          initialPrice: 2500000,
          agreedPrice: 2400000,
          currency: 'EGP',
          status: SellerDealStatus.COMPLETED,
          sellerReportedOnly: true,
          notes: 'Signed off-platform',
          completedAt: new Date(),
          createdAt: new Date(),
          updatedAt: new Date(),
          listing: { id: 'listing-a', title: 'Luxury Flat', media: [] },
        }),
      },
    };

    const svc = new SellerCenterService(mockPrisma, auditMock);
    const created = await svc.createDeal(sellerAUserId, {
      listingId: 'listing-a',
      customerName: 'Mostafa',
      agreedPrice: 2400000,
      status: SellerDealStatus.NEGOTIATING,
      notes: 'Buyer requested viewing',
    });

    expect(created.sellerReportedOnly).toBe(true);
    expect(created.initialPrice).toBe(2500000);
    expect(auditMock.logEvent).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'SELLER_CRM_DEAL_CREATED' }),
    );

    const updated = await svc.updateDeal(sellerAUserId, 'deal-1', {
      status: SellerDealStatus.COMPLETED,
      notes: 'Signed off-platform',
    });
    expect(updated.status).toBe(SellerDealStatus.COMPLETED);
    expect(updated.completedAt).toBeTruthy();
  });

  it('computes real analytics without synthetic values and accurate response rate', async () => {
    const now = new Date('2026-11-27T12:00:00Z');
    const mockPrisma: any = {
      account: {
        findMany: jest.fn().mockResolvedValue([{ id: sellerAAccountId }]),
      },
      listing: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'l-1',
            title: 'Apartment 1',
            price: 2000000,
            currency: 'EGP',
            publicationStatus: 'published',
            availabilityStatus: 'available',
            viewsCount: 120,
            contactRevealsCount: 5,
            _count: { favorites: 8, conversations: 2 },
          },
        ]),
      },
      favorite: { count: jest.fn().mockResolvedValue(8) },
      conversation: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'c-1', createdAt: now, messages: [{ id: 'm-1' }] },
          { id: 'c-2', createdAt: now, messages: [] },
        ]),
      },
      booking: { count: jest.fn().mockResolvedValue(3) },
      sellerDeal: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'd-1', status: SellerDealStatus.COMPLETED, createdAt: now },
          { id: 'd-2', status: SellerDealStatus.NEW_INQUIRY, createdAt: now },
        ]),
      },
    };

    const svc = new SellerCenterService(mockPrisma);
    const analytics = await svc.getAnalytics(sellerAUserId, { range: '30d' });

    expect(analytics.metrics).toEqual({
      totalAds: 1,
      activeAds: 1,
      totalViews: 120,
      totalFavorites: 8,
      customerInquiries: 10, // 2 conv + 3 bookings + 5 contact reveals
      conversationsCount: 2,
      completedSellerReportedDeals: 1,
      responseRatePercent: 50,
    });
    expect(analytics.dailySeries).toHaveLength(1);
    expect(analytics.dailySeries[0]).toEqual({
      date: '2026-11-27',
      inquiries: 2,
      deals: 2,
    });
  });

  it('throws NotFoundException when updating a non-existent deal', async () => {
    const mockPrisma: any = {
      account: {
        findMany: jest.fn().mockResolvedValue([{ id: sellerAAccountId }]),
      },
      sellerDeal: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const svc = new SellerCenterService(mockPrisma);

    await expect(
      svc.updateDeal(sellerAUserId, 'missing-id', { notes: 'x' }),
    ).rejects.toThrow(NotFoundException);
  });
});
