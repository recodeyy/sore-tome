// SERO spike test — sudden burst on top of baseline (pack Stage 6 / burst RPS).
// Models a due-date / login spike: fast arrival-rate jump and recovery.
// Run: k6 run -e BASE_URL=https://api.example.com -e TOKEN=<jwt> load/k6_spike.js
//   -e BURST_RPS=1500 to model Target B's 1,500 RPS burst.
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:4000';
const TOKEN = __ENV.TOKEN || '';
const BASE_RPS = parseInt(__ENV.BASE_RPS || '200', 10);
const BURST_RPS = parseInt(__ENV.BURST_RPS || '1000', 10);
const MAX_VUS = parseInt(__ENV.MAX_VUS || '2000', 10);

const errors = new Rate('business_errors');

export const options = {
  scenarios: {
    spike: {
      executor: 'ramping-arrival-rate',
      startRate: BASE_RPS,
      timeUnit: '1s',
      preAllocatedVUs: Math.min(MAX_VUS, 500),
      maxVUs: MAX_VUS,
      stages: [
        { duration: '1m', target: BASE_RPS },   // baseline
        { duration: '10s', target: BURST_RPS }, // sudden spike
        { duration: '2m', target: BURST_RPS },  // hold the spike
        { duration: '10s', target: BASE_RPS },  // drop
        { duration: '2m', target: BASE_RPS },   // recovery observation
      ],
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
    business_errors: ['rate<0.01'],
  },
};

const params = {
  headers: {
    Authorization: TOKEN ? `Bearer ${TOKEN}` : '',
    'Content-Type': 'application/json',
  },
};

const SPIKE_READS = [
  '/api/v1/finance/invoices',
  '/api/v1/admin/dashboard',
  '/api/v1/notices',
];

export default function () {
  const path = SPIKE_READS[Math.floor(Math.random() * SPIKE_READS.length)];
  const res = http.get(`${BASE_URL}${path}`, params);
  const ok = check(res, { 'handled': (r) => r.status < 500 });
  errors.add(!ok);
  sleep(0.2);
}
