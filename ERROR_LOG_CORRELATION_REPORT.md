# Error Log Correlation Report — 2026-07-10

## Backend
- `contextMiddleware` (server.js:70) provides request-scoped tracing/log context (AsyncLocalStorage `requestContextStore`), used by the DB layer for RLS + slow-query logs.
- Structured pino-style logs with level/time/env/service; security events tagged SEC-FAIL/SEC-WARN/SEC-ALERT; login logs include ip+userId.
- Error responses are consistent JSON (`{error}` or `{success:false,error:{code,message}}`) — no empty-message 500s observed live.

## Correlations established this audit
| Symptom | Network evidence | Backend cause |
|---|---|---|
| "connection errors with empty messages" locally | `PostgreSQL Heartbeat Failed` with empty error | local Postgres container down |
| Blank screens after idle | client TimeoutException at 15s | Render cold start >60s |
| Resident sections "Something went wrong" | 403 `No active membership for this user` (parcels: 500) | Postgres members row missing (Firestore-only membership) |
| "superadmin login not working" | 403 PORTAL_MISMATCH | wrong prefilled account, not an auth defect |

## Gaps (P2 hardening)
- No `X-Request-Id` response header — clients can't quote a request id in bug reports. Suggest: echo the context id in responses and render it in frontend error states.
- parcels_pg error map lacked NOT_A_MEMBER (mapped to 500) — moot after self-heal fix, but align its map with resident_pg's.
- Frontend (both) should show retry + request id, never raw stack traces — mobile currently prints response bodies via debugPrint only in debug builds (OK).
