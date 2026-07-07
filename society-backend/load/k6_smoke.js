import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:4000';

export const options = {
  vus: 5,
  duration: '30s',
};

export default function () {
  // Prefer the liveness probe; fall back to /health if it 404s.
  let res = http.get(`${BASE_URL}/api/v1/health/live`);
  if (res.status === 404) {
    res = http.get(`${BASE_URL}/health`);
  }

  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  sleep(1);
}
