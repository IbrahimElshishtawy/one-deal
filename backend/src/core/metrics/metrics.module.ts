import { Global, Module } from '@nestjs/common';
import { MetricsService } from './metrics.service';
import { MetricsController } from './metrics.controller';
import { MetricsInterceptor } from './metrics.interceptor';
import { MetricsAuthGuard } from './metrics-auth.guard';

@Global()
@Module({
  controllers: [MetricsController],
  providers: [MetricsService, MetricsInterceptor, MetricsAuthGuard],
  exports: [MetricsService, MetricsInterceptor, MetricsAuthGuard],
})
export class MetricsModule {}
