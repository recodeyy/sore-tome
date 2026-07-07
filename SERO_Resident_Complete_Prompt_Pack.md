# SERO Member / Resident App — Complete Prompt Pack

This pack contains:

1. Resident frontend implementation prompt
2. Resident backend implementation prompt
3. Resident frontend/backend QC and release-audit prompt

The Resident module must use the same SERO design system and canonical cross-role records used by Admin, Staff, Super Admin, and the AI Copilot.

---

# SERO Member / Resident App — Frontend Master Implementation Prompt

## Role

Act as a **Principal Flutter Architect, Senior Consumer Product Designer, Riverpod Expert, Design-System Engineer, Accessibility Specialist, and Mobile UX Lead**.

You are working inside the existing **SERO — AI Powered Society Management Platform** repository.

Your task is to design and implement the complete **Member / Resident application** for all 57 Resident capabilities, covering:

- Profile and household management
- Vehicles and KYC
- Bills, payments, receipts, and auto-pay
- Visitors and domestic help
- Complaints and resident-admin communication
- Community notices, events, polls, marketplace, carpool, and lost & found
- Amenity discovery, booking, payment, and reviews
- SOS and emergency contacts
- Rules, bylaws, receipts, and NOCs

The Resident application must use the **same SERO emerald/navy design language** as the Admin, Super Admin, Staff, and shared modules, while providing a simpler, friendly, consumer-grade experience.

Do not create a disconnected resident app with duplicate data. Resident actions must update the same canonical records used by Admin and Staff.

---

# 1. Repository-first instructions

Before implementation, inspect:

- Existing Flutter theme and design tokens
- `main_shell.dart`
- Existing Resident shell/screens
- Admin and Staff shared modules
- Authentication and role routing
- Resident providers and services
- Payment screens and provider integration
- Visitor approval flows
- Complaint screens
- Notice/event/poll screens
- Amenity booking screens
- Emergency/SOS screens
- Rules/document screens
- AI Copilot integration
- Push/deep-link routing
- Offline/local storage
- Existing mock/static data
- Direct Firestore reads/writes
- Current API contracts

Produce first:

1. `RESIDENT_FRONTEND_AUDIT.md`
2. `RESIDENT_FEATURE_MATRIX_57.md`
3. `RESIDENT_SCREEN_MAP.md`
4. `RESIDENT_ROUTE_MAP.md`
5. `RESIDENT_COMPONENT_INVENTORY.md`
6. `RESIDENT_FRONTEND_BACKEND_CONTRACT.md`
7. `RESIDENT_OFFLINE_AND_NOTIFICATION_PLAN.md`

Do not begin bulk screen generation until the audit is complete.

---

# 2. Preserve the SERO design language

Use the existing repository theme as the source of truth.

## 2.1 Colors

Reuse:

- Deep Emerald: `#064E3B`
- Near-black Navy: `#111827`
- Deep Navy Blue: `#1E3A8A`
- Emerald Accent: `#10B981`
- Sky Accent: `#0EA5E9`
- Slate Background: `#F8FAFC`
- Slate Border: `#E2E8F0`
- Primary Text: `#1E293B`
- Secondary Text: `#64748B`
- Muted Text: `#94A3B8`
- Error: `#EF4444`
- Existing success, warning, priority, and information colors

Use the same premium emerald-to-navy gradients.

## 2.2 Typography

Use **Outfit**:

- Page titles: 22–24 px, weight 700–800
- Section headings: 16–18 px, weight 600–700
- Financial/stat values: 20–28 px, weight 700–900
- Body: 13–14 px
- Status labels: 10–12 px, weight 600–700

## 2.3 Shape and spacing

- Main cards: approximately 24 px radius
- Inputs and primary buttons: approximately 20 px radius
- Chips/status badges: approximately 10–12 px radius
- Horizontal page padding: approximately 20 px
- Generous whitespace
- Soft slate borders
- Low-opacity shadows
- Clear consumer-friendly hierarchy
- Large touch targets

## 2.4 Resident UX principles

- Important information visible within two taps
- Payment and emergency actions easy to find
- Plain-language explanations
- No accounting jargon without explanation
- Clear bill and payment status
- Clear privacy and audience settings
- No confusing Admin-only terminology
- Easy one-handed mobile use
- Strong empty, loading, error, and offline states
- Confirmation for financial, visitor, community-post, and emergency actions

---

# 3. Resident roles and household context

Support:

- `resident_owner`
- `resident_tenant`
- `family_member`
- `co_owner`
- `authorized_household_member`

Permissions must also consider:

- Society membership
- Unit relationship
- Ownership/tenancy dates
- Household permissions
- Primary account holder
- Bill responsibility
- Visitor approval rights
- Amenity eligibility
- Voting eligibility
- Feature entitlement
- KYC status

Do not assume all family members can:

- Pay bills
- Enable auto-pay
- Approve visitors
- Upload KYC for others
- Vote
- Request NOCs
- See every household document

Use backend-provided capabilities.

---

# 4. Resident application structure

Create or complete:

- `lib/app/resident_shell.dart`
- `lib/screens/resident/**`
- `lib/providers/resident/**`
- `lib/services/resident/**`
- `lib/models/resident/**`
- `lib/widgets/resident/**`

## 4.1 Mobile bottom navigation

Use five tabs:

1. **Home**
2. **Community**
3. **Pay**
   - Center circular emerald button using a ₹ or wallet icon
   - Same visual logic as the Admin center action
4. **Complaints**
5. **More**

## 4.2 More menu/drawer

- Profile and Household
- Vehicles
- KYC
- Visitors
- Domestic Help
- Bills and Payments
- Receipts
- Amenities
- Marketplace
- Carpool
- Lost & Found
- Emergency
- Rules and Bylaws
- NOCs
- AI Copilot
- Notifications
- Settings
- Help
- Logout

## 4.3 Persistent resident context

Show where relevant:

- Society name
- Wing/block/unit
- Owner/tenant role
- Outstanding dues
- Active complaint count
- Visitors awaiting action
- Upcoming booking/event
- KYC/document status

---

# 5. Complete 57 Resident capabilities

Implement the following 57 capabilities.

## A. Profile and household — 1 to 8

1. View and update personal profile.
2. Manage family members.
3. Manage co-owner, tenant, and household relationships according to permission.
4. Manage household emergency contacts.
5. Register, edit, and remove resident vehicles.
6. Upload and track KYC documents.
7. Manage communication, language, privacy, and notification preferences.
8. View unit/occupancy details, move-in information, membership status, and profile verification progress.

## B. Bills, payments, receipts, and auto-pay — 9 to 16

9. View current and past bills.
10. View detailed bill components, taxes, penalties, adjustments, and due date.
11. Pay a full, partial, or permitted combined amount.
12. Track payment processing, success, failure, refund, and reconciliation status.
13. Download and share official receipts.
14. Configure, pause, resume, or cancel auto-pay/mandate where supported.
15. View payment history, credits, advances, refunds, and outstanding balance.
16. Receive reminders, raise a billing query/dispute, and track resolution.

## C. Visitors and domestic help — 17 to 24

17. Pre-approve a visitor.
18. Approve or reject a walk-in visitor request in realtime.
19. Generate or share a secure visitor QR/OTP gate pass.
20. View active, expected, completed, denied, and expired visitor records.
21. Receive visitor entry, exit, overstay, and exception notifications.
22. Add and manage domestic-help profiles.
23. Configure domestic-help schedules, access days, and permitted gates.
24. Pause, revoke, or report domestic-help access and view attendance/access history where permitted.

## D. Complaints and communication — 25 to 31

25. Raise a complaint/service request.
26. Select category/location, add description, and upload photo/video/document evidence.
27. Track complaint status, assignment, SLA/due time, and timeline.
28. Chat with Admin/assigned Staff using resident-visible comments.
29. Add information, withdraw where allowed, or respond to clarification.
30. Reopen a resolved complaint where policy permits.
31. Rate the resolution and submit feedback.

## E. Community — 32 to 44

