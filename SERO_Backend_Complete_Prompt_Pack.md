# SERO Backend Prompts

This file contains two copy-ready prompts:

1. Master backend implementation prompt
2. Backend QA/QC and release audit prompt

---

# SERO Admin Backend — Master Implementation Prompt

## Role

Act as a **Principal Backend Architect, Staff TypeScript Engineer, Database Architect, Security Engineer, and SRE**. You are working on **SERO — AI Powered Society Management Platform**.

You will receive the full repository containing:

- A Flutter frontend under `sero/`
- A partial Node.js/Express backend under `society-backend/`
- Project documentation and feature plans
- Existing Firebase, PostgreSQL, Redis, BullMQ, Razorpay, AI/RAG, audit, and notification code

Your task is to **audit, complete, refactor, test, and productionize the backend for the full Admin application without redesigning the existing Flutter UI**.

Do not create a toy backend, demo API, mock server, or isolated proof of concept. Build a production-grade, multi-tenant backend capable of supporting **2,000–3,000 concurrently active users**, multiple societies, financial transactions, real-time updates, background jobs, AI workflows, and strict tenant isolation.

---

# 1. Repository-first working rules

1. Inspect the entire repository before changing code:
   - Flutter routes, screens, models, Riverpod providers, service classes, mock data, direct Firestore usage, expected JSON fields, navigation flows, upload flows, and error states.
   - Existing backend routes, middleware, services, migrations, tests, Firestore rules, Redis logic, AI services, cron jobs, Docker files, and environment variables.

2. Create a **frontend-to-backend contract matrix** before implementation. For every Admin screen/action, record:
   - Screen/file
   - User action
   - Required role/permission
   - Endpoint
   - Request body/query
   - Response model
   - Database tables touched
   - Side effects
   - Audit event
   - Notification event
   - Error and empty states

3. Reuse valid existing code, but do not preserve insecure, duplicated, inconsistent, mock-only, or partially working code merely for compatibility.

4. Do not rebuild the Flutter design. You may update:
   - API service classes
   - Riverpod providers
   - JSON parsing/models
   - Authentication integration
   - Real-time subscriptions
   - Error/loading handling
   - Removal of mock data and direct client writes

5. Every implemented feature must work end to end from the existing Flutter screen to the database and back.

6. Do not mark a module complete until:
   - Its migrations exist
   - Its API is documented
   - Authorization is enforced
   - Tenant isolation is tested
   - Validation is present
   - Audit logging exists
   - Unit/integration/contract tests pass
   - The Flutter screen no longer depends on mock data for that function

---

# 2. Current repository context to preserve or improve

The current codebase already contains concepts for:

- Flutter + Riverpod
- `/api/v1` HTTP API
- Admin, main admin, secretary, treasurer, resident, staff, and guard roles
- Authentication and refresh logic
- Notices, issues, funds, rules, events, visitors, staff, facilities, polls, channels
- Admin dashboard and access logs
- Firebase Admin, Firestore, Firebase Messaging
- PostgreSQL, pgvector, Knex
- Redis, Redlock, BullMQ
- Razorpay
- AI chat, receipt extraction, document ingestion, RAG, semantic cache, AI costs, AI logs
- Sentry and Pino logging
- Docker deployment

The existing backend is partial and mixed JavaScript/TypeScript. Consolidate it into a coherent, typed architecture.

---

# 3. Non-negotiable architecture

Use a **modular monolith with background workers**, designed so high-volume modules can later be split into services.

## 3.1 Core stack

- Node.js LTS
- TypeScript in strict mode
- Express or Fastify; prefer keeping Express if migration risk is high
- PostgreSQL as the authoritative source of truth for operational and financial data
- Knex, Prisma, or Drizzle for migrations/querying; select one and use it consistently
- PostgreSQL Row Level Security as defense in depth for tenant isolation
- Redis for:
  - Distributed cache
  - Distributed rate limiting
  - Idempotency
  - Redlock/distributed locks
  - Presence
  - Short-lived OTP state
  - Job queues
- BullMQ for background jobs
- Firebase Auth as the identity provider and Firebase Cloud Messaging for push notifications
- S3-compatible object storage or Firebase Storage for files, with signed URLs and malware scanning
- WebSocket or Server-Sent Events for live updates; use an outbox-driven event stream
- OpenAPI 3.1 generated and kept in CI
- Pino structured logs, OpenTelemetry traces/metrics, and Sentry error reporting
- Docker images with health/readiness endpoints
- GitHub Actions or equivalent CI

## 3.2 Data ownership

Use PostgreSQL as the primary system of record for:

- Societies
- Users, memberships, roles, permissions
- Wings, blocks, floors, units
- Committee members
- Bills, invoices, payments, receipts, journal entries, ledger
- Expenses and approvals
- Complaints and SLA data
- Staff, attendance, leave, rosters, payroll
- Amenities and bookings
- Parking and vehicles
- Assets, maintenance, vendors, AMC contracts
- Notices, polls, meetings, events, rules, reports
- Audit logs and access logs
- Idempotency keys and outbox events

Firestore must not remain an unrestricted second source of truth. Either:

A. Replace business-data Firestore reads/writes with API + WebSocket/SSE, or  
B. Use Firestore only as a read projection fed by the backend outbox.

Never let the Flutter client write financial, role, approval, complaint workflow, booking, parking, asset, or audit data directly.

## 3.3 Multi-tenancy

- Every tenant-owned table must contain `society_id`.
- Derive `society_id` only from the verified identity/session.
- Never trust a client-supplied `society_id`.
- Every repository query must require tenant context.
- Add PostgreSQL RLS policies.
- Super-admin cross-tenant access must require an explicit privileged context and be separately audited.
- Add automated Society A vs Society B isolation tests for every module.
- Unique constraints must generally include `society_id`.
- Cache keys, object paths, queue payloads, WebSocket rooms, logs, and vector-search filters must include tenant context.

---

# 4. Authentication, sessions, RBAC, and permissions

## 4.1 Identity

Consolidate authentication around Firebase Auth. Do not keep two independent password databases unless there is a documented migration requirement.

- Verify Firebase ID tokens server-side.
- Store application profile and membership in PostgreSQL.
- Support revocation and “logout all devices.”
- Store device sessions and FCM tokens.
- Require MFA for high-privilege roles when enabled.
- Add secure account recovery and phone/email verification.
- Never log tokens, OTPs, passwords, or secrets.

## 4.2 Roles

Support at least:

- `super_admin`
- `main_admin`
- `admin`
- `secretary`
- `treasurer`
- `committee_member`
- `facility_manager`
- `security_manager`
- `guard`
- `staff`
- `resident_owner`
- `resident_tenant`
- `auditor`

Do not hard-code all access in route files. Implement:

- Roles
- Permissions
- Role-permission mapping
- Society-scoped user-role assignments
- Optional temporary/delegated access with expiry
- Permission middleware such as:
  - `society.read`
  - `society.update`
  - `member.approve`
  - `member.manage`
  - `finance.read`
  - `finance.bill.generate`
  - `finance.expense.approve`
  - `notice.publish`
  - `complaint.assign`
  - `complaint.resolve`
  - `staff.payroll.run`
  - `amenity.manage`
  - `parking.allocate`
  - `asset.maintenance.manage`
  - `report.export`
  - `audit.read`

