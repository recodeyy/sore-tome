# SERO 10,000–20,000 User Performance and Load-Test Complete Prompt Pack

This pack contains:

1. Frontend/mobile/web performance and resilience prompt
2. Backend/infrastructure/load/capacity prompt

Use both prompts against the same production-like environment and test dataset. The frontend prompt proves actual device and browser usability while the backend prompt proves API, database, Redis, queue, realtime, payment, AI, storage, and autoscaling capacity.

---

# SERO Frontend Performance and Load-Test Master Prompt — 10,000 to 20,000 Users

## Role

Act as a **Principal Flutter Performance Engineer, Mobile/Web Performance Architect, Frontend SRE, Quality Architect, Accessibility Specialist, and Release Manager**.

You are auditing and hardening the complete SERO frontend for production-scale usage across:

- Super Admin
- Society Admin and Committee
- Staff and Security
- Member / Resident
- SERO AI Copilot
- Shared cross-role modules
- Mobile, tablet, and web

The full platform must remain responsive and usable while the backend serves **10,000–20,000 concurrently active authenticated users**.

This prompt focuses on the frontend and client experience. It must be executed together with the SERO backend 10,000–20,000-user load-test prompt.

Do not claim frontend readiness only because APIs survive load. Prove that actual Flutter clients remain responsive, memory-stable, visually correct, and recoverable under latency, errors, realtime storms, and sustained use.

---

# 1. Objectives

Prove that:

1. Every role can log in and open the correct shell during high traffic.
2. No page freezes, crashes, becomes blank, or shows an infinite loader.
3. Every page remains connected to live APIs.
4. No production screen falls back to mock/static data.
5. Lists, charts, search, filters, pagination, forms, scanners, payments, AI streaming, and realtime updates remain usable.
6. Memory, CPU, battery, network, and storage use stay within reasonable limits.
7. Mobile, tablet, and web behave correctly under backend latency and partial failures.
8. Reconnect logic does not create duplicate requests or subscriptions.
9. Offline/online transitions do not corrupt state.
10. The complete app meets a strict release gate for 10,000–20,000-user backend capacity.

---

# 2. Required frontend deliverables

Create:

1. `FRONTEND_20K_PERFORMANCE_EXECUTIVE_SUMMARY.md`
2. `FRONTEND_20K_DEVICE_MATRIX.md`
3. `FRONTEND_20K_SCREEN_PERFORMANCE_MATRIX.md`
4. `FRONTEND_20K_NETWORK_PROFILE_REPORT.md`
5. `FRONTEND_20K_MEMORY_CPU_BATTERY_REPORT.md`
6. `FRONTEND_20K_REALTIME_STREAMING_REPORT.md`
7. `FRONTEND_20K_UI_FREEZE_AND_STUCK_STATE_REPORT.md`
8. `FRONTEND_20K_WEB_VITALS_REPORT.md`
9. `FRONTEND_20K_ACCESSIBILITY_UNDER_LOAD_REPORT.md`
10. `FRONTEND_20K_REGRESSION_FINDINGS.md`
11. `FRONTEND_20K_RELEASE_GATE.md`
12. `frontend_20k_findings.json`
13. `frontend_20k_metrics.json`

---

# 3. Test applications and roles

Test:

- Super Admin
- Platform Support
- Platform Finance
- Main Admin
- Secretary
- Treasurer
- Committee Member
- Staff
- Guard
- Security Manager
- Facility Manager
- Resident Owner
- Resident Tenant
- Family Member
- AI Copilot user

Use at least:

- Society A
- Society B
- Small society
- Large society
- Different subscription plans
- Different feature flags
- Different data volumes
- Multiple-role users
- Suspended/inactive users
- Users with slow devices and networks

---

# 4. Device matrix

Test real devices where possible and emulators only as supplemental evidence.

## Android

- Low-end Android:
  - 3–4 GB RAM
  - Older mid-range CPU
- Mid-range Android:
  - 6–8 GB RAM
- High-end Android
- Android versions currently supported by the application

## iOS

- Older supported iPhone
- Mid-range/current iPhone
- Large-screen iPhone
- Supported iOS versions

## Tablet

- Android tablet
- iPad
- Landscape and portrait

## Web

- Chrome
- Edge
- Safari
- Firefox where supported
- 1366×768
- 1440×900
- 1920×1080
- Mobile browser width
- Tablet browser width

Record:

- Device
- OS
- App version
- Build mode
- Network
- Battery state
- Test duration
- Memory
- CPU
- FPS/jank
- Crash rate

Use release/profile builds. Do not use debug-mode performance as release evidence.

---

# 5. Build and bundle validation

Verify:

- Flutter release build passes
- Android App Bundle builds
- iOS release/archive builds where environment permits
- Web release build passes
- Tree shaking works
- No debug-only package in release
- No source map or secret leakage
- No embedded API secret
- No Firebase service-account credential
- Correct environment configuration
- Build size tracked
- Asset size tracked
- Font/image duplication removed
- Lazy loading/code splitting used where applicable
- Compression enabled for web assets
- Cache headers correct
- Service worker versioning correct
- Old web build does not corrupt new API contracts

Record build sizes and compare to a baseline.

---

# 6. Screen inventory and performance traceability

Inventory every screen across all shells.

For each screen record:

- Role
- Route
- Source file
- Initial API calls
- Realtime subscriptions
- Number of rendered items
- Pagination type
- Images/files
- Charts
- Expensive widgets
- Build count
- First meaningful render
- Time to interactive
- Memory delta
- Scroll FPS
- Error/offline behavior
- Test status

Flag screens that:

- Rebuild entire trees unnecessarily
- Start duplicate API calls
- Keep subscriptions alive after dispose
- Load all records instead of paginating
- Render large lists without virtualization
- Decode full-resolution images unnecessarily
- Compute large aggregates on the UI thread
- Parse large JSON on the UI isolate
- Leak controllers, streams, timers, or focus nodes
- Use base64 files in memory
- Use mock fallback after timeout

---

# 7. Frontend concurrency model

A single frontend instance does not host 20,000 users. The frontend test must combine:

1. Real device/client profiling
2. Automated end-to-end multi-session testing
3. Backend-generated load
4. Realtime broadcast/reconnect storms
5. Browser concurrency testing
6. Synthetic user journeys
7. Long-duration soak on selected devices

Run at least:

- 100–300 automated browser/mobile sessions where infrastructure permits
- 10,000–20,000 backend virtual users in parallel
- 10,000–20,000 realtime connections from load generators
- Real devices receiving production-like API and event traffic

Do not misrepresent 20,000 backend virtual users as 20,000 physical devices.

---

# 8. Network profiles

Test:

- Wi-Fi
- Fast 5G
- Average 4G
- Slow 4G
- 3G-like throttling
- 500 ms latency
- 2% packet loss
- 5% packet loss
- Intermittent connectivity
- Offline for 30 seconds
- Offline for 5 minutes
- Network change Wi-Fi → mobile
- Network change mobile → Wi-Fi
- Captive portal-like failure
- DNS delay
- TLS handshake delay

For every major page verify:

- Loader appears promptly
- Timeout is bounded
- Retry works
- User can navigate away
- Button state recovers
- No duplicate action
- No false success
- Safe form data is preserved
- Stale data is labeled
- Offline state is clear
- Sync state is visible

---

# 9. Startup and login performance

Measure:

- Cold start
- Warm start
- Time to login screen
- Login submission
- MFA/OTP
- Workspace selection
- Shell initialization
- Dashboard first render
- Realtime connection establishment
- State hydration
- Deep link after cold start
- App resume after long background period

Targets:

- No blank screen
- No unauthorized page flash
- No wrong-role shell
- Login UI responds immediately to tap
- Shell loads progressively
- Heavy dashboard calls do not block navigation
- Session refresh does not cause login loop
- Workspace switch clears prior state quickly

Test login during:

- 10,000-user login ramp
- 20,000-user login ramp
- Identity-provider slowdown
- Redis slowdown
- API replica restart

---

# 10. UI responsiveness targets

Measure on representative low-end and mid-range devices.

Targets:

- No sustained frozen UI
- Tap feedback within 100 ms where practical
- Smooth navigation transition
- 60 FPS target on capable devices
- No repeated frames over 32 ms during normal interaction
- Scrolling remains usable on long lists
- Search input does not lag
- Keyboard does not cause severe jank
- Camera/QR screen remains responsive
- Payment sheet remains responsive
- SOS action remains responsive
- AI streaming does not rebuild the entire chat on every token

Record:

- Average FPS
- Worst-frame duration
- Jank percentage
- Main/UI thread utilization
- Raster thread utilization
- Build/layout/paint hotspots

---

# 11. Memory and resource tests

Test each application for:

- 30-minute normal-use session
- 2-hour heavy-use session
- 4-hour staff/guard shift simulation
- Repeated navigation through 100+ screens
- Repeated login/logout
- Repeated workspace switching
- Repeated AI conversations
- Image upload loops
- PDF viewing loops
- Realtime reconnect loops
- App background/resume cycles

Detect:

- Memory leaks
- Stream leaks
- Timer leaks
- Image cache growth
- Large retained route trees
- Stale provider state
- WebSocket/SSE duplication
- File buffer retention
- Growing local database/cache
- Unbounded chat history in memory

Define per-device memory budgets and justify them.

---

# 12. List, search, filter, and pagination testing

Test large datasets:

- 10,000 residents
- 50,000 notices/activity items
- 100,000 visitor records
- 100,000 payments
- 50,000 complaints
- 20,000 staff/attendance rows
- Large audit logs
- Large marketplace/community feeds

Verify:

