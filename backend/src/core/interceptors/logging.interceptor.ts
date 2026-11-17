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

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const ctx = context.switchToHttp();
    const req = ctx.getRequest<FastifyRequest>();
    const res = ctx.getResponse<FastifyReply>();

    const rawReq = req?.raw as any;
    const traceId =
      (req?.headers?.['x-trace-id'] as string) ||
      (req?.headers?.['x-request-id'] as string) ||
      rawReq?.traceId ||
      rawReq?.requestId ||
      uuidv4();

    // Ensure trace headers in response
    if (res.header) {
      res.header('x-trace-id', traceId);
      res.header('x-request-id', traceId);
    }

    const startTime = Date.now();
    const { method, url } = req;
    const userId = (req as any)?.user?.id as string | undefined;

    return next.handle().pipe(
      tap({
        next: () => {
          const duration = Date.now() - startTime;
          const statusCode = res.statusCode;
          this.logger.log(
            JSON.stringify({
              level: 'info',
              time: Date.now(),
              trace_id: traceId,
              user_id: userId ?? null,
              req: {
                method,
                url,
                ip: req.ip,
                user_agent: req.headers?.['user-agent'],
              },
              res: {
                status_code: statusCode,
                duration_ms: duration,
              },
              msg: `${method} ${url} ${statusCode} - ${duration}ms`,
            }),
          );
        },
        error: (err) => {
          const duration = Date.now() - startTime;
          this.logger.error(
            JSON.stringify({
              level: 'error',
              time: Date.now(),
              trace_id: traceId,
              user_id: userId ?? null,
              req: {
                method,
                url,
                ip: req.ip,
                user_agent: req.headers?.['user-agent'],
              },
              res: {
                status_code: err?.status || 500,
                duration_ms: duration,
              },
              err: err?.message,
              msg: `${method} ${url} FAILED - ${duration}ms`,
            }),
          );
        },
      }),
    );
  }
}