Sensitive actions must support maker-checker approval where configured.

---

# 5. The 92 Admin backend capabilities to implement

Implement the following capabilities as complete backend workflows, not merely endpoints.

## A. Dashboard and control center — 1 to 8

1. Admin dashboard summary with pending approvals, open complaints, today’s collection, maintenance due, visitors today, and staff on duty.
2. Real-time society vitals: parcels pending, guards on duty, active maintenance, and system health.
3. Recent activity feed across members, finance, complaints, visitors, notices, bookings, and assets.
4. Date-range trend analytics for collections, expenses, complaints, occupancy, visitors, and staff.
5. Actionable alerts for overdue bills, breached SLAs, expiring documents/AMCs, payment failures, and security incidents.
6. Quick-action backend support for add notice, create poll, add member, generate bill, and other dashboard actions.
7. Tenant-scoped global search across members, units, bills, complaints, staff, vehicles, assets, notices, and documents.
8. Configurable dashboard widgets and saved filters per admin.

## B. Society setup and member administration — 9 to 22

9. Read/update society profile, registration details, description, address, timezone, currency, financial year, and contact details.
10. Upload, crop, version, replace, and delete society logo/branding assets.
11. CRUD for wings with ordering, active status, and validation.
12. CRUD for blocks/towers linked to wings.
13. Floors and numbering schemes.
14. CRUD for flats/units with area, unit type, ownership status, occupancy status, and maintenance weight.
15. CSV/XLSX bulk import with dry run, validation report, duplicate detection, and rollback.
16. Occupancy history for owner, tenant, vacant, and jointly occupied units.
17. Member lifecycle: invite/register, pending, approve, reject, suspend, deactivate, reactivate, and move-out.
18. Family members, co-owners, tenants, emergency contacts, and unit relationships.
19. Committee member management with designation, term, permissions, and tenure history.
20. KYC and document workflows with review status, rejection reason, expiry, signed URLs, and audit trail.
21. Society-level settings including numbering, billing defaults, notification preferences, booking policies, and feature flags.
22. Society setup progress/checklist with completion percentages, blockers, and onboarding milestones.

## C. Finance, billing, payments, and accounting — 23 to 42

23. Chart of accounts and configurable income/expense categories.
24. Maintenance billing configuration by flat, area, occupancy, fixed amount, or formula.
25. Bill templates and charge components such as maintenance, sinking fund, parking, water, penalties, and adjustments.
26. Bulk bill generation for selected period, wings, blocks, units, or members.
27. Draft, preview, approval, publish, cancel, and regenerate billing runs.
28. Recurring scheduled billing with safe retry and duplicate prevention.
29. Proration for move-in/move-out, ownership changes, and partial periods.
30. Late fees, interest, grace periods, waivers, and configurable penalty rules.
31. GST-compliant invoices/credit notes with immutable invoice numbering and tax breakdown.
32. Razorpay order creation or other provider adapter, without storing card data.
33. Webhook signature verification, idempotent payment processing, replay protection, and reconciliation status.
34. Full, partial, advance, split, and over-payments with allocation against invoices.
35. Receipt generation, download, email/push delivery, and void/reissue controls.
36. Proper double-entry accounting with immutable journal entries and ledger postings.
37. Expense capture with vendor, category, invoice, tax, payment method, and attachments.
38. Expense approval workflow with maker-checker thresholds and rejection comments.
39. Receipt OCR/AI extraction with human verification before posting.
40. Bank statement import and bank reconciliation with matched, partially matched, and unmatched entries.
41. Dues, defaulters, ageing buckets, reminders, waivers, and collection follow-ups.
42. Income, expense, collection efficiency, cash-flow, trial balance, ledger, GST, and period reports with PDF/Excel export.

## D. Communication, community, and governance — 43 to 58

43. Notice CRUD with categories, priorities, status, author, and version history.
44. Draft, preview, schedule, publish, unpublish, archive, and expiry workflows.
45. Target notices by all residents, role, wing, block, unit, ownership type, or custom audience.
46. Secure notice attachments with file validation and signed access.
47. Read receipts, acknowledgement-required notices, reminders, and unread counts.
48. Global/society announcements through in-app, push, email, and optional SMS channels.
49. AI notice writer with editable drafts, guardrails, source trace, and no automatic publishing.
50. Real-time channels, channel membership, read-only channels, moderation, pagination, and unread counters.
51. Message/listing moderation, abuse reports, soft deletion, retention, and admin actions.
52. Poll creation, options, audience, start/end dates, anonymous mode, and result visibility.
53. Vote integrity: one eligible vote per user/unit as configured, atomic tallying, and auditability.
54. AGM/committee meeting creation and calendar management.
55. Agenda, attendance, quorum, proxies, document pack, and voting eligibility.
56. Resolutions, minutes, decisions, action items, owners, deadlines, and completion tracking.
57. Society events, RSVP, capacity, waitlist, reminders, and attendance.
58. Rules, bylaws, NOCs, records, document versions, full-text search, and society-scoped RAG ingestion.

## E. Complaint and SLA management — 59 to 69

59. Complaint categories, subcategories, departments, default priority, and SLA policy.
60. Complaint create/edit with unit, location, category, description, privacy, and contact preference.
61. Rule-based and AI-assisted routing with an explainable assignment result.
62. Assignment/reassignment to internal staff, committee member, or vendor.
63. Priority, impact, urgency, due date, and admin override.
64. SLA timers that pause/resume according to status and business hours.
65. Escalation rules, reminder ladder, breach events, and recipient configuration.
66. Internal notes, resident-visible comments, chat, mentions, and complete timeline.
67. Attachments, image/video proof, before/after evidence, and malware scanning.
68. Valid status transitions, resolution notes, reopen flow, duplicate linking, and merge.
69. Closure acknowledgement, resident CSAT, resolution analytics, ageing, and SLA reports.

## F. Staff, attendance, roster, and payroll — 70 to 79

70. Staff profile CRUD with role, department, contractor, contact, status, joining/leaving dates, and assigned areas.
71. Staff permissions and restricted app access.
72. Attendance check-in/out, manual correction, approval, device metadata, and optional geofence/QR.
73. Shift templates, duty rosters, swaps, coverage rules, and conflict validation.
74. Leave types, balance, request, approve/reject, cancellation, and calendar.
75. Payroll configuration, earnings, deductions, advances, payslips, run approval, and payment status.
76. Overtime, holiday, late-arrival, and attendance-based calculations.
77. Staff KYC, contracts, training, certifications, and expiry reminders.
78. Incident reports, performance notes, disciplinary actions, and private access control.
79. Attendance, leave, payroll, overtime, staffing, and audit reports.

## G. Amenities and bookings — 80 to 85