32. View the notice board.
33. Open notices, attachments, read status, and acknowledgement requirements.
34. Discover society events.
35. RSVP, join waitlist, add to calendar, cancel RSVP, and receive reminders.
36. View eligible polls and cast a vote.
37. View poll participation and published results according to policy.
38. Browse and search marketplace listings.
39. Create, edit, pause, and close own marketplace listings.
40. Contact a listing owner through privacy-safe messaging and report inappropriate listings.
41. Create a carpool offer or request.
42. Join, leave, or manage a carpool trip with seat and schedule status.
43. Create and browse lost-and-found posts, matching suggestions, and claim workflow.
44. Report, block, or flag community content and track moderation outcome where visible.

## F. Amenities — 45 to 50

45. Browse amenities, rules, pricing, operating hours, and eligibility.
46. View live slot availability and closures.
47. Book an amenity slot with guest/capacity details.
48. Pay booking fees/deposits and track payment/refund status.
49. View, reschedule, cancel, join waitlist, and manage upcoming/past bookings.
50. Write, edit, and view amenity reviews subject to moderation.

## G. Emergency — 51 to 54

51. Trigger an SOS alert.
52. View SOS acknowledgement, responder status, escalation, and resolution timeline.
53. Manage personal and household emergency contacts.
54. Access society emergency directory, procedures, helplines, assembly points, and safety guidance.

## H. Documents — 55 to 57

55. View and search rules, bylaws, policies, circulars, and document versions.
56. View/download official receipts and resident-accessible account documents.
57. Request, track, download, and verify NOCs and other resident certificates.

---

# 6. Required screens

## 6.1 Resident Home Dashboard

Create `resident_dashboard_screen.dart`.

Header:

- Menu/profile
- Notification icon with badge
- Greeting
- Resident name
- Society/unit context
- Date

Primary card:

- Outstanding amount
- Next due date
- Pay now
- Bill detail
- Auto-pay status

Quick actions:

- Pay Bill
- Approve Visitor
- Raise Complaint
- Book Amenity
- SOS
- Ask SERO

KPI cards:

- Active Complaints
- Expected Visitors
- Upcoming Bookings
- New Notices
- Events
- Pending KYC/NOC

Sections:

- Latest notices
- Upcoming events
- Visitor awaiting approval
- Complaint progress
- Recent payments
- Community highlights
- Emergency shortcut

All values must be live and permission-scoped.

## 6.2 Profile and Household

Tabs/sections:

- My Profile
- Unit
- Family
- Co-owner/Tenant
- Emergency Contacts
- Preferences
- Verification

Support:

- Edit profile
- Phone/email verification where required
- Add/edit/remove household relationships
- Invite household member
- Approval/consent state
- Privacy settings
- Membership status

## 6.3 Vehicles

- Vehicle list
- Add/edit/remove
- Registration number
- Vehicle type
- Make/model/color
- Sticker/pass status
- Parking allocation
- Document upload if required
- Duplicate vehicle warning
- Transfer/revoke workflow

## 6.4 KYC

- Document requirements
- Upload
- Camera/file selection
- Status:
  - Not submitted
  - Under review
  - Approved
  - Rejected
  - Replacement requested
  - Expired
- Rejection reason
- Expiry reminders
- Private document preview
- Signed access
- No public URL

## 6.5 Bills

List:

- Current
- Overdue
- Paid
- Partially paid
- Cancelled/adjusted

Bill detail:

- Bill number
- Period
- Charge components
- Taxes
- Previous balance
- Penalties
- Credits
- Total
- Paid
- Outstanding
- Due date
- Download invoice
- Ask SERO to explain
- Raise query
- Pay

## 6.6 Payment Checkout

- Selected bill(s)
- Amount
- Partial/full choice where allowed
- Credits/advance application
- Provider method
- Terms/consent
- Redirect/SDK state
- Pending verification
- Success only after verified backend state
- Failure/retry
- Receipt link

Never collect or log raw card details in SERO.

## 6.7 Auto-pay

- Provider mandate status
- Maximum amount/rule
- Start date
- Next debit
- Consent
- Pause/resume/cancel
- Failure status
- Reauthorization
- History
- Clear statement that final debit depends on provider/bank confirmation

## 6.8 Receipts and Payment History

- Filter by date/status/bill
- Payment amount
- Provider reference
- Allocation
- Receipt
- Refund
- Reconciliation state
- Download/share
- Raise payment issue

## 6.9 Visitor Approval

- Realtime approval card
- Visitor name/photo if policy allows
- Purpose
- Gate
- Time
- Vehicle
- Approve
- Reject with reason
- Call/message gate only through safe channel where supported
- Expiry countdown
- Duplicate/flag warning without oversharing

## 6.10 Pre-approve Visitor

Steps:

1. Visitor details
2. Date/time window
3. Gate/purpose
4. Vehicle/person count
5. Number of allowed entries
6. Review
7. Generate pass

Show:

- QR/pass
- Share link/pass
- Revoke
- Extend where policy permits
- Entry/exit timeline

## 6.11 Domestic Help

- Profile
- Photo/ID status
- Phone
- Service type
- Schedule
- Gates
- Active/paused/revoked
- Access history
- Attendance notifications
- Report concern
- Privacy and consent

## 6.12 Complaints

List filters:

- Open
- Assigned
- In progress
- Waiting
- Resolved
- Closed

Create:

- Category/subcategory
- Unit/common area
- Description
- Priority guidance
- Attachments
- Contact preference
- Privacy
- Review/submit

Detail:

- Status
- SLA/due time
- Assigned team/staff where permitted
- Public timeline
- Chat
- Attachments
- Add information
- Reopen
- Rate

Internal notes must never be visible.

## 6.13 Notices

- Search/filter
- Priority/category
- Read/unread
- Required acknowledgement
- Attachments
- Effective/expiry dates
- Save/share if permitted
- Ask SERO to explain

## 6.14 Events

- Upcoming/past
- Category
- Date/location
- Capacity
- RSVP
- Waitlist
- Guest rules
- Add to calendar
- Reminder
- Cancel
- Attendance/QR if supported

## 6.15 Polls

- Eligibility
- Start/end
- Anonymous/not anonymous disclosure
- Options
- One-vote confirmation
- Submitted state
- Results visibility
- Quorum/participation where published

Never allow vote editing unless policy permits before closure.

## 6.16 Marketplace

- Browse/search/filter
- Listing detail
- Create/edit/pause/close
- Images
- Price/category
- Privacy-safe contact
- Report/block
- My listings
- Expiry

Do not expose private phone numbers by default.

## 6.17 Carpool

- Offer/request
- Route
- Date/time/repetition
- Seats
- Pickup point
- Join/request
- Approve rider if configured
- Leave/cancel
- Privacy-safe messaging
- Report safety concern

Include safety disclaimer and society policy.

## 6.18 Lost & Found

- Post lost/found
- Category/location/time
- Photo
- Description
- Matching suggestions
- Claim workflow
- Verification question
- Resolve/close
- Report abuse

Do not reveal sensitive proof answers publicly.

## 6.19 Amenities

Browse:

- Amenity card
- Rules
- Price
- Hours
- Capacity
- Availability
- Closure

Booking:

- Date
- Slot
- Guests
- Price/deposit
- Terms
- Payment
- Confirmation
- QR/code if needed
- Cancel/reschedule
- Refund status
- Waitlist

Reviews:

- Rating
- Comment
- Edit/delete own
- Moderation state

## 6.20 SOS

Use a deliberate emergency interaction:

- Large SOS control
- Press-and-hold or confirm according to product policy
- Alert type
- Current/selected location
- Optional note
- Contact emergency services warning
- Trigger
- Realtime status:
  - Sent
  - Dispatched
  - Acknowledged
  - Responding
  - On scene
  - Resolved
- Cancel only under allowed state
- False alarm option
- Emergency contact notifications

Do not delay a confirmed SOS with unnecessary screens.

## 6.21 Emergency Directory

- Security desk
- Ambulance
- Fire
- Police
- Society management
- Nearby approved emergency references
- Assembly points
- Procedures
- Offline-cached emergency information with last-updated timestamp

## 6.22 Rules and Bylaws

- Search
- Categories
- Current/effective versions
- Download
- Page/section navigation
- Read acknowledgement
- Ask SERO
- Previous version where resident-visible
- Signed document links

## 6.23 NOCs and Certificates

- Document type
- Eligibility/requirements
- Form
- Attachments
- Fees if applicable
- Submit
- Status timeline
- Clarification
- Approval/rejection
- Signed downloadable certificate
- QR/verification code
- Expiry
- Reapply

---

# 7. AI Copilot integration

