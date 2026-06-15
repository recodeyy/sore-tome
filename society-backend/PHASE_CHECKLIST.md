# SERO Backend — Implementation Checklist

Tracks progress against `SERO_Backend_Complete_Prompt_Pack.md` (the 7-phase plan + 92 Admin capabilities). Status is **evidence-based**: a module is marked ✅ Done only when it has a Postgres migration, a typed service, a wired route, and **passing integration tests** against a real database.

_Last updated: 2026-06-16. Verified via `knex migrate:latest` (batches 1–10 applied) and `jest` integration suites (63 tests passing across Phases 2/4/5)._

Legend: ✅ Done & tested · 🟡 Partial · ⛔ Not started

---

## Phase status (Section 18 of the prompt)

| Phase | Scope | Status | Notes |
|---|---|---|---|
| **0 — Audit & stabilization** | Reproduce build/test, fix deps, CI, freeze contract | 🟡 Partial | `BACKEND_AUDIT.md` done. Dependency-conflict fix, CI pipeline, and clean-`npm ci` proof still pending. |
| **1 — Platform foundation** | Strict TS, config, DB/Redis, auth, RLS, errors, audit, outbox, files, observability | 🟡 Partial | DB/Redis/Pino/Sentry exist. **Gaps:** mixed JS/TS (runs via `tsx`, no build gate), auth is custom JWT (not Firebase ID-token), **no Postgres RLS**, **no outbox/event table**, file service minimal. |
| **2 — Society structure & users** | Wings/blocks/floors/units, members, committee, KYC, bulk import | 🟡 Partial | **Structure (wings/blocks/floors/units/occupancy) ✅ done & tested.** Members/committee/KYC still Firestore; CSV/XLSX bulk import ⛔. |
| **3 — Finance** | Billing, invoices, journal, payments, receipts, expenses, OCR, dues, Razorpay | ✅ Mostly done | Double-entry ledger, invoices, payments, expenses (maker-checker), dues, Razorpay webhook + integration tests. Bank reconciliation & GST credit-notes 🟡. |
| **4 — Complaints, communication, governance** | Complaints/SLA, notices, channels, polls, meetings, events, rules | ✅ Done | 7 modules, 38 tests. See capability table below. |
| **5 — Staff, amenities, parking, assets** | Attendance/roster/leave/payroll, booking, parking, asset maintenance | 🟡 Mostly done | Staff ✅, Parking ✅, Assets ✅ (tested). **Amenities 🟡** (basic booking exists; eligibility/pricing/blackouts/approval/refund/calendar pending). |
| **6 — AI & reports** | RAG ingestion, AI tool confirmation, scheduled reports & exports | 🟡 Partial | AI chat/RAG/extraction/guardrails exist (pre-existing). Finance report service + cron exist. Generic report templates/scheduled exports/retention ⛔. |
| **7 — Scale & release hardening** | Load/soak, security tests, backup restore, failure injection, runbooks | ⛔ Not started | No k6 proof of 3k users, no restore evidence, no failure-injection suite, no release gate run. |

---

## 92 Admin capabilities

### A. Dashboard & control center (1–8) — 🟡 Partial
- 1 Dashboard summary 🟡 (DashboardService exists) · 2 Real-time vitals 🟡 · 3 Activity feed 🟡 · 4 Trend analytics ⛔ · 5 Actionable alerts 🟡 (SecurityAlertService) · 6 Quick actions 🟡 · 7 Global search ⛔ · 8 Configurable widgets ⛔

### B. Society setup & member admin (9–22) — 🟡 Partial
- 9 Society profile 🟡 · 10 Logo/branding ⛔ · **11 Wings ✅ · 12 Blocks ✅ · 13 Floors ✅ · 14 Units ✅ · 16 Occupancy history ✅** · 15 Bulk import ⛔ · 17 Member lifecycle 🟡 (Firestore) · 18 Family/co-owners 🟡 · 19 Committee 🟡 · 20 KYC workflow 🟡 · 21 Society settings 🟡 · 22 Onboarding checklist 🟡 (structure summary added)

### C. Finance, billing, payments, accounting (23–42) — ✅ Mostly done
- 23 Chart of accounts ✅ · 24–26 Billing config/templates/bulk gen ✅ · 27 Draft/publish/cancel ✅ · 28 Recurring billing 🟡 · 29 Proration 🟡 · 30 Late fees/waivers 🟡 · 31 GST invoices 🟡 · 32 Razorpay order ✅ · 33 Webhook idempotency ✅ · 34 Payment allocation ✅ · 35 Receipts 🟡 · 36 Double-entry ledger ✅ · 37 Expense capture ✅ · 38 Expense approval (maker-checker) ✅ · 39 Receipt OCR ✅ (AI) · 40 Bank reconciliation ⛔ · 41 Dues/ageing ✅ · 42 Reports/export 🟡

