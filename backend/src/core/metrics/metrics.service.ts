import { Injectable } from '@nestjs/common';

interface HistogramData {
  buckets: number[];
  counts: number[];
  sum: number;
  count: number;
}

/**
 * Lightweight Prometheus-compatible metrics registry exposing:
 * - http_requests_total (method, route, status_code)
 * - http_request_duration_seconds (histogram buckets for p50/p95/p99)
 * - http_requests_in_flight
 * - process_resident_memory_bytes / process_uptime_seconds
 */
@Injectable()
export class MetricsService {
  private readonly defaultBuckets = [
    0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5,
  ];
  private readonly requestCounts = new Map<string, number>();
  private readonly histograms = new Map<string, HistogramData>();
  private inFlight = 0;

  incrementInFlight(): void {
    this.inFlight += 1;
  }

  decrementInFlight(): void {
    this.inFlight = Math.max(0, this.inFlight - 1);
  }

  recordHttpRequest(
    method: string,
    route: string,
    statusCode: number,
    durationSeconds: number,
  ): void {
    const cleanRoute = this.normalizeRoute(route);
    const counterKey = `${method}|${cleanRoute}|${statusCode}`;
    this.requestCounts.set(
      counterKey,
      (this.requestCounts.get(counterKey) || 0) + 1,
    );

    const histKey = `${method}|${cleanRoute}`;
    let hist = this.histograms.get(histKey);
    if (!hist) {
      hist = {
        buckets: [...this.defaultBuckets],
        counts: new Array(this.defaultBuckets.length).fill(0),
        sum: 0,
        count: 0,
      };
      this.histograms.set(histKey, hist);
    }

    hist.sum += durationSeconds;
    hist.count += 1;
    for (let i = 0; i < hist.buckets.length; i += 1) {
      if (durationSeconds <= hist.buckets[i]) {
        hist.counts[i] += 1;
      }
    }
  }

  renderPrometheus(): string {
    const lines: string[] = [];

    lines.push(
      '# HELP http_requests_total Total number of HTTP requests processed',
      '# TYPE http_requests_total counter',
    );
    for (const [key, count] of this.requestCounts.entries()) {
      const [method, route, statusCode] = key.split('|');
      lines.push(
        `http_requests_total{method="${this.escapeLabel(method)}",route="${this.escapeLabel(route)}",status_code="${this.escapeLabel(statusCode)}"} ${count}`,
      );
    }

    lines.push(
      '# HELP http_request_duration_seconds HTTP request duration in seconds',
      '# TYPE http_request_duration_seconds histogram',
    );
    for (const [key, hist] of this.histograms.entries()) {
      const [method, route] = key.split('|');
      const labels = `method="${this.escapeLabel(method)}",route="${this.escapeLabel(route)}"`;
      for (let i = 0; i < hist.buckets.length; i += 1) {
        lines.push(
          `http_request_duration_seconds_bucket{${labels},le="${hist.buckets[i]}"} ${hist.counts[i]}`,
        );
      }
      lines.push(
        `http_request_duration_seconds_bucket{${labels},le="+Inf"} ${hist.count}`,
      );
      lines.push(
        `http_request_duration_seconds_sum{${labels}} ${hist.sum.toFixed(6)}`,
      );
      lines.push(
        `http_request_duration_seconds_count{${labels}} ${hist.count}`,
      );
    }

    lines.push(
      '# HELP http_requests_in_flight Current number of active HTTP requests',
      '# TYPE http_requests_in_flight gauge',
      `http_requests_in_flight ${this.inFlight}`,
      '# HELP process_resident_memory_bytes Resident set size memory in bytes',
      '# TYPE process_resident_memory_bytes gauge',
      `process_resident_memory_bytes ${process.memoryUsage().rss}`,
      '# HELP process_uptime_seconds Process uptime in seconds',
      '# TYPE process_uptime_seconds gauge',
      `process_uptime_seconds ${Math.floor(process.uptime())}`,
    );

    return `${lines.join('\n')}\n`;
  }

  private normalizeRoute(rawRoute: string): string {
    const withoutQuery = (rawRoute || '/').split('?')[0];
    return withoutQuery.replace(
      /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi,
      ':id',
    );
  }

  private escapeLabel(val: string): string {
    return String(val).replace(/\\/g, '\\\\').replace(/"/g, '\\"');
  }
}