Add contextual “Ask SERO” entry points for:

- Bill explanation
- Notice explanation
- Rule/bylaw question
- Event details
- Facility/amenity timing
- Complaint guidance
- Visitor guidance
- Parking/vehicle guidance
- NOC requirements
- Emergency procedure

AI must:

- Use the resident’s society and permission context
- Cite official sources
- Never expose other units/users
- Never mark payment successful without verified status
- Never create a complaint, visitor, booking, or NOC request without a visible proposal and confirmation
- Never cast a vote
- Never trigger SOS without explicit resident confirmation

---

# 8. Shared cross-role integration

Use canonical records shared with Admin and Staff.

## Visitor

- Resident creates/approves
- Staff verifies and records entry/exit
- Admin monitors
- Resident receives updates

## Complaint

- Resident creates
- Admin assigns
- Staff works
- Resident sees public updates
- Admin verifies
- Resident rates/reopens

## Payment

- Admin publishes bill
- Resident pays
- Provider webhook verifies
- Ledger updates
- Receipt appears

## Parcel

- Staff logs
- Resident receives notification
- Staff hands over
- Resident sees collected status

## Event/amenity

- Admin publishes/configures
- Resident books/RSVPs
- Capacity updates for everyone

Do not create duplicate resident-only copies.

---

# 9. Riverpod and data layer

Create providers/notifiers for:

- Resident session/capabilities
- Active society/unit/household
- Dashboard
- Profile/family
- Vehicles
- KYC
- Bills
- Payments
- Receipts
- Auto-pay
- Visitor approvals
- Visitor passes/history
- Domestic help
- Complaints/chat
- Notices
- Events/RSVP
- Polls/voting
- Marketplace
- Carpool
- Lost & Found
- Amenities/bookings/reviews
- SOS
- Emergency directory
- Rules/documents
- NOCs
- Notifications
- Offline/cache state

Requirements:

- Cursor pagination
- Debounced search
- Cancellation
- Request deduplication
- Realtime lifecycle
- Refresh/invalidation
- Optimistic update only where safe
- Rollback
- State clearing on logout, society switch, unit relationship change, or permission change
- No production mock fallback

---

# 10. Offline and weak-network behavior

Allow safe offline behavior for:

- Previously loaded notices/rules/emergency directory
- Draft complaint
- Draft marketplace/lost-found post
- Draft visitor pre-approval
- Draft NOC form
- Cached bills/receipts marked with last-updated time

Do not show final success offline for:

- Payment
- Visitor approval/entry
- Amenity booking
- Poll vote
- SOS dispatch
- Auto-pay mandate
- NOC submission requiring server
- KYC upload completion

Show:

- Offline
- Pending sync
- Last updated
- Retry
- Conflict
- Permanent failure

Encrypt local sensitive data and clear according to policy.

---

# 11. Notifications and deep links

Support:

- Bill generated
- Due reminder
- Payment success/failure/refund
- Auto-pay upcoming/failure
- Visitor approval request
- Visitor entry/exit/overstay
- Parcel received/reminder/collected
- Complaint assignment/status/message
- Notice
- Event reminder/waitlist promotion
- Poll opening/closing
- Marketplace/carpool/lost-found response
- Amenity booking/reminder/cancellation/refund
- SOS status
- KYC status
- NOC status

Every notification must deep-link to the correct record.

Respect preferences, mandatory operational notices, quiet hours, and lock-screen privacy.

---

# 12. Payment and financial UI safety

- Display server-calculated totals
- Use decimal/minor-unit-safe formatting
- Show as-of timestamp
- Never calculate authoritative outstanding from a truncated list
- Never mark success only from client callback
- Show “Processing” until backend verifies
- Prevent duplicate pay taps
- Handle app close during payment
- Restore pending payment state
- Show provider reference
- Handle partial payment and credits accurately
- Auto-pay consent must be explicit
- Do not store card/bank credentials

---

# 13. Privacy and security

- Secure token storage
- No public KYC/document URLs
- No raw payment credentials
- No other resident/unit data
- No internal complaint notes
- No unrestricted visitor history
- No private marketplace phone exposure
- No domestic-help ID oversharing
- No household permission assumption
- No client-trusted vote eligibility
- No client-trusted QR/OTP
- No direct privileged Firestore writes
- Clear cached data on logout/society/unit switch
- Redact crash logs
- Step-up authentication for high-risk actions where required

---

# 14. Responsive and accessibility

Support:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet portrait/landscape
- 1366×768 web
- 1440×900 web

Mobile:

- Bottom navigation
- Cards
- Bottom sheets
- Full-screen payment/SOS/booking flows

Tablet/web:

- Navigation rail/sidebar
- Two-column dashboards
- Master-detail where useful

Accessibility:

- WCAG 2.1 AA where applicable
- Screen-reader labels
- Keyboard support
- Visible focus
- Text scaling
- High contrast
- No color-only status
- Accessible charts
- Large touch targets
- Reduced motion
- Multilingual rendering
- Clear financial and emergency semantics

---

# 15. Frontend tests

Create:

## Authentication/context

- Owner
- Tenant
- Family member
- Multiple units
- Society switch
- Role change
- Permission revocation
- Suspended membership

## Profile/KYC

- Profile edit
- Family add/remove
- Vehicle duplicate
- KYC upload/status/replacement
- Private preview

## Payments

- Bill list/detail
- Full/partial payment
- Pending
- Success
- Failure
- App restart
- Duplicate tap
- Receipt
- Refund
- Auto-pay consent/pause/cancel

## Visitors/domestic help

- Pre-approval
- Walk-in approval/reject
- QR/pass
- Revoke
- Entry/exit realtime
- Domestic-help schedule/pause/history

## Complaints

- Create
- Attachment
- Timeline
- Chat
- Clarification
- Reopen
- Rating
- Internal-note privacy

## Community

- Notice acknowledgement
- Event RSVP/waitlist
- Poll voting
- Marketplace
- Carpool
- Lost & Found
- Moderation/report

## Amenities

- Availability
- Booking concurrency response
- Payment
- Cancellation/refund
- Waitlist
- Review

## Emergency/documents

- SOS
- Responder status
- Emergency directory offline
- Rules search
- NOC request/download

## Quality

- Loading
- Empty
- Error
- Offline
- Deep links
- Push
- Accessibility
- Responsive
- Golden tests
- State clearing
- No mock data

Golden screens:

- Resident dashboard
- Bill detail
- Payment processing/success
- Visitor approval
- Complaint detail
- Community home
- Event
- Poll
- Marketplace
- Amenity booking
- SOS active
- Rules
- NOC
- KYC

---

# 16. Routes

Use:

- `/resident`
- `/resident/dashboard`
- `/resident/profile`
- `/resident/household`
- `/resident/vehicles`
- `/resident/kyc`
- `/resident/bills`
- `/resident/bills/:id`
- `/resident/payments`
- `/resident/receipts`
- `/resident/autopay`
- `/resident/visitors`
- `/resident/visitors/new`
- `/resident/visitors/:id`
- `/resident/domestic-help`
- `/resident/complaints`
- `/resident/complaints/new`
- `/resident/complaints/:id`
- `/resident/notices`
- `/resident/notices/:id`
- `/resident/events`
- `/resident/events/:id`
- `/resident/polls`
- `/resident/polls/:id`
- `/resident/marketplace`
- `/resident/marketplace/:id`
- `/resident/carpool`
- `/resident/lost-found`
- `/resident/amenities`
- `/resident/amenities/:id`
- `/resident/bookings`
- `/resident/sos`
- `/resident/emergency`
- `/resident/rules`
- `/resident/documents`
- `/resident/nocs`
- `/resident/nocs/:id`
- `/copilot`

Routes must be capability-aware.

---

# 17. Deliverables

1. Resident frontend audit
2. 57-feature matrix
3. Screen and route maps
4. Dedicated Resident shell
5. Complete screens
6. Shared cross-role integration
7. Riverpod providers/services/models
8. Payment and realtime integration
9. Offline/cache behavior
10. Push/deep links
11. Responsive/accessibility
12. Tests
13. No production mock data
14. No privileged direct Firestore writes
15. `RESIDENT_FRONTEND_TRACEABILITY.md` mapping:
    - Feature 1–57
    - Role/household permission
    - Screen
    - Route
    - Provider
    - Service
    - API
    - Realtime/notification
    - Test
    - Status

