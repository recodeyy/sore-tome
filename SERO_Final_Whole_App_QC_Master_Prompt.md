# SERO Entire Platform — Final End-to-End QC, Integration, Live-Data, Security, Performance, and Release-Gate Master Prompt

## Role

Act as an independent **Principal Quality Architect, Staff Flutter Engineer, Staff Backend Engineer, Application Security Engineer, AI Red-Team Engineer, Database Reliability Engineer, SRE, Performance Engineer, Accessibility Auditor, and Product Release Manager**.

You are conducting the **final production-readiness audit of the entire SERO — AI Powered Society Management Platform**.

The repository may contain:

- Flutter mobile/web frontend
- Super Admin application
- Society Admin application
- Staff/Guard application
- Resident/Member application
- AI Chatbot / SERO Copilot
- Shared cross-role modules
- Node.js/TypeScript backend
- PostgreSQL
- Redis
- BullMQ workers
- Firebase Authentication and FCM
- Object storage
- Razorpay/payment provider
- AI/RAG/vector database
- Docker and CI/CD
- Existing tests, mocks, migrations, seed data, and documentation

Your goal is to prove that **the entire platform works as one connected live system**.

This is not a code-style review and not a superficial checklist. You must execute the application, connect every screen to real backend services, test every button and state, detect static/mock data, test all endpoints, verify every role, prove cross-role synchronization, validate AI behavior, test security, and load-test the system for **3,000–5,000 concurrently active users**.

Do not claim the application is production-ready without executable evidence.

---

# 1. Final audit principles

1. Treat SERO as **one product**, not separate apps.
2. Every screen, button, card, filter, graph, badge, menu, notification, form, action, and deep link must be tested.
3. Every visible value must come from:
   - A real API
   - A real database query
   - A real realtime subscription
   - A documented computed state
4. No production screen may silently display:
   - Mock data
   - Hard-coded totals
   - Placeholder charts
   - Fake names
   - Static activity
   - Sample notifications
   - Dummy lists
   - Random counters
   - Locally generated financial totals
5. Every frontend action must map to:
   - A route
   - A provider/controller
   - A service method
   - An API endpoint or realtime event
   - A permission
   - A database operation
   - An audit record
   - A test
6. Every backend endpoint must be:
   - Reachable
   - Authenticated where required
   - Authorized
   - Tenant-safe
   - Validated
   - Documented
   - Tested
   - Observable
7. UI success must never be shown before backend success unless explicitly implemented as a safe optimistic update with rollback.
8. No loader, modal, bottom sheet, scanner, stream, page, or button may remain stuck indefinitely.
9. Test the application under:
   - Normal connectivity
   - Slow connectivity
   - Offline/online transitions
   - Dependency failures
   - Concurrent updates
   - High load
10. Record evidence for every pass and failure.

---

# 2. Required deliverables

Create the following files:

1. `FINAL_QC_EXECUTIVE_SUMMARY.md`
2. `FINAL_QC_RELEASE_GATE.md`
3. `FINAL_PLATFORM_ARCHITECTURE_VERIFICATION.md`
4. `FINAL_SCREEN_INVENTORY.md`
5. `FINAL_SCREEN_API_TRACEABILITY.md`
6. `FINAL_ENDPOINT_INVENTORY.md`
7. `FINAL_ENDPOINT_TEST_REPORT.md`
8. `FINAL_STATIC_MOCK_DATA_REPORT.md`
9. `FINAL_UI_UX_CONSISTENCY_REPORT.md`
10. `FINAL_NAVIGATION_AND_DEEPLINK_REPORT.md`
11. `FINAL_AUTH_RBAC_TENANT_REPORT.md`
12. `FINAL_CROSS_ROLE_INTEGRATION_REPORT.md`
13. `FINAL_DATABASE_AND_MIGRATION_REPORT.md`
14. `FINAL_REALTIME_NOTIFICATION_REPORT.md`
15. `FINAL_AI_CHATBOT_REPORT.md`
16. `FINAL_PAYMENT_FINANCE_REPORT.md`
17. `FINAL_FILE_UPLOAD_SECURITY_REPORT.md`
18. `FINAL_OFFLINE_SYNC_REPORT.md`
19. `FINAL_SECURITY_REPORT.md`
20. `FINAL_ACCESSIBILITY_REPORT.md`
21. `FINAL_PERFORMANCE_LOAD_REPORT.md`
22. `FINAL_RELIABILITY_FAILURE_INJECTION_REPORT.md`
23. `FINAL_BACKUP_RESTORE_REPORT.md`
24. `FINAL_OBSERVABILITY_OPERATIONS_REPORT.md`
25. `FINAL_FEATURE_TRACEABILITY_MATRIX.md`
26. `FINAL_BLOCKING_FIXES.md`
27. Machine-readable `final_qc_findings.json`
28. Machine-readable `final_feature_traceability.json`
29. Machine-readable `final_endpoint_results.json`