- Cursor pagination
- Infinite scroll
- Pull to refresh
- Search debounce
- Filter/sort
- Back-navigation state
- No duplicate items
- No missing items
- No full-dataset client load
- No client-side authoritative aggregation
- Empty result
- Deleted item
- Updated item
- Realtime insertion

Use virtualized lists and bounded page sizes.

---

# 13. Forms and action testing under load

For every major action:

- Tap once
- Double tap
- Rapid tap
- Navigate away mid-request
- Background app mid-request
- Timeout
- 409 conflict
- 422 validation
- 429 rate limit
- 500 error
- Retry
- Success
- Duplicate response
- Out-of-order response

Actions include:

- Login
- Bill payment
- Auto-pay setup
- Visitor approval
- QR/OTP validation
- Complaint creation/update
- Parcel handover
- Attendance check-in
- Amenity booking
- Poll vote
- SOS
- NOC request
- KYC upload
- AI action confirmation
- Super Admin feature rollout

Verify:

- Button disables safely
- Progress is visible
- User can cancel when appropriate
- No duplicate business effect
- Correct success state
- Correct server response is shown
- Error includes request/reference ID where useful

---

# 14. Realtime and push performance

Test:

- 10,000 realtime connections
- 20,000 realtime connections
- Reconnect storm
- Broadcast notice
- Visitor approval/entry
- Complaint status
- Parcel notification
- Payment status
- Staff assignment
- SOS
- Event capacity
- Poll result publication
- AI action execution

Frontend checks:

- One active connection per intended context
- No duplicate subscriptions
- Reconnect backoff
- Last event ID
- Deduplication
- Out-of-order handling
- App background/resume
- Logout disconnect
- Workspace switch disconnect/reconnect
- Permission revocation
- Battery impact
- Network impact

Push:

- Correct deep link
- No duplicate notification
- Lock-screen redaction
- Foreground/background
- Burst handling
- Notification badge accuracy

---

# 15. AI Copilot frontend performance

Test:

- 100 simultaneous AI streams
- 300 active chat sessions
- Long conversation
- 100+ messages
- Citation cards
- Attachments
- Multiple tool proposals
- Stop generation
- Regenerate
- Reconnect
- Provider slowdown
- Provider timeout
- Rate limit
- Offline
- App background/resume

Verify:

- Incremental rendering
- Bounded message list rendering
- No full-chat rebuild per token
- Stream cancellation works
- Memory remains bounded
- Sources/citations load lazily
- Attachments do not use large base64 memory
- Tool confirmation stays responsive
- No duplicate message after reconnect

---

# 16. Image, PDF, and file performance

Test:

- Profile image
- KYC image/PDF
- Complaint evidence
- Marketplace images
- Parcel/visitor image
- NOC PDF
- Receipt PDF
- Rules/bylaws PDF

Verify:

- Thumbnailing
- Lazy image load
- Compression
- Cache limits
- Upload progress
- Cancel
- Retry
- Resumable behavior if implemented
- Memory-safe decode
- No full-resolution decode when thumbnail is enough
- No public URL exposure
- PDF viewer performance
- Large file failure state

---

# 17. Web performance

Measure:

- Largest Contentful Paint
- Interaction to Next Paint
- Cumulative Layout Shift
- First Contentful Paint
- Total Blocking Time
- JavaScript bundle size
- Asset transfer size
- Cache behavior
- Service worker update
- Realtime connection stability
- Memory during long tab sessions

Suggested targets:

- LCP under 2.5 seconds on representative broadband
- INP under 200 ms for common interactions
- CLS under 0.1
- No blocking startup bundle growth without justification

Test:

- Hard refresh
- Cached refresh
- New deployment
- Old service worker
- Multiple open tabs
- Token refresh across tabs
- Logout in one tab
- Workspace switch in one tab
- Browser back/forward
- Deep links

---

# 18. Accessibility under performance stress

Verify:

- Screen reader remains usable during loading and streaming
- Focus does not jump during realtime inserts
- AI token streaming does not overwhelm announcements
- Large lists expose semantic labels efficiently
- Dialog focus trap remains correct
- Error messages are announced
- Payment/SOS status is announced
- Text scaling does not trigger excessive rebuild loops
- Keyboard navigation remains responsive
- Reduced motion is respected

---

# 19. Frontend failure injection

Inject:

- 1-second API delay
- 5-second API delay
- 30-second timeout
- Random 500s
- Random 429s
- Realtime disconnect
- FCM delay
- Object-storage timeout
- AI stream interruption
- Payment callback interruption
- Malformed JSON
- Missing nullable fields
- New unknown enum
- Clock skew
- Old app against new backend
- New app against previous backend during rolling deployment

Verify:

- Safe fallback
- Version compatibility
- No crash
- No infinite spinner
- No corrupted local state
- No false success
- Upgrade-required flow where necessary

---

# 20. Automated frontend journeys

