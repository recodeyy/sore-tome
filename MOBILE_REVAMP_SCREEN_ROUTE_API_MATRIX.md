# MOBILE_REVAMP — Screen / Route / API Matrix

> 2026-07-07. Granularity: feature module (310 Dart screens don't fit a hand table; per-screen detail lives in `mobile_revamp_findings.json` and is extended as Phase 2/4 touches each screen). Probe = live HTTP result against local backend with scoped role token.

Legend: ✅ live-verified 200 · ⚠️ works with caveat · ❌ broken/missing · ▢ not yet probed

## Resident (shell: `resident_shell.dart`, tabs: Home/Community/Amenities/Payments/Profile)

| Module | Screens (dir) | State mgmt | API | Probe | Notes |
|---|---|---|---|---|---|
| Home dashboard | `resident/home/*` | Provider | `/users/me`, `/notices-v2`, `/funds/maintenance-status` | ✅ | counts live |
| Payments/bills | `resident/payments/*`, `finance/` | Provider | `/finance/invoices`, `/funds/payments/create-order`, `/funds/payments/verify`, `/funds/transactions` | ✅/▢ | Razorpay test keys in env; E2E pending Phase 5 |
| Visitors | `resident/visitors/*` | Provider | `/visitors`, `/visitors/:id/action`, `/visitors/:id/checkout` | ✅ | pre-approval + QR pass = Phase 2/4 build |
| Complaints | `resident/complaints/*` | Provider | `/complaints` | ✅ | chat via channels |
| Community | `resident/community/*` (marketplace, carpool, lost&found) | Provider | `community_pg` routes | ▢ | added June-30 |
| Notices/polls/events | shared screens | Provider | `/notices-v2`, `/polls-v2`, `/events-v2` | ✅ | poll voting uses legacy `/polls/{id}/vote` in one path ⚠️ |
| Amenities | `resident/amenities/*` | Provider | `/amenities` | ✅ | booking E2E pending |
| Parking/vehicles | `resident/parking`, `resident/vehicles` | Provider | `/parking/my`, `/resident/vehicles` | ✅ | |
| Family/KYC/emergency | `resident/profile/*` | Provider | `/resident/family`, `/resident/kyc`, `/resident/emergency-contacts` | ✅ | |
| Documents/rules | `rules/` | Provider | `/rules-v2`, `/rules-v2/documents` | ▢ | one legacy `/rules` caller ⚠️ |
| **Onboarding (society→flat→approval)** | **missing** | — | needs `/societies/search`, `/resident/join-requests` | ❌ | §5 flow to build |

## Staff / Guard (shell: `staff_shell.dart`, tabs today: Security/Assistant/Profile — spec wants Home/Gate/Tasks/Security/More)

| Module | Screens | API | Probe | Notes |
|---|---|---|---|---|
| Gate dashboard | `guard/guard_home.dart` (single file) | `/guard/visitors`, `/guard/visitors/check-in` | ✅ login+list | Whole staff app = 1 screen; §8 requires full build-out |
| Visitor entry/exit/QR/OTP | partial in guard_home | `/visitors/checkin`, `/visitors/:id/checkout` | ▢ | provider quick-select (Swiggy/Zomato/…) missing |
| Parcels | missing | — | ❌ | |
| SOS/incidents/patrol | missing | backend `/security/*` exists (src/modules) | ❌ app side | |
| Tasks (complaints) | missing | `/complaints` (assignee view) | ❌ app side | |
| Attendance | via staff-v2 | `/staff-v2/attendance/check-in|out` | ✅ route exists | UI minimal |

## Admin (shell: `admin_shell.dart`; 80 screens — most complete role)

| Module | API | Probe |
|---|---|---|
| Dashboard | `/admin/dashboard/summary|vitals|preferences` | ✅ |
| Members | `/members-v2`, `/members-v2/committee` | ▢ |
| Structure | `/structure/wings|blocks|units|summary` | ▢ |
| Finance | `/finance/invoices|payments|expenses|reports/*` | ✅ |
| Complaints | `/complaints`, `/complaints/analytics` | ✅ |
| Staff | `/staff-v2`, payroll, roster, leave | ✅ |
| Parking | `/parking/slots|allocations|requests|violations` | ❌ `/parking/allocations` 404 |
| Notices/polls/events/meetings | `/notices-v2`, `/polls-v2`, `/events-v2`, `/meetings` | ✅ |
| Amenities/assets/reports | `/amenities`, `/assets*`, `/reports/*` | ✅/▢ |
| Society profile/logo/setup | `/society/*` | ▢ |

## Super Admin (19 screens)

| Module | API | Probe |
|---|---|---|
| Platform/societies/revenue/support | `/super-admin/*` | ▢ login untested (rate-limit window); credentials TBD |
| Feature controls / impersonation / KYC | `/super-admin/*` | ▢ + C-03 context-async fixes needed |

## Cross-cutting

- 116 unique HTTP paths called from Flutter; canonical v2 endpoints dominate. Legacy still consumed: `/funds/*` (payments — intentional for Razorpay), `/polls/{id}/vote`, `/rules`, `/channels`, `/issues` (one-off), `/notices` (one-off).
- Realtime: `sse_manager.dart` → `/realtime/sse` (outbox events).
- Notifications: see NOTIFICATION_GAP report (P0 broken).