---

# 3. Finding format

For every finding, include:

- Finding ID
- Severity:
  - P0
  - P1
  - P2
  - P3
- Category
- Application/role
- Module
- Screen
- Route
- Endpoint
- File and line
- Environment
- Reproduction steps
- Expected behavior
- Actual behavior
- User impact
- Business impact
- Security/privacy/financial impact
- Root cause
- Required fix
- Regression test
- Evidence
- Owner
- Status

Severity definition:

## P0

- Cross-tenant data exposure
- Authentication bypass
- Remote compromise
- Financial corruption
- Duplicate payment/ledger posting
- Irrecoverable data loss
- Production-wide outage
- Public KYC/private file exposure
- Unauthorized AI action
- Critical secret exposure

## P1

- Major role/permission bypass
- Broken login or core role flow
- Major page unreachable
- Duplicate bill/visitor/parcel/booking/attendance effect
- Broken payment workflow
- SOS failure
- AI cross-role leak
- Significant performance failure
- Backup cannot restore
- Repeated app freeze/crash
- Critical realtime inconsistency

## P2

- Important workflow defect
- Incorrect calculation
- Missing audit
- UI/backend mismatch
- Broken empty/error state
- Important accessibility issue
- Performance degradation
- Incorrect notification/deep link
- Partial static data

## P3

- Minor visual inconsistency
- Low-risk copy issue
- Non-blocking polish
- Documentation issue

---

# 4. Final release verdict

Use one verdict only:

- **PASS**
- **PASS WITH P2/P3 EXCEPTIONS**
- **FAIL**

The release automatically fails if any of these remain:

- Any unresolved P0
- Any unresolved P1 affecting:
  - Authentication
  - Tenant isolation
  - Payments
  - Ledger
  - AI actions
  - KYC/files
  - SOS
  - Visitor/parcel handover
  - Attendance
  - Backup/restore
  - Core navigation
- Clean install fails
- Flutter build fails
- Backend build fails
- Migrations fail
- Tests fail
- OpenAPI contract is inconsistent
- Any production screen uses mock/static data
- Any major button has no working action
- Any protected page is reachable by the wrong role
- Any required page is disconnected
- Any API endpoint used by the frontend returns an unhandled response
- Any loader can remain indefinitely stuck
- Payment replay creates duplicate financial impact
- Cross-role canonical records become inconsistent
- AI reveals data outside authorization
- The 3,000–5,000-user load target is not met
- Backup/restore is not proven

---

# 5. Clean environment and reproducibility

Perform the audit from a clean checkout or clean container.

Verify:

- Node version is pinned
- Flutter/Dart versions are documented
- `npm ci` succeeds without:
  - `--force`
  - `--legacy-peer-deps`
- Lockfile is valid
- Native dependencies build
- TypeScript strict compilation passes
- Lint passes
- Formatting passes
- Flutter pub get succeeds
- Flutter analyze passes
- Backend unit tests pass
- Backend integration tests pass
- Flutter unit tests pass
- Flutter widget tests pass
- Golden tests pass
- Contract tests pass
- Docker images build
- Docker Compose starts
- PostgreSQL migrations run from empty database
- Upgrade migrations run from prior schema
- Seed data works
- Workers start
- Health/readiness endpoints work
- No open test handles
- No unhandled promise rejections
- No development-only secret or emulator is silently used in production mode
- No test bypass is used

Record every command, exit code, and relevant output.

---

# 6. Entire repository inventory

Create a complete inventory of:

- Flutter screens
- Routes
- Shells
- Drawers
- Bottom-navigation tabs
- Providers
- Notifiers/controllers
- Services
- Models/DTOs
- API endpoints
- Realtime channels
- Background jobs
- Database tables
- Migrations
- Feature flags
- Roles and permissions
- Object-storage paths
- Notification templates
- AI tools
- Reports/exports
- Tests

For each screen, record:

- Application
- Role
- Route
- Source file
- Expected API calls
- Expected realtime subscriptions
- Required permissions
- Loading state
- Empty state
- Error state
- Offline state
- Actions
- Deep links
- Test coverage
- Live/static status

For each endpoint, record:

- Method
- Path
- Controller
- Service
- Permission
- Tenant scope
- Validation schema
- Database tables
- Side effects
- Events/jobs
- Response schema
- Error codes
- Frontend consumers
- Tests
- Status

---

# 7. Applications and roles to test

Create test identities for:

## Platform roles

- Super Admin
- Platform Owner
- Platform Operations
- Platform Finance
- Platform Support
- Platform Security
- Platform Auditor
- Platform Read-Only

## Society governance roles

- Main Admin
- Admin
- Secretary
- Treasurer
- Committee Member
- Auditor

## Operations roles

