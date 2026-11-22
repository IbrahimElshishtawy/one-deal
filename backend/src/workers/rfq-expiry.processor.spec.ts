import { Test, TestingModule } from '@nestjs/testing';
import { RfqExpiryProcessor } from './rfq-expiry.processor';
import { PrismaService } from '../core/database/prisma.service';
import { QuotationStatus, RfqStatus } from '../modules/rfq/rfq.enums';

describe('RfqExpiryProcessor', () => {
  let processor: RfqExpiryProcessor;

  const mockPrisma = {
    rfqRequest: {
      updateMany: jest.fn(),
    },
    quotation: {
      updateMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RfqExpiryProcessor,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    processor = module.get<RfqExpiryProcessor>(RfqExpiryProcessor);
    jest.clearAllMocks();
  });

  it('should expire past-due open RFQs and quotations', async () => {
    mockPrisma.rfqRequest.updateMany.mockResolvedValue({ count: 2 });
    mockPrisma.quotation.updateMany.mockResolvedValue({ count: 3 });

    const result = await processor.processExpiredRfqsAndQuotations();

    expect(result).toEqual({ expiredRfqs: 2, expiredQuotations: 3 });
    expect(mockPrisma.rfqRequest.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { status: RfqStatus.EXPIRED },
      }),
    );
    expect(mockPrisma.quotation.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { status: QuotationStatus.EXPIRED },
      }),
    );
  });

  it('should absorb database errors gracefully', async () => {
    mockPrisma.rfqRequest.updateMany.mockRejectedValue(
      new Error('DB connection lost'),
    );

    const result = await processor.processExpiredRfqsAndQuotations();
    expect(result).toEqual({ expiredRfqs: 0, expiredQuotations: 0 });
  });
});