80. Amenity CRUD for gym, hall, clubhouse, pool, courts, and custom facilities.
81. Operating hours, slot duration, blackouts, maintenance closures, and holiday calendars.
82. Member eligibility, capacity, guest rules, pricing, deposit, tax, and cancellation policy.
83. Atomic booking creation with overlap protection, distributed locking, capacity checks, and waitlist.
84. Approval, rejection, cancellation, reschedule, refund, no-show, and payment workflow.
85. Booking calendar, reviews, revenue, utilization, and audit analytics.

## H. Parking, assets, reporting, and audit — 86 to 92

86. Parking slot inventory, type, location, accessibility, EV support, and status.
87. Resident vehicle registry, allocation history, waiting list, transfer, release, and reserved slots.
88. Visitor parking, parking requests, violations, fines, evidence, and resolution.
89. Asset registry for lifts, generators, pumps, CCTV, fire equipment, and custom assets.
90. Preventive maintenance schedules, work orders, breakdowns, vendors, AMC contracts, spare parts, downtime, and completion proof.
91. Report templates, on-demand generation, scheduled reports, report runs, access-controlled PDF/Excel files, and retention.
92. Immutable administrative audit logs and security/access logs with actor, tenant, request ID, before/after diff, IP/device, reason, result, and export.

---

# 6. Required data model

Create normalized migrations for at least the following logical entities. You may rename tables consistently, but do not omit functionality.

## Platform and access

- societies
- society_settings
- feature_flags
- users
- user_profiles
- society_memberships
- roles
- permissions
- role_permissions
- membership_roles
- user_sessions
- device_tokens
- invitations
- kyc_documents
- stored_files
- idempotency_keys
- audit_logs
- access_logs
- outbox_events
- notifications
- notification_deliveries

## Society structure

- wings
- blocks
- floors
- units
- unit_occupancies
- unit_members
- family_members
- committee_members
- vehicles
- emergency_contacts

## Finance

- chart_of_accounts
- billing_policies
- charge_components
- billing_runs
- invoices
- invoice_lines
- credit_notes
- journal_entries
- journal_lines
- payments
- payment_allocations
- payment_webhook_events
- receipts
- expenses
- expense_approvals
- vendors
- bank_accounts
- bank_statement_imports
- bank_statement_lines
- reconciliations
- reminder_runs

## Communication and governance

- notices
- notice_versions
- notice_audiences
- notice_reads
- channels
- channel_members
- messages
- message_reads
- moderation_reports
- moderation_actions
- polls
- poll_options
- poll_eligibility
- votes
- meetings
- meeting_agenda_items
- meeting_attendance
- proxies
- resolutions
- minutes
- action_items
- events
- event_rsvps
- rules
- rule_versions
- society_documents
- document_versions

## Complaints

- complaint_categories
- sla_policies
- complaints
- complaint_assignments
- complaint_comments
- complaint_attachments
- complaint_status_history
- complaint_sla_events
- complaint_escalations
- complaint_feedback

## Staff

- staff
- staff_documents
- shift_templates
- duty_rosters
- attendance_entries
- attendance_adjustments
- leave_types
- leave_balances
- leave_requests
- payroll_settings
- payroll_runs
- payroll_items
- staff_incidents

## Amenities, parking, and assets

- amenities
- amenity_schedules
- amenity_blackouts
- amenity_pricing_rules
- amenity_bookings
- booking_payments
- booking_reviews
- parking_slots
- parking_allocations
- parking_requests
- visitor_parking
- parking_violations
- assets
- asset_categories
- maintenance_schedules
- maintenance_work_orders
- asset_downtime
- amc_contracts
- maintenance_vendors
- spare_parts

## AI and jobs

- ai_documents
- document_chunks
- ai_conversations
- ai_messages
- ai_tool_actions
- ai_audit_logs
- ai_costs
- ingestion_jobs
- report_jobs
- job_runs

## Database rules

- Use UUIDs or ULIDs.
- Use `numeric`, never float, for money.
- Store money in minor units or fixed precision consistently.
- Use UTC timestamps and society timezone only for presentation/scheduling.
- Add created_by, updated_by, created_at, updated_at, deleted_at where relevant.
- Use soft deletion where audit/history is required.
- Add optimistic locking/version columns to mutable records.
- Add indexes for tenant + common filters.
- Add partial and unique indexes for active states.
- Add foreign keys and explicit delete behavior.
- Use transactions for multi-table writes.
- Add RLS policies and migration tests.

---

# 7. API design

Use `/api/v1`. Generate OpenAPI 3.1 and typed clients/models.

## Response standards

Success:

```json
{
  "success": true,
  "data": {},
  "meta": {
    "requestId": "uuid",
    "nextCursor": null
  }
}
```

Error:

```json
{
  "success": false,
  "error": {
    "code": "COMPLAINT_INVALID_TRANSITION",
    "message": "The complaint cannot move from resolved to in_progress.",
    "fieldErrors": {},
    "requestId": "uuid"
  }
}
```

During migration, provide a compatibility adapter or update Flutter service/provider parsing atomically so no screen breaks.

## API requirements

- Cursor pagination for high-volume lists
- Filtering, sorting, date range, and search
- Strict Zod validation for body, params, and query
- Correct 400/401/403/404/409/422/429/500 behavior
- `Idempotency-Key` for bill generation, payment actions, expense posting, booking, report jobs, and other retryable writes
- ETags or version checks for concurrent updates
- Rate limits by user + tenant + endpoint class, stored in Redis
- Request size and file size limits per route
- Signed upload URLs for large files
- Webhook endpoints must use raw request bodies
- Versioned webhook event storage
- API deprecation policy
- No undocumented legacy routes after migration

## Endpoint groups

Create complete CRUD/action APIs under:

- `/auth`
- `/me`
- `/admin/dashboard`
- `/society`
- `/structure/wings`
- `/structure/blocks`
- `/structure/floors`
- `/units`
- `/members`
- `/committee`
- `/documents`
- `/finance/accounts`
- `/finance/billing-policies`
- `/finance/billing-runs`
- `/finance/invoices`
- `/finance/payments`
- `/finance/expenses`
- `/finance/ledger`
- `/finance/reconciliation`
- `/notices`
- `/announcements`
- `/channels`
- `/polls`
- `/meetings`
- `/events`
- `/rules`
- `/complaints`
- `/sla-policies`
- `/staff`
- `/attendance`
- `/rosters`
- `/leave`
- `/payroll`
- `/amenities`
- `/bookings`
- `/parking`
- `/vehicles`
- `/assets`
- `/maintenance`
- `/reports`
- `/audit-logs`
- `/access-logs`
- `/notifications`
- `/ai`

Document every endpoint with permission, request/response examples, errors, idempotency, and emitted events.

---

# 8. Critical workflow logic

## 8.1 Bill generation

- Validate billing period and scope.
- Acquire a distributed lock per society + billing period + policy.
- Require an idempotency key.
- Resolve eligible units and charge formulas.
- Generate a preview/draft.
- On publish, create invoices, invoice lines, journal entries, and outbox events in one database transaction.
- Prevent duplicate invoice numbers and duplicate period billing.
- Queue PDF generation and notifications after commit.
- Support partial failure retry without duplicate bills.
- Preserve immutable published invoice snapshots.