- Security Manager
- Facility Manager
- Supervisor
- Guard
- Maintenance Staff
- Housekeeping Staff
- Reception Staff
- Parcel Desk Staff
- General Staff

## Resident roles

- Resident Owner
- Resident Tenant
- Family Member or authorized household user where supported

Create at least:

- Society A
- Society B
- Different subscription plans
- Different feature flags
- Different wings/blocks/units
- Active/inactive/suspended users
- Pending/approved/rejected members
- Current and expired documents
- Current and overdue bills
- Open/resolved complaints
- Visitors/parcels/events
- Staff shifts
- Assets/parking
- AI documents
- Support tickets

---

# 8. Login, authentication, and session testing

Test all login and session scenarios:

- Valid login
- Invalid password
- Unknown account
- Pending account
- Rejected account
- Suspended account
- Disabled society
- Expired session
- Revoked token
- Logout
- Logout all devices
- Password reset/recovery
- OTP login if supported
- MFA
- Step-up authentication
- Multiple devices
- Role change during active session
- Society switch
- Staff post/zone change
- Super Admin impersonation
- Session expiry during form submission
- Refresh token race
- Offline launch
- App cold start
- App background/resume
- Deep link while logged out
- Deep link with wrong role
- Token after permission revocation

Verify:

- Correct shell opens
- No unauthorized screen flashes before redirect
- Correct role label
- Correct society
- Cached data is cleared
- Back navigation cannot reveal previous-role data
- Errors are user-friendly
- Tokens are not logged
- Secure storage is used

---

# 9. Navigation and page connectivity

Test every route and every navigation entry.

For each page:

- Open from intended navigation
- Open by direct/deep link
- Use browser/mobile back
- Use app back
- Switch tab
- Open drawer
- Return from detail
- Preserve filters and scroll where expected
- Refresh
- Reopen after app restart
- Open notification deep link
- Open from AI action result
- Test permission-denied redirect
- Test unknown/invalid ID
- Test deleted/archived record
- Test loading
- Test empty state
- Test API error
- Test offline state

Detect:

- Dead pages
- Unreachable pages
- Route loops
- White screens
- Blank states
- Missing back buttons
- Broken deep links
- Incorrect tab selection
- Stale data after returning
- Duplicate route names
- Wrong role shell
- Page opened without required context
- Navigation to unimplemented placeholder

Every menu item, tab, quick action, notification, card, and “View All” must work.

---

# 10. UI consistency audit

Compare all applications against the established SERO design system.

Verify:

- Color tokens
- Emerald/navy gradients
- Outfit typography
- Card radius
- Input/button radius
- Page padding
- Header pattern
- Navigation pattern
- Icons
- Status chips
- Empty states
- Error states
- Loading skeletons
- Dialogs
- Bottom sheets
- Toast/snackbar style
- Forms
- Charts
- Data tables
- Responsive breakpoints

Audit:

- Super Admin
- Admin
- Staff
- Guard
- Resident
- AI Copilot
- Shared modules
- Login/onboarding

Flag:

- Random colors
- Unrelated fonts
- Different card language
- Inconsistent status colors
- Dense desktop tables on mobile
- Different button behavior
- Misaligned spacing
- Text clipping
- Overflow
- Inconsistent dark/light treatment
- Screens that appear to belong to another product

Test screen sizes:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet portrait
- Tablet landscape
- 1024×768
- 1366×768
- 1440×900
- 1920×1080
- 200% text scaling

---

# 11. UI freeze, stuck loader, and interaction testing

Actively detect UI states that can become stuck.

Test:

- Slow API
- API timeout
- 401
- 403
- 404
- 409
- 422
- 429
- 500
- Empty response
- Malformed response
- Realtime disconnect
- Upload timeout
- AI stream timeout
- Payment provider redirect failure
- Scanner permission denied
- Camera permission denied
- Location permission denied
- App backgrounded mid-request
- Double tap
- Rapid navigation
- Form submit twice
- Dependency outage

Verify:

- Loader has timeout or recovery
- Retry works
- Cancel works
- Button re-enables after failure
- Modal can close
- Bottom sheet can close
- Back navigation works
- Skeleton is replaced
- Stream can stop
- Upload can retry/cancel
- Form retains safe data
- No infinite spinner
- No unresponsive overlay
- No duplicate submission
- No memory leak
- No crash

Automate long-running UI interaction tests.

---

# 12. Static, mock, placeholder, and fake-data detection

Search the entire frontend and backend for:

- `mock`
- `dummy`
- `sample`
- `placeholder`
- `fake`
- `hardcoded`
- `TODO`
- `FIXME`
- `coming soon`
- `not implemented`
- Static JSON
- Random generators
- Demo counters
- Local arrays
- Stub service methods
- Empty method bodies
- Hard-coded chart series
- Fixed dates/names/amounts
- Silent fallback data
- `Future.delayed` used to simulate APIs
- Firestore demo collections
- Environment-based production fallback to test data

