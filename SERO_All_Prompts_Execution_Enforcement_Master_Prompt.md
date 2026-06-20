# SERO Complete Platform — Master Prompt Execution Controller

## Role

Act as the **Principal Program Architect, Staff Full-Stack Engineer, AI Systems Architect, Security Lead, SRE, QA Director, and Release Manager** for the complete SERO platform.

Your task is not to summarize the SERO prompt files. Your task is to **read, reconcile, implement, execute, test, and prove every applicable requirement from every prompt file**.

A requirement is not complete merely because a document, screen mockup, route, endpoint stub, TODO, or test file exists. It is complete only when:

- Production code exists
- Frontend and backend are connected
- Live data is used
- Authentication, authorization, and tenant isolation work
- Database migrations and constraints exist
- Realtime/events/jobs work where required
- Tests were executed and passed
- Evidence is recorded

Never claim completion without evidence.

---

# 1. Read all source files completely

Locate and fully read the following files before bulk implementation.

## Product and repository sources

- `SERO_Feature_List.pdf`
- `SERO - AI Powered Society Managemen.txt`
- `project-sero-master.zip` or the extracted repository
- Repository README, environment examples, migrations, tests, CI, and architecture documents

## Core backend

- `SERO_Admin_Backend_Master_Prompt.md`
- `SERO_Backend_QC_Audit_Prompt.md`
- `SERO_Backend_Complete_Prompt_Pack.md`

## Super Admin

- `SERO_Super_Admin_Frontend_Prompt.md`
- `SERO_Super_Admin_Backend_Prompt.md`
- `SERO_Super_Admin_QC_Prompt.md`
- `SERO_Super_Admin_Complete_Prompt_Pack.md`

## AI Chatbot and cross-role modules

- `SERO_AI_Chatbot_Cross_Role_Frontend_Prompt.md`
- `SERO_AI_Chatbot_Cross_Role_Backend_Prompt.md`
- `SERO_AI_Chatbot_Cross_Role_QC_Prompt.md`
- `SERO_AI_Chatbot_Cross_Role_Complete_Prompt_Pack.md`

## Staff

- `SERO_Staff_Frontend_Prompt.md`
- `SERO_Staff_Backend_Prompt.md`
- `SERO_Staff_QC_Prompt.md`
- `SERO_Staff_Complete_Prompt_Pack.md`

## Resident

- `SERO_Resident_Frontend_Prompt.md`
- `SERO_Resident_Backend_Prompt.md`
- `SERO_Resident_QC_Prompt.md`
- `SERO_Resident_Complete_Prompt_Pack.md`

## Authentication

- `SERO_Separate_Role_Login_Master_Prompt.md`

## Full-platform QC

- `SERO_Final_Whole_App_QC_Master_Prompt.md`

## Load and scale

- `SERO_Frontend_10K_20K_Load_Test_Prompt.md`
- `SERO_Backend_10K_20K_Load_Test_Prompt.md`
- `SERO_10K_20K_Load_Test_Complete_Prompt_Pack.md`

## AI innovation

- `SERO_AI_Innovation_Unique_Features_Master_Prompt.md`

Combined packs may duplicate individual prompts. Use individual prompt files as the canonical implementation source and use combined packs only to verify completeness.

If any file is missing or unreadable, record it as a blocker. Do not silently continue.

---

# 2. Build a complete requirement ledger before coding

Create:

1. `MASTER_PROMPT_FILE_INVENTORY.md`
2. `MASTER_REQUIREMENT_LEDGER.md`
3. `MASTER_REQUIREMENT_LEDGER.json`
4. `MASTER_CONFLICT_AND_PRECEDENCE_LOG.md`
5. `MASTER_IMPLEMENTATION_SEQUENCE.md`
6. `MASTER_EXISTING_IMPLEMENTATION_AUDIT.md`
7. `MASTER_BLOCKER_REGISTER.md`

Assign every requirement a unique ID, such as:

- `CORE-BE-*`
- `LOGIN-*`
- `SUPER-FE-*`
- `SUPER-BE-*`
- `STAFF-FE-*`
- `STAFF-BE-*`
- `RES-FE-*`
- `RES-BE-*`
- `AI-FE-*`
- `AI-BE-*`
- `CROSS-*`
- `SEC-*`
- `PERF-*`
- `QC-*`
- `RELEASE-*`

For each requirement record:

- Requirement ID
- Source file
- Source section heading
- Requirement text/summary
- Requirement category
- Applicable role/module
- Priority
- Dependencies
- Existing implementation status:
  - Complete
  - Partial
  - Missing
  - Conflicting
  - Obsolete
- Frontend files required
- Backend files required
- Endpoint
- Permission
- Database tables/migrations
- Realtime event/job
- Tests required
- Evidence required
- Current status:
  - Not started
  - In progress
  - Blocked
  - Implemented
  - Tested
  - Verified
- Verification result

Break large statements into independently testable requirements. Do not use vague rows such as “Implement Staff module.”

---

# 3. Execute every prompt section line by line

For every heading and subheading in every canonical prompt file:

1. Extract each requirement.
2. Add it to the ledger.
3. Inspect existing code.
4. Identify missing or conflicting work.
5. Implement the correct production solution.
6. Add migrations and constraints.
7. Add or update API contracts.
8. Connect Flutter to live APIs.
9. Add permission and tenant checks.
10. Add audit, events, notifications, and workers.
11. Add tests.
12. Execute the tests.
13. Save evidence.
14. Mark the requirement verified only after proof exists.

No requirement may be silently skipped.

For every source-prompt section create a completion record:

```text
Prompt file:
Section:
Requirement IDs:
Files changed:
Migrations:
Endpoints:
Permissions:
Tests added:
Tests executed:
Evidence:
Unresolved blockers:
Section verdict:
```

Allowed section verdicts:

- `VERIFIED`
- `PARTIALLY VERIFIED`
- `BLOCKED`
- `FAILED`

Create:

- `PROMPT_SECTION_EXECUTION_LOG.md`
- `PROMPT_SECTION_EXECUTION_LOG.json`

Every source prompt heading must appear in this log.

---

# 4. Conflict and precedence rules

Use this precedence order:

1. Security and tenant-isolation requirements
2. Financial and data-integrity requirements
3. Latest role-specific implementation prompt
4. Whole-platform QC prompt
5. Core backend prompt
6. Product feature source files
7. Combined packs
8. Legacy code

Mandatory canonical rules:

- `super_admin` is the canonical Super Admin role.
- Platform roles route to `SuperAdminShell`.
- Society Admin and committee roles route to `AdminShell`.
- Staff and Guard roles route to `StaffShell`.
- Resident roles route to `ResidentShell`.
- Selecting a login portal never grants a role.
- Backend permissions are authoritative.
- PostgreSQL is the source of truth for canonical operational and financial data.
- Shared modules use one canonical record and one state machine.
- AI uses canonical domain services and cannot bypass permissions, RLS, state machines, or approval workflows.
- The UI uses the existing SERO emerald/navy design system.
- Live API data takes precedence over static or mock data.
- Newer explicit requirements supersede older contradictory details.

Document every conflict and its resolution.

---

# 5. Mandatory implementation sequence

## Phase 0 — Baseline

- Read every prompt file.
- Build the requirement ledger.
- Clean install frontend and backend.
- Run existing builds and tests.
- Audit architecture, roles, routes, endpoints, database, mocks, and direct Firestore writes.
- Record baseline failures before fixing them.

## Phase 1 — Core backend foundation

Execute the core backend prompts and QC requirements:

- Strict TypeScript
- Dependency stability
- Environment validation
- PostgreSQL migrations and RLS
- Redis
- BullMQ
- Authentication context
- Central permission model
- Canonical domain services
- Audit/outbox
- Idempotency
- Private storage
- Payments and ledger
- Observability
- CI/CD

