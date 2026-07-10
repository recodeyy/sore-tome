# Final Deployment Release Gate — 2026-07-10

## Gate criteria (§17)

| Criterion | Verdict |
|---|---|
| Backend connects to correct deployed DB | ✅ PASS (live data endpoints healthy) |
| Render service healthy | ✅ PASS (with cold-start mitigation pending deploy) |
| Website reaches backend | ✅ PASS (BFF verified live) |
| Mobile APK reaches backend | ✅ PASS (correct URL; contract verified) |
| CORS blocks production website | ✅ N/A-by-design (BFF); latent misconfig fixed |
| Resident blank screen after login | 🟡 root causes fixed in code — **pending backend deploy + APK rebuild** |
| Core roles can login | 🟡 resident/admin/superadmin ✅ live; staff/guard creds missing → seed & verify |
| Workspaces null/incorrect | ✅ PASS (activeWorkspace correct on live) |
| Migrations on deployed DB | ✅ PASS (auto preDeploy; schema current) |
| Notifications on physical device | ☐ BLOCKED — device test required |
| Website action updates app / app updates website | 🟡 same-backend architecture verified; UI runs blocked on device |
| Payment simulated locally | ✅ real Razorpay Test Mode wired (webhook secret presence in dashboard unverified) |
| Receipt download | ☐ device |
| Wrong recipient isolation | 🟡 RLS + tenant scoping verified in code; Society-B live test needs second society |
| Any P0 open | ✅ none open in code; three fixes await deploy |
| Unapproved P1 | 🟡 F-6 git split-brain awaits owner decision |
| Secrets printed/committed | ✅ PASS (masked throughout; git clean) |

## Verdict: **FAIL (deploy-pending)** → expected **PASS WITH APPROVED P2/P3 EXCEPTIONS** once:
1. Backend tree pushed to `render-live` (command in RENDER_DEPLOYMENT_REPORT.md) and `/resident/family` returns 200.
2. Website redeployed (`npm run sst:deploy`) and superadmin tab login verified in browser.
3. APK rebuilt and idle-wake login passes on a device.
4. Device-side FCM + two-session sync suites executed (currently the only untested surface).
5. Git default-branch decision made (also activates the keepalive cron).

Per §17: PASS may not be declared until deployed website + backend + DB + release APK are tested **together** — items 3–4 are the remaining gap and require a physical device.