For every visible element, prove the data source.

Test by changing backend records and confirming the UI changes.

Test by using:

- Empty database
- One record
- Many records
- Different society
- Different role
- Different date range
- Different feature flag
- Deleted record

No production UI may show fake success or sample data.

---

# 13. Frontend-to-backend contract verification

For every API call:

- Verify method/path
- Verify auth header
- Verify request body
- Verify query params
- Verify date format
- Verify money format
- Verify enum values
- Verify pagination
- Verify file upload
- Verify response parsing
- Verify null handling
- Verify empty list
- Verify error parsing
- Verify request ID
- Verify optimistic rollback
- Verify retry safety

Generate contract tests from OpenAPI where possible.

Detect:

- Frontend calls nonexistent endpoint
- Backend response does not match DTO
- Field renamed
- Role enum mismatch
- Status enum mismatch
- Date timezone mismatch
- Money precision issue
- Cursor mismatch
- Incorrect HTTP status handling
- Unhandled backend error
- Silent null/default hiding backend failure

---

# 14. Endpoint completeness and functional testing

Test every endpoint, not only those used in happy-path UI.

For each endpoint:

- Valid request
- Missing token
- Wrong role
- Wrong society
- Invalid ID
- Invalid fields
- Missing required field
- Extra/mass-assignment field
- Duplicate request
- Concurrent request
- Rate limit
- Large payload
- Empty payload
- Deleted record
- Archived record
- Database error
- Redis error
- Job failure
- Idempotency
- Audit log
- Realtime event
- Notification
- OpenAPI match

Fail any endpoint that:

- Is undocumented
- Is unreachable
- Returns placeholder data
- Bypasses permission
- Leaks another tenant
- Has no validation
- Returns inconsistent errors
- Does not handle retry
- Produces partial state
- Has no test

---

# 15. Super Admin end-to-end testing

Test:

- Platform dashboard
- Society totals
- User totals
- DAU/MAU
- Revenue
- Churn
- Society list
- Society detail
- Approval
- Rejection
- Request information
- KYC
- Setup progress
- Subscription monitoring
- Plans
- Plan versioning
- Plan assignment
- Invoices/payments/refunds
- Revenue reports
- Feature flags
- Rollouts
- White label
- Global announcements
- Push campaigns
- Support
- Audit/access logs
- Impersonation
- API clients
- Webhooks
- System health
- Jobs/incidents
- Platform users/settings
- AI usage/costs

Verify all data is platform-live, not tenant-local or static.

---

# 16. Society Admin end-to-end testing

Test all Admin capabilities, including:

- Dashboard
- Society profile
- Wings/blocks/floors/units
- Members
- Committee
- KYC
- Billing
- Invoices
- Payments
- Receipts
- Ledger
- Expenses
- Approvals
- Reconciliation
- Dues/defaulters
- Notices
- Announcements
- Polls
- AGM/meetings
- Events
- Rules/documents
- Complaints
- SLA
- Staff
- Attendance
- Roster
- Leave
- Payroll
- Amenities
- Bookings
- Parking
- Vehicles
- Assets
- Maintenance
- Reports
- Audit/access logs
- AI features

Verify every Admin page is connected to live APIs.

---

# 17. Staff and Guard end-to-end testing

Test:

- Staff dashboard
- Current shift
- Expected visitors
- Walk-in visitor
- Resident approval
- OTP
- QR
- Entry
- Exit
- Overstay
- Parcels
- Notifications
- Handover
- Incidents
- SOS
- Patrol
- Checkpoints
- Shift handover
- Assigned complaints/tasks
- Public/internal notes
- Evidence
- Completion/rework
- Attendance
- Break
- Roster
- Leave
- Offline sync

Verify guard/staff access is restricted to correct gate/post/zone/assignment.

---

# 18. Resident end-to-end testing

Test:

- Registration/invitation
- Approval status
- Profile
- Family/co-owner/tenant
- Vehicles
- KYC
- Bills
- Payments
- Receipts
- Autopay if supported
- Visitor approval
- Domestic help
- Parcel notification/collection
- Complaints
- Chat with Admin
- Notices
- Events
- Polls
- Marketplace/carpool/lost and found if implemented
- Amenities
- Reviews
- SOS
- Emergency contacts
- Rules/bylaws
- NOCs
- Documents
- AI Copilot

Verify resident sees only their permitted unit/family data.

---

# 19. Cross-role canonical-record testing

Prove that shared modules use one source of truth.

## Visitor lifecycle

1. Resident creates/pre-approves visitor.
2. Staff sees visitor.
3. Staff verifies and records entry.
4. Admin sees live entry.
5. Resident receives entry notification.
6. Staff records exit.
7. All permitted timelines update.