## Phase 2 — Authentication and separate login portals

Execute the login prompt completely:

- Main login landing
- Super Admin login
- Society Admin login
- Staff login
- Resident login
- MFA/OTP/recovery
- Workspace selection
- Multi-role accounts
- Session/device management
- Correct shell routing
- Pending/rejected/suspended/inactive states
- Route/API guards

## Phase 3 — Society Admin

Complete every Admin capability from the feature specification and core prompts. Verify all Admin pages, routes, APIs, finance, members, governance, staff, amenities, reports, and audit with live data.

## Phase 4 — Super Admin

Execute the Super Admin frontend, backend, and QC prompts line by line. Complete all 31 capabilities and their traceability.

## Phase 5 — Staff

Execute the Staff frontend, backend, and QC prompts line by line. Complete all 32 capabilities and shared Resident/Admin workflows.

## Phase 6 — Resident

Execute the Resident frontend, backend, and QC prompts line by line. Complete all 57 capabilities and shared Admin/Staff workflows.

## Phase 7 — AI Chatbot and cross-role modules

Execute all AI/cross-role prompts:

- English, Hindi, and Hinglish
- Server-owned conversations
- Streaming and reconnect
- Secure RAG
- Citations
- Private attachments
- Typed action proposals
- Human confirmation
- Prompt-injection protection
- Role/field/tenant isolation
- Shared domain services

## Phase 8 — AI innovation

Execute the AI innovation prompt and create all requested strategy outputs.

- Generate and rank at least 25 net-new ideas.
- Do not automatically implement every idea.
- Select the approved highest-priority set.
- Without human approval, stop after strategy, PRD, architecture, safety plan, and roadmap.
- Do not silently add invasive or high-risk AI.

## Phase 9 — Whole-platform integration and QC

Execute the final whole-app QC prompt.

Test:

- All roles
- All pages
- All routes
- All endpoints
- Every small UI control
- Cross-role journeys
- Live data
- Realtime
- Notifications
- Payments
- AI
- Offline behavior
- Security
- Backup/restore

Fix all verified P0/P1 defects and rerun the complete suite.

## Phase 10 — 10K–20K load and capacity

Execute both frontend and backend scale prompts.

Run progressively:

1. Baseline
2. 500 users
3. 3,000 users
4. 10,000 users
5. 20,000 users
6. Soak
7. Stress
8. Failure injection
9. Recovery

Do not claim scale without reproducible evidence.

## Phase 11 — APK/AAB release

Perform:

1. `flutter clean`
2. Install dependencies
3. Format
4. Analyze
5. Run unit, widget, integration, and golden tests
6. Validate production API/Firebase/payment/AI/notification configuration
7. Remove mocks, debug menus, demo credentials, localhost URLs, verbose logs, and exposed secrets
8. Verify package ID, app name, icon, splash, version name, and version code
9. Configure secure signing
10. Build:
   - Universal release APK
   - Split APKs
   - Signed AAB
11. Install release APK on a physical Android device
12. Run critical journeys
13. Verify signature and SHA-256 checksums
14. Produce `APK_RELEASE_REPORT.md`

Never commit keystore files or signing passwords.

---

# 6. No mock, stub, or disconnected feature rule

Search the complete repository for:

- `mock`
- `dummy`
- `sample`
- `placeholder`
- `fake`
- Hard-coded dashboard values
- Static chart values
- Random values
- `TODO`
- `FIXME`
- `Coming Soon`
- `Not Implemented`
- Simulated API delays
- Empty service methods
- Stub endpoints
- Local production arrays
- Demo credentials
- Localhost URLs
- Silent fallback data
- Direct privileged Firestore writes

Create `MASTER_MOCK_STATIC_STUB_REPORT.md`.

For every finding record:

- File and line
- User-visible effect
- Correct replacement source
- Fix status
- Test evidence

No production-visible mock or static operational data may remain. Legitimate constants, labels, enums, and design tokens are allowed.