## 8.2 Payment processing

- Create provider order with internal payment intent.
- Store only provider-safe identifiers.
- Verify webhook signature against raw body.
- Store webhook event before processing.
- Make webhook processing idempotent.
- Lock the payment intent.
- Validate amount, currency, society, order, and status.
- Post payment, allocations, receipt, journal entries, and outbox event atomically.
- Handle duplicate, delayed, out-of-order, failed, refunded, and disputed events.
- Reconciliation must never trust only the client callback.

## 8.3 Expense posting

- OCR produces a proposal only.
- Admin verifies vendor, date, amount, tax, category, and attachment.
- High-value or configured categories require approval.
- Approved expense creates immutable journal entries.
- Edits after posting use reversal/adjustment, not destructive mutation.

## 8.4 Amenity booking

- Validate member eligibility, outstanding-dues restrictions if configured, operating hours, blackout, capacity, and booking policy.
- Use a database constraint plus transaction/advisory lock to prevent double booking.
- Payment-required bookings remain held for a short TTL.
- Automatically release expired holds.
- Cancellation and refunds follow policy snapshots saved on the booking.

## 8.5 Complaint SLA

- SLA policy is snapshotted when complaint is created.
- Calculate due time using society timezone and business calendar.
- Persist pause/resume events.
- A worker sends reminders and escalations.
- Status changes must follow an explicit state machine.
- All assignments and status changes are auditable.
- Resident-visible and internal comments must be separated.

## 8.6 Voting

- Determine eligibility at poll/meeting start and snapshot it.
- Enforce one vote per eligible user or unit according to configuration.
- Use an atomic insert/unique constraint.
- Never expose individual votes for anonymous polls.
- Preserve auditable totals and quorum calculations.

## 8.7 AI tool actions

- AI can propose actions but cannot directly publish notices, post expenses, modify roles, generate final bills, resolve complaints, or make payments without explicit authorized confirmation.
- Validate every AI tool call through the same permission and business service used by normal APIs.
- Store prompt/model/provider/token/cost/tool/result metadata without exposing private content unnecessarily.
- Filter RAG retrieval by `society_id` at the database query level.
- Defend against prompt injection in uploaded documents.
- Add confidence/source citations and graceful fallback.

---

# 9. Real-time architecture

- Use an outbox table written in the same database transaction as business state.
- A worker publishes events to Redis Streams/PubSub or a broker.
- WebSocket/SSE gateway subscribes users to:
  - `society:{societyId}`
  - `user:{userId}`
  - Role/wing/block/unit rooms when authorized
- Re-authorize subscriptions.
- Support reconnect with last event ID where practical.
- Emit events for:
  - Dashboard changes
  - Member approvals
  - Notice publication/read acknowledgement
  - New/updated complaint
  - Payment success/failure
  - Bill publication
  - Visitor approval
  - Staff attendance
  - Booking status
  - SLA breach
  - Asset maintenance
- FCM notifications are asynchronous and retryable.
- Store delivery attempts and deduplicate notifications.

---

# 10. Files and uploads

- Use signed uploads; do not proxy large files through the API unless necessary.
- Validate MIME by content, not only extension.
- Enforce per-type size limits.
- Virus/malware scan before making files available.
- Use tenant-prefixed object keys.
- Encrypt at rest and in transit.
- Store metadata, checksum, uploader, status, and retention date.
- Strip dangerous metadata where needed.
- Prevent public buckets.
- Use short-lived signed download URLs.
- Add document access audit logs.
- Generate thumbnails/previews asynchronously.

---

# 11. Performance and scale target

“3,000 concurrent users” is not the same as 3,000 requests per second. Engineer and test for:

- 3,000 simultaneous authenticated users/connections
- At least 250 sustained mixed API requests/second for 15 minutes
- At least 500 requests/second burst for 60 seconds
- At least 3,000 concurrent WebSocket/SSE connections
- Heavy operations moved to queues
- Horizontal scaling with no in-memory session dependence
- PostgreSQL connection pooling
- Redis-backed distributed rate limiting and locks
- Query plans verified for high-volume endpoints
- Cache dashboard aggregates and reference data with event-based invalidation

Performance acceptance targets, excluding slow third-party calls:

- p95 read latency under 300 ms
- p95 normal write latency under 500 ms
- p99 under 1.5 s
- Error rate under 1%
- No cross-tenant reads
- No duplicate bills, payments, votes, bookings, or ledger posts
- No negative inventory/capacity caused by races
- Event loop lag and memory remain stable during soak testing

Do not use a single global IP rate limit that breaks apartment residents sharing NAT/Wi-Fi. Rate limit by authenticated identity, tenant, route risk, and IP fallback.

---

# 12. Security requirements

Implement and test:

- OWASP API Security Top 10
- Broken object-level authorization/IDOR prevention
- Broken function-level authorization prevention
- Tenant isolation
- SQL injection prevention
- NoSQL injection prevention during migration
- XSS-safe stored content
- SSRF protection for URL fetchers
- Path traversal prevention
- File upload security
- Webhook spoof/replay protection
- CSRF protection where cookie auth is used
- CORS allowlist
- Secure headers
- Brute-force and credential-stuffing controls
- OTP abuse controls
- Secret rotation
- Encryption in transit and at rest
- PII minimization and redaction
- Log scrubbing
- Data retention and deletion workflows
- Backup encryption
- Dependency and container scanning
- Admin action reasons for sensitive changes
- Session revocation and privilege-change token invalidation

Firestore rules, if retained, must enforce both tenant and role permissions. Same-tenant authentication alone is not sufficient to allow updates/deletes.

---

# 13. Reliability, jobs, and operations

- Separate API and worker processes.
- Every job must have:
  - Unique job key
  - Retry policy
  - Exponential backoff
  - Timeout
  - Dead-letter handling
  - Idempotent processor
  - Status persistence
  - Correlation/request ID
- Jobs include:
  - Scheduled billing
  - Bill/receipt/report PDF generation
  - Notifications
  - SLA reminders/escalations
  - Payment reconciliation
  - Booking hold expiry
  - Document parsing/OCR/embedding
  - Expiry reminders
  - Data exports
  - Audit retention/partition creation
- Add startup dependency checks.
- Add `/health/live`, `/health/ready`, and protected deep health.
- Graceful shutdown must stop accepting traffic, drain requests, and close workers/connections.
- Cron jobs must not execute independently on every replica; use leader election or queue schedulers.
- Add PITR-capable PostgreSQL backups and object-storage versioning.
- Document restore and disaster-recovery drills.

---

# 14. Observability

- Correlation/request ID propagated through API, database, queue, webhook, and notification paths.
- Structured logs with tenant/user IDs but no sensitive payloads.
- Metrics:
  - Request rate, latency, errors
  - DB pool usage and slow queries
  - Redis health
  - Queue depth, failures, retries, age
  - WebSocket connections
  - Payment webhook processing
  - Notification delivery
  - SLA breaches
  - AI token/cost/error/cache rate
