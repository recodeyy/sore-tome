# SERO Admin & Super-Admin Web Portal — Executive Summary

**Deliverable:** `sero-admin-web/` — a Next.js 14 + TypeScript control portal for SERO
society operations, sharing the **same backend and database** as the mobile app.
**Date:** 2026-07-07 · **Demo society:** Hubtown Sunkist (A-1402).

---

## What was built

A production-structured, **live-data** admin website with two portals:

- **Society Admin portal** — Dashboard, Members, Billing, Payments, Bank Reconciliation,
  Expenses, Reports, Notices, Polls/AGM, Events, Complaints, Staff, Visitors/Security,
  Parking, Assets, AI Assistant, Settings.
- **Super Admin portal** — Platform Dashboard, Societies, Approvals, Revenue, Support
  Tickets, Global Announcements, System Health, Audit Logs.

Every screen reads/writes the **canonical backend** (`society-backend`, :3001) through a
Next.js **BFF proxy** — there is **no second database and no mock data**. Money is handled
in integer minor units end-to-end.

## Cross-role sync (proven)

The website drives the exact same Postgres-backed `-v2`/domain endpoints the Flutter app
consumes. Verified live: an admin **created + published a notice on the web** and it was
**read back from the shared DB** (status `published`) — the same feed the resident app
reads. Complaint assignment targets the staff app; billing writes appear in resident dues.
See `WEBSITE_CROSS_ROLE_SYNC_REPORT.md`.

## AI + Voice

- **AI assistant** (floating, all pages): Groq/Gemini via a server-side proxy — **keys never
  reach the browser**. Role/tenant scoped by the backend. High-impact prompts (send/generate/
  delete/refund…) require **explicit human confirmation** before execution.
- **Voice**: ElevenLabs **text-to-speech** via `/api/voice/tts` server proxy — returns valid
  MP3 audio (verified). Mic input via Web Speech API. Privacy notice shown.

## Multilingual

i18n dictionaries for **English, Hindi, Marathi, Gujarati, Kannada** + language selector with
persisted preference. IDs, amounts, and receipt numbers are never machine-translated.
See `WEBSITE_MULTILINGUAL_PLAN.md`.

## Verification (evidence-based)

| Check | Result |
|---|---|
| `tsc --noEmit` typecheck | **PASS** (exit 0) |
| `next build` (35 routes) | **PASS** |
| API cross-role E2E (Playwright) | **5/5 PASS** |
| Login → httpOnly cookie → live proxy | **PASS** |
| Unauthenticated proxy | **401 (blocked)** |
| Admin write → shared DB read-back | **PASS (published)** |
| AI chat proxy (Groq) | **PASS** |
| ElevenLabs TTS proxy | **PASS (20 KB MP3)** |
| Super-admin live dashboard | **PASS** |

## AWS readiness

Deploy plan, environment matrix, and runbook target **AWS Amplify Hosting** (SSR) or
**S3+CloudFront** (static export), with **Secrets Manager/SSM** for keys, **ACM** for TLS,
**CloudWatch** logs, and **WAF** rate limits. No real AWS resources were provisioned (no cost).

## Verdict

**PASS WITH APPROVED P2/P3 EXCEPTIONS.** All P0/P1 acceptance gates are green (live data,
cross-role sync, live exports, AI authz, voice confirmation, tenant isolation, deployable).
P2/P3 exceptions are enhancements (full write-CRUD on every operations module, backend-side
AI key provisioning, background export jobs). See `WEBSITE_FINAL_RELEASE_GATE.md`.
