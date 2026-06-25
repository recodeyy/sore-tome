# SERO Production Recovery — Full Backend Repair, Cross-Role Live Integration, Notifications, GCP Stability, and Demo Payment Master Prompt

## Role

Act as the **Principal Full-Stack Recovery Architect, Staff Flutter Engineer, Staff Backend Engineer, PostgreSQL Architect, Firebase/FCM Engineer, GCP SRE, Payments Engineer, Security Engineer, QA Director, and Release Manager**.

You are working directly on this repository:

`https://github.com/recodeyy/sore-tome`

The current system is partially implemented and partially connected. Some APIs work, some do not. Some pages crash, become blank, show “Something went wrong,” remain stuck, or display zero/empty values because their endpoints or response fields are missing. Cross-role actions are not consistently synchronized. Notifications are unreliable or missing. The application is deployed on GCP and must work for teammates opening the live app—not only on one developer’s machine.

Your task is to **repair the current repository**, not create another prototype.

The completed system must make all Super Admin, Admin, Staff/Guard, Resident, AI, and cross-role features work together as one live platform.

---

# 1. Core outcome

After implementation, the following must be true:

- Admin creates data → eligible Residents and Staff see it.
- Resident performs an action → Admin and assigned Staff see it.
- Staff updates or approves an action → Resident and Admin receive live updates and notifications.
- Super Admin changes a society feature or subscription → the society application reflects it.
- All role applications use the same canonical records.
- All visible screens use live backend data.
- No production page depends on mock, dummy, sample, placeholder, or locally generated operational data.
- No major page crashes or becomes blank.
- No loader remains stuck forever.
- Push notifications, in-app notifications, realtime updates, and deep links work.
- The production GCP deployment uses the same migrations, configuration, endpoints, and features tested locally/staging.
- A complete demo society proves every workflow end to end.

Do not mark the platform complete because an audit document says PASS. Re-run and prove everything against the current repository and deployed environment.

---

# 2. Current-repository audit leads that must be reverified

Treat these as investigation leads, not assumptions:

1. The repository contains:
   - Flutter frontend in `sero/`
   - Backend in `society-backend/`
   - Firebase authentication/FCM integration
   - PostgreSQL migrations
   - Redis/BullMQ-related infrastructure
   - GCP load-test scripts
   - Existing live-data, auth, endpoint, and release reports

2. Existing reports have previously identified issues such as:
   - Client calling legacy `/events` while current data existed at `/events-v2`
   - Missing `GET /amenities`
   - Authentication failures caused by invalid/null society context
   - Phantom or incorrectly scoped workspaces
   - Missing backend fields for dashboard metrics
   - Empty revenue/category charts
   - Missing attendance/payroll activity fields
   - Missing amenity dashboard aggregates
   - Generic or zero dashboard values
   - Screens showing “No invoice selected” because route IDs were not passed

3. The existing final release report must not be trusted without rerunning:
   - Live endpoint tests
   - GCP deployment tests
   - Cross-role workflows
   - Notification tests
   - Physical-device APK tests
   - Data integrity tests

Produce exact file/line evidence for the current state.

---

# 3. Mandatory first outputs

Before bulk coding, create:

1. `RECOVERY_CURRENT_STATE_AUDIT.md`
2. `RECOVERY_GCP_DEPLOYMENT_AUDIT.md`
3. `RECOVERY_SCREEN_ROUTE_API_MATRIX.md`
4. `RECOVERY_ENDPOINT_STATUS_MATRIX.md`
5. `RECOVERY_CROSS_ROLE_EVENT_MATRIX.md`
6. `RECOVERY_NOTIFICATION_MATRIX.md`
7. `RECOVERY_CRASH_AND_BLANK_SCREEN_REPORT.md`
8. `RECOVERY_DATABASE_SOURCE_OF_TRUTH_MAP.md`
9. `RECOVERY_IMPLEMENTATION_PLAN.md`
10. `RECOVERY_BLOCKERS.md`
11. `recovery_findings.json`
12. `recovery_traceability.json`