## Complaint lifecycle

1. Resident creates complaint.
2. Admin sees it.
3. Admin assigns Staff.
4. Staff accepts and works.
5. Staff uploads proof.
6. Resident sees public update.
7. Admin verifies/resolves.
8. Resident rates/reopens where allowed.

## Parcel lifecycle

1. Staff logs parcel.
2. Resident receives notification.
3. Admin sees parcel metrics.
4. Staff verifies handover.
5. Resident sees collected status.

## Event lifecycle

1. Admin creates event.
2. Resident sees it.
3. Resident RSVPs.
4. Capacity updates.
5. Staff checks attendance where permitted.
6. Admin sees final attendance.

## Payment lifecycle

1. Admin publishes bill.
2. Resident sees bill.
3. Resident pays.
4. Provider webhook verifies payment.
5. Receipt appears.
6. Admin ledger updates.
7. Dashboard metrics update.

## Staff lifecycle

1. Admin publishes roster.
2. Staff sees shift.
3. Staff checks in.
4. Admin attendance updates.
5. Payroll receives verified attendance input.

## Asset/task lifecycle

1. Admin creates work order.
2. Staff receives assignment.
3. Staff updates/provides proof.
4. Admin verifies.
5. Resident sees public outage/service status if relevant.

Fail if separate records diverge.

---

# 20. Realtime and notification testing

Test all realtime event flows:

- Member approval
- Visitor approval
- Visitor entry/exit
- Parcel received/collected
- Complaint assignment/status
- SOS
- Patrol alert
- Payment success/failure
- Bill publication
- Notice publication
- Event capacity
- Staff roster
- Leave
- Asset maintenance
- Support ticket
- AI action execution

Test:

- Correct recipient
- Correct society
- Correct role
- Correct deep link
- Lock-screen redaction
- Duplicate suppression
- Retry
- Provider failure
- App foreground/background
- Reconnect
- Last event ID
- Out-of-order event
- Permission revoked
- Logout
- Society switch

No event may leak to another society or role.

---

# 21. AI Chatbot / SERO Copilot final testing

Test:

- Login-required access
- Resident context
- Admin context
- Staff context
- Guard context
- Super Admin context
- English
- Hindi
- Hinglish
- Mixed language
- Society-specific answers
- Rule lookup
- Event information
- Facility timings
- Complaint guidance
- Bill explanation
- Payment guidance
- Visitor guidance
- Staff shift guidance
- Parking/asset/governance guidance
- Conversation persistence
- Conversation search
- Rename/archive/delete
- Streaming
- Stop generation
- Regenerate
- Citations
- Attachments
- Feedback
- Quota
- Provider failure
- Offline
- Reconnect

## AI security

Test:

- Cross-society prompt
- Cross-role prompt
- System-prompt request
- Prompt injection
- Indirect prompt injection in documents/images
- Secret request
- Another user’s conversation
- Unauthorized tool
- Tool parameter tampering
- Proposal replay
- Expired proposal
- Changed permission
- Feature disabled
- Step-up auth
- Approval-required action

## AI correctness

Verify:

- Citation supports claim
- Correct document version
- Correct page/section
- Correct society
- Correct date/amount
- No fabricated official rule
- Uncertainty is stated
- No write happens without confirmed proposal
- AI uses canonical domain services
- AI does not mark payment success without verified provider state

---

# 22. Finance, billing, and payment testing

Test invariants:

- Journal debits equal credits
- Published invoices are immutable
- Payment allocation does not exceed payment
- No floating-point money
- Duplicate webhook does not duplicate posting
- Duplicate bill request does not duplicate invoice
- Concurrent plan/bill/payment actions are safe
- Refund/dispute/reversal works
- Receipt matches payment
- Dashboard totals match database
- Date filters are correct
- GST/tax is correct
- Proration is correct
- Late fee/waiver is correct
- Expenses require correct approval
- OCR is proposal-only until verified
- Reconciliation is correct
- Reports match source

Test provider:

- Valid webhook
- Invalid signature
- Replay
- Out-of-order
- Wrong amount
- Wrong currency
- Wrong society
- Timeout
- Retry
- Partial payment
- Overpayment
- Refund
- Chargeback
- Reconciliation mismatch

---

# 23. Database, migrations, and data integrity

Test:

- Fresh database
- Upgrade from prior schema
- Rollback where supported
- Seed
- Foreign keys
- Unique constraints
- RLS
- Tenant isolation
- Optimistic locking
- Soft delete
- Audit immutability
- Indexes
- Query plans
- Large tables
- Partitioning
- Transaction rollback
- Deadlock retry
- Backup/restore
- Referential integrity

Check for:

- Firestore/PostgreSQL divergence
- Dual-write without reconciliation
- Orphan records
- Duplicate canonical records
- Missing society ID
- Missing created_by/updated_by
- Money stored as float
- Incorrect timezone handling
- Unbounded table scan
- Missing index
- Unsafe cascade delete

