import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { FastifyReply, FastifyRequest } from 'fastify';
import { v4 as uuidv4 } from 'uuid';
import {
  ErrorLayer,
  StructuredFlowLogger,
} from '../observability/structured-flow.logger';

export interface StandardApiError {
  code: string;
  message: string;
  details?: unknown;
  trace_id: string;
}

export interface StandardApiErrorResponse {
  success: false;
  error: StandardApiError;
}

function normalizeErrorCode(status: number, rawError?: unknown): string {
  if (typeof rawError === 'string' && rawError.trim().length > 0) {
    return rawError
      .trim()
      .toUpperCase()
      .replace(/[\s-]+/g, '_');
  }
  const statusText = HttpStatus[status];
  if (statusText) {
    return statusText.toUpperCase().replace(/[\s-]+/g, '_');
  }
  return 'HTTP_ERROR';
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<FastifyReply>();
    const request = ctx.getRequest<FastifyRequest>();

    const rawReq = request?.raw as any;
    const traceId: string =
      (request?.headers?.['x-request-id'] as string) ||
      (request?.headers?.['x-trace-id'] as string) ||
      rawReq?.requestId ||
      rawReq?.traceId ||
      uuidv4();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_SERVER_ERROR';
    let message = 'An unexpected server error occurred.';
    let details: unknown = undefined;
    let layer: ErrorLayer = 'SERVER';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const resObj = exceptionResponse as Record<string, unknown>;
        message = (resObj.message as string) || exception.message;
        code = normalizeErrorCode(status, resObj.error);

        if (Array.isArray(resObj.message)) {
          code = 'VALIDATION_FAILED';
          message = 'Validation failed for one or more fields';
          details = resObj.message.map((msg: unknown) => {
            if (typeof msg === 'string') {
              return { issue: msg };
            }
            return msg;
          });
        } else if (resObj.details !== undefined) {
          details = resObj.details;
        }
      } else {
        message = String(exceptionResponse);
        code = normalizeErrorCode(status);
      }
      if (status === HttpStatus.UNAUTHORIZED) {
        layer = 'AUTH';
      } else if (status === HttpStatus.FORBIDDEN) {
        layer = 'AUTHORIZATION';
      } else if (status === HttpStatus.TOO_MANY_REQUESTS) {
        layer = 'RATE_LIMIT';
      } else if (code === 'VALIDATION_FAILED' || status === HttpStatus.BAD_REQUEST) {
        layer = 'VALIDATION';
      } else {
        layer = 'HTTP';
      }
    } else if (
      typeof exception === 'object' &&
      exception !== null &&
      'code' in exception &&
      typeof (exception as any).code === 'string' &&
      (exception as any).code.startsWith('P2')
    ) {
      layer = 'DATABASE';
      // Safe, sanitized Prisma known request error mapping (never leaks schema/SQL)
      const prismaCode = (exception as any).code as string;
      if (prismaCode === 'P2023') {
        status = HttpStatus.BAD_REQUEST;
        code = 'INVALID_IDENTIFIER';
        message = 'Invalid identifier format';
      } else if (prismaCode === 'P2002') {
        status = HttpStatus.CONFLICT;
        code = 'CONFLICT';
        message = 'A record with this unique value already exists';
      } else if (prismaCode === 'P2025') {
        status = HttpStatus.NOT_FOUND;
        code = 'NOT_FOUND';
        message = 'Requested resource was not found';
      } else if (prismaCode === 'P2003') {
        status = HttpStatus.BAD_REQUEST;
        code = 'INVALID_REFERENCE';
        message = 'Referenced resource does not exist';
      } else {
        this.logger.error(
          `[${traceId}] Unmapped Prisma Error (${prismaCode}): ${(exception as any)?.message}`,
        );
      }
    } else if (
      typeof exception === 'object' &&
      exception !== null &&
      (((exception as any).name &&
        [
          'PrismaClientInitializationError',
          'PrismaClientRustPanicError',
        ].includes(String((exception as any).name))) ||
        (typeof (exception as any).code === 'string' &&
          (exception as any).code.startsWith('P1')))
    ) {
      layer = 'DATABASE';
      // Safe 503 Service Unavailable for database connectivity/initialization errors (never leaks host/credentials)
      const prismaCode = (exception as any).code || (exception as any).name;
      this.logger.error(
        `[${traceId}] Database availability error (${prismaCode}): ${(exception as any)?.message}`,
      );
      status = HttpStatus.SERVICE_UNAVAILABLE;
      code = 'SERVICE_UNAVAILABLE';
      message =
        'Database service temporarily unavailable. Please retry shortly.';
    } else if (
      typeof exception === 'object' &&
      exception !== null &&
      typeof (exception as any).statusCode === 'number' &&
      (exception as any).statusCode >= 400 &&
      (exception as any).statusCode < 500
    ) {
      // Fastify transport-level 4xx errors (e.g. 413 Payload Too Large, 400 Invalid JSON, 415 Unsupported Media Type)
      status = (exception as any).statusCode;
      code = normalizeErrorCode(status, (exception as any).code);
      message = (exception as any).message || 'Invalid request';
    } else {
      // Unhandled / Internal exception
      const err = exception as Error;
      this.logger.error(
        `[${traceId}] Unhandled Exception: ${err?.message || exception}`,
        err?.stack,
      );
    }

    // Emit unified structured error telemetry (stack trace included only in development)
    StructuredFlowLogger.logError({
      code,
      message,
      layer,
      statusCode: status,
      requestId: traceId,
      method: request?.method,
      path: request?.url,
      stack: exception instanceof Error ? exception.stack : undefined,
    });

    if (response.sent || (response.raw as any)?.headersSent) {
      this.logger.warn(
        `[${traceId}] Skipping error reply because headers were already sent (status=${status})`,
      );
      return;
    }

    // Ensure trace headers and send reply safely even if client socket closed mid-flight
    try {
      if (response.header) {
        response.header('x-trace-id', traceId);
        response.header('x-request-id', traceId);
      }

      const payload: StandardApiErrorResponse = {
        success: false,
        error: {
          code,
          message,
          details: details ?? null,
          trace_id: traceId,
        },
      };

      response.status(status).send(payload);
    } catch (sendErr: any) {
      this.logger.warn(
        `[${traceId}] Failed to send error response (client socket may have closed): ${sendErr?.message || sendErr}`,
      );
    }
  }
}
