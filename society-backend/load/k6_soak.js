// SERO Stage 5 — Soak (pack: 10K-20K concurrency, 4-8 hours).
// Holds a steady mixed load for a long duration to surface leaks, pool
// exhaustion, queue backlog growth, and replica lag.
// Run: k6 run -e BASE_URL=https://api.example.com -e TOKEN=<jwt> \
//        -e SOAK_HOURS=4 -e MAX_VUS=10000 load/k6_soak.js
//
// Default MAX_VUS is intentionally modest; raise to 10000-20000 only on
// distributed/cloud runners. SOAK_HOURS controls the sustained window.
import { mixed, realtime } from './k6_scale.js';

const MAX_VUS = parseInt(__ENV.MAX_VUS || '2000', 10);
const RT_VUS = parseInt(__ENV.RT_VUS || String(Math.min(2000, MAX_VUS)), 10);
const SOAK_HOURS = __ENV.SOAK_HOURS || '4';

export const options = {
  scenarios: {
    soak_mixed: {
      executor: 'ramping-vus',
      exec: 'mixed',
      startVUs: 0,
      stages: [
        { duration: '5m', target: MAX_VUS },         // ramp to plateau
        { duration: `${SOAK_HOURS}h`, target: MAX_VUS }, // long soak
        { duration: '5m', target: 0 },               // ramp down
      ],
      gracefulRampDown: '1m',
    },
    soak_realtime: {
      executor: 'ramping-vus',
      exec: 'realtime',
      startVUs: 0,
      stages: [
        { duration: '5m', target: RT_VUS },
        { duration: `${SOAK_HOURS}h`, target: RT_VUS },
        { duration: '5m', target: 0 },
      ],
      gracefulRampDown: '1m',
    },
  },
  thresholds: {
    // Soak must not degrade over time — same gate as the scale test.
    read_duration: ['p(95)<300'],
    write_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
    business_errors: ['rate<0.01'],
  },
};

export { mixed, realtime };

export default function () {
  mixed();
}
