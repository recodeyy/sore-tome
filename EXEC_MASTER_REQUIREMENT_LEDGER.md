# EXEC_MASTER_REQUIREMENT_LEDGER

Phase 0 ledger. Date 2026-06-16. Source: 9 canonical packs + login master.
Status legend (existing impl): C=Complete, P=Partial, M=Missing, X=Conflicting, O=Obsolete.
Current status: NS=Not started, IP=In progress, BL=Blocked, IM=Implemented, TE=Tested, VE=Verified.

> Evidence base: code inspected under `society-backend/src/routes` (25 TS route files),
> `society-backend/migrations` (41), `society-backend/__tests__` (other agent reports 51 suites /
> 267 tests PASS), `sero/lib/{screens,providers,services,config}`. The frontend blocker
> `sero/lib/config/dev_config.dart:1 kUseMockData=true` and ~29 admin screens importing
> `data/mock_data.dart` gate every FE row to BL/P. See `MASTER_EXISTING_IMPLEMENTATION_AUDIT.md`.
> Full machine-readable rows are in `EXEC_MASTER_REQUIREMENT_LEDGER.json`. This MD is the summary view.

## CORE-BE — Core backend (SERO_Backend_Complete_Prompt_Pack.md)

| ID | Section | Summary | Pri | Exist | Endpoint/Artifact | Cur | Notes |
|----|---------|---------|-----|-------|-------------------|-----|-------|
| CORE-BE-01 | §3.1 | Strict TypeScript, Node/Express core stack | P0 | C | tsconfig + src/ TS | P | strict flag not re-verified this pass |
| CORE-BE-02 | §3.2 | PostgreSQL is source of truth for operational/financial data | P0 | C | migrations/ + _pg routes | P | dual-stack: legacy Firestore JS routes/ still present |
| CORE-BE-03 | §3.3 | Multi-tenancy + RLS tenant isolation | P0 | C | migrations/20260616204000_enable_rls.js; rls_isolation.integration.test | P | tested; non-superuser app role added recently |
| CORE-BE-04 | §4.1-4.2 | Identity, sessions, RBAC, canonical roles | P0 | C | auth context + permission model | P | central permission model present |
| CORE-BE-05 | §5 A-H | 92 Admin backend capabilities (dashboard→audit) | P0 | P | admin_dashboard/finance/members/... _pg | P | route surface exists; per-capability proof pending |
| CORE-BE-06 | §6 | Required data model (platform/structure/finance/...) | P0 | C | 41 migrations incl. ledger, outbox, vector, audit partition | P | |
| CORE-BE-07 | §7 | API design: response standards, endpoint groups | P1 | P | routes/*.ts | P | OpenAPI completeness unverified |
| CORE-BE-08 | §8.1-8.7 | Critical workflows: bill gen, payment, expense, booking, SLA, voting, AI tool | P0 | P | services/finance,amenities,polls,ai | P | break into per-workflow rows (see JSON) |
| CORE-BE-09 | §9 | Realtime architecture (SSE/sockets, events) | P1 | C | routes/realtime.ts; sse_manager (FE) | P | |
| CORE-BE-10 | §10 | Files & uploads (private storage) | P1 | C | services/files | P | file-security tests added recently |
| CORE-BE-11 | §11 | Performance/scale targets | P1 | M | — | NS | no load run; see PERF |
| CORE-BE-12 | §12 | Security requirements | P0 | P | RLS/file-security/webhook tests | P | full audit pending Phase 9 |
| CORE-BE-13 | §13 | Reliability, jobs (BullMQ), idempotency, outbox | P0 | C | services/outbox,cron | P | |
| CORE-BE-14 | §14 | Observability | P1 | P | — | P | metrics/tracing not verified |
| CORE-BE-15 | §15-16 | Testing requirements + CI/CD quality gates | P0 | C | __tests__ 51 suites; .github workflows | P | GH Actions pipeline added |
| CORE-BE-QC-* | QC §1-22 | Backend QA/QC audit (ledger invariants, isolation, concurrency, DR) | P0 | P | QC_* reports exist | P | DR/backup = skipped smoke only |

## LOGIN — Auth & separate portals (SERO_Separate_Role_Login_Master_Prompt.md)

| ID | Section | Summary | Pri | Exist | Cur | Notes |
|----|---------|---------|-----|-------|-----|-------|
| LOGIN-01 | §2-3 | Login landing page + 4 role cards | P0 | P | BL | FE gated by kUseMockData |
| LOGIN-02 | §4.2-4.5 | Dedicated SuperAdmin/Admin/Staff/Resident login screens | P0 | P | BL | screens exist; live-data cutover pending |
| LOGIN-03 | §5-6 | Multi-role accounts + canonical role normalization | P0 | P | P | providers/shared/auth_provider.dart |
| LOGIN-04 | §7-8 | Backend auth architecture + auth APIs | P0 | C | P | auth routes + login tests |
| LOGIN-05 | §9 | Portal mismatch behavior (portal never grants role) | P0 | P | P | precedence rule; needs negative test |
| LOGIN-06 | §10 | Login state screens (pending/rejected/suspended/inactive) | P1 | P | NS | states partially present |
| LOGIN-07 | §11 | Password / OTP / MFA / recovery | P0 | P | P | OTP/MFA presence unverified |
| LOGIN-08 | §12 | Session & workspace security (rotation/revocation/devices) | P0 | P | P | |
| LOGIN-09 | §14 | Correct shell routing (Super→SuperAdminShell etc.) | P0 | P | P | main_shell.dart + auth_guard.dart |
| LOGIN-10 | §15 | Login page live-data | P1 | M | BL | mock |
| LOGIN-11 | §18-20 | QC + backend + Flutter login tests | P0 | P | P | role-portal login tests exist |

## SUPER — Super Admin (SERO_Super_Admin_Complete_Prompt_Pack.md), 31 capabilities

| ID | Section | Summary | Pri | Exist | Cur | Notes |
|----|---------|---------|-----|-------|-----|-------|
| SUPER-BE-01 | BE §1-3 | Two-plane arch, platform identity/roles/permissions | P0 | C | P | super_admin.ts + 3 test suites |
| SUPER-BE-02 | FE §5 A-F | 31 capabilities backend support (overview→security/ops) | P0 | P | P | break per-capability in JSON |
| SUPER-FE-01 | FE §3-4 | super_admin role, SuperAdminShell, nav tabs/drawer | P0 | P | P | providers/super_admin present |
| SUPER-FE-02 | FE §6.1-6.20 | 20 Super Admin screens (overview, societies, KYC, revenue, feature controls, impersonation, audit, health...) | P0 | P | BL | screens exist (feature_controls/impersonation/kyc_verification seen); live data pending |
| SUPER-FE-03 | FE §6.4-6.5 | Society approval queue + KYC verification | P0 | P | P | kyc_verification_screen.dart present |
| SUPER-FE-04 | FE §6.17 | Impersonation (audited) | P0 | P | P | impersonation_screen.dart |
| SUPER-FE-05 | FE §10-11 | Security-sensitive FE reqs + FE tests | P0 | P | NS | |
| SUPER-QC-* | QC | Super Admin QC + traceability (31 caps) | P0 | P | NS | |

## STAFF — Staff/Guard (SERO_Staff_Complete_Prompt_Pack.md), 32 capabilities

| ID | Section | Summary | Pri | Exist | Cur | Notes |
|----|---------|---------|-----|-------|-----|-------|
| STAFF-BE-01 | BE | Staff/guard backend (visitor, parcel, incident, SOS, patrol, tasks, attendance) | P0 | C | P | staff_pg.ts, guard_pg.ts + tests |
| STAFF-FE-01 | FE §3-4 | Canonical staff types, StaffShell, bottom nav + status | P0 | P | P | screens/guard present |
| STAFF-FE-02 | FE §6.1-6.16 | 16 staff screens (home, visitors, walk-in, QR, parcels, incident, SOS, patrols, handover, tasks, attendance, leave) | P0 | P | BL | mock cutover |
| STAFF-FE-03 | FE §7 | Offline-first behavior | P1 | M | NS | |
| STAFF-FE-04 | FE §10 | Camera/QR/OTP/location/media | P1 | P | NS | |
| STAFF-FE-05 | FE §8 | Shared cross-role integration | P0 | P | NS | |
| STAFF-QC-* | QC | Staff QC (32 caps) | P0 | P | NS | |

## RES — Resident (SERO_Resident_Complete_Prompt_Pack.md), 57 capabilities

| ID | Section | Summary | Pri | Exist | Cur | Notes |
|----|---------|---------|-----|-------|-----|-------|
| RES-BE-01 | BE | Resident backend (bills/pay, visitors, complaints, community, amenities, SOS, docs) | P0 | C | P | resident_pg.ts + tests |
| RES-FE-01 | FE §3-4 | Resident roles, ResidentShell, bottom nav + context | P0 | P | P | screens/resident present |
| RES-FE-02 | FE §6.1-6.23 | 23 resident screens incl. bills, checkout, autopay, visitors, complaints, notices, events, polls, marketplace, carpool, lost&found, amenities, SOS, rules, NOCs | P0 | P | BL | mock cutover |
| RES-FE-03 | FE §6.6-6.8 | Payment checkout / auto-pay / receipts | P0 | P | BL | financial UI safety §12 |
| RES-FE-04 | FE §7 | AI Copilot integration in resident app | P1 | P | P | ai_chat screens present |
| RES-FE-05 | FE §10-11 | Offline + notifications/deep links | P1 | P | NS | |
| RES-QC-* | QC | Resident QC (57 caps) | P0 | P | NS | |

## AI — AI Copilot + cross-role (SERO_AI_Chatbot_Cross_Role_Complete_Prompt_Pack.md)

| ID | Section | Summary | Pri | Exist | Cur | Notes |
|----|---------|---------|-----|-------|-----|-------|
| AI-BE-01 | BE §3+ | Server-owned conversations, streaming, secure RAG, citations | P0 | C | P | services/ai/* full suite + 4 AI test suites |
| AI-BE-02 | BE | Typed action proposals + human confirmation + tool authorization | P0 | C | P | AIGuardrailsService etc. |
| AI-BE-03 | BE | Prompt-injection protection, role/field/tenant isolation | P0 | C | P | AIGuardrailsService |
| AI-FE-01 | FE §7.1-7.5 | Chat screen, conversation behavior, EN/HI/Hinglish, quick actions | P0 | P | P | screens/shared/ai_chat/* present |
| AI-FE-02 | FE §8 | Answer/action card types + action proposal UX | P0 | P | P | proposed_action_card.dart present |
| AI-FE-03 | FE §9 | Attachment/document UX (private) | P1 | P | NS | |
| AI-FE-04 | FE §13 | Realtime streaming behavior + reconnect | P0 | P | P | sse_manager.dart |
| CROSS-01..14 | FE §10.1-10.14 | 14 cross-role modules (auth, users, notices, complaints, funds, rules, events, visitors, staff, assets, parking, payments, analytics, governance) | P0 | P | P | one canonical record + state machine per module (precedence rule) |

## AI-INNOV — AI innovation (SERO_AI_Innovation_Unique_Features_Master_Prompt.md)

| ID | Section | Summary | Pri | Exist | Cur | Notes |
|----|---------|---------|-----|-------|-----|-------|
| AI-INNOV-01 | §3-4 | Generate/rank >=25 net-new ideas | P2 | P | NS | AIInnovationService exists (pulse/clusters/anomalies/predictions) |
| AI-INNOV-02 | §5-6 | Scoring framework + shortlist (top 3x3) | P2 | M | NS | strategy doc not produced this pass |
| AI-INNOV-03 | §7-8 | Min recommended set + detailed product design | P2 | M | NS | |
| AI-INNOV-04 | §11-12 | AI action safety tiers + privacy/ethics | P0 | P | P | guardrails service |
| AI-INNOV-05 | §all | STOP after strategy without human approval (no auto-implement) | P0 | n/a | NS | enforcement rule |

## SEC / PERF / QC / RELEASE (cross-cutting)

| ID | Source | Summary | Pri | Exist | Cur | Notes |
|----|--------|---------|-----|-------|-----|-------|
| SEC-01 | QC §26, Master §10 | Auth/MFA/session/RBAC/tenant/RLS/IDOR/injection/SSRF/file/payment-replay/vote-uniqueness/AI-injection | P0 | P | NS | partial tests; full audit Phase 9 |
| SEC-02 | Master §10 | Financial invariants: debits=credits, no float money, immutable invoices, single webhook effect | P0 | P | NS | ledger migration exists; invariant suite pending |
| PERF-01 | Load pack, Master §11 | 10K/20K progressive load (baseline→soak→stress→failure→recovery) | P1 | M | NS | no run; MASTER_PERFORMANCE_CAPACITY_REPORT.md = not executed |
| QC-01 | Final QC §1-30 | Whole-app E2E QC across all roles/pages/routes/endpoints | P0 | P | NS | per-section log in EXEC_PROMPT_SECTION_EXECUTION_LOG.md |
| QC-02 | Final QC §12 | Static/mock/placeholder detection | P0 | X | BL | kUseMockData=true + 29 mock screens; see MASTER_MOCK_STATIC_STUB_REPORT.md |
| QC-03 | Final QC §19 | Cross-role canonical-record journeys (Master §9, 10 journeys) | P0 | M | NS | not executed end-to-end |
| RELEASE-01 | Master §5 Phase 11 | APK/AAB: clean, analyze, test, secure signing, signed build, device install, report | P0 | M | BL | last release = FAIL gate (mock on, debug signing) |
| RELEASE-02 | QC §19, DR | Backup/restore evidence | P0 | M | BL | backup_restore_smoke skips real dump |

## Status rollup (this pass, indicative — see JSON for per-ID)
- Requirement rows extracted: 80 (this MD summary) / expanded testable rows tracked in JSON.
- By existing-impl: Complete ~15, Partial ~50, Missing ~10, Conflicting 2 (QC-02, CORE-BE-02 dual-stack), Obsolete 0.
- By current-status: Verified 0, Implemented 0, Partial(in-progress baseline) ~45, Blocked ~12, Not started ~23.
- No requirement marked Verified — no end-to-end proof executed in Phase 0 (correct per master prompt: ledger-first, no bulk coding).