---

# 18. Implementation phases

## Phase 0 — Audit

- Inspect repository
- Map current resident screens
- Map shared records
- Map payments/visitors/complaints
- Detect mocks/direct Firestore

## Phase 1 — Foundation

- Resident shell
- Capabilities
- Household/unit context
- Navigation
- Shared components
- Notifications/deep links

## Phase 2 — Profile and KYC

- Profile
- Family
- Vehicles
- KYC
- Preferences

## Phase 3 — Payments

- Bills
- Checkout
- Receipts
- History
- Auto-pay
- Billing query

## Phase 4 — Visitors and complaints

- Visitor approvals/passes/history
- Domestic help
- Complaint create/detail/chat/reopen/rate

## Phase 5 — Community

- Notices
- Events
- Polls
- Marketplace
- Carpool
- Lost & Found
- Moderation

## Phase 6 — Amenities/emergency/documents

- Amenities/bookings/reviews
- SOS/emergency
- Rules/bylaws
- NOCs

## Phase 7 — Hardening

- AI contextual entry points
- Offline
- Accessibility
- Responsive
- Golden/contract tests
- Remove mocks
- Traceability

At each phase report:

- Files/screens/routes
- APIs connected
- Realtime flows
- Tests/results
- Security issues
- Remaining blockers

---

# 19. Definition of done

Complete only when:

- All 57 features are implemented and traced
- The Resident app uses the same SERO design system
- Owner/tenant/family permissions are correct
- Every screen uses live, tenant-scoped data
- Bills and payments are backend-authoritative
- Auto-pay uses provider mandates and explicit consent
- Visitor flows synchronize with Staff/Admin
- Complaint flows synchronize with Staff/Admin
- Community moderation and privacy work
- Poll votes are eligibility-safe and duplicate-safe
- Amenity bookings are concurrency-safe
- SOS is realtime and cannot falsely show success
- KYC/documents are private
- NOCs are trackable and verifiable
- AI uses resident-safe context
- No production mock data remains
- No privileged direct Firestore write remains
- Flutter analyze and all tests pass
- Existing Super Admin/Admin/Staff/AI flows remain functional

Begin with the audit and feature matrix, not disconnected UI generation.


---

# SERO Member / Resident App — Backend Master Implementation Prompt

## Role

Act as a **Principal Backend Architect, Staff TypeScript Engineer, Payments Engineer, Security Engineer, Database Architect, Realtime Systems Engineer, and SRE**.

You are working inside the existing SERO backend.

Your task is to implement the complete backend for the 57 Resident capabilities:

- Profile, family, vehicles, KYC
- Bills, payments, receipts, auto-pay
- Visitors and domestic help
- Complaints and resident-admin communication
- Notices, events, polls, marketplace, carpool, lost & found
- Amenities and reviews
- SOS and emergency contacts
- Rules, bylaws, receipts, NOCs

The Resident backend must use the same canonical records and domain services used by Admin, Staff, Super Admin, and the AI Copilot.

Do not create separate resident-only copies of bills, visitors, complaints, events, amenities, or documents.

---

# 1. Repository-first audit

Inspect:

- Authentication and membership
- Resident routes/screens contracts
- Admin billing/payment services
- Visitor services
- Complaint services
- Community modules
- Amenity booking
- SOS
- KYC/files
- Documents/rules
- NOC workflows
- Firebase Auth/FCM
- PostgreSQL/RLS
- Redis/BullMQ
- Razorpay/payment provider
- Realtime/outbox
- AI tools
- Firestore usage/rules
- Existing tests
- OpenAPI
- Migrations

Produce:

1. `RESIDENT_BACKEND_AUDIT.md`
2. `RESIDENT_DOMAIN_ARCHITECTURE.md`
3. `RESIDENT_PERMISSION_MATRIX.md`
4. `RESIDENT_API_CONTRACT.md`
5. `RESIDENT_DATA_MODEL.md`
6. `RESIDENT_PAYMENT_AND_AUTOPAY_DESIGN.md`
7. `RESIDENT_THREAT_MODEL.md`

Do not start bulk implementation before the audit.

---

# 2. Architecture rules

Use the approved platform stack:

- Node.js LTS
- Strict TypeScript
- Express or existing framework
- PostgreSQL source of truth
- RLS
- Redis
- Redlock
- BullMQ
- Firebase Auth
- FCM
- Private object storage
- Outbox
- OpenAPI 3.1
- Pino
- OpenTelemetry
- Sentry
- Docker
- CI/CD

Canonical services:

- `ResidentProfileService`
- `HouseholdService`
- `VehicleService`
- `KYCService`
- `BillingService`
- `PaymentService`
- `ReceiptService`
- `AutoPayService`
- `VisitorService`
- `DomesticHelpService`
- `ComplaintService`
- `NoticeService`
- `EventService`
- `PollService`
- `MarketplaceService`
- `CarpoolService`
- `LostFoundService`
- `AmenityService`
- `BookingService`
- `SOSService`
- `EmergencyService`
- `RuleDocumentService`
- `NOCService`
- `NotificationService`
- `FileService`

Admin, Staff, Resident, and AI must call these same services.

---

# 3. Resident authorization model

Support:

- `resident_owner`
- `resident_tenant`
- `family_member`
- `co_owner`
- `authorized_household_member`

Permissions include:

- `profile.read_own`
- `profile.update_own`
- `household.read`
- `household.manage`
- `vehicle.read`
- `vehicle.manage`
- `kyc.read_own`
- `kyc.upload_own`
- `bill.read_own`
- `payment.create`
- `payment.read_own`
- `receipt.read_own`
- `autopay.manage`
- `visitor.create`
- `visitor.approve`
- `visitor.revoke`
- `domestic_help.manage`
- `complaint.create`
- `complaint.read_own`
- `complaint.comment`
- `complaint.reopen`
- `complaint.rate`
- `notice.read`
- `event.read`
- `event.rsvp`
- `poll.vote`
- `marketplace.read`
- `marketplace.create`
- `carpool.use`
- `lost_found.use`
- `amenity.read`
- `amenity.book`
- `amenity.review`
- `sos.trigger`
- `sos.read_own`
- `emergency.read`
- `document.read`
- `noc.request`
- `noc.read_own`

Authorization must also evaluate:

- Society
- Unit relationship
- Occupancy dates
- Primary/secondary household role
- Bill responsibility
- Voting eligibility
- Amenity eligibility
- KYC status
- Account/society status
- Feature entitlement
- Resource ownership
- State
- Step-up authentication

Never trust unit ID, role, bill responsibility, or eligibility from the request body.

---

# 4. Complete 57 backend capabilities

Implement all capabilities numbered in the frontend prompt.

Use the same numbering in:

- API docs
- Traceability
- Tests
- Final reports

---

# 5. Data model

Use or extend canonical tables.

## Profile and household

- users
- user_profiles
- society_memberships
- unit_members
- household_relationships
- family_members
- household_permissions
- emergency_contacts
- communication_preferences
- resident_verifications
- occupancy_history

## Vehicles/KYC

- vehicles
- vehicle_documents
- vehicle_passes
- kyc_documents
- kyc_reviews
- kyc_status_history
- stored_files

## Billing/payment

- invoices
- invoice_lines
- payments
- payment_allocations
- payment_intents
- payment_webhook_events
- receipts
- refunds
- disputes
- credits
- resident_billing_queries
- autopay_mandates
- autopay_attempts
- autopay_events
- payment_reconciliations

## Visitors/domestic help

- visitor_profiles
- visitor_visits
- visitor_approvals
- visitor_passes
- visitor_gate_events
- domestic_help_profiles
- domestic_help_assignments
- domestic_help_schedules
- domestic_help_access_events
- domestic_help_status_history

## Complaints

Reuse canonical:

- complaints
- complaint_comments
- complaint_attachments
- complaint_status_history
- complaint_assignments
- complaint_feedback
- complaint_reopen_requests

## Community

- notices
- notice_audiences
- notice_reads
- events
- event_rsvps
- event_waitlist
- polls
- poll_eligibility
- poll_options
- votes
- marketplace_listings
- marketplace_images
- marketplace_conversations
- marketplace_reports
- carpool_trips
- carpool_requests
- carpool_members
- lost_found_posts
- lost_found_matches
- lost_found_claims
- community_reports
- moderation_actions
- blocked_users