For every screen record:

- Role
- Route
- Flutter file
- Provider/notifier
- Service method
- Endpoint
- Response model
- Database source
- Permission
- Loading state
- Empty state
- Error state
- Realtime event
- Notification event
- Current result
- Required fix
- Test

For every endpoint record:

- Method/path
- Route file
- Controller/service
- Authentication
- Permission
- Society scope
- Tables/views
- Request schema
- Response schema
- Frontend consumers
- Realtime/outbox events
- Tests
- Local status
- GCP status

---

# 4. Build one complete staging/demo society

Create an idempotent staging seed:

`Hubtown Sunkist`

Use it only as a demo/test fixture. Do not represent the data as real resident information.

## Society structure

- Society: Hubtown Sunkist
- Wing: A
- Floor: 14
- Flat/Unit: 1402
- Additional wings, floors, and units so list/filter/pagination flows can be tested
- Amenities:
  - Gym
  - Clubhouse
  - Swimming Pool
  - Community Hall
- Gates:
  - Main Gate
  - Service Gate
- Parking slots
- Assets:
  - Lift
  - Generator
  - Pump
  - CCTV system

## Test identities

Create secure documented test identities for:

- Super Admin
- Main Admin
- Treasurer
- Secretary
- Security Manager
- Guard at Main Gate
- Maintenance Staff
- Resident Owner of A-1402
- Resident Tenant or Family Member
- Resident in another unit
- Society B users for tenant-isolation tests

Do not commit plaintext production credentials. Use staging-only environment variables or deterministic local test credentials clearly separated from production.

## Seed data

Seed:

- Society profile/settings
- Wings/floors/units
- Memberships and household relationships
- Vehicles
- KYC statuses
- Maintenance bills
- Payment records
- Notices
- Announcements
- Polls
- Events
- Rules/bylaws
- Complaints
- Staff roster/attendance
- Visitors
- Parcels
- Amenities/bookings
- Parking allocations
- Assets/work orders
- SOS/incident test records
- NOC requests
- Support tickets
- AI documents

The seed must be repeatable and must not create duplicates.

---

# 5. Canonical cross-role architecture

Each business object must have one canonical record.

## Required canonical domains

- Society
- User and membership
- Unit/household
- Bill/payment/receipt/ledger
- Notice/announcement
- Poll/vote
- Event/RSVP
- Visitor/pass/gate event
- Domestic help/access event
- Parcel/handover
- Complaint/assignment/work update
- Staff/roster/attendance/leave
- Amenity/availability/booking/review
- Parking/allocation/vehicle
- Asset/work order/maintenance
- Rule/document/NOC
- SOS/incident/patrol
- Support ticket
- Notification
- AI conversation/action

Admin, Resident, Staff, Super Admin, and AI must call the same domain services.

Do not maintain:

- Admin notices and Resident notices as separate data
- Staff tasks and Resident complaints as separate unrelated records
- Admin parking allocations and Resident parking display as separate records
- Client-only payment state
- AI-only write paths

---

# 6. Required cross-role workflows

Implement and automate all workflows below.

## 6.1 Notice and announcement

1. Admin publishes a notice or maintenance announcement.
2. Backend stores the canonical notice.
3. Audience is calculated:
   - Entire society
   - Wing
   - Floor
   - Unit
   - Owners
   - Tenants
   - Staff
4. Outbox event is created.
5. FCM push and in-app notification are created.
6. Resident A-1402 receives it.
7. Notice appears in Resident Notice Board.
8. Unread badge updates.
9. Opening notification deep-links to notice detail.
10. Read/acknowledgement status becomes visible to Admin.

## 6.2 Maintenance bill and payment

