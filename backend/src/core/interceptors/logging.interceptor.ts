import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { FastifyRequest, FastifyReply } from 'fastify';
import { v4 as uuidv4 } from 'uuid';
import {
  isDevelopmentObservabilityEnabled,
  runWithRequestContext,
  sanitizeLogString,
} from '../observability/request-context';
import { StructuredFlowLogger } from '../observability/structured-flow.logger';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const ctx = context.switchToHttp();
    const req = ctx.getRequest<FastifyRequest>();
    const res = ctx.getResponse<FastifyReply>();

    const rawReq = req?.raw as any;
    const traceId =
      (req?.headers?.['x-request-id'] as string) ||
      (req?.headers?.['x-trace-id'] as string) ||
      rawReq?.requestId ||
      rawReq?.traceId ||
      uuidv4();

    // Ensure trace headers in response (guard against already-sent headers)
    if (res.header && !res.sent && !(res.raw as any)?.headersSent) {
      res.header('x-trace-id', traceId);
      res.header('x-request-id', traceId);
    }

    const startTime = Date.now();
    const { method, url } = req;
    const safeUrl = sanitizeLogString(url, 300);
    const userId = (req as any)?.user?.id as string | undefined;

    if (isDevelopmentObservabilityEnabled()) {
      StructuredFlowLogger.stage(
        'REQUEST',
        `${method} ${safeUrl} received`,
        {
          method,
          path: safeUrl,
          userId: userId ?? null,
        },
        traceId,
      );
    }

    return new Observable((subscriber) => {
      runWithRequestContext(
        {
          requestId: traceId,
          method,
          path: safeUrl,
          userId: userId ?? null,
          startedAt: startTime,
        },
        () => {
          const subscription = next
            .handle()
            .pipe(
              tap({
                next: () => {
                  const duration = Date.now() - startTime;
                  const statusCode = res.statusCode;
                  this.logger.log(
                    JSON.stringify({
                      level: 'info',
                      stage: 'RESPONSE',
                      time: Date.now(),
                      trace_id: traceId,
                      request_id: traceId,
                      user_id: userId ?? null,
                      req: {
                        method,
                        url: safeUrl,
                        ip: req.ip,
                        user_agent: req.headers?.['user-agent'],
                      },
                      res: {
                        status_code: statusCode,
                        duration_ms: duration,
                      },
                      msg: `[RESPONSE] ${method} ${safeUrl} ${statusCode} - ${duration}ms`,
                    }),
                  );
                },
                error: (err) => {
                  const duration = Date.now() - startTime;
                  const safeErr = sanitizeLogString(
                    String(err?.message ?? ''),
                    500,
                  );
                  this.logger.error(
                    JSON.stringify({
                      level: 'error',
                      stage: 'ERROR',
                      time: Date.now(),
                      trace_id: traceId,
                      request_id: traceId,
                      user_id: userId ?? null,
                      req: {
                        method,
                        url: safeUrl,
                        ip: req.ip,
                        user_agent: req.headers?.['user-agent'],
                      },
                      res: {
                        status_code: err?.status || 500,
                        duration_ms: duration,
                      },
                      err: safeErr,
                      msg: `[ERROR] ${method} ${safeUrl} FAILED - ${duration}ms`,
                    }),
                  );
                },
              }),
            )
            .subscribe(subscriber);

          return () => subscription.unsubscribe();
        },
      );
    });
  }
}