- Distributed tracing for critical workflows.
- Sentry release/environment tagging.
- Alerts for:
  - Error-rate spike
  - Payment failures
  - Queue backlog
  - Database saturation
  - Redis outage
  - Cross-tenant security test failure
  - Backup failure
  - High AI spend
- Provide operational dashboards and runbooks.

---

# 15. Testing requirements

Create:

- Unit tests for services and state machines
- Integration tests against real PostgreSQL and Redis containers
- API tests with Supertest
- Contract tests against Flutter models/services
- Tenant isolation matrix tests
- RBAC permission matrix tests
- Payment webhook tests
- Ledger invariants/property tests
- Concurrency tests for billing, booking, voting, and payment
- Queue retry/idempotency tests
- File security tests
- AI RAG tenant-isolation and prompt-injection tests
- End-to-end happy and failure paths
- k6 load, spike, stress, and soak tests
- Migration up/down tests
- Backup/restore smoke test

Financial invariants must include:

- Sum of journal debits equals sum of credits
- Published invoices cannot be silently mutated
- Payment allocations do not exceed payment amount
- Invoice outstanding cannot become incorrect under retries
- Webhook replay creates no duplicate posting
- Reversals preserve audit history

Coverage is not the only gate. Critical business workflows and security branches must be explicitly tested.

---

# 16. CI/CD quality gates

CI must fail on:

- Non-reproducible install
- Lockfile drift
- Type errors
- Lint errors
- Unit/integration/contract test failures
- OpenAPI drift
- Migration failure
- Tenant-isolation failure
- High/critical dependency vulnerabilities without documented exception
- Secret detection
- Container scan failure
- Build failure
- Load-test regression beyond agreed thresholds for release candidate

Pin compatible dependency versions. Native dependencies such as `canvas` must either be removed, isolated in a worker image with required system packages, or made reproducibly installable.

---

# 17. Deliverables

Produce all of the following:

1. `BACKEND_AUDIT.md`
   - Existing architecture
   - Current working modules
   - Broken/incomplete modules
   - Security and scale risks
   - Frontend mock/direct-Firestore inventory

2. `FRONTEND_BACKEND_CONTRACT.md`
   - Every Admin screen/action mapped to API and schema

3. `ARCHITECTURE.md`
   - System components
   - Data ownership
   - Tenant isolation
   - Request and event flows
   - Scaling decisions
   - Architecture diagrams in Mermaid

4. `DATABASE_SCHEMA.md`
   - ERD in Mermaid
   - Table definitions
   - Constraints
   - Indexes
   - RLS

5. Complete migrations and seed data.

6. Complete TypeScript backend implementation.

7. Updated Flutter service/provider integration with mocks removed for completed modules.

8. `openapi.yaml` and generated API documentation.

9. Test suites and k6 scripts.

10. Docker Compose for local development:
    - API
    - Worker
    - PostgreSQL
    - Redis
    - Optional object-storage emulator
    - Optional mail catcher

11. Production Dockerfiles.

12. `.env.example` with every variable documented and no real secret.

13. CI workflow.

14. `DEPLOYMENT.md`, `RUNBOOK.md`, `BACKUP_RESTORE.md`, and `SECURITY.md`.

15. A final traceability matrix:
    - Feature 1–92
    - Frontend screen
    - Endpoint
    - Table
    - Test
    - Status

---

# 18. Implementation sequence

Work in safe phases and keep the repository runnable after each phase.

## Phase 0 — Audit and stabilization

- Reproduce install/build/test.
- Fix dependency conflicts and lockfile.
- Standardize Node version.
- Fix existing tests and open handles.
- Inventory mocks and direct Firestore access.
- Freeze API contract baseline.
- Add CI.

## Phase 1 — Platform foundation

- Strict TypeScript conversion
- Config validation
- Database/Redis abstraction
- Request context
- Auth and permissions
- Tenant RLS
- Unified errors/responses
- Audit/outbox
- File service
- Observability

## Phase 2 — Society structure and users

- Society, wings, blocks, floors, units
- Members, approvals, committee, KYC
- Bulk imports
- Flutter integration

## Phase 3 — Finance

- Billing, invoices, journal, payments, receipts
- Expenses, approvals, OCR verification
- Dues and reports
- Razorpay webhook and reconciliation

## Phase 4 — Complaints, communication, and governance

- Notices, channels, polls, meetings, events, rules
- Complaints, SLA, assignments, escalations, feedback

## Phase 5 — Staff, amenities, parking, and assets

- Attendance, roster, leave, payroll
- Booking engine
- Parking workflows
- Asset maintenance

## Phase 6 — AI and reports

- Secure RAG ingestion
- AI proposals/tool confirmation
- Scheduled reports and exports

## Phase 7 — Scale and release hardening

- Load/soak testing
- Security testing
- Backup restore
- Failure injection
- Runbooks
- Release checklist

At the end of each phase, output:
- Files changed
- Migrations added
- APIs added/changed
- Flutter integrations updated
- Tests added
- Test results
- Remaining blockers

---

# 19. Known issues in the starting repository that must be verified and resolved

Treat these as audit leads, not assumptions:

- Dependency installation has a LangChain/Stagehand/Zod peer conflict.
- Native `canvas` installation may not be reproducible in a clean environment.
- Existing notice tests have role/permission expectation failures.
- Jest may leave open handles.
- Backend is mixed JavaScript and TypeScript.
- Some versioned authentication routes may not receive the intended rate limiter due to middleware mount paths.
- Rate limiting appears process-local and too coarse for multi-instance/NAT usage.
- Environment variable naming for CORS may be inconsistent.
- Firestore rules appear tenant-aware but may allow excessive same-tenant writes without role checks.
- Several Admin service classes are stubs.
- Multiple Admin screens still use mock data.
- Some frontend files write/read Firestore directly.
- Current finance logic is not a complete immutable double-entry ledger.
- Existing schema migrations cover mainly AI tables rather than the full product.
- Legacy unversioned routes may remain reachable.
- The current load script does not prove 2,000–3,000-user capacity.

Confirm each finding with exact file/line evidence and fix it.

---

# 20. Definition of done

The project is complete only when:

- All 92 Admin capabilities are mapped and implemented or clearly marked as intentionally deferred with reason.
- Every Admin screen loads real tenant-scoped data.
- No production screen silently falls back to mock data.
- No privileged business write relies on direct client Firestore access.
- Tenant isolation passes automated adversarial tests.
- Financial invariants pass.
- Payment replay and duplicate requests are safe.
- Booking/vote/billing concurrency tests pass.
- All tests pass in a clean CI environment.
- The app supports the documented load target.
- Backups restore successfully.
- OpenAPI, migrations, runbooks, and traceability matrix are complete.
- There are zero unresolved P0/P1 security defects.
- The final report contains evidence, not unsupported “production ready” claims.

Begin by producing the repository audit and contract matrix. Then implement phase by phase. Do not skip directly to coding a few endpoints.


---

# SERO Backend — QA/QC, Security, Reliability, and Scale Audit Prompt

## Role

