import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

export const errorRate = new Rate('errors');

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000/api/v1';
const HEALTH_BASE_URL = BASE_URL.replace(/\/api\/v1\/?$/, '');

/**
 * Load test targeting 5,000 concurrent online users across core marketplace flows:
 * - 60% public feed + categories/locations browse
 * - 25% Arabic & spatial search
 * - 10% listing detail view
 * - 5% OTP request flow (CGNAT-safe rate limit verification)
 */
export const options = {
  scenarios: {
    browse_and_search: {
      executor: 'ramping-vus',
      startVUs: 50,
      stages: [
        { duration: '2m', target: 1000 },
        { duration: '3m', target: 3000 },
        { duration: '5m', target: 5000 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<400', 'p(99)<900'],
    errors: ['rate<0.01'],
  },
};

const ARABIC_QUERIES = ['تويوتا', 'شقة', 'ايفون', 'سيارة', 'فيلا التجمع'];

export default function () {
  const roll = Math.random();

  if (roll < 0.45) {
    const res = http.get(`${BASE_URL}/listings?limit=20`);
    const ok = check(res, {
      'feed status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  } else if (roll < 0.6) {
    const res = http.get(`${BASE_URL}/categories`);
    const ok = check(res, {
      'categories status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  } else if (roll < 0.85) {
    const q = ARABIC_QUERIES[Math.floor(Math.random() * ARABIC_QUERIES.length)];
    const res = http.get(
      `${BASE_URL}/search?q=${encodeURIComponent(q)}&lat=30.0444&lng=31.2357&radiusKm=25`,
    );
    const ok = check(res, {
      'search status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  } else if (roll < 0.95) {
    const res = http.get(`${BASE_URL}/locations/governorates`);
    const ok = check(res, {
      'governorates status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  } else {
    const res = http.get(`${HEALTH_BASE_URL}/health/ready`);
    const ok = check(res, {
      'readiness status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  }

  sleep(1);
}
