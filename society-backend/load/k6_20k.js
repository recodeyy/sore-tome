// SERO Stage 4 — Target B (20K).
// Run: k6 run -e BASE_URL=https://api.example.com -e TOKEN=<jwt> load/k6_20k.js
// Capacity: 20,000 auth users / 10,000 active / 1,000 sustained RPS / 1,500 burst /
//           20,000 realtime / 200 AI streams (pack Stage 4). Sustain 30 min.
//
// 20K VUs is NOT feasible on a single host. Use k6 Cloud / distributed runners,
// or scale down with -e MAX_VUS=300 -e RT_VUS=300 -e BURST_RPS=150 to dry-run.
import { buildOptions, mixed, realtime } from './k6_scale.js';

export const options = buildOptions('20k');
export { mixed, realtime };

export default function () {
  mixed();
}
