# SERO Complete Live-Data Migration and Zero-Mock Enforcement Master Prompt

## Role

Act as a **Principal Full-Stack Architect, Staff Flutter Engineer, Staff Backend Engineer, Database Architect, Realtime Systems Engineer, QA Lead, and Release Manager**.

You are working inside the complete **SERO — AI Powered Society Management Platform** repository.

Your task is to ensure that **every feature in every application is fully connected to live backend data** and that **no production-visible mock, dummy, sample, placeholder, hard-coded, randomly generated, or simulated operational data remains anywhere in the platform**.

This applies to:

- Super Admin
- Society Admin and Committee
- Staff and Security
- Member / Resident
- SERO AI Copilot
- Shared cross-role modules
- Mobile, tablet, and web
- Dashboards, lists, forms, charts, files, notifications, realtime events, and reports

Do not merely remove the word `mock`. Replace every fake source with a real authenticated, authorized, tenant-scoped data path.

---

# 1. Non-negotiable rules

1. Every visible operational value must come from:
   - A real API
   - A real database query
   - A real aggregate/materialized view
   - A real realtime event
   - A documented computed state derived from live backend data

2. Production screens must not use:
   - Mock repositories
   - Dummy JSON
   - Sample arrays
   - Placeholder names
   - Random counters
   - Hard-coded chart data
   - Fake notifications
   - Simulated payment success
   - Simulated visitor entry
   - Simulated complaints
   - Static dashboard totals
   - Local-only operational records
   - Silent fallback data
   - `Future.delayed` as an API replacement
   - Development Firestore collections in production

3. Legitimate static content is allowed only for:
   - Labels
   - Design tokens
   - Icons
   - Fixed enum definitions
   - Empty-state copy
   - Legal copy
   - Explicit configuration constants

4. The frontend must never calculate authoritative totals from:
   - A paginated list
   - A truncated response
   - Cached incomplete data
   - Locally generated demo values

5. The backend is authoritative for:
   - Money
   - Bills
   - Payments
   - Ledger
   - Voting eligibility
   - Amenity availability
   - Visitor authorization
   - Attendance
   - Role permissions
   - AI tool execution
   - KYC status
   - NOC status
   - SOS status
   - Subscription state
   - Analytics totals

---

# 2. Required audit outputs

Before changing production code, create:

1. `LIVE_DATA_REPOSITORY_AUDIT.md`
2. `LIVE_DATA_SCREEN_INVENTORY.md`
3. `LIVE_DATA_COMPONENT_INVENTORY.md`
4. `LIVE_DATA_API_INVENTORY.md`
5. `LIVE_DATA_MOCK_STATIC_FINDINGS.md`
6. `LIVE_DATA_SOURCE_OF_TRUTH_MAP.md`
7. `LIVE_DATA_MIGRATION_PLAN.md`
8. `LIVE_DATA_BLOCKERS.md`
9. `live_data_findings.json`
10. `live_data_traceability.json`

For every visible element record:

- Application
- Role
- Screen
- Route
- Component
- Element name
- Current value source
- Current provider/controller
- Expected live source
- API endpoint
- Database table/view
- Realtime event
- Permission
- Tenant scope
- Loading state
- Empty state
- Error state
- Offline state
- Test
- Status

---

# 3. Mandatory codebase search

Search the entire repository for:

- `mock`
- `dummy`
- `sample`
- `placeholder`
- `fake`
- `demo`
- `hardcoded`
- `random`
- `TODO`
- `FIXME`
- `coming soon`
- `not implemented`
- `Future.delayed`
- Local static arrays
- Static chart series
- Fixed dashboard counters
- Hard-coded names, dates, amounts, IDs, addresses, society names
- Stub services
- Empty API methods
- Test credentials
- Localhost URLs
- Direct Firestore reads/writes from privileged screens
- Silent catch blocks returning sample data
- Fallback repositories
- Environment flags that enable production demo mode

For every result:

- Record file and line
- Determine whether it is production-visible
- Identify the correct live replacement
- Add a migration task
- Add a regression test
- Do not delete the finding from the report after fixing it; mark it verified

