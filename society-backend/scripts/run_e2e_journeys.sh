#!/usr/bin/env bash
# Runs the §17 cross-role E2E journey suites (__tests__/e2e_journeys/*).
#
# Prerequisites:
#   - Postgres up at $DATABASE_URL (default postgres://sero:sero@localhost:5544/sero_dev)
#   - hubtown-sunkist seed applied:  node scripts/seed_hubtown_sunkist.js
#   - For the login smoke: dev server running on :3001 (npm start) with the
#     Firestore logins seeded (node scripts/seed_hubtown_sunkist_logins.js).
#     Override the target with E2E_BASE_URL.
#
# Usage:  bash scripts/run_e2e_journeys.sh [extra jest args]
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== SERO cross-role E2E journeys =="
npx jest e2e_journeys --ci --runInBand "$@"