1. Admin/Treasurer generates a maintenance bill for A-1402.
2. Resident dashboard and Bills screen update.
3. Resident receives bill notification.
4. Resident opens detailed line items.
5. Resident pays using Razorpay Test Mode.
6. Backend creates a real test order/payment intent.
7. Client opens Razorpay test checkout.
8. Backend webhook/signature verification is authoritative.
9. UI remains `Processing` until verified.
10. Receipt is generated.
11. Ledger and payment allocation update.
12. Resident and Admin dashboards update.
13. Duplicate callback/webhook produces one financial effect.
14. Refund/failure/pending paths are tested.

## 6.3 Visitor: guest, Swiggy, Zomato, delivery, cab, service provider

Staff/Guard must be able to select a visitor category:

- Guest
- Swiggy
- Zomato
- Blinkit/Zepto/Grocery Delivery
- Courier
- Cab/Driver
- Domestic Help
- Maintenance Technician
- Vendor
- Other

Workflow:

1. Guard searches/selects A-1402.
2. Guard selects visitor category/provider.
3. Guard enters minimum required details or scans pass.
4. Resident receives immediate push + in-app approval card.
5. Resident approves/rejects.
6. Guard screen updates in realtime.
7. OTP/QR verification is performed where configured.
8. Entry is recorded.
9. Resident receives “entered” notification.
10. Admin/Security dashboard updates.
11. Exit is recorded.
12. Resident receives exit update where policy permits.
13. Overstay and exception rules work.
14. No visitor data leaks to other units.

Include one-tap quick actions for common delivery providers, but use generic configurable provider categories rather than hard-coding business logic to a single brand.

## 6.4 Complaint

1. Resident creates complaint with evidence.
2. Admin sees it immediately.
3. Auto-routing suggests or applies the correct department according to configured rules.
4. Admin assigns Staff.
5. Staff receives notification.
6. Staff accepts/updates status.
7. Resident sees public timeline update.
8. Staff uploads before/after proof.
9. Admin verifies.
10. Resident receives resolution notification.
11. Resident rates/reopens.
12. Internal notes never appear to Resident.

## 6.5 Parking

1. Admin creates parking inventory.
2. Admin allocates a slot to A-1402.
3. Resident sees live allocation and vehicle mapping.
4. Resident receives allocation/update notification.
5. Guard can verify the vehicle/slot.
6. Transfer, release, visitor parking, waitlist, and violation flows update all roles.
7. Unique active allocation is database-enforced.

## 6.6 Poll

1. Admin creates and publishes a poll.
2. Eligible A-1402 resident receives notification.
3. Resident sees poll.
4. Resident votes once.
5. Backend validates eligibility.
6. Duplicate/concurrent vote is rejected safely.
7. Admin dashboard updates.
8. Results follow configured visibility.
9. Poll opening/closing notifications work.

## 6.7 Event

1. Admin creates event.
2. Resident sees event and receives notification.
3. Resident RSVPs.
4. Capacity/waitlist updates live.
5. Admin sees attendees.
6. Staff sees check-in view if permitted.
7. Cancellation/reminder/deep-link flows work.

## 6.8 Amenities

1. Admin configures gym/hall/clubhouse/pool.
2. Resident sees rules, price, timings, and live slots.
3. Resident books.
4. Backend prevents double booking.
5. Booking payment/deposit uses test payment where configured.
6. Admin sees booking.
7. Resident receives confirmation/reminder.
8. Cancellation/refund/waitlist/review flows work.

## 6.9 Staff action notification

Whenever Staff:

- Accepts a complaint
- Changes task status
- Uploads proof
- Completes work
- Approves/verifies an operational request
- Records parcel receipt/handover
- Records visitor entry/exit
- Acknowledges SOS

the correct Resident/Admin recipients must receive:

- Realtime update
- In-app notification
- FCM push where enabled
- Correct deep link

## 6.10 Super Admin controls

1. Super Admin approves Hubtown Sunkist.
2. Society becomes available to Admin.
3. Super Admin enables/disables a feature.
4. Eligible society navigation and API capability reflect it.
5. Disabled feature is inaccessible through UI and API.
6. Subscription/white-label/support/audit changes propagate.
7. All changes are audited.

