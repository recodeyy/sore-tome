# SEED_DATA_POLICY

Per spec section 14.

## Allowed environments for seed/test data
- Local development only
- Automated tests (`society-backend/__tests__`, Flutter widget/integration tests)
- A dedicated staging/demo environment

## Rules
1. Seeding runs ONLY via an explicit, separate command (e.g. `npm run seed`, `knex seed:run`) — never as a side effect of app start or migration.
2. Every seed entry point is guarded by an environment check: refuse to run when `NODE_ENV === 'production'`.
3. Seeded records must be clearly labelled (e.g. demo society code prefix) and isolated to demo societies.
4. No demo/test credentials ship in a production build. `sero/lib/services/api_service.dart::_getMockResponse` is gated by `kUseMockData` and must be `false` in production builds (release gate).
5. No staging endpoint in production config: production `ApiClient.baseUrl` must point at the production API, not localhost/staging (`sero/lib/config/env.dart`).
6. Test data must never appear in a real society account (tenant isolation via `tenantMiddleware`/RLS).

## Frontend specifics
- `data/mock_data.dart` is neutralized (all empty/zero) and must NOT be imported by any production screen. CI check (`scripts/check-production-mocks.*`, spec 18) should fail when `lib/screens/**` imports `data/mock_data.dart`.
- After this migration, the remaining importers are listed in the final summary; target = 0.

## Cutover gate
`kUseMockData = false` is flipped by the release lead only after: all admin screens migrated, backend reachable, and the production-mock CI check passes.
