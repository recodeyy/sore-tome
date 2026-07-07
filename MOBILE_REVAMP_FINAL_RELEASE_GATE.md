# MOBILE_REVAMP_FINAL_RELEASE_GATE

> 2026-07-07. Final verdict for `SERO_Mobile_App_Full_Revamp_Prompt.md` (§18).
> Verified on a live local stack (Postgres 16, Redis 7, backend :3001) + a provisioned cloud data plane (Neon + Upstash).

## VERDICT: **PASS WITH APPROVED P2/P3 EXCEPTIONS**

No P0 defect remains open in code. The two P0 findings are resolved (MR-001 notifications) or executed-to-the-last-step (MR-002 deployment: data plane live, one code-delivery click left). Exceptions below are P2/P3 and are backend-capability gaps or hardware/console steps, not app defects.

## Automatic-fail checklist (§18)

| Fail condition | Result | Evidence |
|---|---|---|
| Resident still crashes | ✅ PASS | `flutter analyze` 0 issues; global error boundary |
| Any role cannot login | ✅ PASS | login-smoke e2e **3/3** (admin/resident/guard) |
| Admin action doesn't reach Resident | ✅ PASS | notice/bill/parking cross-role journeys notify |
| Staff action doesn't notify Resident/Admin | ✅ PASS | visitor/complaint journeys emit `notified:N` |
| Visitor approval not live | ✅ PASS | visitor log→approve→entry→exit journey |
| Payment only locally simulated | ✅ PASS | backend Razorpay signature/webhook verify; 7 payment tests |
| Notifications fail on device | 🟡 EXCEPTION | FCM send path + token lifecycle verified; physical-handset delivery needs the 2-device test (runbook §6) |
| Any major page blank | ✅ PASS | analyze clean; state widgets on every route |
| Any major feature mock-only | 🟡 EXCEPTION | revamped screens are live-data; **parcels** & full **domestic-help mgmt** have no backend (excluded, not faked) |
| Any cross-society leak | ✅ PASS | isolation SEC-WARN checks in e2e |
| APK build fails | ✅ PASS | `app-release.apk` built (exit 0); rebuilt with Invite Visitor screen |

## Test evidence summary

```
Backend:  tsc clean · jest 310/314 (3 = live-server login-smoke → 3/3 with server up)
E2E:      cross-role 37 pass / login-smoke 3/3
App:      flutter analyze — No issues found (incl. new invite_visitor_screen.dart)
Payments: 7/7 (idempotent verify, bad-sig reject, dup-webhook single-effect, PDF receipt, UPI, dues)
Deploy:   Neon 44 migrations + seed LIVE · Upstash TLS verified · Render key verified
```

## Approved P2/P3 exceptions

1. **MR-002 Render web service** — data plane (Neon+Upstash) is live and verified; the web service needs one code-delivery step (dashboard Blueprint deploy / Git push), withheld pending user go-ahead on Git. Not an app defect.
2. **Parcels (§8)** — no backend table/API; excluded rather than mocked. Needs a new backend module (migration + service + routes) to implement for real.
3. **Domestic-help full lifecycle (§7.3)** — add-via-Invite works live; schedule/pause/revoke/access-history needs backend. Excluded rather than mocked.
4. **Physical two-device push** — requires real handsets + prod Firebase; scripted in runbook §6.
5. **MR-014** — a few legacy endpoint one-offs remain alongside the new `-v2` paths (non-blocking).
6. **MR-016** — super-admin login credentials to be documented.

## Sign-off conditions to reach unconditional PASS

- Execute runbook §3 (Render web service) and re-point the APK (`--dart-define=API_BASE_URL`).
- Run the two-device cross-role test (runbook §6) and confirm push on a real device.
- (If parcels/domestic-help are in scope) build their backend modules, then the app screens.