Act as an independent **Principal QA Architect, Application Security Engineer, FinTech/Accounting QA Specialist, SRE, Performance Engineer, and Backend Code Auditor**.

You are auditing the SERO repository after backend implementation. Your job is not to praise the code or provide a superficial checklist. Your job is to **prove whether the backend is safe, correct, tenant-isolated, financially consistent, reproducible, and capable of serving 2,000–3,000 concurrently active users**.

You must inspect and execute the repository. Report only evidence-backed results.

---

# 1. Required operating method

1. Read:
   - Flutter Admin screens, models, providers, services, and navigation
   - Backend routes, services, middleware, schemas, migrations, workers, queues, storage, notifications, AI/RAG, tests, deployment files, and documentation
   - OpenAPI specification
   - Feature traceability matrix

2. Build a complete **Admin screen-to-API contract inventory**.

3. Run the application from a clean environment.

4. Execute existing tests before modifying anything.

5. Record:
   - Exact command
   - Environment
   - Exit code
   - Relevant output
   - File and line
   - Expected result
   - Actual result

6. Do not accept comments, README claims, or mocked tests as proof.

7. Do not suppress failing tests, weaken assertions, add arbitrary sleeps, use `--force`, or bypass dependency checks merely to obtain green output.

8. Where a failure is found:
   - Reproduce it
   - Explain impact
   - Classify severity
   - Propose the smallest correct fix
   - Add a regression test
   - Re-run the affected and full suites

---

# 2. Audit output format

For every defect, use:

- ID
- Severity: P0 / P1 / P2 / P3
- Category
- Feature/module
- File and line
- Evidence
- Reproduction steps
- Expected behavior
- Actual behavior
- User/business impact
- Security/financial/tenant impact
- Root cause
- Recommended fix
- Regression test required
- Status

Severity:

- **P0:** cross-tenant exposure, financial corruption, auth bypass, remote compromise, data loss, production-wide outage
- **P1:** major privilege bypass, duplicate payment/billing, broken critical workflow, severe performance/reliability defect
- **P2:** important correctness, maintainability, observability, or partial workflow defect
- **P3:** low-risk polish/documentation issue

Produce:

1. `QC_EXECUTIVE_SUMMARY.md`
2. `QC_FINDINGS.md`
3. `QC_TEST_MATRIX.md`
4. `QC_LOAD_REPORT.md`
5. `QC_SECURITY_REPORT.md`
6. `QC_FINANCE_REPORT.md`
7. `QC_TENANT_ISOLATION_REPORT.md`
8. `QC_RELEASE_GATE.md`
9. Machine-readable `qc_findings.json`

---

# 3. Release gate

The release must be marked one of:

- **PASS**
- **PASS WITH P2/P3 EXCEPTIONS**
- **FAIL**

Automatic FAIL conditions:

- Any unresolved P0
- Any unresolved P1 affecting auth, tenant isolation, finance, payment, booking concurrency, backup, or critical user workflow
- Clean install/build failure
- Migration failure
- Test suite failure
- OpenAPI/client contract mismatch
- Cross-tenant test failure
- Payment replay duplication
- Unbalanced ledger
- Duplicate bill generation
- Double booking
- Missing backup restore proof
- Load target not met
- High/critical known vulnerability without an approved mitigation

---

# 4. Repository health and reproducibility

Test from a clean checkout/container:

- Pinned Node version
- `npm ci` succeeds without `--force` or `--legacy-peer-deps`
- Lockfile matches package manifest
- Native dependencies install reproducibly
- TypeScript strict compilation
- Lint
- Formatting
- Unit tests
- Integration tests
- Contract tests
- Build
- Docker image build
- Docker Compose startup
- Database migration from empty database
- Migration against previous schema
- Rollback where supported
- Worker startup
- Health/readiness probes

Check for:

- Mixed CommonJS/ESM/TS runtime failures
- JS/TS duplicate implementations
- Unused/dead routes
- Missing exports
- Circular dependencies
- Unhandled promise rejections
- Open handles after Jest
- Environment variables read under inconsistent names
- Secrets committed to repository
- Development fallbacks active in production
- Legacy routes bypassing current middleware
- Mock data enabled in release builds

Known starting leads to verify:

- LangChain/Stagehand/Zod peer dependency conflict
- `canvas` native installation risk
- Notice tests failing because role expectations do not match middleware
- Jest open handles
- CORS environment variable mismatch
- Versioned auth routes possibly bypassing intended auth rate limiter
- Mixed JavaScript and TypeScript

---

# 5. Frontend/backend contract QA

For every Flutter Admin screen/action:

- Identify endpoint or real-time subscription
- Verify method/path
- Verify authentication header
- Verify required permission
- Verify request fields and types
- Verify success response shape
- Verify error response shape
- Verify null/empty/pagination behavior
- Verify date and money parsing
- Verify upload behavior
- Verify optimistic update rollback
- Verify offline/retry behavior
- Verify screen no longer uses mock data
- Verify no privileged direct Firestore write remains

Specifically inspect:

- Dashboard
- Members and pending approvals
- Society profile/logo/wings/blocks/units
- Finance dashboard
- Bill generation and bill detail
- Payment history
- Ledger and income reports
- Receipt OCR and expense posting
- Notices and AI notice writer
- Polls, events, channels, moderation
- Complaints dashboard/detail/SLA
- Staff, attendance, roster, leave, payroll
- Amenities and bookings
- Parking and slot allocation
- Assets and maintenance
- Reports and exports
- Access logs and AI audit
- Rules/bylaws/document ingestion

Fail any screen that displays success while the backend action failed.

---

# 6. Authentication, session, RBAC, and authorization testing

Test:

- Missing token
- Invalid token
- Expired token
- Revoked token
- Token after password/role change
- Logout one device
- Logout all devices
- Disabled/suspended user
- Pending/rejected member
- User removed from society
- Token from Society A used against Society B resource
- Role downgrade while session is active
- MFA-required admin without completed MFA
- Brute force and credential stuffing
- OTP replay, guessing, resend abuse, and enumeration
- Refresh/token rotation race
- Session fixation
- Token leakage in logs/errors

Build a permission matrix for all roles and sensitive endpoints.

Test both positive and negative cases for:

- Member approval/edit/suspension
- Finance read/write/approve
- Bill generation
- Expense approval
- Notice publish
- Complaint assign/resolve
- Staff payroll
- Parking allocation
- Asset maintenance
- Report export
- Audit access
- AI tool execution

Check for:

- IDOR/BOLA
- Broken function-level authorization
- Role names that differ across frontend, token, DB, middleware, and tests
- Routes with auth but no tenant middleware
- Routes with tenant middleware but insufficient permission
- Hidden legacy routes
- Object ownership bypasses

---

# 7. Multi-tenant isolation testing

Create at least:

- Society A
- Society B
- Super admin
- Main admin A/B
- Secretary A/B
- Treasurer A/B
- Staff/guard A/B
- Resident A/B

For every tenant-owned entity:

- List
- Get by ID
- Create
- Update
- Delete
- Search
- Export
- Upload/download
- Real-time subscription
- Background job
- Notification
- Cache hit
- Queue retry
- AI retrieval

