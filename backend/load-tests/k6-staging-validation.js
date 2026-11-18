import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

export const errorRate = new Rate('errors');

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:3099/api/v1';
const HEALTH_BASE_URL = BASE_URL.replace(/\/api\/v1\/?$/, '');

export const options = {
  scenarios: {
    staging_gradual_load: {
      executor: 'ramping-vus',
      startVUs: 5,
      stages: [
        { duration: '10s', target: 25 },
        { duration: '20s', target: 75 },
        { duration: '10s', target: 100 },
        { duration: '5s', target: 0 },
      ],
      gracefulRampDown: '5s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<400', 'p(99)<900'],
    errors: ['rate<0.01'],
  },
};

const ARABIC_QUERIES = ['تويوتا', 'شقة', 'ايفون', 'سيارة', 'فيلا'];

export default function () {
  const roll = Math.random();

  if (roll < 0.40) {
    const res = http.get(`${BASE_URL}/listings?limit=20`);
    const ok = check(res, {
      'feed status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  } else if (roll < 0.55) {
    const res = http.get(`${BASE_URL}/categories`);
    const ok = check(res, {
      'categories status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  } else if (roll < 0.80) {
    const q = ARABIC_QUERIES[Math.floor(Math.random() * ARABIC_QUERIES.length)];
    const res = http.get(
      `${BASE_URL}/search?q=${encodeURIComponent(q)}&lat=30.0444&lng=31.2357&radiusKm=25`,
    );
    const ok = check(res, {
      'search status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  } else if (roll < 0.90) {
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

  sleep(0.2);
}
