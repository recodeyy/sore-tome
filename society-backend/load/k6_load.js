import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:4000';
const TOKEN = __ENV.TOKEN || '';

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

const params = {
  headers: {
    Authorization: `Bearer ${TOKEN}`,
    'Content-Type': 'application/json',
  },
};

// Small mix of read-only GET endpoints.
const ENDPOINTS = [
  '/api/v1/finance/invoices',
  '/api/v1/notices',
  '/api/v1/events',
  '/api/v1/issues',
];

export default function () {
  for (const path of ENDPOINTS) {
    const res = http.get(`${BASE_URL}${path}`, params);
    check(res, {
      'status is 2xx': (r) => r.status >= 200 && r.status < 300,
    });
  }
  sleep(1);
}
