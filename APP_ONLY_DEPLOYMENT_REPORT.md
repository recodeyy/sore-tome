# APP_ONLY_DEPLOYMENT_REPORT

> 2026-07-07 · scope: **mobile app only** (no website). Commit `b3ab522`.
> Executes `SERO_App_Only_Deployment_Full_Testing_Prompt.md` Phases 0–3.

## Phase 0 — Clean baseline (recorded, nothing hidden)

| Check | Result |
|---|---|
| Commit SHA | `b3ab522f5aafdf60ace36214d203d893e2754e78` |
| Backend `tsc --noEmit` | ✅ clean |
| Backend `jest` | ✅ 277 pass (53 suites, incl. 4 new parcels/domestic); e2e need live server → 40/40 with server up |
| Flutter `analyze` | ✅ No issues found |
| Flutter `test` | ⚠️ no `test/` directory — no widget tests authored (documented, not a failure) |
| `dart format` | ✅ applied to new screens |

## Phase 1 — Backend deploy (data plane LIVE, compute pending)

| Service | Provider | Status |
|---|---|---|
| Database | **Neon Postgres** | ✅ 45 migrations applied + Hubtown Sunkist seed (incl. parcels + domestic help). Verified `\dt`, unit A-1402, live API reads |
| Redis | **Upstash** (TLS) | ✅ PING=PONG, set/get verified |
| Storage | Firebase Storage (`sero-73976`) | ✅ unchanged, signed uploads via `/users/upload-image`, `/users/me/photo` |
| Firebase Admin | `sero-73976` | ✅ FCM send path + token lifecycle verified |
| Razorpay | Test Mode | ✅ order/verify/webhook + 7 payment tests |
| API compute | **Render** (target) | ⏳ blueprint (`render.yaml`) ready; API key verified; **web-service deploy pending code delivery** (see §Blocker) |
| Health/readiness | `/health` | ✅ 200 (readiness = same handler) |
| Device-token endpoint | `POST /notifications/devices` | ✅ 401 without auth (mounted), writes `device_tokens` |
| Realtime (SSE) | `/realtime` | ✅ mounted |

## Phase 2 — Mobile release config

| Item | Result |
|---|---|
| API base URL | `env.dart` reads `--dart-define=API_BASE_URL`; default is a cloud URL (not localhost) |
| Firebase Android | `google-services.json` present in APK |
| Notification permission + channels | ✅ 5 channels, Android 13+ permission requested |
| Deep links | ✅ named-route deep-link handler (3 app states) |
| Release signing | ✅ APK assembled release (see Phase 3) |
| Version | `1.0.0+8` |
| No localhost/dev URL | ✅ only a code comment references 10.0.2.2 |
| No mock fallback (`kUseMockData`) | ✅ flag removed entirely |

## Phase 3 — Build

| Command | Result |
|---|---|
| `flutter build apk --release` | ✅ `app-release.apk` 66.6 MB (exit 0) |
| Archived | `builds/sero-app-20260707-parcels-domestic.apk` |
| SHA-256 | `06692ef8a6cf6c98619a82f7692112b7111ac812524003ccb396c7b45b76d67a` |
| split-per-abi / appbundle | ⏳ not built this pass (universal APK done); one command each when needed |
| Firebase App Distribution / GitHub Release | ⏳ upload pending (needs distribution credentials / Git) |

## Blocker (single, honest)

**Backend compute is not on a public URL yet.** Render builds from a Git repo or registry; the GitHub token was excluded by the user and no container registry account is available, so the web-service step needs either a 2-min dashboard Blueprint connect or explicit Git authorization. **The data plane it will use (Neon + Upstash) is already live and seeded.** Until then, the app talks to the existing (expiring) GCP backend or a local/override URL.

## Deployment facts (for §18 final format)

- Backend URL: _pending Render deploy_ (data plane: Neon + Upstash live)
- Backend provider: Render (target) · Database: Neon · Redis: Upstash · Storage: Firebase · Firebase: sero-73976
- APK: `builds/sero-app-20260707-parcels-domestic.apk` · Version 1.0.0+8
- App Distribution / GitHub Release links: _pending upload_