---

# 7. Notification system repair

Build one canonical NotificationService.

## Notification channels

- In-app notification inbox
- FCM push
- Optional email/SMS adapters behind configuration
- Realtime event

## Required notification event types

- Notice published
- Announcement
- Maintenance bill generated
- Payment pending/success/failure/refund
- Visitor approval request
- Visitor approved/rejected
- Visitor entered/exited/overstayed
- Parcel received/reminder/collected
- Complaint created/assigned/status/comment/resolved/reopened
- Staff task assigned
- Poll opened/closing/results
- Event created/reminder/cancelled/waitlist promotion
- Amenity booking/approval/reminder/cancel/refund
- Parking allocation/violation/update
- Staff attendance/roster/leave
- SOS triggered/acknowledged/responding/resolved
- KYC/NOC status
- Support ticket
- Subscription/feature change
- AI action completion

## Notification data model

Store:

- Notification ID
- Society ID
- Recipient user ID
- Recipient role/workspace
- Event type
- Resource type
- Resource ID
- Title
- Body
- Deep-link route
- Channel
- Priority
- Created time
- Delivery state
- Read time
- Deduplication key
- Retry count
- Provider message ID
- Failure reason

## FCM requirements

- Register/update device tokens
- Support multiple devices
- Remove invalid tokens
- Topic use only where safe
- User/society targeting
- Background/foreground handling
- Android notification channels
- Deep links
- Badge synchronization
- Retry/backoff
- Delivery logging
- Lock-screen privacy
- No cross-tenant topic leakage

Do not send directly from random route handlers. Use outbox → queue → NotificationService.

---

# 8. GCP production repair

Inspect the actual deployed GCP architecture and do not assume local behavior matches production.

Audit:

- GCP project
- Region
- Cloud Run/GCE/GKE service actually used
- Container image/version
- Environment variables
- Secret Manager
- Cloud SQL/PostgreSQL
- Redis/Memorystore or actual Redis deployment
- Firebase project
- FCM configuration
- Storage bucket
- CORS
- VPC/connectivity
- Migrations
- Service account permissions
- Health checks
- Autoscaling
- Logs
- Error Reporting
- Monitoring
- Build/deploy pipeline
- Flutter production API base URL

Create:

- `GCP_ACTUAL_TOPOLOGY.md`
- `GCP_ENVIRONMENT_DIFF.md`
- `GCP_RUNTIME_FAILURE_REPORT.md`

## GCP runtime debugging

Use logs and traces to identify every:

- 4xx/5xx
- Crash loop
- Timeout
- Database connection failure
- Missing table/migration
- Invalid environment variable
- CORS error
- Firebase token verification failure
- FCM failure
- Null response field
- JSON model mismatch
- Unhandled exception
- Slow query
- Memory/OOM
- Cold-start issue

Correlate Flutter error request IDs with backend logs.

Do not suppress production exceptions merely to avoid crashes.

---

# 9. Flutter crash, blank page, and “Something went wrong” repair

Inventory every screen in:

- Super Admin
- Admin
- Staff/Guard
- Resident
- AI Copilot

For every screen test:

- Normal data
- Empty data
- Partial/null fields
- Slow response
- 401
- 403
- 404
- 409
- 422
- 429
- 500
- Offline
- Realtime reconnect
- Deleted record
- Unknown enum
- Old client/new backend during rollout

Fix:

- Unsafe `!`
- Invalid casts
- Missing route arguments
- Model/API mismatches
- Unbounded loaders
- Provider exceptions
- Stream lifecycle
- SetState after dispose
- Duplicate navigation
- Unhandled null lists/maps
- Oversized widgets
- Render overflow
- Large synchronous JSON parsing
- Duplicate API calls
- Stale workspace data

Requirements:

- No blank page
- No infinite loader
- Error state includes retry
- Correct request/reference ID
- App does not expose stack trace
- Navigation remains available
- Safe form state is retained
- Crash reporting is wired to Sentry/Crashlytics or approved equivalent

