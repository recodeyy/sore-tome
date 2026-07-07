# MOBILE_REVAMP_FEATURE_MATRIX

> 2026-07-07. Evidence-based status of the mobile revamp against `SERO_Mobile_App_Full_Revamp_Prompt.md`.
> Legend: ✅ done & verified · 🟡 partial · ⛔ blocked (needs external resource). "Proof" cites the test/file that demonstrates it.

## Findings register (from `mobile_revamp_findings.json`) — resolution

| ID | Sev | Area | Title | Status | Proof |
|---|---|---|---|---|---|
| MR-001 | P0 | notifications | FCM token never persisted | ✅ fixed | `device_tokens` table + `PATCH /users/me` + `POST /notifications/devices`; send path reads active tokens & prunes dead (`services/notificationService.js`); e2e shows `notified:N` |
| MR-002 | P0 | deployment | Only live backend is expiring GCP | 🟡 documented, provisioning pending | `DEPLOYMENT_*` docs + `render.yaml`; app URL overridable via `--dart-define`. Needs user's Render/Neon accounts to execute |
| MR-003 | P0 | security | adminsdk JSON in repo | ✅ mitigated | `git check-ignore` → ignored/untracked; flagged for on-disk delete + key rotation |
| MR-004 | P1 | api | GET /parking/allocations 404 | ✅ fixed | `src/routes/parking_pg.ts:57` GET added; `ParkingService.listAllocations` |
| MR-005 | P1 | api | complaint assign 500 non-uuid | ✅ fixed | `ComplaintService.assign` accepts text id; full jest suite 310 pass |
| MR-006 | P1 | product | resident onboarding flow missing | ✅ built | `screens/resident/onboarding/*` (search→unit→profile→status) + `/onboarding` routes + `societies_public.ts` |
| MR-007 | P1 | product | staff single screen vs 5-tab | ✅ built | `staff_shell.dart`: Home/Gate/Tasks/Security/More |
| MR-008 | P1 | notifications | app NotificationService stub | ✅ built | `notification_service.dart`: bg handler, 5 channels, deep-links (3 states), multi-device, token-refresh |
| MR-009 | P1 | product | visitor pre-approval/parcels/SOS missing | ✅ built | `visitor_approval_screen`, `gate_screen`; visitor+SOS cross-role e2e pass |
| MR-010 | P2 | ui | competing palettes | ✅ unified | `theme.dart` canonical `#064E3B/#10B981/#ECFDF5` per §4 |
| MR-011 | P2 | crash | use_build_context_synchronously ×12 | ✅ fixed | `flutter analyze` → No issues found |
| MR-012 | P2 | nav | resident tabs lack Pay/Visitors | ✅ fixed | `resident_shell.dart`: Home/Community/**Pay**(center)/Visitors/More |
| MR-013 | P2 | demo | wrong seed society/flat | ✅ fixed | `seed_hubtown_sunkist.js`; unit `A-1402` present in DB |
| MR-014 | P2 | api | legacy endpoints consumed | 🟡 mostly | new `-v2` paths used; a few legacy one-offs remain (non-blocking) |
| MR-015 | P3 | quality | 40 analyze lints | ✅ fixed | `flutter analyze` → 0 issues |
| MR-016 | P3 | auth | super-admin creds undocumented | 🟡 | admin/resident/guard seeded+documented; super-admin login still to document |

## Prompt-section capability coverage

| § | Capability | Status | Proof |
|---|---|---|---|
| 5 | Separate login portals (SA/Admin/Staff/Resident) + backend role verify | ✅ | login-smoke e2e 3/3 |
| 5 | Resident onboarding (society→flat→approval→unlock) | ✅ | MR-006 |
| 6 | Role bottom-nav (all 4 shells) | ✅ | resident/staff shells; admin/super-admin shells present |
| 7.1 | Resident home live dashboard | ✅ | live probes pass (audit) |
| 7.2 | Payments (bills, Razorpay test, UPI QR, receipts, history) | ✅ | `payment_demo.integration` 7 tests |
| 7.3 | Visitors — resident **Invite/pre-approval** (type select + gate pass code) | ✅ | `invite_visitor_screen.dart` → live `POST /resident/visitors`; FAB on Visitors tab + `/resident/invite-visitor` route |
| 7.3 | Visitors (provider select, staff entry/exit) | ✅ | cross-role visitor journey |
| 7.3 | Domestic help — full lifecycle (add/pause/revoke/history + gate check-in/out) | ✅ | **built real**: migration `…140000`, `DomesticHelpService`, `/domestic-help` routes, `domestic_help_screen.dart`; tests 4/4; live seed (Sunita Devi) |
| 8 | Parcel log/collect flow (guard log + OTP handover + resident view) | ✅ | **built real**: `parcels` table, `ParcelService`, `/parcels` routes, resident `parcels_screen.dart` + staff `staff_parcels_screen.dart`; tests + live probe (Amazon OTP 482913) |
| 7.4 | Complaints (raise/track/chat/reopen/rating) | ✅ | complaint journey + assign fix |
| 7.5 | Community (notices/polls/events/discover) | ✅ | notice+poll journeys |
| 7.6 | Amenities (browse/book/cancel) | ✅ | amenity booking journey |
| 7.7 | Parking & vehicles | ✅ | parking allocate journey + MR-004 |
| 7.9 | Emergency SOS | ✅ | security incident journey |
| 8 | Staff/Guard operational app | ✅ | MR-007 |
| 9 | Admin mobile | ✅ | admin shell + members/operations screens |
| 10 | Notifications + realtime | ✅ | MR-001/MR-008 + cross-role notify counts |
| 11 | Live backend APIs | ✅ | e2e against real PG; no mock in revamped screens |
| 12 | Demo data via seed | ✅ | MR-013 |
| 13 | Payment demo (Razorpay test + UPI) | ✅ | payment_demo tests |
| 14 | Crash-free states | ✅ | error boundary + analyze clean |
| 15 | Deployment off GCP | 🟡 | docs done; provisioning pending |
| 16 | UI polish (green-white) | ✅ | palette unified; analyze clean |
| 17 | 12 automated cross-role journeys | ✅ | `e2e_journeys` 37 assertions pass |
| 18 | Final reports | ✅ | this set of 9 docs |
