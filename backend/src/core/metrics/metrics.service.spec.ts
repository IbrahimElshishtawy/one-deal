import { MetricsService } from './metrics.service';

describe('MetricsService (Prometheus Exporter)', () => {
  let service: MetricsService;

  beforeEach(() => {
    service = new MetricsService();
  });

  it('should record HTTP requests, normalize UUID path segments, and render Prometheus buckets', () => {
    service.incrementInFlight();
    service.recordHttpRequest(
      'GET',
      '/api/v1/listings/11111111-2222-3333-4444-555555555555?page=1',
      200,
      0.042,
    );
    service.decrementInFlight();

    const output = service.renderPrometheus();

    expect(output).toContain(
      'http_requests_total{method="GET",route="/api/v1/listings/:id",status_code="200"} 1',
    );
    expect(output).toContain(
      'http_request_duration_seconds_bucket{method="GET",route="/api/v1/listings/:id",le="0.05"} 1',
    );
    expect(output).toContain(
      'http_request_duration_seconds_bucket{method="GET",route="/api/v1/listings/:id",le="+Inf"} 1',
    );
    expect(output).toContain('http_requests_in_flight 0');
    expect(output).toContain('process_resident_memory_bytes');
  });
});
