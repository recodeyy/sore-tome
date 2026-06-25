import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:4000';
const LOADTEST = (__ENV.LOADTEST || 'false') === 'true';
const LOGIN_PHONE = __ENV.LOGIN_PHONE || '9876543200';
let TOKEN = __ENV.TOKEN || '';

export const options = {
  stages: [
    { duration: '2m', target: 500 }, // ramp up to 500 VUs
    { duration: '5m', target: 500 }, // hold at 500 VUs
    { duration: '2m', target: 0 },   // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<300'],
    http_req_failed: ['rate<0.01'],
  },
};

// Mint a society-scoped token once (Postgres load-test login, no Firebase).
export function setup() {
  if (LOADTEST) {
    const r = http.post(`${BASE_URL}/api/v1/auth/loadtest-login`,
      JSON.stringify({ phone: LOGIN_PHONE }),
      { headers: { 'Content-Type': 'application/json' } });
    try { return { token: JSON.parse(r.body).data.token }; } catch (_) { return { token: '' }; }
  }
  return { token: TOKEN };
}

// Read-only GET endpoints that exist on the live backend.
const ENDPOINTS = [
  '/api/v1/finance/invoices',
  '/api/v1/notices-v2',
  '/api/v1/events-v2',
  '/api/v1/complaints',
  '/api/v1/admin/dashboard/summary',
];

export default function (data) {
  const token = (data && data.token) || TOKEN;
  const params = { headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } };
  for (const path of ENDPOINTS) {
    const res = http.get(`${BASE_URL}${path}`, params);
    check(res, { 'status is 2xx': (r) => r.status >= 200 && r.status < 300 });
  }
  sleep(1);
}