### D. Communication, community, governance (43–58) — ✅ Done
- **43–47 Notices CRUD/versions/schedule/publish/audience/reads ✅** · 48 Announcements (multi-channel) 🟡 (notices + FCM) · 49 AI notice writer 🟡 (AI exists) · **50 Channels/read-only/unread ✅ · 51 Moderation/abuse/soft-delete ✅** · **52 Polls ✅ · 53 Vote integrity (atomic) ✅** · **54 Meetings/calendar ✅ · 55 Agenda/attendance/quorum/proxies ✅ · 56 Resolutions/minutes/action items ✅** · **57 Events/RSVP/waitlist ✅** · **58 Rules/documents/versions/full-text search ✅**

### E. Complaint & SLA management (59–69) — ✅ Done
- **59 Categories/SLA policy ✅ · 60 Create/edit ✅ · 61 Routing 🟡 (manual+reason; AI routing hook pending) · 62 Assignment ✅ · 63 Priority/override ✅ · 64 SLA pause/resume (business hours) ✅ · 65 Escalation ladder 🟡 (events captured; worker pending) · 66 Internal vs resident notes ✅ · 67 Attachments 🟡 · 68 Status state machine/reopen/duplicate ✅ · 69 CSAT/analytics ✅**

### F. Staff, attendance, roster, payroll (70–79) — ✅ Mostly done
- **70 Staff CRUD ✅ · 71 Permissions/restricted access 🟡 · 72 Attendance check-in/out (no-dup) ✅ · 73 Shift/roster/conflict ✅ · 74 Leave types/balance/approve (race-safe) ✅ · 75 Payroll run (idempotent + maker-checker) ✅ · 76 Overtime/holiday calc 🟡 (proration done) · 77 KYC/expiry 🟡 (field + reminder hook) · 78 Incidents/disciplinary ✅ · 79 Reports 🟡**

### G. Amenities & bookings (80–85) — 🟡 Partial
- 80 Amenity CRUD ✅ · 81 Hours/blackouts/holidays ⛔ · 82 Eligibility/pricing/deposit ⛔ · **83 Atomic booking + overlap protection ✅** · 84 Approval/cancel/refund/no-show 🟡 · 85 Calendar/utilization analytics ⛔

### H. Parking, assets, reporting, audit (86–92) — 🟡 Mostly done
- **86 Slot inventory/EV/accessible ✅ · 87 Vehicle registry/allocation/transfer/release/waitlist ✅ · 88 Visitor parking/violations/fines ✅** · **89 Asset registry ✅ · 90 PM schedules/work orders (no-dup)/breakdowns/AMC/downtime/parts ✅** · 91 Report templates/scheduled/exports ⛔ · 92 Immutable audit/access logs 🟡 (audit logs exist in Firestore + Postgres partitioning)

---

## What was built this cycle (Postgres, tested)

| Module | Migration | Service | Route | Tests |
|---|---|---|---|---|
| Complaints/SLA | `…160000_create_complaints` | `ComplaintService` | `/complaints` | 7 ✅ |
| Notices | `…170000_create_notices` | `NoticeService` | `/notices-v2` | 6 ✅ |
| Polls/voting | `…170500_create_polls` | `PollService` | `/polls-v2` | 6 ✅ |
| Events | `…171000_create_events` | `EventService` | `/events-v2` | 6 ✅ |
| Meetings/governance | `…171500_create_meetings` | `MeetingService` | `/meetings` | 6 ✅ |
| Rules/documents | `…172000_create_rules_documents` | `RuleService` | `/rules-v2` | 6 ✅ |
| Channels/moderation | `…173000_create_channels` | `ChannelService` | `/channels-v2` | 5 ✅ |
| Staff/payroll | `…180000_create_staff` | `StaffService` | `/staff-v2` | 5 ✅ |
| Parking | `…181000_create_parking` | `ParkingService` | `/parking` | 6 ✅ |
| Assets/maintenance | `…182000_create_assets` | `AssetService` | `/assets` | 6 ✅ |
| Society structure | `…190000_create_structure` | `StructureService` | `/structure` | 4 ✅ |

New Postgres routes mounted at distinct paths (`-v2` / new) so the live Firestore-backed Flutter app keeps working; **client cutover to these endpoints is a separate deliverable.**

---

## Remaining work (priority order)

1. **Phase 2 finish** — member lifecycle, committee, KYC on Postgres; CSV/XLSX bulk import with dry-run/rollback.
2. **Phase 5 amenities** — eligibility, pricing/deposit, blackouts/holidays, approval/refund/no-show, calendar analytics.
3. **Phase 1 foundation hardening** — Postgres RLS policies, outbox table + realtime gateway (WebSocket/SSE), Firebase ID-token auth consolidation, finish JS→TS.
4. **Phase 6 reports** — report templates, scheduled report jobs, access-controlled PDF/Excel exports + retention.
5. **Dashboard (A 1–8)** — trend analytics, tenant-scoped global search, configurable widgets.
6. **Phase 7 release hardening** — k6 load/soak proving 2–3k users, security test suite (OWASP API top 10), backup/restore evidence, failure injection, runbooks, release gate.
7. **Cross-cutting** — wire Flutter services to the new `*-v2` endpoints and remove mock/direct-Firestore writes (Definition of Done, Section 20).

---

## How to verify

```bash
cd society-backend
npx knex migrate:latest --env development          # applies all migrations
npx jest __tests__/*.integration.test.ts --runInBand   # runs the Postgres integration suites
```