---

# 4. Source-of-truth architecture

Use PostgreSQL as the canonical source of truth for operational and financial data.

Use Redis for:

- Cache
- Distributed locks
- Rate limits
- Session coordination
- Queue coordination
- Realtime coordination

Use Firebase only for approved capabilities such as:

- Authentication
- FCM notifications
- Explicit read projections where designed

Do not maintain conflicting production writes across PostgreSQL and Firestore.

For every domain define one canonical domain service:

- Society
- Users and memberships
- Bills/payments/ledger
- Visitors
- Parcels
- Complaints/work orders
- Staff/attendance/leave
- Notices/events/polls
- Amenities/bookings
- Assets/parking
- Rules/documents/NOCs
- SOS/incidents/patrols
- Marketplace/carpool/lost and found
- Support
- Analytics
- AI conversations/actions

All role applications and AI tools must call the same domain services.

---

# 5. Frontend live-data migration rules

For every Flutter screen:

1. Remove mock repository usage.
2. Remove hard-coded operational values.
3. Add typed DTO/model parsing.
4. Add repository/service method.
5. Add Riverpod provider/notifier.
6. Connect to a real endpoint.
7. Add authentication and active workspace context.
8. Add tenant/role-aware request handling.
9. Add:
   - Loading
   - Empty
   - Error
   - Retry
   - Offline
10. Add pagination where data may grow.
11. Add realtime invalidation where required.
12. Add optimistic updates only where safe.
13. Roll back optimistic state on failure.
14. Show backend request ID on supportable errors.
15. Clear state on:
   - Logout
   - Society switch
   - Role change
   - Staff post change
   - Impersonation end
16. Add widget/provider/integration tests.
17. Prove the UI changes when backend data changes.

Do not hide disconnected features behind a decorative card.

---

# 6. Every small UI element must be live

Verify every:

- Dashboard card
- KPI
- Count
- Badge
- Status pill
- Notification count
- Chart
- Graph
- Progress bar
- Timeline
- Activity feed
- “Recent” list
- “Upcoming” list
- Filter count
- Search result count
- Due amount
- Payment status
- Visitor status
- Complaint status
- Attendance state
- Booking availability
- Poll result
- Support SLA
- AI usage count
- Subscription metric
- System-health indicator

For each element, identify:

- API source
- Refresh behavior
- Realtime behavior
- Empty state
- Error state
- As-of timestamp
- Date range
- Tenant/role scope

No decorative operational chart may remain.

---

# 7. Backend endpoint completion

For every frontend data requirement:

- Ensure endpoint exists
- Add route
- Add validation
- Add authentication
- Add permission
- Add tenant/unit/post scope
- Add domain service
- Add repository query
- Add indexes
- Add pagination
- Add aggregate query/view where needed
- Add audit
- Add outbox event
- Add cache where appropriate
- Add OpenAPI
- Add tests
- Add performance result

Do not add broad “return everything” endpoints.

Use purpose-specific, permission-safe contracts.

---

# 8. Live dashboards and analytics

All dashboards must use backend aggregates.

Required dashboards include:

- Super Admin platform dashboard
- Society Admin dashboard
- Staff dashboard
- Resident dashboard
- Finance dashboard
- Complaint/SLA dashboard
- Staff/attendance dashboard
- Visitor dashboard
- Amenity dashboard
- AI usage dashboard
- Support dashboard
- System health dashboard

Rules:

- Use aggregate tables/materialized views where needed
- Include `asOf`
- Include date range
- Include comparison period
- Include currency where relevant
- Include permissions
- No raw-table full scan per request
- No client-side totals from list responses
- No static chart data

---

# 9. Cross-role live synchronization

Prove that all roles see the same canonical record.

## Visitor

- Resident creates/approves
- Staff sees live request
- Staff enters/exits
- Admin sees timeline
- Resident receives update

## Complaint

- Resident creates
- Admin sees
- Admin assigns
- Staff updates
- Resident sees public progress
- Admin verifies
- Resident rates

## Parcel

- Staff creates
- Resident notified
- Admin metrics update
- Staff hands over
- Resident status updates

