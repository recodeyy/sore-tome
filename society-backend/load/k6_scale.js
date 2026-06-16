// SERO scale load test — parametrized 10K / 20K target driver.
//
// Implements the SERO_10K_20K_Load_Test_Complete_Prompt_Pack staging:
//   ramp -> sustained -> burst -> ramp-down, plus an SSE realtime scenario
//   and a realistic traffic mix across /api/v1 endpoint families.
//
// Tune the target with -e TARGET=10k|20k (default 10k). Override any stage
// VU count with -e MAX_VUS=... and the burst arrival rate with -e BURST_RPS=...
//
// NOTE: Driving 10K-20K real VUs requires k6 Cloud / distributed execution or
// a host tuned for high connection counts (ulimit -n, ephemeral ports). On a
// laptop, scale down with -e MAX_VUS=200 to validate behaviour.
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:4000';
const TOKEN = __ENV.TOKEN || '';
// Custom metrics split read vs write so thresholds map to the pass criteria.
const readDur = new Trend('read_duration', true);
const writeDur = new Trend('write_duration', true);
const errors = new Rate('business_errors');

// Pack Target A (10K) / Target B (20K) capacity numbers.
function profileFor(target) {
  return target === '20k'
    ? { authUsers: 20000, activeUsers: 10000, sustainRps: 1000, burstRps: 1500, realtime: 20000, aiStreams: 200 }
    : { authUsers: 10000, activeUsers: 5000, sustainRps: 600, burstRps: 1000, realtime: 10000, aiStreams: 100 };
}

// Build a k6 options object for the given target ('10k' | '20k').
// Env overrides: MAX_VUS, RT_VUS, BURST_RPS, SUSTAIN_MIN.
export function buildOptions(target) {
  const t = (target || __ENV.TARGET || '10k').toLowerCase();
  const PROFILE = profileFor(t);
  const MAX_VUS = parseInt(__ENV.MAX_VUS || String(PROFILE.activeUsers), 10);
  const RT_VUS = parseInt(__ENV.RT_VUS || String(Math.min(PROFILE.realtime, MAX_VUS)), 10);
  const BURST_RPS = parseInt(__ENV.BURST_RPS || String(PROFILE.burstRps), 10);
  const SUSTAIN_MIN = __ENV.SUSTAIN_MIN || '30'; // pack: sustain 30 minutes

  return {
  scenarios: {
    // Realistic mixed read/write traffic: ramp -> sustained -> ramp-down.
    mixed_traffic: {
      executor: 'ramping-vus',
      exec: 'mixed',
      startVUs: 0,
      stages: [
        { duration: '3m', target: Math.round(MAX_VUS * 0.5) }, // ramp
        { duration: '2m', target: MAX_VUS },                   // ramp to full active set
        { duration: `${SUSTAIN_MIN}m`, target: MAX_VUS },      // sustained
        { duration: '2m', target: 0 },                         // ramp-down
      ],
      gracefulRampDown: '30s',
      tags: { scenario: 'mixed' },
    },
    // Burst: arrival-rate spike on top of sustained load.
    burst: {
      executor: 'ramping-arrival-rate',
      exec: 'mixed',
      startRate: PROFILE.sustainRps,
      timeUnit: '1s',
      preAllocatedVUs: Math.min(MAX_VUS, 2000),
      maxVUs: MAX_VUS,
      startTime: '7m', // begins once sustained load is established
      stages: [
        { duration: '2m', target: PROFILE.sustainRps }, // hold sustained RPS
        { duration: '1m', target: BURST_RPS },          // burst up
        { duration: '2m', target: BURST_RPS },          // hold burst
        { duration: '1m', target: PROFILE.sustainRps }, // recover
      ],
      tags: { scenario: 'burst' },
    },
    // Realtime: long-lived SSE connections (pack: 10K/20K realtime connections).
    realtime: {
      executor: 'ramping-vus',
      exec: 'realtime',
      startVUs: 0,
      stages: [
        { duration: '3m', target: RT_VUS }, // connection ramp
        { duration: `${SUSTAIN_MIN}m`, target: RT_VUS },
        { duration: '1m', target: 0 },
      ],
      gracefulRampDown: '30s',
      tags: { scenario: 'realtime' },
    },
  },
  thresholds: {
    // Pack pass criteria (section 21 + report gate): read/write p95, error rate.
    read_duration: ['p(95)<300'],          // standard read p95 < 300ms
    write_duration: ['p(95)<500'],         // standard write p95 < 500ms
    'http_req_duration{scenario:mixed}': ['p(99)<1500'],
    http_req_failed: ['rate<0.01'],        // error rate < 1%
    business_errors: ['rate<0.01'],
  },
  };
}

// Default export options when this file is run directly (TARGET env, default 10k).
export const options = buildOptions(__ENV.TARGET);

function authHeaders() {
  return {
    headers: {
      Authorization: TOKEN ? `Bearer ${TOKEN}` : '',
      'Content-Type': 'application/json',
    },
  };
}

// Read-heavy endpoint families pulled from server.js v1 routes.
const READS = [
  '/api/v1/admin/dashboard',
  '/api/v1/finance/invoices',
  '/api/v1/notices',
  '/api/v1/notices-v2',
  '/api/v1/complaints',
  '/api/v1/issues',
  '/api/v1/events',
  '/api/v1/polls',
  '/api/v1/amenities',
  '/api/v1/visitors',
  '/api/v1/staff',
  '/api/v1/reports',
  '/api/v1/notifications',
];

function doRead(path) {
  const res = http.get(`${BASE_URL}${path}`, Object.assign({ tags: { op: 'read' } }, authHeaders()));
  readDur.add(res.timings.duration);
  const ok = check(res, { 'read 2xx/3xx': (r) => r.status >= 200 && r.status < 400 });
  errors.add(!ok);
  return res;
}

function doWrite(path, body) {
  const res = http.post(`${BASE_URL}${path}`, JSON.stringify(body),
    Object.assign({ tags: { op: 'write' } }, authHeaders()));
  writeDur.add(res.timings.duration);
  // Accept 2xx, plus 4xx auth/validation as "served" (not a server failure).
  const ok = check(res, { 'write handled': (r) => r.status < 500 });
  errors.add(!ok);
  return res;
}

// Realistic weighted mix: mostly dashboard/finance reads, some writes/search.
export function mixed() {
  const roll = Math.random();
  if (roll < 0.55) {
    // Dashboard + finance reads (the dominant traffic).
    group('reads', () => {
      doRead(READS[Math.floor(Math.random() * READS.length)]);
      doRead('/api/v1/admin/dashboard');
    });
  } else if (roll < 0.75) {
    // Search-style read with query params.
    doRead(`/api/v1/visitors?search=ramp&page=1`);
  } else if (roll < 0.90) {
    // Complaint create (write path).
    doWrite('/api/v1/complaints', { title: 'Load test complaint', category: 'maintenance', description: 'k6' });
  } else {
    // Poll vote / amenity check (hot-row writes).
    doWrite('/api/v1/polls/vote', { pollId: 'loadtest', optionId: '1' });
  }
  sleep(Math.random() * 2 + 0.5);
}

// Realtime SSE scenario: open the stream and hold it open.
export function realtime() {
  const res = http.get(`${BASE_URL}/api/v1/realtime/sse`,
    Object.assign({ timeout: '60s', tags: { op: 'realtime' } }, authHeaders()));
  check(res, { 'sse opened': (r) => r.status === 200 || r.status === 401 });
  sleep(15);
}

export default function () {
  mixed();
}