---

# 24. File upload, document, and media testing

Test:

- Image
- PDF
- Office document
- Video if supported
- Valid upload
- Large upload
- MIME spoof
- Double extension
- Malware test file
- Zip bomb
- Active content
- Path traversal
- Cross-tenant object key
- Public object
- Expired signed URL
- Deleted file
- Unauthorized preview
- Thumbnail
- Checksum
- Upload retry
- Cancel
- Offline upload
- Parser failure
- OCR failure
- Prompt injection in document
- Retention/deletion

Verify no production file is publicly readable unless intentionally public.

---

# 25. Offline and synchronization testing

Test supported offline flows:

- App launch offline
- Login token available/unavailable
- Cached lists
- Visitor draft
- Parcel intake
- Incident draft
- Patrol checkpoint
- Complaint/task update
- Attendance attempt
- Shift handover
- AI unavailable
- Payment unavailable

Test:

- Pending sync visibility
- App restart
- Duplicate retry
- Out-of-order retry
- State changed on server
- Role revoked
- Shift ended
- Society changed
- File pending
- Conflict resolution
- Permanent rejection
- Local encryption
- Local cleanup

No offline flow may display final success for operations requiring online verification.

---

# 26. Security audit

Cover:

- OWASP API Security Top 10
- BOLA/IDOR
- Function-level authorization
- Tenant isolation
- Field-level authorization
- Mass assignment
- SQL injection
- NoSQL injection
- XSS
- SSRF
- CSRF where applicable
- CORS
- Security headers
- Rate limiting
- Brute force
- OTP abuse
- QR replay
- Webhook replay
- File upload
- Prompt injection
- AI tool abuse
- Session fixation
- Token leakage
- Secret leakage
- Log injection
- CSV formula injection
- Report/PDF injection
- API key protection
- Impersonation
- Audit mutation
- Data retention/deletion
- Container security
- Dependency vulnerabilities
- Backup encryption

Use automated tools and manual adversarial tests.

---

# 27. Accessibility testing

Test:

- Screen reader
- Keyboard
- Focus order
- Focus visibility
- Text scaling
- Contrast
- Touch targets
- Form labels/errors
- Dialog focus trap
- Bottom sheets
- Charts with text alternatives
- Status not color-only
- Reduced motion
- Scanner instructions
- SOS announcement
- Streaming AI accessibility
- Hindi/mixed-script rendering
- Responsive layout

Target WCAG 2.1 AA where applicable.

---

# 28. Performance and load testing for 3,000–5,000 people

Use production-like infrastructure.

## 28.1 Concurrent-user targets

Test:

- 3,000 concurrent authenticated users
- 5,000 concurrent authenticated users
- 3,000–5,000 realtime connections
- 300 concurrent Admin/Staff operational users
- 300 active AI chat sessions
- 100 simultaneous AI streams

## 28.2 Traffic mix

Use a realistic mix:

- 20% dashboard/list reads
- 10% notices/events/rules
- 12% complaints/tasks
- 8% visitor operations
- 6% parcel operations
- 8% payments/finance reads
- 3% payment writes/provider callbacks
- 5% attendance/roster/leave
- 4% assets/parking
- 4% governance/polls
- 5% support/platform operations
- 5% reports/search
- 10% AI/realtime/background behavior

## 28.3 Load scenarios

1. Baseline 50 users
2. Ramp to 3,000 users
3. Sustain 3,000 for 30 minutes
4. Ramp to 5,000 users
5. Sustain 5,000 for 15 minutes
6. 500 RPS burst
7. 750 RPS short burst
8. Four-hour soak
9. Morning login spike
10. Gate visitor spike
11. Parcel delivery spike
12. Shift attendance spike
13. Bill publication spike
14. Payment webhook burst with duplicates
15. Notice broadcast
16. SOS dispatch
17. AI stream spike
18. Realtime reconnect storm
19. Large report generation
20. Redis restart
21. API replica termination
22. Worker crash
23. Slow database
24. Object-storage slowdown
25. AI-provider slowdown

## 28.4 Performance targets

Excluding slow third parties:

- Read p95 under 300–400 ms
- Standard write p95 under 500–700 ms
- p99 under 1.5 seconds
- Login p95 under 1 second excluding identity-provider delay
- QR/OTP p95 under 500 ms
- SOS internal dispatch under 1 second
- Payment webhook processing internal p95 under 1 second
- Warm global dashboard p95 under 700 ms
- AI cached answer p95 under 1 second
- AI time-to-first-token p95 under 2.5 seconds
- Standard RAG answer p95 under 8 seconds excluding provider degradation
- Error rate under 1%
- No memory leak
- No event-loop degradation
- DB pool remains healthy
- Redis remains healthy
- Queue drains after recovery
- No duplicate business effect
- No cross-tenant response
- No UI freeze