Attempt cross-tenant access by:

- Replacing path ID
- Replacing query ID
- Supplying a foreign `society_id` in body
- Cursor from another tenant
- Signed file URL
- Export job ID
- Report file
- WebSocket room
- Redis/cache-key collision
- Queue job payload tampering
- AI vector search
- Firestore direct access if retained
- Soft-deleted IDs
- Bulk import references
- Webhook metadata

Requirements:

- Cross-tenant access returns 404 or 403 consistently without leaking existence.
- Database RLS blocks access even if application filtering is accidentally omitted.
- Audit logs record privileged cross-tenant super-admin activity.
- Cache and realtime events cannot leak between societies.

Create automated isolation tests for every module and fail release on any leak.

---

# 8. Financial and accounting QC

Treat finance as a high-risk subsystem.

## 8.1 Ledger invariants

Test:

- Every journal entry balances
- Debit total equals credit total
- Money uses fixed precision
- No floating-point rounding drift
- Published journal entries are immutable
- Corrections use reversal/adjustment
- Deleted users/units do not erase history
- Period closing rules
- Duplicate transaction IDs
- Concurrent posting
- Timezone/financial-year boundaries

## 8.2 Billing

Test:

- Full society generation
- Wing/block/unit subset
- Empty scope
- Duplicate period request
- Same idempotency key
- Different idempotency key for same period
- Concurrent requests from two admins
- Worker retry after partial completion
- Formula and area-based charges
- Maintenance exemptions
- Proration
- Late fee
- Waiver
- GST/tax rounding
- Draft vs publish
- Cancel/regenerate
- Invoice numbering under concurrency
- PDF failure after database commit
- Notification failure after publish

Expected: no duplicate published invoice and no partial financial corruption.

## 8.3 Payments

Test:

- Valid provider callback
- Valid webhook
- Client callback without webhook
- Invalid signature
- Replay
- Out-of-order events
- Duplicate event ID
- Wrong amount
- Wrong currency
- Wrong order
- Wrong society metadata
- Partial payment
- Multiple invoice allocation
- Overpayment
- Refund
- Chargeback/dispute
- Webhook timeout and retry
- Redis unavailable
- Database deadlock/retry
- Receipt generation failure
- Reconciliation mismatch

Expected: exactly-once financial effect even when delivery is at least once.

## 8.4 Expenses and OCR

Test:

- OCR incorrect amount/date/vendor
- Malicious document
- Duplicate receipt
- Human correction
- Approval threshold
- Maker approving own expense when forbidden
- Rejection
- Post-approval mutation
- Attachment deletion
- Reversal

---

# 9. Concurrency and idempotency QC

Create race tests for:

- Two admins approving the same member
- Two admins generating the same billing run
- Duplicate payment webhook
- Two users booking the final amenity slot
- Two residents requesting the same parking slot
- Two voters submitting simultaneously
- Complaint status update conflict
- Staff check-in duplication
- Asset work-order completion duplication
- Report job retry
- AI tool action retry

Validate:

- Database constraints
- Transaction isolation
- Advisory/distributed locks
- Idempotency keys
- Optimistic locking/version fields
- Safe retry behavior
- No stale-cache overwrite
- No lost update

Use barriers to force simultaneous execution. Do not rely only on sequential tests.

---

# 10. Complaint/SLA QA

Test:

- Category and SLA selection
- Society business hours/timezone
- Weekend/holiday handling
- Pause/resume
- Assignment/reassignment
- Escalation recipients
- Due-today and overdue classification
- Worker restart
- Duplicate escalation prevention
- Resolution and reopen
- Invalid status transitions
- Internal vs resident-visible notes
- Attachment permissions
- CSAT once only
- SLA analytics correctness

---

# 11. Staff/payroll QA

Test:

- Duplicate attendance
- Overnight shifts
- Missing checkout
- Manual correction approval
- Leave overlapping roster
- Leave balance race
- Shift conflicts
- Overtime calculation
- Holiday/weekend rules
- Payroll rounding
- Deduction and advance
- Re-run protection
- Payslip privacy
- Maker-checker approval
- Terminated staff access
- Staff KYC expiry

---

# 12. Amenity, parking, and asset QA

## Amenities

- Overlap
- Capacity > 1
- Hold expiry
- Payment timeout
- Cancellation cutoff
- Refund
- Blackout/maintenance closure
- Timezone/DST
- Waitlist promotion
- Outstanding-dues restriction
- Admin override audit

## Parking

- Unique active allocation
- Transfer/release
- Reserved/accessibility slot permissions
- Visitor-parking expiry
- Violation and fine lifecycle
- Vehicle duplicate across units/societies
- Waitlist fairness

## Assets

- Preventive schedule generation
- Duplicate work order
- AMC expiry
- Breakdown and downtime
- Parts usage
- Vendor access
- Completion proof
- Scheduled job duplication across replicas

---

# 13. File and document security QC

Test:

- MIME spoof
- Double extension
- Oversized file
- Zip bomb
- Malware test file in safe test environment
- PDF/office active content
- Path traversal
- Object-key injection
- Cross-tenant signed URL
- Expired signed URL
- Public bucket/object
- Unauthorized preview/download
- Deleted file still accessible
- Checksum mismatch
- Concurrent upload completion
- OCR/parser crash
- Prompt injection in uploaded rules document

Verify:

- Malware quarantine
- Content-based validation
- Tenant-prefixed keys
- Short-lived signed URLs
- Access audit
- Retention/deletion
- No secrets/PII in logs

---

# 14. AI/RAG QC

Test:

- Society A document queried by Society B
- Empty knowledge base
- Low-confidence answer
- Conflicting rules
- Outdated version
- Prompt injection in document
- User prompt asking to ignore policy
- PII in prompt/output
- Provider timeout
- Provider rate limit
- Model fallback
- Semantic cache collision across tenants
- Tool call without permission
- Tool call without confirmation
- Duplicate tool execution
- Cost limit
- Token limit
- Hallucinated source
- Deleted document still retrieved
- Re-index race
- Embedding dimension mismatch

Require source trace and tenant filter at SQL/vector query level.

---

# 15. API security and abuse testing

Cover OWASP API Security Top 10 and:

- SQL injection
- NoSQL injection
- Mass assignment
- Prototype pollution
- JSON depth/size abuse
- Regex DoS
- SSRF
- XSS stored/reflected
- Header injection
- CORS misconfiguration
- Missing security headers
- HTTP method confusion
- Request smuggling exposure at proxy
- Unsafe redirects
- Rate-limit bypass
- Distributed brute force
- Enumeration
- Webhook replay/spoof
- CSV formula injection in exports
- PDF/report content injection
- Log injection
- Sensitive error detail
- Dependency vulnerabilities
- Container privilege/configuration

Validate rate limits under multi-instance deployment using Redis. Confirm shared apartment NAT users are not incorrectly blocked by a low global IP quota.

---

# 16. Performance and load test plan

Use k6 or an equivalent tool. Run against a production-like environment with PostgreSQL and Redis metrics.

## 16.1 User mix

