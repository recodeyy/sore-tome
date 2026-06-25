# EXEC_MASTER_IMPLEMENTATION_SEQUENCE

Date 2026-06-16. Phase plan from Master §5, annotated with exists-vs-missing per code inspection.
Legend: [DONE] mostly exists/verified · [PARTIAL] exists, proof/cutover pending · [TODO] missing/not run.

| Phase | Scope | State | Annotation / evidence |
|-------|-------|-------|------------------------|
| 0 — Baseline | Read prompts, build ledger, clean install, run builds/tests, audit, record baseline | [PARTIAL] | THIS PASS. Ledger built (EXEC_*). `flutter analyze` ran: 128 issues, 0 errors. Backend tests reported 51 suites/267 PASS by other agent. Audit in MASTER_EXISTING_IMPLEMENTATION_AUDIT.md. |
| 1 — Core backend foundation | TS strict, env, PG migrations+RLS, Redis, BullMQ, auth ctx, permissions, domain services, audit/outbox, idempotency, storage, payments/ledger, observability, CI/CD | [PARTIAL] | 25 `_pg` routes, 41 migrations (RLS, ledger, outbox, vector, audit partition), services per domain, GH Actions exist. Gaps: observability unverified, legacy Firestore routes still present (C-02), strict-flag/OpenAPI unverified. |
| 2 — Auth & separate login portals | landing, 4 portals, MFA/OTP/recovery, workspace select, multi-role, sessions, shell routing, guards, states | [PARTIAL] | Backend auth + role-portal login tests exist. FE screens exist but BLOCKED by mock cutover (C-03). State screens + portal-mismatch negative test missing. |
| 3 — Society Admin | all Admin pages/routes/APIs/finance/members/governance/staff/amenities/reports/audit on live data | [PARTIAL] | Backend `_pg` substantial. FE: dashboard cut over; ~29 admin screens on mock (BLOCKED). |
| 4 — Super Admin | FE/BE/QC line-by-line, 31 capabilities + traceability | [PARTIAL] | super_admin.ts + 3 suites; 20 screens exist (kyc/impersonation/feature_controls seen); live-data + per-cap proof pending. |
| 5 — Staff | FE/BE/QC line-by-line, 32 capabilities + shared workflows | [PARTIAL] | staff_pg/guard_pg + tests; 16 screens exist; offline + mock cutover pending. |
| 6 — Resident | FE/BE/QC line-by-line, 57 capabilities + shared workflows | [PARTIAL] | resident_pg + tests; 23 screens exist; payment UI + mock cutover pending. |
| 7 — AI Copilot & cross-role | EN/HI/Hinglish, server-owned convos, streaming/reconnect, secure RAG, citations, attachments, typed actions, human confirm, injection protection, isolation, shared services | [PARTIAL] | Full `services/ai/*` + 4 AI suites + guardrails; FE ai_chat screens + sse_manager. 14 cross-role modules present; end-to-end + private attachment proof pending. |
| 8 — AI innovation | >=25 ideas, scoring, shortlist, PRD/architecture/safety/roadmap; STOP before auto-implementing | [TODO] | AIInnovationService exists (pulse/clusters/anomalies/predictions). Strategy deliverables not produced. Must NOT auto-implement (C-06). |
| 9 — Whole-platform integration & QC | all roles/pages/routes/endpoints/controls, cross-role journeys, live data, realtime, notifications, payments, AI, offline, security, backup/restore; fix P0/P1; rerun | [TODO] | Not executed. 10 cross-role journeys (QC-03) not run. |
| 10 — 10K-20K load | progressive baseline->500->3k->10k->20k->soak->stress->failure->recovery | [TODO] | No load run. k6 suite scaffolding exists (10K-20K). |
| 11 — APK/AAB release | clean/format/analyze/tests/config-validate/de-mock/signing/build/device-install/verify/report | [TODO/BLOCKED] | Last release = FAIL gate (mock on, debug signing, cutover incomplete). |

## Critical-path blockers gating later phases
1. C-03 mock cutover + `kUseMockData=false` (owned by live-data agent) gates Phases 2-6 FE verification, 9, 11.
2. C-02 legacy Firestore route removal gates "PostgreSQL source of truth" claim.
3. Backup/restore real evidence (RELEASE-02) gates Phase 9/11 release verdict.
4. No load run (PERF-01) gates any scale claim.