---

# 10. Endpoint repair and contract unification

Do not leave parallel ambiguous endpoints such as legacy and v2 without a migration plan.

For each domain:

1. Select canonical API path.
2. Update all Flutter consumers.
3. Keep temporary compatibility only if necessary.
4. Add deprecation logging.
5. Add OpenAPI contract.
6. Add contract tests.
7. Remove obsolete path after migration.

Fix all:

- Missing list endpoints
- Missing detail endpoints
- Missing aggregates
- Missing response fields
- Wrong route IDs
- Wrong enum/date names
- Incorrect pagination
- Empty legacy Firestore endpoints
- Frontend/backed response mismatch

Use typed DTOs on both sides.

---

# 11. Feature coverage

All 212 documented capabilities must be mapped and tested.

## Super Admin

Verify all 31 intended platform capabilities, including:

- Societies
- Users
- Revenue
- Subscriptions
- Approvals
- KYC
- Setup progress
- Plans
- Feature toggles
- MAU/DAU
- Churn
- Reports
- Global communications
- White-label
- Support
- Audit
- Impersonation
- API access
- Platform health and operational controls from the expanded specifications

## Admin

Verify all 92 intended capabilities across:

- Society structure
- Members/committee
- Finance
- Bills/payments/ledger/expenses/GST
- Notices/announcements/polls/AGM
- Complaints/SLA/escalations
- Staff/attendance/payroll/roster
- Amenities
- Parking
- Assets
- Reports/exports
- Documents/governance/security/analytics from expanded specifications

## Staff

Verify all 32:

- Visitors
- OTP/QR
- Parcels
- Incidents
- SOS
- Patrol
- Shift handover
- Complaint tasks/proof
- Attendance
- Leave/roster

## Resident

Verify all 57:

- Profile/household/vehicles/KYC
- Bills/payments/receipts/auto-pay
- Visitors/domestic help
- Complaints/chat
- Notices/events/polls
- Marketplace/carpool/lost and found
- Amenities/reviews
- SOS/emergency
- Rules/bylaws/receipts/NOCs

## AI and cross-role modules

Verify all AI and shared-module requirements.

No feature is complete if only its UI exists.

---

# 12. Razorpay demo/test payment

Use **Razorpay Test Mode** for the demo.

Requirements:

- Keys come from GCP Secret Manager/environment variables
- No key is committed
- Backend creates order
- Frontend opens test checkout
- Test success/failure/cancel paths
- Backend verifies signature
- Webhook endpoint verifies raw-body signature
- Event is stored idempotently
- Payment/receipt/ledger update transactionally
- Duplicate webhook has one effect
- Resident sees processing until verified
- Admin sees updated collection
- Test-mode label is clear in staging/demo
- Production payment feature remains disabled until real production credentials and compliance are approved

Create a staging demo bill for A-1402 and prove payment end to end.

Do not simulate success by changing a local boolean.

---

# 13. Database and migration repair

Audit:

- Firestore versus PostgreSQL ownership
- Missing migrations in GCP
- Empty or unseeded tables
- Duplicate schemas
- Missing society IDs
- Foreign keys
- Unique constraints
- RLS
- Indexes
- Materialized views
- Notification/outbox tables
- Realtime event tables
- Payment/ledger invariants

Use PostgreSQL as the source of truth for canonical operational and financial data.

Do not allow direct privileged Flutter writes.

All GCP deployments must run migrations before serving new code.

Add readiness checks that fail when required migrations are absent.

---

# 14. Realtime architecture

Use one authorized realtime layer.

Support:

- WebSocket or SSE
- Last event ID
- Reconnect
- Event deduplication
- Ordered per-resource events
- User/society/unit/gate/task rooms
- Permission revalidation
- Logout disconnect
- Workspace-switch disconnect
- Background/resume

Do not rely only on periodic refresh for urgent workflows.