## Amenities

- amenities
- amenity_schedules
- amenity_blackouts
- amenity_bookings
- booking_payments
- booking_waitlist
- booking_refunds
- booking_reviews

## Emergency

- sos_alerts
- sos_status_history
- sos_assignments
- resident_emergency_contacts
- emergency_directory_entries
- emergency_procedures
- assembly_points

## Documents/NOCs

- rules
- rule_versions
- society_documents
- document_versions
- resident_document_access
- noc_types
- noc_requirements
- noc_requests
- noc_attachments
- noc_status_history
- noc_certificates
- noc_verification_tokens

## Shared

- notifications
- notification_deliveries
- outbox_events
- idempotency_keys
- audit_logs
- access_logs
- feature_entitlements

---

# 6. Database requirements

- UUID/ULID
- Society ID on tenant data
- UTC
- Society timezone for display/scheduling
- Fixed precision/minor units for money
- RLS
- Unique constraints for votes, active passes, bookings, mandates, payment effects
- Transactions
- Optimistic version
- Soft delete where appropriate
- Immutable financial/audit history
- Indexes on society, unit, user, status, date, due date, event, amenity, category
- Partial indexes for active/current/pending
- Field encryption for sensitive metadata where needed
- Partition high-volume access/payment/audit events if required

---

# 7. API design

Use `/api/v1/resident`.

## Dashboard/context

- `GET /dashboard`
- `GET /capabilities`
- `GET /context`
- `GET /notifications`

## Profile/household

- `GET /profile`
- `PATCH /profile`
- `GET /household`
- `POST /household/members`
- `PATCH /household/members/:id`
- `DELETE /household/members/:id`
- `GET /emergency-contacts`
- `POST /emergency-contacts`
- `PATCH /emergency-contacts/:id`
- `DELETE /emergency-contacts/:id`
- `GET /preferences`
- `PATCH /preferences`

## Vehicles/KYC

- `GET /vehicles`
- `POST /vehicles`
- `PATCH /vehicles/:id`
- `DELETE /vehicles/:id`
- `GET /kyc`
- `POST /kyc/upload-intent`
- `POST /kyc/:id/complete`
- `GET /kyc/:id`

## Bills/payments

- `GET /bills`
- `GET /bills/:billId`
- `POST /payments/intents`
- `GET /payments`
- `GET /payments/:paymentId`
- `GET /receipts`
- `GET /receipts/:receiptId`
- `POST /billing-queries`
- `GET /billing-queries`
- `GET /autopay`
- `POST /autopay/setup`
- `POST /autopay/:id/pause`
- `POST /autopay/:id/resume`
- `POST /autopay/:id/cancel`

## Visitors/domestic help

- `GET /visitors`
- `POST /visitors`
- `GET /visitors/:visitId`
- `POST /visitors/:visitId/approve`
- `POST /visitors/:visitId/reject`
- `POST /visitors/:visitId/revoke`
- `POST /visitors/:visitId/extend`
- `GET /domestic-help`
- `POST /domestic-help`
- `PATCH /domestic-help/:id`
- `POST /domestic-help/:id/pause`
- `POST /domestic-help/:id/resume`
- `POST /domestic-help/:id/revoke`
- `GET /domestic-help/:id/access-history`

## Complaints

- `GET /complaints`
- `POST /complaints`
- `GET /complaints/:id`
- `POST /complaints/:id/comments`
- `POST /complaints/:id/attachments`
- `POST /complaints/:id/withdraw`
- `POST /complaints/:id/reopen`
- `POST /complaints/:id/feedback`

## Community

- `GET /notices`
- `GET /notices/:id`
- `POST /notices/:id/read`
- `POST /notices/:id/acknowledge`
- `GET /events`
- `GET /events/:id`
- `POST /events/:id/rsvp`
- `DELETE /events/:id/rsvp`
- `POST /events/:id/waitlist`
- `GET /polls`
- `GET /polls/:id`
- `POST /polls/:id/votes`
- `GET /marketplace`
- `POST /marketplace`
- `GET /marketplace/:id`
- `PATCH /marketplace/:id`
- `POST /marketplace/:id/pause`
- `POST /marketplace/:id/close`
- `POST /marketplace/:id/report`
- `GET /carpool`
- `POST /carpool`
- `POST /carpool/:id/join`
- `POST /carpool/:id/leave`
- `GET /lost-found`
- `POST /lost-found`
- `POST /lost-found/:id/claim`
- `POST /community/reports`

## Amenities

- `GET /amenities`
- `GET /amenities/:id`
- `GET /amenities/:id/availability`
- `POST /bookings`
- `GET /bookings`
- `GET /bookings/:id`
- `POST /bookings/:id/cancel`
- `POST /bookings/:id/reschedule`
- `POST /bookings/:id/waitlist`
- `POST /amenities/:id/reviews`

## Emergency

- `POST /sos`
- `GET /sos/:id`
- `POST /sos/:id/cancel`
- `POST /sos/:id/false-alarm`
- `GET /emergency-directory`
- `GET /emergency-procedures`

## Documents/NOCs

- `GET /rules`
- `GET /rules/:id`
- `GET /documents`
- `GET /documents/:id`
- `GET /nocs/types`
- `GET /nocs`
- `POST /nocs`
- `GET /nocs/:id`
- `POST /nocs/:id/attachments`
- `POST /nocs/:id/respond`
- `GET /nocs/:id/certificate`

Use OpenAPI 3.1 and typed contracts.

---

# 8. Profile/household logic

- Only authorized household manager can add/remove relationships.
- Invited household users require identity verification/acceptance.
- Ownership/tenancy dates affect eligibility.
- Removal must not erase historical billing/voting/visitor records.
- Unit transfer/move-out triggers permission and cache updates.
- Emergency contacts have consent/privacy controls.
- Sensitive fields are field-level protected.
- All changes are audited.

---

# 9. KYC logic

- Signed upload
- Private storage
- MIME/content validation
- Malware scan
- OCR proposal where used
- Review status
- Replacement
- Expiry
- Access audit
- Retention
- No KYC data in normal logs
- Residents only see their authorized documents
- Family members do not automatically see each other’s KYC

---

# 10. Billing and payment logic

Resident APIs are read/action layers over the canonical finance ledger.

## Bill visibility

- Resolve responsible unit/user relationships.
- Return immutable published bill snapshot.
- Include server-calculated outstanding and as-of time.
- No client-side authoritative totals.

## Payment intent

- Validate eligible bills and amount.
- Prevent paying cancelled/fully paid bills.
- Support partial/combined payment only according to policy.
- Idempotency key.
- Create provider order.
- Store safe identifiers only.

## Webhook

- Raw-body signature verification.
- Persist event before processing.
- Idempotent.
- Out-of-order safe.
- Validate amount/currency/order/society.
- Post payment, allocations, receipt, journal, and outbox atomically.
- Client callback never becomes authoritative.

## Receipt

- Immutable
- Signed/private download
- Matches allocation
- Reissue/void only through controlled finance workflow

## Billing query

- Link bill/payment.
- Category.
- Resident message.
- Attachments.
- Status/timeline.
- Route to Admin support/finance.

---

# 11. Auto-pay logic

Use provider mandate/token APIs. Never store raw card/bank details.

Support:

- Setup intent
- Consent record
- Provider mandate ID
- Status:
  - Pending
  - Active
  - Paused
  - Failed
  - Cancelled
  - Expired
- Maximum amount/approved policy
- Advance notice
- Debit attempt
- Retry
- Failure notification
- Reauthorization
- Pause/resume/cancel

Requirements:

- Step-up auth where appropriate
- Idempotency
- Webhook verification
- Mandate version/history
- Consent snapshot
- No charge above authorized rule
- No duplicate debit
- Reconciliation
- Refund/dispute path
- Audit

---

# 12. Visitor and domestic-help logic

## Visitor pre-approval

- Validate resident/unit permission.
- Create time-bounded pass.
- Generate opaque/signed QR token.
- Entry limit.
- Gate constraints.
- Revoke/extend.
- Share-safe representation.
- Notify Staff when relevant.

## Walk-in approval

- Staff creates pending visit.
- Eligible household approvers receive realtime request.
- First valid decision wins or follow configured rule.
- Approval/rejection is idempotent.
- Approval does not itself record gate entry.
- Staff verifies and enters through canonical VisitorService.

