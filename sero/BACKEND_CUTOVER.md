# Backend Cutover Roadmap

Migrating the Flutter client from mock data / direct Firestore reads to the new
Postgres-backed backend, mounted under `/api/v1/...`.

## Data layer (as found)

- **HTTP base**: `lib/services/api_client.dart` — `ApiClient` (package:http), Bearer
  JWT via `AuthService.getToken()`, 401 refresh handling, multipart upload.
- **Base URL**: `lib/config/env.dart` → `Environment.apiBaseUrl`
  (`--dart-define=API_BASE_URL=...`, default `http://10.0.2.2:3001/api/v1`).
- **Facade**: `lib/services/api_service.dart` — `ApiService.get/post/put/patch/delete`
  delegate to `ApiClient`. Now also exposes `ApiService.unwrap(res)` to parse the
  new `{ success, data, meta }` envelope. Still has a `kUseMockData` mock selector
  for endpoints not yet cut over.
- **Mock switch**: `lib/config/dev_config.dart` → `const bool kUseMockData = true`.
- **Mock data**: `lib/data/mock_data.dart`.
- **Direct Firestore reads**: `lib/services/firestore_service.dart`, several
  `lib/providers/shared/*` (notices stream, channels, presence, vitals).
- **Providers**: Riverpod under `lib/providers/**` and per-domain admin services
  under `lib/services/admin/**`.

## Envelope contract

Newer endpoints return `{ success: bool, data: <object|array>, meta?: {...} }`.
Use `ApiService.unwrap(response)` — it returns `data` on success, throws otherwise.

## Roadmap

| Module / Screen | New endpoint(s) | Current source | Status |
|---|---|---|---|
| **Admin Dashboard summary** (`dashboard_home_screen`) | `GET /admin/dashboard/summary` | mock + stub service | **DONE** |
| **Notices** (admin `notices_screen`, resident) `noticesProvider` | `GET/POST /notices-v2` | mock `/notices` + Firestore | **DONE** |
| Society vitals (`societyVitalsProvider`) | (realtime) `/notifications` SSE or `/admin/dashboard/summary` | Firestore stream | TODO |
| Notices realtime (`noticesStreamProvider`) | `/notices-v2` + SSE | Firestore stream | TODO |
| Admin Search | `GET /admin/search` | none | TODO |
| Finance (`finance_provider`, `funds_provider`, `invoices_provider`) | `/finance/*` | mock `/funds/*` | TODO |
| Complaints / Issues (`issues_provider`, admin complaints) | `/complaints` | mock `/issues` | TODO |
| Members (`users_provider`, registration, approvals) | `/members-v2` | mock `/users`, `/auth/pending` | TODO |
| Society structure (blocks/units) | `/structure` | Firestore/mock | TODO |
| Amenities / Facilities (`facilities_screen`) | `/amenities` | mock/Firestore | TODO |
| Parking (`admin_parking_service`) | `/parking` | mock | TODO |
| Assets (`admin_asset_service`) | `/assets` | mock | TODO |
| Reports (`admin/reports`) | `/reports` | none | TODO |
| Notifications | `/notifications` | Firestore/none | TODO |
| Resident home/funds/polls/visitors | `/resident/*` | mock/Firestore | TODO |
| Guard (`guard_home`) | `/guard/*` | mock/Firestore | TODO |
| Super Admin (`super_admin_service`) | `/super-admin/*` | mock | TODO |
| AI Copilot screens | `/ai/*` | `ai_service` | TODO |

## Cutover pattern (established by the two DONE modules)

1. Point the service/provider at the real `/api/v1` endpoint.
2. Parse with `ApiService.unwrap(res)` into the existing model's `fromJson/fromMap`.
3. Drop the per-module mock/`kUseMockData` fallback (leave others untouched).
4. Do not change UI. Add a new service/provider alongside if a switch is risky.

## Recommended next

1. **Finance reads** (`/finance/*`) — high value, read-mostly, models exist.
2. **Complaints/Issues** (`/complaints`) — replace mock `/issues`.
3. **Members** (`/members-v2`) — unblocks approvals/registration flows.
