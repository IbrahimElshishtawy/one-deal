import { HttpExceptionFilter } from './http-exception.filter';
import { HttpException, HttpStatus, BadRequestException } from '@nestjs/common';

describe('HttpExceptionFilter', () => {
  let filter: HttpExceptionFilter;

  beforeEach(() => {
    filter = new HttpExceptionFilter();
  });

  it('should format standard HttpException with code, message, and trace_id', () => {
    const mockSend = jest.fn();
    const mockStatus = jest.fn().mockReturnValue({ send: mockSend });
    const mockHeader = jest.fn();

    const mockHost: any = {
      switchToHttp: () => ({
        getResponse: () => ({
          status: mockStatus,
          header: mockHeader,
        }),
        getRequest: () => ({
          headers: { 'x-trace-id': 'test-trace-id-123' },
          raw: { traceId: 'test-trace-id-123' },
        }),
      }),
    };

    const exception = new HttpException(
      'Forbidden access',
      HttpStatus.FORBIDDEN,
    );
    filter.catch(exception, mockHost);

    expect(mockStatus).toHaveBeenCalledWith(HttpStatus.FORBIDDEN);
    expect(mockHeader).toHaveBeenCalledWith('x-trace-id', 'test-trace-id-123');
    expect(mockSend).toHaveBeenCalledWith({
      success: false,
      error: {
        code: 'FORBIDDEN',
        message: 'Forbidden access',
        details: null,
        trace_id: 'test-trace-id-123',
      },
    });
  });

  it('should format validation errors into VALIDATION_FAILED with field details', () => {
    const mockSend = jest.fn();
    const mockStatus = jest.fn().mockReturnValue({ send: mockSend });
    const mockHeader = jest.fn();

    const mockHost: any = {
      switchToHttp: () => ({
        getResponse: () => ({
          status: mockStatus,
          header: mockHeader,
        }),
        getRequest: () => ({
          headers: {},
          raw: { traceId: 'val-trace-456' },
        }),
      }),
    };

    const exception = new BadRequestException([
      'phone must be an Egyptian mobile number',
      'price must not be negative',
    ]);
    filter.catch(exception, mockHost);

    expect(mockStatus).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({
          code: 'VALIDATION_FAILED',
          message: 'Validation failed for one or more fields',
          details: [
            { issue: 'phone must be an Egyptian mobile number' },
            { issue: 'price must not be negative' },
          ],
          trace_id: 'val-trace-456',
        }),
      }),
    );
  });

  it('should format unhandled 500 error gracefully with trace_id', () => {
    const mockSend = jest.fn();
    const mockStatus = jest.fn().mockReturnValue({ send: mockSend });
    const mockHeader = jest.fn();

    const mockHost: any = {
      switchToHttp: () => ({
        getResponse: () => ({
          status: mockStatus,
          header: mockHeader,
        }),
        getRequest: () => ({
          headers: { 'x-trace-id': 'unhandled-trace-789' },
          raw: {},
        }),
      }),
    };

    const exception = new Error('Database connection exploded');
    filter.catch(exception, mockHost);

    expect(mockStatus).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({
          code: 'INTERNAL_SERVER_ERROR',
          message: 'An unexpected server error occurred.',
          trace_id: 'unhandled-trace-789',
        }),
      }),
    );
  });

  it('should map Prisma P1001 availability error to 503 SERVICE_UNAVAILABLE safely', () => {
    const mockSend = jest.fn();
    const mockStatus = jest.fn().mockReturnValue({ send: mockSend });
    const mockHeader = jest.fn();

    const mockHost: any = {
      switchToHttp: () => ({
        getResponse: () => ({ status: mockStatus, header: mockHeader }),
        getRequest: () => ({ headers: { 'x-trace-id': 'db-down-1' }, raw: {} }),
      }),
    };

    filter.catch({ code: 'P1001', message: 'Can not reach db at secret-host' }, mockHost);

    expect(mockStatus).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        error: expect.objectContaining({
          code: 'SERVICE_UNAVAILABLE',
          message: 'Database service temporarily unavailable. Please retry shortly.',
          trace_id: 'db-down-1',
        }),
      }),
    );
  });

  it('should skip reply when headers were already sent and absorb socket-closed send errors', () => {
    const mockSendAlreadySent = jest.fn();
    const hostSent: any = {
      switchToHttp: () => ({
        getResponse: () => ({ sent: true, status: jest.fn().mockReturnValue({ send: mockSendAlreadySent }) }),
        getRequest: () => ({ headers: {}, raw: {} }),
      }),
    };
    expect(() => filter.catch(new Error('late error'), hostSent)).not.toThrow();
    expect(mockSendAlreadySent).not.toHaveBeenCalled();

    const hostClosedSocket: any = {
      switchToHttp: () => ({
        getResponse: () => ({
          header: jest.fn(),
          status: jest.fn().mockReturnValue({
            send: jest.fn(() => {
              throw new Error('EPIPE');
            }),
          }),
        }),
        getRequest: () => ({ headers: {}, raw: {} }),
      }),
    };
    expect(() => filter.catch(new Error('socket dropped'), hostClosedSocket)).not.toThrow();
  });
});