## Domestic help

- Profile and society-specific assignment.
- Resident association.
- KYC/status references where permitted.
- Schedule/gate rules.
- Pause/revoke.
- Access history.
- Multiple households handled safely.
- Privacy and limited data disclosure.
- Staff gate events use same access record.

---

# 13. Complaint logic

Use canonical complaint state machine.

Resident can:

- Create
- View own/eligible complaint
- Add public comments
- Add attachments
- Respond to clarification
- Withdraw in allowed states
- Reopen
- Rate

Resident cannot:

- See internal notes
- Change assignment/SLA
- Force status
- Access other units

SLA, assignment, Staff progress, Admin verification, and notifications use the same complaint record.

---

# 14. Notice/event/poll logic

## Notices

- Audience policy.
- Read receipt.
- Required acknowledgement.
- Attachment permission.
- Version/effective dates.

## Events

- Eligibility.
- Capacity.
- RSVP uniqueness.
- Waitlist order.
- Cancellation.
- Reminder.
- Realtime capacity.
- Attendance.

## Polls

- Eligibility snapshot.
- One vote per eligible user/unit as configured.
- Atomic unique vote.
- Anonymous vote privacy.
- No AI vote.
- No client eligibility trust.
- Results according to visibility policy.
- Quorum/participation.

---

# 15. Marketplace, carpool, and lost & found

## Marketplace

- Society-scoped.
- Listing ownership.
- Status lifecycle.
- Image scanning.
- Privacy-safe contact.
- Reporting/moderation.
- Expiry.
- Rate limits.
- Block list.
- No prohibited items according to product policy.

## Carpool

- Offer/request.
- Route/schedule/seats.
- Join approval.
- Capacity.
- Cancellation.
- Privacy-safe communication.
- Reporting.
- Safety acknowledgment.
- No payment processing unless explicitly designed.

## Lost & Found

- Lost/found posts.
- Matching.
- Claims.
- Private verification answer.
- Resolution.
- Moderation.
- Fraud/abuse controls.

---

# 16. Amenity booking logic

- Eligibility
- Outstanding-dues restrictions if configured
- Operating hours
- Blackouts
- Capacity
- Guest rules
- Pricing/deposit/tax
- Distributed/database lock
- Unique/overlap constraints
- Temporary payment hold
- Hold expiry
- Booking confirmation
- Waitlist
- Cancellation/reschedule
- Refund
- No-show
- Review eligibility only after permitted use
- One review policy if configured
- Moderation

Prevent double booking under concurrency.

---

# 17. SOS and emergency logic

SOS:

- Validate active resident/society.
- Capture alert type/location/note.
- Create alert transaction.
- Dispatch realtime and push to eligible responders.
- Acknowledgement timeout.
- Escalation.
- Status timeline.
- Resident can view their alert.
- Cancellation only in allowed state.
- False alarm flow.
- No silent delete.
- Audit.
- Privacy.

Emergency directory:

- Society-managed entries.
- Version/last updated.
- Resident-visible scope.
- Cache-safe offline payload.
- No secret/internal-only information.

---

# 18. Rules/documents/NOC logic

## Rules/documents

- Published/effective versions.
- Audience.
- Search.
- Signed file access.
- Access logs.
- RAG metadata.
- Archive/version history.

## NOCs

State machine:

- Draft
- Submitted
- Under review
- Information requested
- Approved
- Rejected
- Issued
- Expired
- Cancelled

Support:

- Type/requirements
- Eligibility
- Form schema
- Attachments
- Fees if applicable
- Comments/clarification
- Approval
- Certificate generation
- Signed document
- Verification token/QR
- Expiry
- Reapply
- Audit

Certificate verification endpoint must expose only safe validity information.

---

# 19. Realtime and notifications

Outbox events for:

- Bill
- Payment
- Refund
- Auto-pay
- Visitor request/decision/entry/exit
- Domestic-help access
- Complaint
- Notice
- Event/waitlist
- Poll
- Marketplace/carpool/lost-found interaction
- Booking
- SOS
- KYC
- NOC

Realtime rooms:

- User
- Household/unit where appropriate
- Society
- Resource
- Booking/event
- SOS alert

Reauthorize subscriptions and prevent cross-unit/society leaks.

---

# 20. File security

All KYC, complaint, marketplace, NOC, and document files use:

- Signed upload intent
- Tenant-prefixed key
- MIME/content validation
- Size limit
- Malware scan
- Quarantine
- Checksum
- Private storage
- Short-lived download URL
- Access audit
- Thumbnail
- Retention/deletion
- No large memory buffer
- No public bucket

Visibility class must be explicit.

---

# 21. Security requirements

Test/implement:

- Tenant isolation
- Unit/household ownership
- Field-level authorization
- IDOR/BOLA
- Mass assignment
- Payment replay
- Auto-pay consent
- Visitor QR/OTP replay
- Poll vote duplication
- Booking concurrency
- Marketplace privacy/abuse
- Domestic-help privacy
- KYC privacy
- SOS location privacy
- NOC forgery
- File upload
- SQL/NoSQL injection
- XSS
- SSRF
- CORS
- CSRF where relevant
- Rate limiting
- Brute force
- Session revocation
- Device change
- Audit immutability
- Log redaction
- Dependency/container scanning

---

# 22. Performance and scale

Support platform target:

- 3,000–5,000 concurrent authenticated users
- 250 sustained mixed RPS
- 500–750 burst RPS
- 3,000–5,000 realtime connections

Resident-specific scenarios:

- Morning login/dashboard spike
- Bill publication
- Payment due-date spike
- Payment webhook burst
- Visitor approval spike
- Event RSVP opening
- Poll opening/closing
- Amenity booking opening
- Notice broadcast
- SOS
- Community feed
- Document downloads

Targets excluding third parties:

- Dashboard p95 < 400 ms
- Lists p95 < 300 ms
- Standard writes p95 < 600 ms
- Payment intent internal p95 < 700 ms
- Visitor approval p95 < 500 ms
- Poll vote p95 < 500 ms
- Booking p95 < 700 ms
- SOS internal dispatch < 1 second
- Error rate < 1%
- No duplicate payment/vote/booking/visitor effect
- No cross-tenant response

---

# 23. Tests

Create:

## Identity/profile

- `resident-auth-context.spec`
- `resident-household-permissions.spec`
- `resident-profile.spec`
- `resident-vehicle.spec`
- `resident-kyc-security.spec`

## Payments

- `resident-bills.spec`
- `resident-payment-intent.spec`
- `resident-payment-webhook-idempotency.spec`
- `resident-receipt.spec`
- `resident-autopay-consent.spec`
- `resident-autopay-idempotency.spec`
- `resident-billing-query.spec`

## Visitors/domestic help

- `resident-visitor-preapproval.spec`
- `resident-walkin-approval.spec`
- `resident-visitor-isolation.spec`
- `resident-domestic-help.spec`

## Complaints/community

- `resident-complaint.spec`
- `resident-complaint-field-security.spec`
- `resident-notice.spec`
- `resident-event-rsvp-concurrency.spec`
- `resident-poll-vote-concurrency.spec`
- `resident-marketplace.spec`
- `resident-carpool.spec`
- `resident-lost-found.spec`
- `resident-community-moderation.spec`

## Amenities/emergency/documents

- `resident-booking-concurrency.spec`
- `resident-booking-payment.spec`
- `resident-review.spec`
- `resident-sos.spec`
- `resident-emergency-directory.spec`
- `resident-rules.spec`
- `resident-noc.spec`
- `resident-file-security.spec`
- `resident-realtime-isolation.spec`
- `resident-load.js`

Use real PostgreSQL/Redis integration tests.

---

# 24. CI/CD gates

Fail on:

- Install/lockfile
- Type
- Lint
- Migration
- Tests
- OpenAPI drift
- Tenant/unit isolation
- Payment replay
- Auto-pay duplicate debit
- Poll duplicate vote
- Booking double-book
- Visitor authorization
- KYC/file exposure
- SOS lifecycle
- NOC forgery
- Secret/vulnerability/container scan
- Build

---

# 25. Deliverables

