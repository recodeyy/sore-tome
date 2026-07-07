// SERO Stage 3 — Target A (10K).
// Run: k6 run -e BASE_URL=https://api.example.com -e TOKEN=<jwt> load/k6_10k.js
// Capacity: 10,000 auth users / 5,000 active / 600 sustained RPS / 1,000 burst /
//           10,000 realtime / 100 AI streams (pack Stage 3). Sustain 30 min.
//
// On a single host scale down with -e MAX_VUS=200 -e RT_VUS=200 -e BURST_RPS=100.
import { buildOptions, mixed, realtime, setup } from './k6_scale.js';

export const options = buildOptions('10k');
export { mixed, realtime, setup };

export default function (data) {
  mixed(data);
}
