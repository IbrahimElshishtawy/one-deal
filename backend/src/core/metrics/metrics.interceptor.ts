import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { FastifyRequest, FastifyReply } from 'fastify';
import { MetricsService } from './metrics.service';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') {
      return next.handle();
    }

    const ctx = context.switchToHttp();
    const req = ctx.getRequest<
      FastifyRequest & { routeOptions?: { url?: string } }
    >();
    const res = ctx.getResponse<FastifyReply>();

    const route = req.routeOptions?.url || req.url || '/';
    if (route === '/metrics') {
      return next.handle();
    }

    const startNs = process.hrtime.bigint();
    this.metricsService.incrementInFlight();

    return next.handle().pipe(
      finalize(() => {
        this.metricsService.decrementInFlight();
        const durationSeconds =
          Number(process.hrtime.bigint() - startNs) / 1_000_000_000;
        const statusCode = res.statusCode || 200;
        this.metricsService.recordHttpRequest(
          req.method,
          route,
          statusCode,
          durationSeconds,
        );
      }),
    );
  }
}