Urgent events:

- Visitor approval
- SOS
- Payment status
- Complaint assignment
- Parcel
- Poll/event capacity

---

# 15. Performance and no-lag requirements

Profile Flutter release builds and production-like backend.

Frontend:

- No blocking JSON parsing on UI thread for large payloads
- Paginated/virtualized lists
- Bounded image cache
- No full chat rebuild per token
- No duplicate providers/subscriptions
- No memory leaks
- No unnecessary dashboard request waterfall
- Skeletons and progressive rendering

Backend:

- Remove N+1 queries
- Add indexes
- Add aggregates/materialized views
- Use PgBouncer/pooling
- Cache safe reads
- Queue expensive work
- Do not generate large PDF/Excel synchronously
- Do not send notifications synchronously inside request transaction

Targets:

- Common reads p95 < 400 ms
- Common writes p95 < 700 ms
- QR/OTP/visitor decision p95 < 500 ms excluding external provider delay
- SOS internal dispatch < 1 second
- Payment webhook internal p95 < 1 second
- Error rate < 1%
- No UI freeze

Run progressive 3K, 10K, and 20K tests using existing GCP load tooling, but fix correctness before scale.

---

# 16. Automated end-to-end suite using Hubtown Sunkist

Create tests that run against a clean seeded environment.

## Journey 1 — Login and role routing

- Login all roles
- Correct shell
- No wrong-role page flash
- Workspace selection

## Journey 2 — Admin notice to Resident

- Admin publishes maintenance notice
- Resident A-1402 receives push/in-app
- Opens deep link
- Admin sees read state

## Journey 3 — Maintenance bill and Razorpay test

- Admin bills A-1402
- Resident pays
- Test webhook verifies
- Receipt/ledger/dashboard update

## Journey 4 — Swiggy/Zomato/delivery approval

- Guard selects A-1402 and delivery type
- Resident receives immediate approval
- Approves
- Guard sees approval
- Entry/exit notifications work

## Journey 5 — Complaint

- Resident creates
- Admin assigns
- Staff updates and uploads proof
- Resident receives updates
- Admin closes
- Resident rates

## Journey 6 — Parking

- Admin allocates slot
- Resident sees it
- Guard verifies vehicle
- Update notification works

## Journey 7 — Poll

- Admin publishes
- Resident votes once
- Admin sees live result

## Journey 8 — Amenity

- Resident books
- Admin sees booking
- Double-book attempt is prevented

## Journey 9 — SOS

- Resident triggers
- Staff receives
- Staff acknowledges
- Resident/Admin see status
- Resolve/audit

## Journey 10 — Super Admin feature toggle

- Toggle feature
- Society UI/API update
- Rollback works

## Journey 11 — AI

- Resident asks current society rule/event/facility question
- Correct live citation
- AI proposes complaint
- Confirm creates canonical complaint

---

# 17. Notification verification

Do not say notifications work because a row was inserted.

Verify on physical Android devices:

- Device token registration
- App foreground
- App background
- App terminated
- Notification tap
- Correct deep link
- Badge count
- Multiple devices
- Invalid token cleanup
- Logout
- Workspace switch
- Resident A-1402 isolation
- Society B isolation

Capture evidence:

- Backend event
- Queue job
- FCM provider response
- Device receipt
- App route
- Read acknowledgement

---

# 18. Deployment and CI/CD

Create a safe pipeline:

1. Install/build/test
2. Contract tests
3. Migration dry run
4. Security scans
5. Build backend image
6. Deploy staging
7. Run migrations
8. Run Hubtown Sunkist E2E
9. Run smoke/load
10. Manual approval
11. Deploy production
12. Monitor
13. Rollback if thresholds fail

Require:

- Versioned images
- Environment validation
- Secret Manager
- No plaintext secrets
- Health/readiness
- Database readiness
- Feature flags
- Rolling/canary deployment
- Rollback
- Flutter production API configuration
- APK/AAB version matched to backend compatibility