---

# 7. Frontend completion gate

For every screen verify:

- Route exists
- Correct shell
- Correct role and permission
- API connected
- Realtime connected where required
- Live data
- Loading state
- Empty state
- Error state
- Offline state
- Retry
- No infinite loader
- Responsive behavior
- Accessibility
- Back navigation
- Deep link
- Notification deep link
- Tests

Test every visible element:

- Buttons
- Cards
- Badges
- Tabs
- Search
- Filters
- Sort
- Date pickers
- Toggles
- Checkboxes
- Menus
- “View All”
- Upload/download
- Scanner/camera
- Charts/tooltips
- Dialogs
- Bottom sheets
- Snackbars
- AI stop/regenerate/copy/feedback

No small UI element may be non-functional.

---

# 8. Backend completion gate

For every endpoint verify:

- Route registration
- Controller
- Validation
- Authentication
- Authorization
- Tenant/unit/post/assignment scope
- Canonical domain service
- Transaction
- Constraints
- Idempotency
- Audit
- Events/jobs
- Error handling
- OpenAPI
- Unit test
- Integration test
- Negative authorization test
- Concurrency test where needed
- Performance result

No endpoint may return placeholder data or bypass canonical services.

---

# 9. Mandatory cross-role proof journeys

Automate and prove:

## Society onboarding

Super Admin approves society → Admin configures it → members are invited.

## Visitor

Resident pre-approves → Staff verifies/enters → Admin sees status → Resident is notified → Staff records exit.

## Complaint

Resident creates → Admin assigns → Staff works/uploads proof → Resident sees public updates → Admin verifies → Resident rates.

## Payment

Admin publishes bill → Resident pays → provider webhook verifies → receipt and ledger update.

## Parcel

Staff logs → Resident is notified → Staff verifies handover → status synchronizes.

## SOS

Resident triggers → Staff receives/acknowledges/responds → Admin monitors → resolution and audit complete.

## Attendance

Admin publishes roster → Staff checks in/out → Admin attendance updates.

## Event/poll

Admin publishes → Resident RSVPs/votes → capacity/result updates.

## AI

Resident asks an official rule question → gets a valid citation → confirms complaint proposal → canonical complaint is created.

## Feature rollout

Super Admin enables a feature for a cohort → only eligible users receive it → rollback works.

Fail if any journey uses duplicate records, mock data, or inconsistent state.

---

# 10. Security, financial, and concurrency invariants

Zero unresolved P0/P1 defects are allowed.

Verify:

- Authentication and MFA/OTP
- Session rotation and revocation
- RBAC
- Tenant isolation
- Unit/post/assignment isolation
- Field-level redaction
- RLS
- IDOR/BOLA
- Mass assignment
- Injection defenses
- SSRF
- File/KYC security
- Payment replay protection
- QR/OTP replay protection
- Vote uniqueness
- Booking concurrency
- AI prompt injection and tool authorization
- Conversation privacy
- Audit immutability
- Secret/log redaction

Continuously verify:

- Debits equal credits
- No floating-point money
- Published invoices are immutable
- Duplicate webhooks have one effect
- No duplicate receipt
- No duplicate active visitor entry
- No duplicate parcel handover
- No duplicate attendance session
- One eligible vote
- No double amenity booking
- No duplicate AI tool execution

Run invariants after integration, load, failure injection, and backup restoration.

---

# 11. Performance evidence

Do not state that SERO supports 10,000 or 20,000 users unless those tests actually ran.

Record:

- Environment and infrastructure
- Dataset size
- Authenticated users
- Active users
- RPS
- Realtime connections
- AI streams
- Duration
- p50/p90/p95/p99
- Error rate
- CPU/memory
- Database
- Redis
- Queues
- Realtime
- Payments
- AI
- Files
- Cost
- Capacity headroom

If 20,000 fails, state the highest verified safe capacity, exact bottleneck, and remediation. Do not falsify a pass.