Automate:

1. Login and dashboard by every role
2. Resident bill payment
3. Resident visitor approval → Staff entry
4. Resident complaint → Admin assignment → Staff completion
5. Staff parcel handover
6. Staff attendance
7. Resident amenity booking
8. Resident poll vote
9. SOS lifecycle
10. AI rule answer and complaint proposal
11. Super Admin society approval
12. Super Admin feature rollout
13. Workspace switching
14. Logout/session expiry
15. Offline draft and sync

Run with backend under:

- 3,000 users
- 10,000 users
- 20,000 users
- Failure injection

---

# 21. Frontend release gates

Automatic FAIL:

- Any role cannot log in
- Wrong shell opens
- Any major route is disconnected
- Any production screen uses mock/static data
- Infinite loader
- Repeated crash
- Memory leak causing degradation
- Duplicate action from client retry
- Realtime duplicate storm
- AI chat becomes unusable
- Payment UI shows false success
- SOS UI shows false success
- Wrong society/unit data remains after workspace switch
- Accessibility-critical flow becomes unusable
- Web vital thresholds are severely missed without remediation
- Low-end supported device cannot complete core journeys

---

# 22. Final frontend report

End with:

## A. Verdict

- PASS
- PASS WITH P2/P3 EXCEPTIONS
- FAIL

## B. Tested matrix

- Devices
- OS
- Browsers
- App builds
- Network profiles
- Test durations

## C. Performance

- Startup
- Login
- Navigation
- FPS/jank
- Memory
- CPU
- Battery
- Network
- Web vitals

## D. Reliability

- Stuck states
- Retry
- Offline
- Realtime
- Push
- AI stream
- File upload

## E. Role verdicts

- Super Admin
- Admin
- Staff/Guard
- Resident
- AI Copilot

## F. Exact blocking fixes

List:

- File
- Route
- Widget/provider/service
- Reproduction
- Fix
- Regression test
- Owner

Do not state frontend production readiness without executed device and browser evidence.


---

# SERO Backend and Infrastructure Load-Test Master Prompt — 10,000 to 20,000 Concurrent Users

## Role

Act as a **Principal Performance Architect, Backend SRE, Database Reliability Engineer, Distributed Systems Engineer, Security Engineer, Payments Reliability Engineer, AI Platform Engineer, and Capacity Planning Lead**.

You are auditing and hardening the complete SERO backend and infrastructure for production-scale operation across:

- Super Admin
- Society Admin
- Staff and Security
- Member / Resident
- AI Copilot
- Shared cross-role modules
- PostgreSQL
- Redis
- BullMQ
- Firebase Auth/FCM
- Object storage
- Razorpay/payment provider
- Realtime gateway
- AI providers/vector store
- Docker/Kubernetes/cloud deployment

The platform must support **10,000–20,000 concurrently active authenticated users**, not merely 20,000 registered accounts.

Do not claim capacity from a small script multiplied on paper. Execute production-like tests, measure bottlenecks, validate horizontal scaling, prove data integrity, and document the tested limit.

---

# 1. Define the capacity model first

Before load testing, define:

- Concurrent authenticated users
- Concurrent active users
- Requests per second
- Realtime connections
- AI streams
- Payment callbacks
- Upload throughput
- Background job volume
- Peak society size
- Number of societies
- Data volumes
- Read/write ratio
- Geographic latency
- Test duration

Use at minimum:

## Target A

- 10,000 concurrent authenticated users
- 5,000 concurrently active users
- 10,000 realtime connections
- 600 sustained mixed RPS
- 1,000 RPS burst
- 100 simultaneous AI streams

## Target B

- 20,000 concurrent authenticated users
- 10,000 concurrently active users
- 20,000 realtime connections
- 1,000 sustained mixed RPS
- 1,500 RPS burst
- 200 simultaneous AI streams

Adjust only with written architectural justification and evidence.

---

# 2. Required backend deliverables

Create:

1. `BACKEND_20K_EXECUTIVE_SUMMARY.md`
2. `BACKEND_20K_ARCHITECTURE_REVIEW.md`
3. `BACKEND_20K_WORKLOAD_MODEL.md`
4. `BACKEND_20K_TEST_DATA_MODEL.md`
5. `BACKEND_20K_ENDPOINT_RESULTS.md`
6. `BACKEND_20K_DATABASE_REPORT.md`
7. `BACKEND_20K_REDIS_QUEUE_REPORT.md`
8. `BACKEND_20K_REALTIME_REPORT.md`
9. `BACKEND_20K_PAYMENT_REPORT.md`
10. `BACKEND_20K_AI_REPORT.md`
11. `BACKEND_20K_FILE_UPLOAD_REPORT.md`
12. `BACKEND_20K_AUTOSCALING_REPORT.md`
13. `BACKEND_20K_FAILURE_INJECTION_REPORT.md`
14. `BACKEND_20K_COST_AND_CAPACITY_REPORT.md`
15. `BACKEND_20K_SECURITY_UNDER_LOAD_REPORT.md`
16. `BACKEND_20K_RELEASE_GATE.md`
17. `backend_20k_results.json`
18. `backend_20k_findings.json`
19. Reproducible k6/Locust/Gatling scripts
20. Infrastructure dashboards and query snapshots

