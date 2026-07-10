# Backend API Health Report — 2026-07-10 (live production)

Base: `https://sero-api-live.onrender.com`

## Health endpoints
| Endpoint | Result |
|---|---|
| `GET /health` | 200 `{"status":"ok","app":"Society Backend",...}` — but **first request after idle took >60s (cold start)**; warm ~0.3s |
| `GET /health/deep` | 401 (requires `x-health-check-secret`) — exists, gated |
| `GET /ready`, `/api/v1/health` | 404 — no separate readiness route (readiness folded into /health/deep) |

## Auth
| Test | Result |
|---|---|
| `POST /api/v1/auth/login` empty body | 400 with per-field Zod details (`body.phone`, `body.password`) — good error shape |
| bad creds | 401 `{"error":"Invalid phone number or password"}` (masked, correct) |
| demo resident `9876543200` | 200: token ✅ firebaseToken ✅ activeWorkspace ✅ (`demo-soc-1`, `resident_owner`, approved) |
| admin `admin` portal=admin | 200 with `main_admin`, workspace `admin-demo-soc-1` |
| admin on super-admin portal | 403 PORTAL_MISMATCH with `allowedPortals:["admin"]` — correct denial |
| superadmin `superadmin` portal=super-admin | 200, role `super_admin` — WORKS |
| Legacy root mount `POST /auth/login` (no /api/v1) | works (v1Router double-mounted) — mobile `kBaseUrl` strip is harmless |

## Resident API smoke (Bearer demo resident)
| Endpoint | Status | Time |
|---|---|---|
| /api/v1/users/me | 200 | 0.8s |
| /api/v1/notices-v2 | 200 | 0.4s |
| /api/v1/funds/summary | 200 | 3.8s ⚠ slow |
| /api/v1/funds/maintenance-status | 200 | 2.0s |
| /api/v1/complaints | 200 | 0.3s |
| /api/v1/amenities | 200 | 0.4s |
| /api/v1/polls-v2 | 200 | 0.4s |
| /api/v1/events-v2 | 200 | 0.7s |
| /api/v1/notifications | 200 | 0.4s |
| /api/v1/parking/my | 200 | 0.3s |
| /api/v1/visitors | 200 `{visitors:[]}` | 0.3s |
| /api/v1/resident/family | **403** "No active membership" → FIXED in 74361a5 (pending deploy) |
| /api/v1/resident/vehicles, /kyc, /emergency-contacts | **403** same root cause → same fix |
| /api/v1/parcels | **500** (same root cause; parcels error map lacks NOT_A_MEMBER) → same fix |
| /api/v1/domestic-help | **403** same root cause → same fix |

## Findings
- F-1 cold start (P1): mitigations added — keepalive workflow + client wake-retry (mobile 15s timeout was guaranteeing failure during wake).
- F-2 membership gap (P1): fixed in code, deploy pending.
- `funds/summary` 3.8s (P3): acceptable on free tier; index review if it worsens.
- No endpoint returned an empty-message 500; error shapes are consistent JSON.
