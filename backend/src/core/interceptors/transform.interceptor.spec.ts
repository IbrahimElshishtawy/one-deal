import { TransformInterceptor } from './transform.interceptor';
import { of } from 'rxjs';

describe('TransformInterceptor', () => {
  let interceptor: TransformInterceptor<any>;

  beforeEach(() => {
    interceptor = new TransformInterceptor();
  });

  it('should wrap raw response in { success: true, data: ... }', (done) => {
    const rawData = { id: 'item-1', title: 'Car for sale' };
    const mockContext: any = {};
    const mockCallHandler: any = {
      handle: () => of(rawData),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe({
      next: (val) => {
        expect(val).toEqual({
          success: true,
          data: rawData,
        });
        done();
      },
      error: done.fail,
    });
  });

  it('should preserve meta when returned in { data, meta } structure', (done) => {
    const responseWithMeta = {
      data: [{ id: 1 }, { id: 2 }],
      meta: { total_count: 2, next_cursor: 'abc123cursor' },
    };
    const mockContext: any = {};
    const mockCallHandler: any = {
      handle: () => of(responseWithMeta),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe({
      next: (val) => {
        expect(val).toEqual({
          success: true,
          data: [{ id: 1 }, { id: 2 }],
          meta: { total_count: 2, next_cursor: 'abc123cursor' },
        });
        done();
      },
      error: done.fail,
    });
  });

  it('should not double-wrap if response already has success and data properties', (done) => {
    const preWrapped = {
      success: true,
      data: { custom: 'payload' },
    };
    const mockContext: any = {};
    const mockCallHandler: any = {
      handle: () => of(preWrapped),
    };

    interceptor.intercept(mockContext, mockCallHandler).subscribe({
      next: (val) => {
        expect(val).toEqual(preWrapped);
        done();
      },
      error: done.fail,
    });
  });

  it('should preserve Flutter listings feed contract without redundant items field', (done) => {
    const feedPayload = {
      data: [{ id: 'listing-1', title: 'Toyota Corolla', sellerPhone: null }],
      meta: {
        nextCursor: '2026-11-18T00:00:00.000Z',
        next_cursor: '2026-11-18T00:00:00.000Z',
        limit: 20,
        hasMore: true,
      },
    };
    interceptor
      .intercept({} as any, { handle: () => of(feedPayload) })
      .subscribe({
        next: (val) => {
          expect(val).toEqual({
            success: true,
            data: feedPayload.data,
            meta: feedPayload.meta,
          });
          expect((val as any).items).toBeUndefined();
          done();
        },
        error: done.fail,
      });
  });
});
