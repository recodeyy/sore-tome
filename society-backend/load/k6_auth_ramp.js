// SERO auth_ramp — login/session/refresh load + self-contained token minting.
//
// Implements the pack's `auth_ramp` scenario (§7, §27) and removes the need to
// pre-issue a TOKEN: it logs in seeded users against POST /api/v1/auth/login to
// obtain real JWTs, then exercises session validation (GET /users/me) and token
// refresh (POST /api/v1/auth/refresh).
//
// Run standalone (Stage: auth ramp):
//   k6 run -e BASE_URL=https://staging.api.example.com \
//          -e PHONE_PREFIX=+9190000 -e USER_COUNT=10000 -e PASSWORD=LoadTest@123 \
//          load/k6_auth_ramp.js
//
// Or import { mintToken } into the scale scripts so they self-auth (no TOKEN env).
//
// Seeded-user convention (override via env): phone = `${PHONE_PREFIX}${n}` padded
// to PHONE_PAD digits for n in [0, USER_COUNT), all sharing PASSWORD. Align this
// with your §5 seed command. A single fixed LOGIN_PHONE/LOGIN_PASSWORD also works.
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:4000';

const PHONE_PREFIX = __ENV.PHONE_PREFIX || '+9190000';
const USER_COUNT = parseInt(__ENV.USER_COUNT || '1000', 10);
const PHONE_PAD = parseInt(__ENV.PHONE_PAD || '5', 10); // digits after prefix
const PASSWORD = __ENV.PASSWORD || 'LoadTest@123';
const LOGIN_PHONE = __ENV.LOGIN_PHONE || ''; // single-user override
const PORTAL = __ENV.PORTAL || ''; // optional portal scoping

const loginDur = new Trend('login_duration', true);
const sessionDur = new Trend('session_duration', true);
const refreshDur = new Trend('refresh_duration', true);
const authErrors = new Rate('auth_errors');

// Pack §7 internal targets (exclude external IdP latency).
export const options = {
  scenarios: {
    auth_ramp: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: parseInt(__ENV.MAX_VUS || '500', 10),
      maxVUs: parseInt(__ENV.MAX_VUS || '2000', 10),
      stages: [
        { duration: '2m', target: parseInt(__ENV.LOGIN_RPS || '200', 10) }, // ramp logins/s
        { duration: '3m', target: parseInt(__ENV.LOGIN_RPS || '200', 10) }, // sustain
        { duration: '1m', target: parseInt(__ENV.BURST_LOGIN_RPS || '500', 10) }, // burst (§7: 500/s)
        { duration: '1m', target: 0 },
      ],
    },
  },
  thresholds: {
    login_duration: ['p(95)<1000'],   // internal login processing p95 < 1s
    session_duration: ['p(95)<200'],  // session validation p95 < 200ms
    refresh_duration: ['p(95)<300'],  // refresh p95 < 300ms
    auth_errors: ['rate<0.01'],
    http_req_failed: ['rate<0.01'],
  },
};

function phoneFor(n) {
  if (LOGIN_PHONE) return LOGIN_PHONE;
  return PHONE_PREFIX + String(n % USER_COUNT).padStart(PHONE_PAD, '0');
}

// When LOADTEST=true, use the Postgres-backed /auth/loadtest-login (no Firebase
// key, no password) instead of the Firestore login. LOGIN_PHONE picks the seeded
// member (e.g. 9876543200 resident / admin / 9000000001 staff).
const LOADTEST = (__ENV.LOADTEST || 'false') === 'true';

// Logs in one user and returns { token, refreshToken } or null on failure.
export function mintToken(n) {
  const path = LOADTEST ? '/api/v1/auth/loadtest-login' : '/api/v1/auth/login';
  const body = LOADTEST
    ? { phone: phoneFor(n == null ? 0 : n) }
    : { phone: phoneFor(n == null ? 0 : n), password: PASSWORD };
  if (!LOADTEST && PORTAL) body.portal = PORTAL;
  const res = http.post(`${BASE_URL}${path}`, JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    tags: { op: 'login' },
  });
  loginDur.add(res.timings.duration);
  const ok = check(res, { 'login 200': (r) => r.status === 200 });
  authErrors.add(!ok);
  if (!ok) return null;
  try {
    const data = JSON.parse(res.body).data || JSON.parse(res.body);
    return { token: data.token, refreshToken: data.refreshToken };
  } catch (_) {
    authErrors.add(true);
    return null;
  }
}

function authHeaders(token) {
  return { headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } };
}

export default function () {
  const n = __VU * 100000 + __ITER;
  const creds = mintToken(n);
  if (!creds) {
    sleep(1);
    return;
  }

  // Session validation.
  const me = http.get(`${BASE_URL}/api/v1/users/me`, Object.assign({ tags: { op: 'session' } }, authHeaders(creds.token)));
  sessionDur.add(me.timings.duration);
  authErrors.add(!check(me, { 'session 200': (r) => r.status === 200 }));

  // Token refresh (rotation).
  if (creds.refreshToken) {
    const rf = http.post(`${BASE_URL}/api/v1/auth/refresh`, JSON.stringify({ refreshToken: creds.refreshToken }), {
      headers: { 'Content-Type': 'application/json' },
      tags: { op: 'refresh' },
    });
    refreshDur.add(rf.timings.duration);
    authErrors.add(!check(rf, { 'refresh 200': (r) => r.status === 200 }));
  }

  sleep(Math.random() * 2 + 1);
}
