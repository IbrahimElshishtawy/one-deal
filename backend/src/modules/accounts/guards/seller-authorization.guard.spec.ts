import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SellerAuthorizationGuard } from './seller-authorization.guard';
import {
  SellerApplicationStatus,
  SellerCapability,
} from '../../../core/enums/domain.enums';

describe('SellerAuthorizationGuard', () => {
  let guard: SellerAuthorizationGuard;
  let reflector: { getAllAndOverride: jest.Mock };
  let prisma: {
    user: { findUnique: jest.Mock };
    account: { findFirst: jest.Mock };
    listing: { findUnique: jest.Mock };
  };
  let securityAudit: { logEvent: jest.Mock };

  const createContext = (reqOverrides: Record<string, any> = {}) => {
    const request = {
      user: { id: 'user-1', role: 'USER' },
      headers: { 'x-request-id': 'req-123', 'user-agent': 'jest' },
      ip: '127.0.0.1',
      method: 'POST',
      url: '/api/v1/listings',
      params: {},
      body: {},
      ...reqOverrides,
    };
    return {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: () => jest.fn(),
      getClass: () => jest.fn(),
    } as unknown as ExecutionContext;
  };

  beforeEach(() => {
    reflector = { getAllAndOverride: jest.fn() };
    prisma = {
      user: { findUnique: jest.fn() },
      account: { findFirst: jest.fn() },
      listing: { findUnique: jest.fn() },
    };
    securityAudit = { logEvent: jest.fn().mockResolvedValue(undefined) };
    guard = new SellerAuthorizationGuard(
      reflector as unknown as Reflector,
      prisma as any,
      securityAudit as any,
    );
  });

  it('denies PENDING seller from creating a listing and records audit log', async () => {
    reflector.getAllAndOverride.mockReturnValue(
      SellerCapability.CAN_CREATE_LISTING,
    );
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      isActive: true,
      deletedAt: null,
      moderationStatus: 'active',
      sellerStatus: SellerApplicationStatus.PENDING,
      sellerSuspendedAt: null,
    });

    await expect(guard.canActivate(createContext())).rejects.toThrow(
      ForbiddenException,
    );
    expect(securityAudit.logEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'UNAUTHORIZED_SELLER_OPERATION_ATTEMPTED',
        actorId: 'user-1',
      }),
    );
  });

  it('denies SUSPENDED seller from accessing seller dashboard', async () => {
    reflector.getAllAndOverride.mockReturnValue(
      SellerCapability.CAN_ACCESS_SELLER_DASHBOARD,
    );
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      isActive: true,
      deletedAt: null,
      moderationStatus: 'active',
      sellerStatus: SellerApplicationStatus.SUSPENDED,
      sellerSuspendedAt: new Date(),
    });

    await expect(guard.canActivate(createContext())).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('allows APPROVED seller with active approved Account to create listing', async () => {
    reflector.getAllAndOverride.mockReturnValue(
      SellerCapability.CAN_CREATE_LISTING,
    );
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      isActive: true,
      deletedAt: null,
      moderationStatus: 'active',
      sellerStatus: SellerApplicationStatus.APPROVED,
      sellerSuspendedAt: null,
    });
    prisma.account.findFirst.mockResolvedValue({ id: 'acc-1' });

    await expect(guard.canActivate(createContext())).resolves.toBe(true);
  });

  it('denies non-owner approved seller from managing another seller listing', async () => {
    reflector.getAllAndOverride.mockReturnValue(
      SellerCapability.CAN_MANAGE_LISTING,
    );
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-2',
      isActive: true,
      deletedAt: null,
      moderationStatus: 'active',
      sellerStatus: SellerApplicationStatus.APPROVED,
      sellerSuspendedAt: null,
    });
    prisma.listing.findUnique.mockResolvedValue({
      id: 'listing-1',
      deletedAt: null,
      account: {
        id: 'acc-1',
        ownerUserId: 'user-1',
        isActive: true,
        deletedAt: null,
        verificationStatus: 'approved',
        members: [],
      },
    });

    await expect(
      guard.canActivate(
        createContext({
          user: { id: 'user-2', role: 'USER' },
          params: { id: 'listing-1' },
        }),
      ),
    ).rejects.toThrow(ForbiddenException);
  });
});