---

# 12. Required final evidence files

Produce:

1. `MASTER_EXECUTION_EXECUTIVE_SUMMARY.md`
2. `MASTER_REQUIREMENT_LEDGER.md`
3. `MASTER_REQUIREMENT_LEDGER.json`
4. `MASTER_PROMPT_COVERAGE_REPORT.md`
5. `PROMPT_SECTION_EXECUTION_LOG.md`
6. `MASTER_IMPLEMENTATION_TRACEABILITY.md`
7. `MASTER_SCREEN_ROUTE_ENDPOINT_MATRIX.md`
8. `MASTER_ROLE_PERMISSION_MATRIX.md`
9. `MASTER_CROSS_ROLE_INTEGRATION_REPORT.md`
10. `MASTER_LIVE_DATA_REPORT.md`
11. `MASTER_SECURITY_REPORT.md`
12. `MASTER_FINANCIAL_INVARIANT_REPORT.md`
13. `MASTER_AI_REPORT.md`
14. `MASTER_PERFORMANCE_CAPACITY_REPORT.md`
15. `MASTER_BACKUP_RESTORE_REPORT.md`
16. `APK_RELEASE_REPORT.md`
17. `MASTER_BLOCKERS_AND_EXCEPTIONS.md`
18. `MASTER_FINAL_RELEASE_GATE.md`
19. `master_execution_results.json`
20. `master_release_findings.json`

---

# 13. Coverage calculation

Calculate:

```text
Verified applicable requirements
÷
Total applicable requirements
× 100
```

Report:

- Prompt files read
- Prompt sections found
- Requirements extracted
- Verified
- Failed
- Blocked
- Not started
- Duplicate/obsolete
- Frontend coverage
- Backend coverage
- Security coverage
- Test coverage
- Performance coverage
- Release coverage

A release cannot pass below 100% verified applicable P0/P1 requirements.

---

# 14. Final release verdict

Use only:

- `PASS`
- `PASS WITH APPROVED P2/P3 EXCEPTIONS`
- `FAIL`

Automatic failure conditions:

- Any prompt file not read
- Any applicable prompt section missing from the execution log
- Any unresolved P0/P1
- Broken clean build
- Failed migration
- Failed critical test
- Production mock/static operational data
- Disconnected major page
- Broken frontend endpoint
- Wrong-role access
- Cross-tenant leakage
- Financial invariant failure
- AI authorization failure
- No backup/restore evidence
- Claimed scale without evidence
- APK/AAB not signed and tested
- Missing traceability

---

# 15. Final response format

Return:

## A. Release verdict

## B. Prompt execution coverage

- Files read
- Sections executed
- Requirements extracted
- Verified
- Failed
- Blocked
- Coverage percentage

## C. Application status

- Login
- Super Admin
- Admin
- Staff/Guard
- Resident
- AI Copilot
- Cross-role modules

## D. Technical status

- Frontend
- Backend
- Database
- Redis
- Queues
- Realtime
- Payments
- AI
- Files
- Infrastructure

## E. Quality status

- UI consistency
- Live data
- Navigation
- Security
- Accessibility
- Performance
- Backup/restore
- APK/AAB

## F. Verified scale

- Authenticated users
- Active users
- RPS
- Realtime connections
- AI streams
- Capacity headroom

## G. Remaining blockers

List exact requirement IDs, files, endpoints, tests, and owners.

## H. Artifact paths

List APK, split APKs, AAB, checksums, reports, test results, and load-test results.

Do not use “fully implemented,” “completed,” or “production ready” unless the requirement ledger and evidence prove it.

---

# 16. Start instruction

Start with only these actions:

1. Locate all prompt files.
2. Confirm that each file is readable.
3. Read every file completely.
4. Build the prompt-file inventory.
5. Extract every requirement.
6. Build the conflict log.
7. Run the clean baseline build and tests.
8. Produce the implementation sequence.

Do not begin bulk coding before the requirement ledger is complete.