---

# 3. Environment requirements

Use a production-like isolated environment.

Match production for:

- API runtime
- Instance/container size
- Replica count
- PostgreSQL version
- PostgreSQL instance class
- Connection pooler
- Redis version/topology
- Queue workers
- Realtime gateway
- Object storage
- CDN
- Authentication provider
- AI provider configuration
- Network policies
- TLS
- Observability
- Autoscaling

Do not use:

- Developer laptop as final evidence
- In-memory database
- In-memory Redis replacement
- Mock queue
- Disabled RLS
- Disabled audit
- Fake payment success
- Mock AI for final provider-latency evidence

You may use provider stubs for deterministic stress isolation, but separately run real provider tests at safe approved scale.

---

# 4. Clean build and baseline

Before load:

- Clean install
- TypeScript strict build
- Lint
- Unit tests
- Integration tests
- Contract tests
- Security tests
- Fresh migration
- Upgrade migration
- Seed
- Docker image
- Health/readiness
- Worker startup
- OpenAPI validation
- No open handles
- No unhandled rejections
- No forced dependency installation
- No skipped critical tests

Establish baseline at:

- 1 user
- 50 users
- 500 users

Fix correctness defects before scale tests.

---

# 5. Test data scale

Create realistic data:

- 100–500 societies
- At least one large society with:
  - 10,000+ residents
  - 2,000+ staff/linked workers if product model permits
  - Large visitor history
  - Large payment history
- 100,000+ users
- 1,000,000+ visitor/access events
- 1,000,000+ payment/ledger-related rows
- 500,000+ complaint/activity rows
- 500,000+ notifications
- 100,000+ amenity bookings
- 100,000+ poll votes
- Large audit/access logs
- Large AI conversation/message set
- Large document/vector index

Data must preserve realistic distribution, tenant boundaries, statuses, and timestamps.

---

# 6. Workload mix

Use a realistic mixed workload.

Suggested baseline:

- 18% dashboard/summary reads
- 12% notices/events/rules/documents
- 12% complaints/tasks
- 10% visitors/parcels/security
- 10% bills/payments/receipts
- 6% staff/attendance/leave
- 6% amenities/bookings
- 5% community/marketplace/carpool/lost-found
- 4% polls/governance
- 4% Super Admin/platform operations
- 4% reports/search/exports
- 5% AI chat/RAG
- 4% miscellaneous profile/KYC/NOC

Separate:

- Read-heavy
- Write-heavy
- Realtime-heavy
- Payment-heavy
- AI-heavy
- Upload-heavy
- Login-heavy

Do not use one endpoint as a proxy for the whole platform.

---

# 7. Authentication and session load

Test:

- 10,000-user login ramp
- 20,000-user login ramp
- 500 login attempts/second burst
- MFA/OTP
- Refresh-token spike
- Session validation
- Workspace selection
- Workspace switching
- Logout
- Logout-all
- Token revocation
- Role/society change
- Suspended society
- Staff termination
- Resident move-out

Verify:

- Distributed rate limiting
- No NAT-wide false blocking
- No session duplication
- Refresh rotation
- No role leakage
- No cache leakage
- Auth provider slowdown handling
- DB/Redis capacity

Targets excluding external identity-provider latency:

- Session validation p95 < 200 ms
- Refresh p95 < 300 ms
- Workspace selection p95 < 300 ms
- Internal login processing p95 < 1 second

---

# 8. Endpoint load coverage

Test every endpoint family:

- Auth
- Super Admin
- Admin
- Resident
- Staff
- AI
- Payments
- Files
- Notifications
- Realtime
- Reports
- Health/operations

For every critical endpoint record:

- RPS
- p50
- p90
- p95
- p99
- Error rate
- Timeout rate
- CPU
- Memory
- DB time
- Redis time
- Queue time
- Response size
- Cache hit
- Slow query
- Lock wait

Critical endpoint examples:

- Login/session
- Dashboards
- Resident bills
- Payment intent
- Payment webhook
- Visitor expected/search
- Visitor QR/OTP
- Visitor entry/exit
- Complaint create/list/status
- Staff attendance
- Amenity availability/booking
- Poll vote
- SOS trigger/acknowledge
- AI conversation/stream
- Super Admin analytics
- Report generation

---

# 9. Database performance

Inspect:

