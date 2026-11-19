#!/usr/bin/env node
/**
 * Deal One Graduated Load Test (Local/Test Environment Only)
 * Tests 10, 25, 50, and 100 concurrent users across Home Feed, Product Details,
 * Search, Filters, and Pagination.
 */
const BASE_URL = process.env.LOAD_BASE_URL || 'http://localhost:3000/api/v1';

// Safety guard: refuse to load-test production URLs
if (BASE_URL.includes('railway.app') || BASE_URL.includes('production')) {
  console.error('SAFETY BLOCK: Refusing to run load test against production URL.');
  process.exit(1);
}

function percentile(sorted, p) {
  if (sorted.length === 0) return 0;
  const idx = Math.min(sorted.length - 1, Math.ceil((p / 100) * sorted.length) - 1);
  return sorted[idx];
}

async function runStage(concurrency, totalRequests, endpoints) {
  const latencies = [];
  let errors = 0;
  let timeouts = 0;
  let totalBytes = 0;
  let cursor = 0;

  const startStage = performance.now();

  async function worker() {
    while (true) {
      const i = cursor++;
      if (i >= totalRequests) break;
      const url = `${BASE_URL}${endpoints[i % endpoints.length]}`;
      const t0 = performance.now();
      const ctrl = new AbortController();
      const timer = setTimeout(() => ctrl.abort(), 5000);
      try {
        const res = await fetch(url, { signal: ctrl.signal });
        const buf = await res.arrayBuffer();
        totalBytes += buf.byteLength;
        if (res.status >= 400) errors++;
        latencies.push(performance.now() - t0);
      } catch (err) {
        if (err.name === 'AbortError') timeouts++;
        else errors++;
      } finally {
        clearTimeout(timer);
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, () => worker()));
  const durationSec = (performance.now() - startStage) / 1000;
  latencies.sort((a, b) => a - b);
  const avg =
    latencies.length > 0
      ? latencies.reduce((a, b) => a + b, 0) / latencies.length
      : 0;

  return {
    concurrency,
    totalRequests,
    durationSec: Number(durationSec.toFixed(2)),
    rps: Number((totalRequests / durationSec).toFixed(1)),
    avgMs: Number(avg.toFixed(1)),
    p50Ms: Number(percentile(latencies, 50).toFixed(1)),
    p95Ms: Number(percentile(latencies, 95).toFixed(1)),
    p99Ms: Number(percentile(latencies, 99).toFixed(1)),
    errorRatePct: Number(((errors / totalRequests) * 100).toFixed(2)),
    timeoutRatePct: Number(((timeouts / totalRequests) * 100).toFixed(2)),
    avgPayloadKb: Number((totalBytes / Math.max(totalRequests, 1) / 1024).toFixed(1)),
  };
}

(async () => {
  // Fetch one real listing ID first
  const homeRes = await fetch(`${BASE_URL}/home?limit=6`);
  const homeJson = await homeRes.json();
  const sampleId = homeJson.data.featured[0].id;

  const endpoints = [
    '/home?limit=6',
    `/listings/${sampleId}`,
    `/search?q=${encodeURIComponent('شقة')}&categorySlug=real-estate&rooms=3&limit=10`,
    '/listings?categorySlug=cars&sort=price_asc&limit=10',
    '/search?categorySlug=home-appliances&page=2&limit=10',
  ];

  const stages = [
    { concurrency: 10, requests: 100 },
    { concurrency: 25, requests: 200 },
    { concurrency: 50, requests: 300 },
    { concurrency: 100, requests: 400 },
  ];

  const results = [];
  for (const s of stages) {
    const r = await runStage(s.concurrency, s.requests, endpoints);
    results.push(r);
  }

  // Query live memory from /health/live
  const liveRes = await fetch(BASE_URL.replace('/api/v1', '/health/live'));
  const liveJson = await liveRes.json();

  console.log(JSON.stringify({ stages: results, serverMemoryRssMb: liveJson.data?.memoryRssMb }, null, 2));
})();