1. Resident backend audit
2. Architecture/threat model
3. Permission matrix
4. Data model/migrations
5. Complete APIs
6. Canonical services
7. Realtime/outbox
8. Workers
9. Payment/auto-pay integration
10. Private files
11. OpenAPI
12. Tests/load
13. Runbooks
14. Backup/restore updates
15. `RESIDENT_BACKEND_TRACEABILITY.md` mapping:
    - Feature 1–57
    - Endpoint
    - Permission
    - Tables
    - State
    - Event/job
    - Test
    - Status

---

# 26. Implementation phases

## Phase 0 — Audit/threat model

## Phase 1 — Resident identity/household foundation

## Phase 2 — Profile, vehicles, KYC

## Phase 3 — Bills, payments, receipts, auto-pay

## Phase 4 — Visitors, domestic help, complaints

## Phase 5 — Notices, events, polls, community

## Phase 6 — Amenities, SOS, documents, NOCs

## Phase 7 — Scale, security, backup/restore, traceability

At each phase report:

- Files/migrations
- Endpoints/services
- Events/jobs
- Tests/results
- Security findings
- Blockers

---

# 27. Definition of done

Complete only when:

- All 57 capabilities are implemented/traced
- Household/unit permissions are correct
- Every resident record is tenant/unit scoped
- Payments are webhook-authoritative and replay-safe
- Auto-pay mandates are consented and duplicate-safe
- Visitor flows share canonical records with Staff/Admin
- Complaints share canonical records with Staff/Admin
- Polls are eligibility and duplicate safe
- Community content is moderated/privacy safe
- Amenity bookings are concurrency safe
- SOS is realtime/auditable
- KYC/files are private/scanned
- NOCs are signed/verifiable
- No production direct Firestore write remains
- OpenAPI/tests/load/backup restore pass
- Zero unresolved P0/P1

Begin with the audit and permission model, not isolated endpoints.


---

# SERO Member / Resident App — Complete Frontend, Backend, Security, and Release QC Prompt

## Role

Act as an independent **Principal QA Architect, Flutter QA Engineer, Application Security Engineer, Payments QA Specialist, Realtime Systems Auditor, Accessibility Specialist, SRE, and Performance Engineer**.

Audit the completed SERO Resident application and backend.

Prove whether:

- All 57 Resident features work
- Every screen uses live data
- Resident UI matches SERO design
- Owner/tenant/family permissions are correct
- Payments and auto-pay are safe
- Visitor and complaint records synchronize with Staff/Admin
- Community modules protect privacy and prevent abuse
- Amenity bookings are concurrency-safe
- SOS works
- KYC/documents/NOCs are secure
- AI Copilot is resident-safe
- The application works for 3,000–5,000 users

Execute tests and report evidence.

---

# 1. Required outputs

Create:

1. `RESIDENT_QC_EXECUTIVE_SUMMARY.md`
2. `RESIDENT_QC_FINDINGS.md`
3. `RESIDENT_FEATURE_TEST_MATRIX_57.md`
4. `RESIDENT_VISUAL_QC_REPORT.md`
5. `RESIDENT_AUTH_HOUSEHOLD_REPORT.md`
6. `RESIDENT_PAYMENT_AUTOPAY_REPORT.md`
7. `RESIDENT_VISITOR_COMPLAINT_REPORT.md`
8. `RESIDENT_COMMUNITY_REPORT.md`
9. `RESIDENT_AMENITY_SOS_DOCUMENT_REPORT.md`
10. `RESIDENT_SECURITY_REPORT.md`
11. `RESIDENT_LIVE_DATA_REPORT.md`
12. `RESIDENT_LOAD_REPORT.md`
13. `RESIDENT_RELEASE_GATE.md`
14. `resident_qc_findings.json`

Every finding:

- ID
- Severity P0/P1/P2/P3
- Feature
- Role/household type
- Screen/endpoint
- File/line
- Evidence
- Reproduction
- Expected
- Actual
- Impact
- Security/privacy/financial impact
- Root cause
- Fix
- Regression test
- Status

---

# 2. Automatic release failure

Fail if:

- Cross-society/unit data leak
- Family member gains unauthorized payment/visitor/vote/NOC rights
- Payment replay duplicates financial effect
- Client callback falsely marks payment success
- Auto-pay charges without valid consent
- Duplicate auto-pay debit
- Visitor approval/QR/OTP bypass
- Resident sees internal complaint notes
- Poll duplicate/unauthorized vote
- Amenity double booking
- KYC/private document exposure
- SOS false success or dispatch failure
- NOC forgery
- Production mock/static data
- Broken login/navigation
- Clean build/test/migration failure
- 3,000–5,000 scale not met
- Backup restore not proven
- Unresolved P0/P1

---

# 3. Clean environment

Run:

- Backend clean install
- TypeScript strict compile
- Lint/tests/build
- Docker/Compose
- Fresh/upgrade migrations
- Workers
- Flutter pub get
- Format
- Analyze
- Unit/widget/golden/integration tests

No forced installs, skipped tests, mock substitution, or forced test exits.

---

# 4. 57-feature matrix

For each feature verify:

- Screen
- Route
- API
- Permission
- Database
- Realtime/notification
- Audit
- Loading
- Empty
- Error
- Offline
- Accessibility
- Responsive
- Test
- Live/static
- Pass/fail

Use the exact 1–57 numbering from the implementation prompts.

---

# 5. Roles and household permission testing

Create:

- Owner
- Tenant
- Family member
- Co-owner
- Authorized household member
- Multiple-unit owner if supported
- Moved-out resident
- Suspended resident
- Pending resident

Test:

- Own profile
- Other household profile
- Family management
- Bill visibility
- Pay permission
- Auto-pay permission
- Visitor approval
- Domestic help
- Vote eligibility
- Booking eligibility
- KYC
- NOC
- Emergency contacts
- Society/unit switch
- Role change
- Occupancy expiry
- Session revocation

No unauthorized data may flash during loading.

---

# 6. Live-data and static-data QC

Search for:

- Mock
- Dummy
- Sample
- Placeholder
- Hard-coded totals
- Static chart data
- Local arrays
- Random values
- Demo notifications
- Silent fallback
- TODO/FIXME/coming soon
- Empty service methods
- Simulated delays

For every visible card, badge, count, graph, status, and list:

- Identify API/query
- Modify database
- Confirm UI updates
- Test empty DB
- Test one/many records
- Test Society A/B
- Test date filters
- Test realtime update

Fail any production static value.

---

# 7. Design and navigation QC

Verify SERO:

- Emerald/navy colors
- Outfit
- Gradients
- Radii
- Spacing
- Status chips
- Header
- Center Pay button
- Bottom navigation
- Drawer/More
- Loading/empty/error

Test:

- Every menu item
- Every quick action
- Every “View All”
- Every card
- Deep links
- Notification routes
- Back navigation
- Invalid/deleted ID
- Wrong role
- App restart

Test sizes:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet
- 1366×768
- 1440×900
- 200% text

Detect overflow, stuck loaders, frozen modal, disabled button not recovering, and inconsistent UI.

---

# 8. Profile, household, vehicle, and KYC QC

Test:

- Profile update
- Email/phone verification
- Add/remove family
- Invite acceptance
- Co-owner/tenant permission
- Emergency contacts
- Move-in/move-out
- Vehicle add/edit/remove
- Duplicate registration
- Parking link
- KYC upload
- MIME spoof
- Malware
- Review
- Rejection/replacement
- Expiry
- Cross-household access
- Signed URL
- Logs/redaction

---

# 9. Bills, payments, receipts, and auto-pay QC

## Bills

- Current/past/overdue/paid/partial
- Components
- Tax
- Penalty
- Credit
- Due date
- Server total
- Date filter
- PDF
- Query/dispute

## Payment

- Full
- Partial
- Combined
- Duplicate tap
- App close
- Redirect failure
- Pending
- Verified success
- Invalid signature
- Replay
- Out-of-order
- Wrong amount/currency/society
- Refund
- Chargeback
- Reconciliation
- Receipt
- Ledger match

## Auto-pay

- Setup
- Consent
- Maximum rule
- Active
- Pause
- Resume
- Cancel
- Duplicate setup
- Duplicate debit
- Provider failure
- Reauthorization
- Upcoming notification
- Insufficient funds
- Refund/dispute
- Revoked permission
- Moved-out resident

Never store raw card/bank credentials.

---

# 10. Visitor and domestic-help QC

Visitor:

- Pre-approve
- Pass
- QR
- OTP
- Revoke
- Extend
- Wrong society/gate
- Replay
- Walk-in approval/reject
- Multiple household approvers
- Entry/exit realtime
- Overstay
- Privacy
- Staff/Admin synchronization

Domestic help:

- Add/edit
- Assignment
- Schedule
- Gate
- Pause/resume/revoke
- Multiple households
- Access history
- Notification
- KYC/privacy
- Staff synchronization

---

# 11. Complaint QC

Test:

- Create
- Category/location
- Attachments
- Assignment
- SLA
- Public chat
- Internal-note privacy
- Clarification
- Withdraw
- Reopen
- Rating
- Realtime
- Staff/Admin synchronization
- Invalid state
- Concurrent update
- Cross-unit/society

---

# 12. Community QC

## Notices

- Audience
- Read
- Acknowledge
- Attachment
- Version
- AI explain

## Events

- Eligibility
- RSVP
- Capacity
- Waitlist
- Cancel
- Reminder
- Calendar
- Concurrent final seat

## Polls

- Eligibility
- One vote
- Unit/user mode
- Anonymous privacy
- Results policy
- Quorum
- Concurrent vote

## Marketplace

- Create/edit/pause/close
- Images
- Contact privacy
- Report/block
- Prohibited content policy
- Moderation
- Expiry

## Carpool

- Offer/request
- Join/leave
- Capacity
- Schedule
- Privacy
- Report/safety

## Lost & Found

- Post
- Match
- Claim
- Verification answer privacy
- Resolve
- Moderation

---

# 13. Amenity QC

Test:

- Browse
- Rules/hours/pricing
- Live availability
- Blackout
- Capacity
- Eligibility
- Dues restriction
- Booking
- Concurrent final slot
- Payment/deposit
- Hold expiry
- Cancel
- Reschedule
- Refund
- Waitlist promotion
- No-show
- Review eligibility/moderation
- Admin synchronization

---

# 14. Emergency QC

SOS:

- Trigger
- Confirmation/hold
- Location
- Dispatch
- Acknowledge
- Responding
- On scene
- Escalate
- Resolve
- False alarm
- Cancel policy
- Notification failure
- Realtime reconnect
- Wrong society
- Privacy
- Audit

Emergency directory:

- Offline cache
- Last-updated
- Phone link
- Procedure
- Assembly point
- Stale data behavior

Measure internal dispatch under load.

---

# 15. Documents and NOC QC

Rules/documents:

- Search
- Effective version
- Archived version
- Signed link
- Cross-role visibility
- AI citation
- Download
- Access log

NOC:

- Type/requirements
- Eligibility
- Form
- Attachment
- Fee
- Submit
- Clarification
- Approve/reject
- Certificate
- QR/token verification
- Expiry
- Reapply
- Forgery/tampering
- Cross-unit access

---

# 16. AI Copilot QC

Test resident context:

- Bill explanation
- Rule
- Notice
- Event
- Amenity
- Complaint
- Visitor
- NOC
- Emergency

Test:

- English/Hindi/Hinglish
- Correct society/unit
- Citation
- No other resident data
- No internal complaint note
- Proposal/confirmation for writes
- No vote action
- No payment success claim
- No SOS without explicit confirmation
- Prompt injection
- Conversation privacy

---

# 17. Realtime, notification, and deep-link QC

Test every event listed in implementation prompt.

Verify:

- Correct user/household
- Correct society
- Duplicate suppression
- Lock-screen redaction
- Foreground/background
- Reconnect
- Last event ID
- Permission revoked
- Moved-out resident
- Deep link
- Deleted record
- Wrong role

---

# 18. Offline QC

Test:

- Cached dashboard
- Notices/rules/emergency
- Complaint draft
- Marketplace/lost-found draft
- Visitor draft
- NOC draft
- App restart
- Pending sync
- Conflict
- Retry
- Role revoked
- Society/unit changed
- Local encryption/cleanup

Ensure no false offline success for payment, vote, booking, SOS, auto-pay, or visitor approval.

---

# 19. Security QC

Cover:

- Tenant/unit isolation
- Household field authorization
- IDOR/BOLA
- Mass assignment
- Payment/autopay replay
- QR/OTP abuse
- Vote replay
- Booking race
- KYC/files
- Marketplace abuse
- Domestic-help privacy
- SOS privacy
- NOC forgery
- SQL/NoSQL injection
- XSS
- SSRF
- Rate limiting
- Session/token
- Log redaction
- Audit immutability
- Dependency/container scan

---

# 20. Accessibility QC

- Screen reader
- Keyboard
- Focus
- Text scaling
- Contrast
- Touch targets
- Form labels/errors
- Payment semantics
- SOS semantics
- Charts
- No color-only status
- Reduced motion
- Hindi/mixed script
- Dialog focus
- Deep-link destination

---

# 21. Performance/load QC

Test:

- 3,000 concurrent users
- 5,000 concurrent users
- 3,000–5,000 realtime connections
- 250 sustained RPS
- 500–750 burst RPS
- Bill publication spike
- Due-date payment spike
- Webhook duplicate burst
- Visitor approval spike
- Event RSVP opening
- Poll opening
- Amenity slot opening
- Notice broadcast
- Community feed
- SOS
- Document downloads
- Four-hour soak
- Redis restart
- API replica termination
- Worker crash

Targets:

- Dashboard p95 < 400 ms
- Lists p95 < 300 ms
- Standard writes p95 < 600 ms
- Payment intent p95 < 700 ms
- Visitor approval p95 < 500 ms
- Vote p95 < 500 ms
- Booking p95 < 700 ms
- SOS internal dispatch < 1 second
- Error rate < 1%
- No duplicate/cross-tenant effect
- No UI freeze

Report p50/p90/p95/p99, RPS, CPU, memory, event loop, DB, Redis, queues, realtime, errors, headroom.

---

# 22. Failure injection

Test:

- PostgreSQL
- Redis
- Worker
- Object storage
- Firebase
- Payment provider
- FCM/email/SMS
- Realtime gateway
- AI provider
- Malware scanner
- PDF/NOC generator
- API crash after commit
- Network timeout
- Duplicate queue
- Clock skew
- Old/new app versions

Verify no false success, corruption, or duplicate effect.

---

# 23. Backup/restore QC

Backup/restore:

- Profiles/households
- Vehicles/KYC
- Bills/payments/receipts/autopay
- Visitors/domestic help
- Complaints
- Community
- Amenities/bookings
- SOS
- Documents/NOCs
- Audit/files

Verify RPO/RTO, links, permissions, ledger, RLS, and referential integrity.

---

# 24. Repository-specific checks

Verify:

1. Dedicated Resident shell exists.
2. Resident roles are normalized.
3. Owner/tenant/family capabilities differ correctly.
4. Center Pay button works.
5. No production mock/static dashboard values.
6. No direct privileged Firestore writes.
7. Bills use backend totals.
8. Payment success is webhook-authoritative.
9. Auto-pay consent is persisted.
10. Visitor records are shared with Staff/Admin.
11. Complaints are shared with Staff/Admin.
12. Internal notes are never resident-visible.
13. Poll vote uniqueness is enforced in DB.
14. Amenity booking has DB concurrency protection.
15. Marketplace contact data is private.
16. SOS cannot be silently dismissed.
17. KYC/documents are private.
18. NOC certificates are verifiable.
19. Realtime rooms are authorized.
20. Existing other-role tests still pass.
21. All 57 features appear in traceability.

---

# 25. Final report

End with:

## Executive verdict

- PASS / PASS WITH P2/P3 EXCEPTIONS / FAIL
- P0/P1/P2/P3
- Tested environment
- Tested scale
- Top blockers

## Feature verdict

All 57 with frontend/backend/security/live-data/test/evidence.

## Design verdict

SERO consistency, responsive, accessibility, stuck states.

## Financial verdict

Bills, payments, receipts, auto-pay, reconciliation.

## Cross-role verdict

Visitors, complaints, parcels/events/amenities synchronization.

## Security verdict

Tenant/unit, household fields, KYC/files, voting, booking, SOS, NOC.

## Performance verdict

3,000/5,000 users, RPS, latency, errors, headroom.

## Blocking actions

Exact files/endpoints/migrations/tests/fixes before release.

Do not state “production ready” without executed evidence.