Report:

- RPS
- Concurrent users
- p50/p90/p95/p99
- Errors
- CPU
- Memory
- Event-loop lag
- DB connections/locks/slow queries
- Redis latency/memory
- Queue depth/age
- Realtime connections
- AI provider latency/cost
- File upload throughput
- Bottlenecks
- Capacity headroom

---

# 29. Reliability and failure injection

Test failure of:

- PostgreSQL
- Redis
- Queue worker
- Object storage
- Firebase Auth
- FCM
- Email
- SMS
- Razorpay/payment provider
- AI provider
- Vector store
- Malware scanner
- OCR/parser
- Report generator
- Realtime gateway
- One API replica
- Network
- DNS
- Clock skew
- Disk/storage quota

Test crashes:

- Before database commit
- After database commit before response
- After webhook event storage
- During queue job
- During file processing
- During AI action execution
- During realtime publish

Verify:

- Timeouts
- Circuit breakers
- Retries with jitter
- Idempotency
- Dead letters
- No partial corruption
- Correct user status
- Alerting
- Recovery
- No manual database edit required
- No false success

---

# 30. Observability and operations

Verify:

- Request ID
- Correlation ID
- Trace across frontend/API/database/queue/notification/AI
- Structured logs
- Tenant/user context
- Sensitive-data redaction
- Error reporting
- Metrics
- Dashboards
- Alerts
- Health endpoints
- Readiness endpoints
- Worker heartbeat
- Queue depth
- Payment monitoring
- Notification delivery
- AI cost
- AI safety
- SLA breaches
- Backup status
- Deployment version

Trigger controlled failures and verify logs/alerts.

Create operational runbooks for:

- Login outage
- Payment outage
- Redis outage
- Database saturation
- Queue backlog
- Realtime outage
- SOS notification issue
- AI provider outage
- File-processing backlog
- Cross-tenant incident
- Backup failure

---

# 31. Backup, restore, retention, and disaster recovery

Test real backup and restore.

Include:

- PostgreSQL
- Object storage
- AI metadata
- Vector index metadata
- Audit logs
- Payment/ledger
- Visitor/parcel
- Complaints
- Staff/attendance
- Files
- Support
- Platform settings

Verify:

- Backup encryption
- Restore to isolated environment
- Point-in-time recovery where supported
- Referential integrity
- Ledger reconciliation
- File links
- RLS and permissions after restore
- Realtime/outbox consistency
- RPO
- RTO
- Retention
- Tenant export
- Tenant offboarding
- User deletion
- Conversation deletion
- Document/vector deletion
- Legal hold if applicable

Do not accept “backup configured” without restore evidence.

---

# 32. Full feature traceability

Create a final traceability matrix containing every documented feature across:

- Super Admin
- Admin
- Staff
- Resident
- AI Chatbot
- Cross-role modules

For each feature:

- Feature ID
- Feature name
- Role
- Screen
- Route
- UI component/action
- Provider/controller
- Service
- Endpoint
- Permission
- Tables
- Realtime event
- Background job
- Audit event
- Unit test
- Integration test
- E2E test
- Load test
- Live/static status
- Pass/fail
- Evidence

No feature may be marked complete without evidence.

---

# 33. Small-element and micro-interaction audit

Test every visible small element:

- Menu icons
- Back buttons
- Search icons
- Filter chips
- Sort dropdowns
- Date pickers
- Tabs
- Badges
- Tooltips
- Info icons
- Toggle switches
- Checkboxes
- Radio buttons
- Pagination controls
- Infinite scroll
- Pull-to-refresh
- “View All”
- “See More”
- Expand/collapse
- Copy buttons
- Download buttons
- Share buttons
- Scanner buttons
- Camera buttons
- Upload progress
- Cancel upload
- Retry
- Notification badges
- Unread counters
- Avatar
- Status pill
- Chart legends
- Chart tooltips
- Empty-state actions
- Error-state actions
- Confirmation dialogs
- Destructive confirmations
- Snackbar actions
- Deep links
- External links
- Form validation
- Password visibility
- OTP resend countdown
- AI stop/regenerate/copy/feedback
- Logout
- Session-expiry prompt

Every small element must have:

- Correct action
- Correct disabled state
- Loading state
- Error handling
- Accessibility label
- Analytics/audit where appropriate

---

# 34. Automated end-to-end journey suite

Create automated E2E journeys.

## Journey 1 — Society onboarding

Super Admin approves society → Main Admin logs in → Configures structure → Invites members → Enables billing → Publishes first notice.

## Journey 2 — Member and visitor

Resident registers → Admin approves → Resident pre-approves visitor → Staff scans QR → Entry/exit → Admin and Resident timelines update.

## Journey 3 — Complaint