---

# 19. Required reports

Produce:

1. `SERO_RECOVERY_EXECUTIVE_SUMMARY.md`
2. `SERO_RECOVERY_FINDINGS.md`
3. `SERO_212_FEATURE_MATRIX.md`
4. `SERO_SCREEN_ROUTE_API_MATRIX.md`
5. `SERO_CROSS_ROLE_WORKFLOW_REPORT.md`
6. `SERO_NOTIFICATION_DELIVERY_REPORT.md`
7. `SERO_GCP_PRODUCTION_REPORT.md`
8. `SERO_CRASH_BLANK_SCREEN_REPORT.md`
9. `SERO_RAZORPAY_TEST_REPORT.md`
10. `SERO_DATABASE_MIGRATION_REPORT.md`
11. `SERO_REALTIME_REPORT.md`
12. `SERO_LIVE_DATA_REPORT.md`
13. `SERO_PERFORMANCE_REPORT.md`
14. `SERO_SECURITY_REPORT.md`
15. `SERO_PHYSICAL_DEVICE_REPORT.md`
16. `SERO_FINAL_RELEASE_GATE.md`
17. `sero_recovery_findings.json`
18. `sero_feature_traceability.json`
19. `sero_endpoint_results.json`
20. `sero_notification_results.json`

---

# 20. Finding format

Every finding must include:

- ID
- Severity P0/P1/P2/P3
- Role
- Module
- Screen
- Route
- Endpoint
- File/line
- GCP/local environment
- Reproduction
- Expected
- Actual
- Root cause
- Fix
- Regression test
- Evidence
- Status

---

# 21. Automatic release failure

Release fails if:

- Any unresolved P0/P1
- Resident section still crashes or shows blank pages
- Any role cannot log in
- Wrong shell opens
- Any major feature is UI-only
- Any documented feature lacks backend/API
- Any Admin action fails to update eligible Resident/Staff views
- Staff action fails to notify eligible Resident/Admin
- Notice/bill/parking/poll/event does not propagate
- Notifications fail on physical device
- Payment is locally simulated
- Payment webhook is not authoritative
- Cross-society data leaks
- Production mock/static data remains
- Missing GCP migrations
- GCP config differs silently from tested environment
- Any core endpoint returns unhandled 500
- Any page can remain on infinite loader
- Data integrity invariant fails
- Backup/restore fails
- Scale is claimed without evidence

---

# 22. Final acceptance criteria

Complete only when:

- All 212 features are mapped
- Every implemented feature is backed by live API/database
- Missing features are implemented or explicitly blocked with evidence
- Cross-role workflows pass
- Hubtown Sunkist A-1402 journeys pass
- Resident UI remains visually distinct but uses shared canonical data
- Admin, Staff, Resident, and Super Admin remain synchronized
- Notice, bill, parking, poll, event, complaint, visitor, parcel, amenity, and SOS notifications work
- Razorpay Test Mode payment passes
- No blank page
- No infinite loader
- No production mock data
- GCP staging and production smoke tests pass
- Physical Android notification tests pass
- Flutter analyze/tests pass
- Backend tests/migrations pass
- Security and tenant isolation pass
- Data integrity passes
- Performance targets pass
- Final evidence is complete

---

# 23. Start instruction

Begin in this exact order:

1. Check out the latest `master` branch.
2. Record commit SHA.
3. Read existing audit/release/blocker reports, but do not trust their verdicts.
4. Run clean backend and Flutter builds/tests.
5. Inspect actual GCP deployment and logs.
6. Build complete screen-route-endpoint matrix.
7. Reproduce Resident crashes and blank pages.
8. Reproduce notification failures.
9. Create Hubtown Sunkist staging seed.
10. Execute the first cross-role notice workflow.
11. Fix canonical backend and notification infrastructure before polishing UI.
12. Continue feature by feature until the release gate passes.

Do not start by adding more static demo screens. Do not write another high-level report without implementing and executing the fixes.