## Payment

- Admin publishes bill
- Resident sees bill
- Resident pays
- Webhook verifies
- Receipt/ledger update
- Dashboards update

## Event and poll

- Admin publishes
- Resident sees
- Resident RSVPs/votes
- Capacity/results update
- Admin sees live totals

## Attendance

- Admin publishes roster
- Staff sees shift
- Staff checks in/out
- Admin sees attendance

Fail if separate records diverge.

---

# 10. Realtime data requirements

Use SSE/WebSocket/outbox events for:

- Visitor approval/entry/exit
- Parcel received/collected
- Complaint assignment/status/chat
- Payment status
- Notice publication
- Event capacity
- Poll publication/result
- Amenity booking/waitlist
- SOS
- Staff task/attendance
- KYC/NOC status
- Support ticket
- AI action execution
- Feature rollout

Frontend must handle:

- Reconnect
- Last event ID
- Duplicate event
- Out-of-order event
- Permission revocation
- Logout
- Workspace switch
- App background/resume

Do not poll aggressively when realtime is already available.

---

# 11. File and document live-data rules

All files must use real storage metadata and signed access.

Applies to:

- KYC
- Complaint evidence
- Visitor/parcel images
- Marketplace images
- Receipts
- Invoices
- Rules
- Bylaws
- NOCs
- Support attachments
- AI documents

Requirements:

- Signed upload
- Private storage
- Scan status
- Processing status
- Live upload progress
- Retry/cancel
- Signed download
- Permission check
- Access audit
- Expiry
- Deleted/archived state

No public placeholder file URLs.

---

# 12. Payments must be fully live

The payment UI must use:

- Live bills
- Live server totals
- Live provider order/intent
- Live webhook verification
- Live payment status
- Live receipt
- Live ledger allocation
- Live refund/reconciliation state
- Live auto-pay mandate

Never use:

- Fake payment success
- Client callback as final authority
- Static receipts
- Random transaction IDs
- Hard-coded outstanding amount

Show `Processing` until the backend verifies the provider event.

---

# 13. AI Copilot live-data rules

AI must use live authorized sources.

AI answers and tools must connect to:

- Current rules/documents
- Current events
- Current facility timings
- Current complaint status
- Current bills/payments
- Current visitor status
- Current staff shift
- Current bookings
- Current NOC/KYC status

Requirements:

- Server-owned conversation history
- Permission-aware retrieval
- Source citations
- Current document version
- Live domain-service tools
- Typed proposals
- Confirmation before writes
- No mock answers
- No static action cards
- No direct client Firestore totals
- No stale cross-workspace cache

If live data is unavailable, AI must say it cannot retrieve the current information.

---

# 14. Seed and test data policy

Seed data is allowed only in:

- Local development
- Automated tests
- Dedicated staging/demo environment

Requirements:

- Separate seed command
- Environment guard
- Clear labels
- Never silently run in production
- No demo credential in production build
- No staging endpoint in production config
- Test data cannot appear in real society accounts

Create:

- `SEED_DATA_POLICY.md`

---

# 15. Empty-state policy

When a real dataset is empty, show a truthful empty state.

Examples:

- `No complaints yet`
- `No outstanding bills`
- `No visitors expected today`
- `No active support tickets`
- `No bookings available for this date`

Do not fill empty states with sample content.

Each empty state may contain:

- Explanation
- Allowed action
- Refresh
- Support link

---

# 16. Error and offline policy

Never replace an API error with fake data.

On error show:

- Clear message
- Retry
- Offline/stale state where relevant
- Last updated time
- Request/reference ID
- Safe cached data only when explicitly labeled

Do not silently swallow errors.

---

# 17. Verification tests

For every screen test:

1. Empty database
2. One record
3. Multiple records
4. Large paginated data
5. Society A
6. Society B
7. Different role
8. Permission revoked
9. Record updated by another role
10. Record deleted/archived
11. Slow API
12. Offline
13. API error
14. Realtime event
15. App restart
16. Workspace switch

For every visible value:

- Change backend value
- Refresh or emit event
- Confirm UI changes
- Confirm no hard-coded fallback remains