Resident raises complaint → Admin assigns Staff → Staff works/uploads proof → Admin verifies → Resident rates.

## Journey 4 — Payment

Admin publishes bill → Resident sees/pays → Webhook verifies → Receipt created → Ledger/dashboard update.

## Journey 5 — Parcel

Staff logs parcel → Resident notified → Resident collects with OTP/QR → Staff handover → Status updates.

## Journey 6 — SOS

Resident triggers SOS → Eligible Staff receive → One acknowledges → Status updates → Admin monitors → Resolve/audit.

## Journey 7 — Attendance

Admin publishes roster → Staff checks in/out → Attendance appears → Correction/leave where applicable.

## Journey 8 — Event/governance

Admin creates event/poll → Resident RSVPs/votes → Capacity/quorum/result update → Minutes published.

## Journey 9 — AI Copilot

Resident asks rule question → Correct citation → Draft complaint → Confirms → Complaint created → Admin sees it.

## Journey 10 — Super Admin controls

Super Admin changes feature rollout → Correct societies receive feature → Others do not → Audit and rollback work.

Run journeys:

- Mobile
- Web where applicable
- Society A/B
- Different roles
- Slow network
- Retry
- Concurrent activity

---

# 35. Fix workflow

When defects are found:

1. Record the finding first.
2. Add failing regression test.
3. Apply the smallest correct fix.
4. Run targeted tests.
5. Run module tests.
6. Run full suite.
7. Run contract tests.
8. Re-run security case.
9. Re-run performance case where relevant.
10. Update traceability.
11. Do not close without evidence.

Do not:

- Hide errors
- Remove features
- Hard-code success
- Replace real API with mock
- Disable tests
- Broaden permissions
- Disable RLS
- Suppress logs
- Bypass validation
- Add arbitrary delays
- Mark a test flaky without root-cause analysis

---

# 36. Final acceptance criteria

The entire platform is complete only when:

- Every role logs in and reaches the correct shell
- Every page is reachable
- Every page uses live data
- No production mock/static data remains
- Every button and small UI element works
- No page or loader gets stuck
- Every frontend API call maps to a working endpoint
- Every endpoint is authorized and tested
- Every role sees only allowed rows, fields, and actions
- Society A cannot access Society B
- Cross-role records synchronize correctly
- Realtime events and notifications work
- AI Chatbot works in English, Hindi, and Hinglish
- AI answers are grounded and permission-safe
- AI actions require confirmation and use canonical services
- Payments and ledger are accurate and replay-safe
- Visitor/parcel/SOS/attendance flows are duplicate-safe
- Files are private and scanned
- Offline sync is visible, safe, and idempotent
- UI matches the SERO design system
- Responsive layouts work
- Accessibility checks pass
- Flutter and backend builds pass
- Migrations pass
- All automated tests pass
- 3,000 concurrent users pass
- 5,000 concurrent users pass or a documented capacity limit and scaling remediation is provided
- Backups restore successfully
- Observability and runbooks are complete
- Zero unresolved P0/P1 issues remain
- Final traceability contains executable evidence

---

# 37. Final response format

At the end of the audit, output:

## A. Final verdict

- PASS / PASS WITH P2/P3 EXCEPTIONS / FAIL
- Release recommendation
- Environment tested
- Build versions
- Tested user scale
- Test duration

## B. Findings summary

- P0 count
- P1 count
- P2 count
- P3 count
- Top 10 blockers

## C. Application verdicts

- Super Admin
- Admin
- Staff/Guard
- Resident
- AI Copilot
- Cross-role modules
- Backend
- Database
- Infrastructure

## D. Connectivity verdict

- Pages connected
- APIs working
- Realtime working
- Notifications working
- Deep links working
- Live data confirmed
- Static/mock data found

## E. UI verdict

- Design consistency
- Responsive
- Accessibility
- Stuck states
- Micro-interactions

## F. Security verdict

- Authentication
- RBAC
- Tenant isolation
- Field security
- Files
- Payments
- AI
- Audit

## G. Performance verdict

- 3,000-user result
- 5,000-user result
- RPS
- p95/p99
- Error rate
- Bottlenecks
- Capacity headroom

## H. Reliability verdict

- Failure recovery
- Offline sync
- Realtime
- Queues
- Backups
- Restore

## I. Exact blocking actions

List the exact files, endpoints, migrations, tests, and fixes required before release.

Do not use the phrase “production ready” unless every blocking criterion has passed with evidence.

---

# 38. Start instruction

Begin with:

1. Clean install and build
2. Repository inventory
3. Screen-route-endpoint traceability
4. Static/mock-data detection
5. Authentication and role routing
6. End-to-end journeys
7. Security
8. AI
9. Performance
10. Backup/restore
11. Final release gate

Do not begin by fixing random UI issues before establishing the full inventory and baseline test results.
