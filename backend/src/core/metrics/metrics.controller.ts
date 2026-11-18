import { Controller, Get, Res, UseGuards } from '@nestjs/common';
import { FastifyReply } from 'fastify';
import { ApiExcludeController } from '@nestjs/swagger';
import { MetricsService } from './metrics.service';
import { MetricsAuthGuard } from './metrics-auth.guard';

@ApiExcludeController()
@UseGuards(MetricsAuthGuard)
@Controller('metrics')
export class MetricsController {
  constructor(private readonly metricsService: MetricsService) {}

  @Get()
  getPrometheusMetrics(@Res() res: FastifyReply) {
    return res
      .header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
      .send(this.metricsService.renderPrometheus());
  }
}
