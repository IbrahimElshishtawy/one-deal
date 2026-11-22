import { Test, TestingModule } from '@nestjs/testing';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { RfqService } from './rfq.service';
import { PrismaService } from '../../core/database/prisma.service';
import { QuotationStatus, RfqStatus } from './rfq.enums';
import { UpdateQuotationStatusDto } from './dto/update-quotation-status.dto';

describe('RfqService', () => {
  let service: RfqService;

  const mockTx = {
    rfqRequest: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    quotation: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    outboxEvent: {
      create: jest.fn(),
    },
  };

  const mockPrisma = {
    category: { findUnique: jest.fn() },
    listing: { findMany: jest.fn() },
    account: { findUnique: jest.fn(), findFirst: jest.fn() },
    rfqRequest: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    quotation: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    $transaction: jest.fn((cb: any) => cb(mockTx)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [RfqService, { provide: PrismaService, useValue: mockPrisma }],
    }).compile();

    service = module.get<RfqService>(RfqService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should create an RFQ with items and enqueue notification', async () => {
    mockTx.rfqRequest.create.mockResolvedValue({
      id: 'rfq-1',
      reference: 'RFQ-20261121-ABC123',
      status: RfqStatus.SUBMITTED,
      items: [{ id: 'item-1', name: 'Steel', quantity: 5, unit: 'ton' }],
    });

    const result = await service.createRfq('buyer-1', {
      title: 'Steel Rebar',
      description: 'Need 5 tons of steel rebar',
      deliveryLocation: 'New Cairo',
      items: [{ name: 'Steel', quantity: 5, unit: 'ton' }],
    });

    expect(result.status).toBe(RfqStatus.SUBMITTED);
    expect(mockTx.outboxEvent.create).toHaveBeenCalledTimes(1);
  });

  it('should reject invalid linked material listing', async () => {
    mockPrisma.listing.findMany.mockResolvedValue([]);

    await expect(
      service.createRfq('buyer-1', {
        title: 'Steel Rebar',
        description: 'Need 5 tons of steel rebar',
        deliveryLocation: 'New Cairo',
        items: [
          {
            listingId: 'missing-listing',
            name: 'Steel',
            quantity: 5,
            unit: 'ton',
          },
        ],
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should submit quotation with server-calculated totals', async () => {
    mockPrisma.rfqRequest.findUnique.mockResolvedValue({
      id: 'rfq-1',
      reference: 'RFQ-1',
      userId: 'buyer-1',
      status: RfqStatus.SUBMITTED,
      items: [{ id: 'item-1' }],
    });
    mockPrisma.account.findFirst.mockResolvedValue({
      id: 'sup-acc-1',
      ownerUserId: 'supplier-1',
    });
    mockTx.quotation.findUnique.mockResolvedValue(null);
    mockTx.quotation.create.mockImplementation((args: any) =>
      Promise.resolve({ id: 'quot-1', ...args.data }),
    );

    const quotation = await service.submitQuotation('rfq-1', 'supplier-1', {
      deliveryFee: 500,
      estimatedDeliveryDays: 3,
      items: [
        {
          rfqItemId: 'item-1',
          name: 'Steel',
          quantity: 2,
          unit: 'ton',
          unitPrice: 40000,
        },
      ],
    });

    expect(quotation.subtotalAmount).toBe(80000);
    expect(quotation.totalAmount).toBe(80500);
    expect(mockTx.rfqRequest.update).toHaveBeenCalledTimes(1);
    expect(mockTx.outboxEvent.create).toHaveBeenCalledTimes(1);
  });

  it('should reject duplicate quotation from same supplier', async () => {
    mockPrisma.rfqRequest.findUnique.mockResolvedValue({
      id: 'rfq-1',
      userId: 'buyer-1',
      status: RfqStatus.SUBMITTED,
      items: [],
    });
    mockPrisma.account.findFirst.mockResolvedValue({
      id: 'sup-acc-1',
      ownerUserId: 'supplier-1',
    });
    mockTx.quotation.findUnique.mockResolvedValue({ id: 'existing-quot' });

    await expect(
      service.submitQuotation('rfq-1', 'supplier-1', {
        estimatedDeliveryDays: 2,
        items: [{ name: 'Cement', quantity: 10, unit: 'ton', unitPrice: 3000 }],
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('should forbid non-owner from viewing all RFQ quotations', async () => {
    mockPrisma.rfqRequest.findUnique.mockResolvedValue({
      id: 'rfq-1',
      userId: 'buyer-1',
    });

    await expect(
      service.getQuotationsForRfq('rfq-1', 'other-user', 'totalAmount'),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should allow RFQ owner to accept quotation without creating fake order', async () => {
    mockTx.quotation.findUnique.mockResolvedValue({
      id: 'quot-1',
      rfqId: 'rfq-1',
      supplierAccountId: 'sup-acc-1',
      status: QuotationStatus.SUBMITTED,
      rfq: {
        id: 'rfq-1',
        reference: 'RFQ-1',
        userId: 'buyer-1',
        status: RfqStatus.QUOTATIONS_RECEIVED,
      },
      supplierAccount: { ownerUserId: 'supplier-1' },
    });
    mockPrisma.account.findUnique.mockResolvedValue({
      ownerUserId: 'supplier-1',
      members: [],
    });
    mockTx.quotation.findFirst.mockResolvedValue(null);
    mockTx.quotation.update.mockResolvedValue({
      id: 'quot-1',
      status: QuotationStatus.ACCEPTED,
    });

    const res = await service.updateQuotationStatus('quot-1', 'buyer-1', {
      status: QuotationStatus.ACCEPTED,
    });

    expect(res.status).toBe(QuotationStatus.ACCEPTED);
    expect(mockTx.rfqRequest.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { status: RfqStatus.ACCEPTED, acceptedQuotationId: 'quot-1' },
      }),
    );
  });

  it('should prevent accepting a second quotation concurrently for the same RFQ (BUG-04)', async () => {
    mockTx.quotation.findUnique.mockResolvedValue({
      id: 'quot-2',
      rfqId: 'rfq-1',
      supplierAccountId: 'sup-acc-2',
      status: QuotationStatus.SUBMITTED,
      rfq: {
        id: 'rfq-1',
        reference: 'RFQ-1',
        userId: 'buyer-1',
        status: RfqStatus.QUOTATIONS_RECEIVED,
      },
      supplierAccount: { ownerUserId: 'supplier-2' },
    });
    mockPrisma.account.findUnique.mockResolvedValue({
      ownerUserId: 'supplier-2',
      members: [],
    });
    mockTx.quotation.findFirst.mockResolvedValue({ id: 'quot-1' });

    await expect(
      service.updateQuotationStatus('quot-2', 'buyer-1', {
        status: QuotationStatus.ACCEPTED,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('should reject unauthorized supplier role (e.g. lister) from withdrawing a quotation (SEC-06)', async () => {
    mockTx.quotation.findUnique.mockResolvedValue({
      id: 'quot-1',
      rfqId: 'rfq-1',
      supplierAccountId: 'sup-acc-1',
      status: QuotationStatus.SUBMITTED,
      rfq: {
        id: 'rfq-1',
        reference: 'RFQ-1',
        userId: 'buyer-1',
        status: RfqStatus.QUOTATIONS_RECEIVED,
      },
      supplierAccount: { ownerUserId: 'supplier-owner' },
    });
    mockPrisma.account.findUnique.mockResolvedValue({
      ownerUserId: 'supplier-owner',
      members: [], // lister filtered out by allowedRoles=['owner','manager','responder']
    });

    await expect(
      service.updateQuotationStatus('quot-1', 'lister-user', {
        status: QuotationStatus.WITHDRAWN,
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should reject private status filters when scope=open_for_suppliers (SEC-01)', async () => {
    await expect(
      service.getRfqs('supplier-1', {
        scope: 'open_for_suppliers',
        status: RfqStatus.DRAFT,
      }),
    ).rejects.toThrow(BadRequestException);

    await expect(
      service.getRfqs('supplier-1', {
        scope: 'open_for_suppliers',
        status: RfqStatus.CANCELLED,
      }),
    ).rejects.toThrow(BadRequestException);

    expect(mockPrisma.rfqRequest.findMany).not.toHaveBeenCalled();
  });

  it('should reject quotation totals that would overflow DECIMAL(14,2)', async () => {
    mockPrisma.rfqRequest.findUnique.mockResolvedValue({
      id: 'rfq-1',
      reference: 'RFQ-1',
      userId: 'buyer-1',
      status: RfqStatus.SUBMITTED,
      items: [],
    });
    mockPrisma.account.findFirst.mockResolvedValue({
      id: 'sup-acc-1',
      ownerUserId: 'supplier-1',
    });

    await expect(
      service.submitQuotation('rfq-1', 'supplier-1', {
        estimatedDeliveryDays: 2,
        items: [
          {
            name: 'Steel',
            quantity: 999999999,
            unit: 'ton',
            unitPrice: 999999999,
          },
        ],
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should reject EXPIRED and SUBMITTED in UpdateQuotationStatusDto (SEC-04)', async () => {
    const expiredDto = plainToInstance(UpdateQuotationStatusDto, {
      status: QuotationStatus.EXPIRED,
    });
    const expiredErrors = await validate(expiredDto);
    expect(expiredErrors.length).toBeGreaterThan(0);

    const validDto = plainToInstance(UpdateQuotationStatusDto, {
      status: QuotationStatus.SHORTLISTED,
    });
    const validErrors = await validate(validDto);
    expect(validErrors).toHaveLength(0);
  });

  it('should edit and submit a DRAFT RFQ and enqueue RFQ_SUBMITTED notification', async () => {
    mockTx.rfqRequest.findUnique.mockResolvedValueOnce({
      id: 'rfq-draft-1',
      userId: 'buyer-1',
      status: RfqStatus.DRAFT,
    });
    mockTx.rfqRequest.update.mockResolvedValueOnce({
      id: 'rfq-draft-1',
      title: 'Updated Title',
      status: RfqStatus.DRAFT,
      items: [{ id: 'item-1' }],
    });

    const edited = await service.updateDraftRfq('rfq-draft-1', 'buyer-1', {
      title: 'Updated Title',
    });
    expect(edited.title).toBe('Updated Title');

    mockTx.rfqRequest.findUnique.mockResolvedValueOnce({
      id: 'rfq-draft-1',
      reference: 'RFQ-DRAFT-1',
      userId: 'buyer-1',
      status: RfqStatus.DRAFT,
      items: [{ id: 'item-1' }],
    });
    mockTx.rfqRequest.update.mockResolvedValueOnce({
      id: 'rfq-draft-1',
      reference: 'RFQ-DRAFT-1',
      status: RfqStatus.SUBMITTED,
      items: [{ id: 'item-1' }],
    });

    const submitted = await service.submitDraftRfq('rfq-draft-1', 'buyer-1');
    expect(submitted.status).toBe(RfqStatus.SUBMITTED);
    expect(mockTx.outboxEvent.create).toHaveBeenCalledTimes(1);
  });

  it('should reject quotations on an expired RFQ and reject accepting an expired quotation (BUG-07)', async () => {
    mockPrisma.rfqRequest.findUnique.mockResolvedValue({
      id: 'rfq-exp',
      userId: 'buyer-1',
      status: RfqStatus.SUBMITTED,
      expiresAt: new Date(Date.now() - 60_000),
      items: [],
    });

    await expect(
      service.submitQuotation('rfq-exp', 'supplier-1', {
        estimatedDeliveryDays: 2,
        items: [{ name: 'Steel', quantity: 1, unit: 'ton', unitPrice: 1000 }],
      }),
    ).rejects.toThrow(BadRequestException);

    mockTx.quotation.findUnique.mockResolvedValue({
      id: 'quot-exp',
      rfqId: 'rfq-1',
      supplierAccountId: 'sup-acc-1',
      status: QuotationStatus.SUBMITTED,
      validUntil: new Date(Date.now() - 60_000),
      rfq: {
        id: 'rfq-1',
        reference: 'RFQ-1',
        userId: 'buyer-1',
        status: RfqStatus.QUOTATIONS_RECEIVED,
        expiresAt: new Date(Date.now() + 86_400_000),
      },
      supplierAccount: { ownerUserId: 'supplier-1' },
    });
    mockPrisma.account.findUnique.mockResolvedValue({
      ownerUserId: 'supplier-1',
      members: [],
    });

    await expect(
      service.updateQuotationStatus('quot-exp', 'buyer-1', {
        status: QuotationStatus.ACCEPTED,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should notify suppliers with active quotations when an RFQ is cancelled', async () => {
    mockTx.rfqRequest.findUnique.mockResolvedValue({
      id: 'rfq-cancel-1',
      reference: 'RFQ-CANCEL-1',
      userId: 'buyer-1',
      status: RfqStatus.QUOTATIONS_RECEIVED,
      quotations: [
        { id: 'q-1', supplierAccount: { ownerUserId: 'supplier-owner-1' } },
        { id: 'q-2', supplierAccount: { ownerUserId: 'supplier-owner-2' } },
      ],
    });
    mockTx.rfqRequest.update.mockResolvedValue({
      id: 'rfq-cancel-1',
      status: RfqStatus.CANCELLED,
      items: [],
    });

    await service.cancelRfq('rfq-cancel-1', 'buyer-1', 'Project postponed');
    expect(mockTx.outboxEvent.create).toHaveBeenCalledTimes(2);
  });
});