---

# 18. Automated static-data detection in CI

Add CI checks that detect production use of:

- Mock repositories
- Demo services
- Local JSON fixtures
- Hard-coded operational arrays
- Placeholder API responses
- Development URLs
- Test credentials
- Sample payment status
- Static dashboard series

Allowlist legitimate test and development directories.

Fail CI when a production source imports a mock data module.

Create:

- `scripts/check-production-mocks.*`
- CI job:
  - `production-live-data-check`

---

# 19. Live-data traceability matrix

Create `LIVE_DATA_FINAL_TRACEABILITY.md`.

For every feature record:

- Feature
- Role
- Screen
- Route
- Visible elements
- Provider
- Service
- Endpoint
- Permission
- Database source
- Aggregate/view
- Realtime event
- Audit event
- Empty state
- Error state
- Offline state
- Test
- Live-data proof
- Status

Status can only be:

- VERIFIED LIVE
- PARTIAL
- BLOCKED
- FAILED

Do not use `DONE`.

---

# 20. Implementation sequence

## Phase 0 — Audit

- Search mocks/static data
- Build screen/component/API inventory
- Map source of truth
- Run baseline tests

## Phase 1 — Backend gaps

- Missing tables/migrations
- Missing services
- Missing endpoints
- Missing aggregates
- Missing realtime events
- Missing permissions

## Phase 2 — Core shared modules

- Auth/users
- Societies
- Visitors
- Complaints
- Payments
- Notices/events
- Staff/attendance
- Documents/files

## Phase 3 — Role applications

- Super Admin
- Admin
- Staff/Guard
- Resident

## Phase 4 — AI

- Live RAG
- Live tools
- Conversation persistence
- Citations
- Action confirmation

## Phase 5 — Analytics/reports

- Live aggregates
- Charts
- Exports
- As-of times

## Phase 6 — Realtime/offline

- Events
- Notifications
- Reconnect
- State clearing
- Offline labeling

## Phase 7 — Verification

- Full E2E
- Cross-role journeys
- Static-data CI check
- Load test
- Final traceability

At the end of every phase report:

- Files changed
- Mock/static sources removed
- Endpoints added
- Screens connected
- Tests executed
- Live-data proof
- Blockers

---

# 21. Definition of done

The migration is complete only when:

- Every production screen uses live data
- Every visible count/chart/status has a documented source
- No production operational mock/static data remains
- No privileged direct Firestore write remains
- Every frontend call has a working endpoint
- Every endpoint is authorized and tenant-scoped
- Cross-role records stay synchronized
- Realtime updates work
- Payments are provider/webhook authoritative
- AI uses live authorized data
- Files are private and live
- Empty states are truthful
- Errors never fall back to fake data
- CI rejects production mock imports
- All tests pass
- Traceability shows `VERIFIED LIVE` for every applicable feature
- Zero unresolved P0/P1 live-data defects remain

---

# 22. Final response format

At completion report:

## A. Verdict

- PASS
- PASS WITH APPROVED P2/P3 EXCEPTIONS
- FAIL

## B. Audit totals

- Screens audited
- Components audited
- Mock/static findings
- Removed
- Remaining
- Endpoints connected
- Realtime flows verified
- Features verified live

## C. Role verdicts

- Super Admin
- Admin
- Staff/Guard
- Resident
- AI Copilot

## D. Data verdict

- PostgreSQL
- Redis
- Firestore migration
- Realtime
- Files
- Analytics
- Payments
- AI

## E. Remaining blockers

List exact:

- File
- Line
- Screen
- Endpoint
- Database source
- Required fix
- Owner
- Test

Do not claim “all live” unless the traceability matrix and executed tests prove every applicable production feature is connected to real data.

---

# 23. Start instruction

Begin with these steps:

1. Run the complete repository search for mock/static/stub data.
2. Build the screen and component inventory.
3. Build the endpoint inventory.
4. Map every visible element to its expected source of truth.
5. Record baseline build/test results.
6. Produce the migration plan.
7. Only then begin replacing data sources.

Do not begin by deleting mock files before identifying every screen that depends on them.