Simulate 3,000 concurrent authenticated users:

- 2,300 residents
- 250 admins/committee
- 200 staff/guards
- 250 mixed/idle realtime users

Traffic mix:

- 25% dashboard/summary
- 15% notices/events/rules
- 15% complaints
- 10% members/search
- 10% finance reads
- 5% finance writes/payments in a safe test provider
- 5% visitors/staff attendance
- 5% amenities
- 5% parking/assets
- 5% channels/realtime

## 16.2 Scenarios

1. Baseline: 50 users
2. Ramp: 0 → 3,000 users over 10 minutes
3. Sustained: 3,000 users for 15 minutes
4. Burst: 500 RPS for 60 seconds
5. Soak: representative traffic for 4 hours
6. Billing spike: publish bills for a large society while reads continue
7. Notice broadcast spike
8. Payment webhook burst with duplicates
9. Realtime reconnect storm
10. Redis restart
11. One API instance termination
12. Slow database/query
13. Queue backlog and recovery

## 16.3 Pass criteria

Excluding slow third parties:

- p95 read < 300 ms
- p95 normal write < 500 ms
- p99 < 1.5 s
- Error rate < 1%
- 3,000 realtime connections remain stable
- No event-loop lag growth
- No unbounded memory growth
- DB connections remain within pool limits
- No cross-tenant response
- No duplicate financial/booking/vote effects
- Queue drains after recovery
- Horizontal scaling improves throughput

Report:

- Throughput
- p50/p90/p95/p99
- Error breakdown
- CPU/memory
- Event loop lag
- DB pool/locks/slow queries
- Redis latency/memory
- Queue depth/age
- WebSocket disconnect/reconnect
- Bottleneck and remediation

A script that sends only 50 unauthenticated requests is not acceptable proof.

---

# 17. Reliability and failure-injection QC

Test behavior when:

- PostgreSQL temporarily unavailable
- Redis unavailable
- Object storage unavailable
- FCM/email provider unavailable
- Razorpay unavailable
- AI provider unavailable
- Worker crashes mid-job
- API crashes after DB commit but before response
- Webhook handler crashes after storing event
- Network timeout causes client retry
- Duplicate queue delivery
- Clock skew
- Disk/storage quota
- Database deadlock
- Partial deployment with old/new instances

Verify:

- Circuit breakers where appropriate
- Timeouts
- Retries with jitter
- Idempotency
- Dead-letter queues
- No cascading failure
- Accurate user-visible status
- Alerting
- Recovery without manual data edits

---

# 18. Observability QC

Confirm:

- Request ID appears in response and logs
- Trace continues through queue jobs
- Logs include tenant/user/action without sensitive payload
- Errors are not swallowed
- Metrics cover API, DB, Redis, queues, payments, notifications, SLA, AI
- Alerts are actionable
- Dashboard distinguishes dependency failure from application failure
- Health/readiness endpoints are truthful
- Deep health is protected
- Sentry environment/release/source maps are correct
- Audit logs are immutable and separately permissioned
- Export of audit logs is itself audited

Trigger controlled failures and verify alerts/logs.

---

# 19. Backup, restore, retention, and disaster recovery QC

Do not accept “backups configured” without restore evidence.

Test:

- PostgreSQL backup
- Point-in-time restore or latest restore
- Object storage version recovery
- Redis treated as disposable where appropriate
- Restore to isolated environment
- Referential integrity after restore
- Payment/ledger reconciliation after restore
- RPO/RTO measurement
- Key/secret availability
- Backup encryption
- Retention
- Audit partition creation
- Data deletion/anonymization
- Tenant offboarding export and purge

Document exact restore commands and measured results.

---

# 20. Current repository-specific checks

Verify these likely risks with file/line evidence:

1. The package graph installs cleanly without peer-dependency bypass.
2. Native `canvas` is necessary and reproducible.
3. All notice authorization tests agree with the intended role model.
4. Jest exits cleanly without forced termination.
5. Auth rate limiting applies to `/api/v1/auth/login` and register endpoints.
6. Rate limiting is distributed and not only in process memory.
7. CORS environment variable names match configuration.
8. Legacy unversioned endpoints cannot bypass newer middleware.
9. Firestore rules enforce role-level authorization, not only same-society checks.
10. The Flutter app does not directly write privileged collections.
11. All Admin service stubs are implemented.
12. All Admin mock-data imports are removed or restricted to explicit demo/test builds.
13. Finance is not calculated from an arbitrary recent-transaction limit.
14. Payment webhook raw-body verification is correct.
15. Cron jobs do not run once per API replica.
16. The full product schema exists, not only AI tables.
17. Cursor pagination cannot use another tenant’s document/cursor.
18. User IDs are consistent between document ID and stored `uid`.
19. Role naming is consistent: `admin`, `main_admin`, `super_admin`, etc.
20. Audit logs have an appropriate retention policy; critical audit data must not expire after a few minutes.
21. Date ranges correctly use inclusive/exclusive boundaries.
22. Notifications are awaited/queued safely and failures do not corrupt core transactions.
23. Firestore and PostgreSQL cannot diverge silently if both remain.
24. Dashboard cache invalidation is complete.
25. AI cache keys include society, user/permission context where needed, document version, and model/prompt version.

---

# 21. Required automated test suites to add when missing

- `auth.spec`
- `rbac-matrix.spec`
- `tenant-isolation.spec`
- `society-structure.spec`
- `member-lifecycle.spec`
- `billing-concurrency.spec`
- `ledger-invariants.spec`
- `payment-webhook-idempotency.spec`
- `expense-approval.spec`
- `notice-targeting.spec`
- `poll-vote-concurrency.spec`
- `meeting-quorum.spec`
- `complaint-sla.spec`
- `staff-attendance.spec`
- `payroll.spec`
- `amenity-double-booking.spec`
- `parking-allocation.spec`
- `asset-maintenance.spec`
- `file-security.spec`
- `report-export-security.spec`
- `ai-tenant-isolation.spec`
- `ai-tool-authorization.spec`
- `queue-idempotency.spec`
- `backup-restore-smoke.spec`
- Flutter/API contract tests
- k6 load/spike/soak scripts

---

# 22. Final release report

End with:

## A. Executive verdict

- Release gate
- Number of P0/P1/P2/P3
- Top five risks
- Tested scale
- Untested scope

## B. Feature coverage

For Admin capabilities 1–92:

- Implemented
- Tested
- Passed
- Failed
- Not tested
- Evidence link/file

## C. Security verdict

- Tenant isolation
- RBAC
- OWASP API
- File security
- AI isolation
- Secrets/dependencies

## D. Financial verdict

- Billing
- Ledger
- Payments
- Expenses
- Reconciliation
- Concurrency/idempotency

## E. Reliability verdict

- Queues
- Realtime
- Failure recovery
- Backup/restore
- Observability

## F. Performance verdict

- Concurrent users
- RPS
- Latencies
- Errors
- Bottlenecks
- Headroom

## G. Required actions before release

List exact blocking changes in priority order.

Do not conclude “production ready” unless every release gate is supported by executed tests and evidence.

