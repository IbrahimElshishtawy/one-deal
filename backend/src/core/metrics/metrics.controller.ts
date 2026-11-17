import { Controller, Get, Res } from '@nestjs/common';
import { FastifyReply } from 'fastify';
import { ApiExcludeController } from '@nestjs/swagger';
import { MetricsService } from './metrics.service';

@ApiExcludeController()
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