- Connection pool size
- PgBouncer or equivalent
- Pool exhaustion
- Long transactions
- Lock waits
- Deadlocks
- Slow queries
- Sequential scans
- Missing indexes
- N+1 queries
- Query plan instability
- Autovacuum
- Table/index bloat
- Replication lag
- WAL growth
- CPU
- IOPS
- Buffer cache
- Temp files
- Materialized-view refresh
- Partition pruning
- RLS overhead

Test:

- Read replica use where appropriate
- Failover
- Connection loss
- Replica lag
- Backup during load
- Restore validation
- Schema migration under controlled load
- Hot rows:
  - Amenity slot
  - Poll
  - Payment allocation
  - Attendance
  - Visitor pass
  - Notification counters

No correctness compromise is allowed for performance.

---

# 10. Redis and distributed coordination

Test:

- Cache
- Rate limits
- Sessions
- Distributed locks
- Pub/sub
- Queue backend
- Realtime coordination
- Idempotency helpers

Measure:

- Ops/sec
- p95/p99 latency
- Memory
- Evictions
- Hit rate
- Connection count
- Key growth
- Hot keys
- Failover
- Persistence impact

Verify key namespace includes tenant/context where required.

Test Redis:

- Restart
- Failover
- Network partition
- Memory pressure
- Eviction
- Slow command
- Cluster reshard if applicable

The system must fail safely without cross-tenant cache leakage.

---

# 11. BullMQ/background job load

Test workers for:

- Notifications
- Reports
- Bill generation
- Payment reconciliation
- Visitor overstay
- Parcel reminders
- Complaint SLA
- Staff roster/attendance
- Document scanning/parsing
- AI embeddings/evaluation
- NOC generation
- Exports
- Analytics aggregation
- Audit archival

Measure:

- Enqueue rate
- Processing rate
- Queue depth
- Oldest job age
- Success/failure
- Retry
- Dead letter
- CPU/memory
- External-provider quota
- Recovery after worker restart

Test:

- Duplicate job
- Worker crash mid-job
- Redis restart
- API crash after enqueue
- Idempotency
- Poison job
- Backpressure
- Priority starvation

Queues must drain after recovery without duplicate business effects.

---

# 12. Realtime capacity

Test:

- 10,000 connections
- 20,000 connections
- Connection ramp
- Reconnect storm
- Broadcast
- Tenant-scoped event
- User-scoped event
- High-frequency complaint/payment/visitor updates
- SOS event
- AI execution status
- Permission revocation
- Logout
- Workspace switch

Measure:

- Connections per instance
- CPU/memory
- Event delivery latency
- Dropped events
- Duplicate events
- Reconnect time
- Backpressure
- Bandwidth
- Redis/pubsub pressure

Targets:

- Tenant/user events delivered within acceptable p95
- SOS internal dispatch < 1 second
- No cross-tenant room leak
- No connection leak
- Graceful rolling restart

---

# 13. Payments and finance load

Test:

- Bill publication
- Due-date spike
- Payment intent creation
- Payment-provider callback burst
- Duplicate webhooks
- Out-of-order webhooks
- Partial payment
- Combined payment
- Refund
- Dispute
- Reconciliation
- Auto-pay debit batch
- Receipt generation
- Ledger posting

Simulate:

- 1,000 payment intents/minute
- 1,000 webhook deliveries/minute with duplicates
- Auto-pay batch load
- Reconciliation batch

Verify:

- Raw-body signature verification
- Event persistence before processing
- Idempotency
- Exactly-once financial effect
- Debit/credit balance
- No lock hotspot causing failure
- No receipt duplication
- Dashboard aggregate consistency
- Queue recovery
- Provider timeout behavior

Financial correctness outranks throughput.

---

# 14. Visitor, parcel, SOS, and attendance spikes

## Visitor

- 300–500 QR scans/minute
- OTP validation spike
- Gate entry/exit concurrency
- Multiple gates
- Duplicate/replay attempts

## Parcel

- Delivery peak
- 300 parcel intakes/minute
- 200 concurrent handovers

## SOS

- Multiple simultaneous alerts
- Broadcast to eligible responders
- Acknowledgement race
- Escalation

## Attendance

- 5,000 check-ins over a short shift-change window
- Duplicate device submissions
- Offline-sync replay

Verify no duplicate effect and acceptable latency.

---

# 15. Amenity, poll, and concurrency hotspots

Test:

- 1,000 users requesting final amenity slots
- 5,000 users voting in a short window
- Event final-seat race
- Marketplace/community posting burst
- NOC request spike

Verify database constraints and locks prevent:

- Double booking
- Duplicate vote
- Over-capacity RSVP
- Duplicate NOC
- Lost update

Measure lock waits and retry behavior.

---

# 16. AI platform load

Test:

- 300 active chat sessions
- 100 simultaneous streams at Target A
- 200 simultaneous streams at Target B
- RAG queries
- Citation retrieval
- Attachments
- Tool proposals
- Tool confirmations
- Provider fallback
- Cost limits
- Semantic cache
- Vector store

Measure:

- Time to first token
- Completion latency
- Provider latency
- Retrieval latency
- Vector query latency
- Cache hit
- Token usage
- Cost
- Stream disconnect
- Queue depth
- Memory

Targets:

- Cached answer p95 < 1 second
- TTFT p95 < 2.5 seconds excluding provider degradation
- Standard RAG p95 < 8 seconds excluding provider degradation
- No cross-tenant retrieval
- No tool duplicate execution

Use provider quotas safely and coordinate with vendor limits.

---

# 17. File/object-storage load

Test:

- KYC uploads
- Complaint evidence
- Marketplace images
- Parcel/visitor images
- Receipts
- NOCs
- Rules PDFs
- AI documents

Scenarios:

- 500 concurrent upload intents
- 100–300 active uploads
- Large-download burst
- Signed URL generation
- Malware scan backlog
- Parser/OCR backlog
- Object-storage slowdown
- CDN cache

Measure:

- Upload throughput
- Failure/retry
- Scan queue age
- Processing time
- Storage errors
- API memory
- Egress

Ensure API servers do not buffer large files unnecessarily.

---

# 18. Reports, analytics, and exports

Test:

- Super Admin dashboard
- Admin dashboard
- Revenue analytics
- DAU/MAU
- Churn
- Dues/defaulters
- Complaint SLA
- Staff attendance
- Visitor reports
- Audit log search
- Large CSV/PDF export

Requirements:

- Pre-aggregates/materialized views
- Background export jobs
- Cursor pagination
- Object-storage download
- No request-thread generation of huge report
- No raw-table full scan per dashboard request

Test concurrent reports and exports without harming transactional APIs.

---

# 19. Autoscaling and capacity

Prove:

- API horizontal scaling
- Worker scaling by queue depth
- Realtime scaling
- Database connection pool remains safe
- Redis connection count remains safe
- Scale-up time
- Scale-down safety
- Rolling deployment
- Pod/instance termination
- Readiness/draining
- No dropped in-flight financial write
- No reconnect storm amplification

Document:

- Minimum replicas
- Maximum replicas
- CPU/memory thresholds
- Queue thresholds
- Connection budgets
- Scale lag
- Warm-up strategy
- Cost per 1,000 active users
- Cost at 10,000
- Cost at 20,000
- Estimated headroom

---

# 20. Test stages

Run:

## Stage 0 — Correctness

- 1–50 users

## Stage 1 — Baseline

- 500 users
- 100 RPS

## Stage 2 — Medium

- 3,000 users
- 250–400 RPS

## Stage 3 — Target A

- 10,000 authenticated
- 5,000 active
- 600 sustained RPS
- 1,000 burst RPS
- 10,000 realtime
- 100 AI streams
- Sustain 30 minutes

## Stage 4 — Target B

- 20,000 authenticated
- 10,000 active
- 1,000 sustained RPS
- 1,500 burst RPS
- 20,000 realtime
- 200 AI streams
- Sustain 30 minutes

## Stage 5 — Soak

- 10,000–20,000 concurrency
- 4–8 hours

## Stage 6 — Stress

- Increase until failure
- Record maximum safe capacity
- Stop before permanent damage

## Stage 7 — Recovery

- Return to normal
- Verify queues, pools, caches, metrics, and data integrity recover

---

# 21. Service-level targets

Suggested release targets:

- Standard read p95 < 400 ms
- Standard write p95 < 700 ms
- p99 < 1.5 seconds for standard APIs
- Error rate < 1%
- Login internal p95 < 1 second
- Session p95 < 200 ms
- QR/OTP p95 < 500 ms
- Visitor entry p95 < 500 ms
- Attendance p95 < 500 ms
- Booking/vote p95 < 700 ms
- Payment webhook internal p95 < 1 second
- SOS dispatch internal < 1 second
- Warm global dashboard p95 < 700 ms
- Queue backlog returns to normal after spike
- No memory leak
- No connection-pool exhaustion
- No cross-tenant response
- No duplicate business effect

Set module-specific SLOs and justify deviations.

---

# 22. Security under load

Test:

- Rate-limit bypass
- Credential stuffing
- OTP abuse
- QR replay
- IDOR/BOLA at scale
- Cross-tenant cache poisoning
- JWT/session replay
- Webhook replay
- File upload abuse
- AI denial-of-wallet
- Expensive search/report abuse
- Large payload abuse
- Pagination abuse
- Realtime subscription abuse
- Connection exhaustion
- Queue flooding

Verify:

- Distributed limits
- Per-user/society/IP/device controls
- Shared-NAT fairness
- Abuse alerts
- No security middleware bypass when autoscaled
- Logs remain complete
- Audit remains append-only

---

# 23. Failure injection

Inject during Target A and selected Target B tests:

- Kill one API replica
- Kill multiple API replicas within safe limits
- Restart Redis
- Redis failover
- Kill workers
- PostgreSQL connection interruption
- Read replica lag
- Object-storage slowdown
- FCM/email/SMS failure
- Payment-provider timeout
- AI-provider timeout/rate limit
- Vector-store slowdown
- DNS delay
- Network packet loss
- Clock skew
- Deployment rollout
- One bad queue job
- Slow database query

Verify:

- Circuit breakers
- Timeouts
- Retry with jitter
- Idempotency
- Dead letters
- Graceful degradation
- Correct user status
- Alerting
- Recovery
- No data corruption
- No false success

---

# 24. Data integrity validation after every major test

Run automated invariants:

- No cross-tenant row leak
- Debits equal credits
- No duplicate payment allocation
- No duplicate receipt
- No duplicate visitor active entry
- No duplicate parcel handover
- No duplicate attendance session
- No duplicate vote
- No double booking
- No duplicate AI tool execution
- No orphan files
- No missing audit for sensitive action
- No stuck job beyond threshold
- No unbounded retry
- No corrupted status transition
- Dashboard aggregates match source

Do not accept performance success with data corruption.

---

# 25. Observability

Collect:

- API metrics
- Distributed traces
- Structured logs
- Database metrics
- Redis metrics
- Queue metrics
- Realtime metrics
- Payment metrics
- AI metrics
- Object-storage metrics
- Kubernetes/cloud metrics
- Cost metrics

Dashboards must show:

- RPS
- Latency
- Errors
- Saturation
- Pool utilization
- Slow queries
- Locks
- Queue depth
- Oldest job
- Realtime connections
- Event delivery latency
- Payment failures
- AI cost/latency
- Upload backlog
- Autoscaling events

Every failure injection must generate an actionable alert.

---

# 26. Load tooling

Use:

- k6 for HTTP/WebSocket/SSE
- Locust or Gatling if helpful
- Playwright for selected browser journeys
- Flutter integration tests for real client journeys
- Database monitoring tools
- Cloud-native metrics
- Packet/network shaping where safe

Requirements:

- Version-controlled scripts
- Parameterized environments
- No hard-coded secrets
- Reproducible seed
- Correlation IDs
- Threshold assertions
- HTML/JSON result export
- Separate smoke/load/stress/soak profiles

---

# 27. Example k6 scenario structure

Implement scenarios such as:

- `auth_ramp`
- `resident_browse`
- `resident_payment`
- `resident_visitor`
- `resident_complaint`
- `resident_amenity`
- `admin_operations`
- `staff_gate`
- `staff_attendance`
- `super_admin_dashboard`
- `realtime_connections`
- `ai_streams`
- `payment_webhooks`
- `file_uploads`
- `report_exports`

Use weighted scenarios and realistic think time.

Do not submit one continuous loop with no user behavior.

---

# 28. Cost and capacity report

Calculate:

- Infrastructure cost at idle
- Cost at 3,000
- Cost at 10,000
- Cost at 20,000
- Cost per 1,000 active users
- AI cost per active chat user
- Notification cost
- Storage/egress cost
- Database scaling cost
- Redis cost
- Realtime cost

Provide:

- Current safe capacity
- Target capacity
- Bottleneck
- Next scaling step
- Estimated headroom
- Cost optimization that does not weaken correctness/security

---

# 29. Backend release gates

Automatic FAIL:

- Target A not met
- Target B claimed without evidence
- Error rate > 1% for sustained target without accepted exception
- p95/p99 severely miss SLO
- Pool exhaustion
- Memory leak
- Queue never recovers
- Realtime connection leak
- Cross-tenant response
- Duplicate payment/visitor/parcel/attendance/vote/booking effect
- AI tool duplicate
- Security control fails under load
- Backup/restore fails after test
- Autoscaling causes outage
- No capacity headroom
- No reproducible scripts/results

If Target B cannot pass, report the exact verified safe capacity and blocking remediation. Do not hide the limit.

---

# 30. Final backend report

End with:

## A. Verdict

- PASS
- PASS WITH P2/P3 EXCEPTIONS
- FAIL

## B. Tested capacity

- Authenticated users
- Active users
- RPS
- Realtime connections
- AI streams
- Test duration

## C. Results

- p50/p90/p95/p99
- Errors
- CPU/memory
- DB
- Redis
- Queues
- Realtime
- Payments
- AI
- Files

## D. Integrity

- Financial
- Cross-tenant
- Duplicate prevention
- State machines
- Audit

## E. Reliability

- Autoscaling
- Failover
- Recovery
- Soak
- Backup/restore

## F. Capacity statement

State:

- Maximum tested safe capacity
- Recommended production operating capacity
- Headroom
- Required minimum infrastructure
- Cost estimate

## G. Blocking fixes

List exact:

- Service
- Endpoint
- Query
- Index
- Pool
- Worker
- Infrastructure setting
- Test
- Owner

Do not state backend production readiness without reproducible 10,000–20,000-user evidence.

