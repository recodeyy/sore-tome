# SERO Staff App — Complete Prompt Pack

This pack contains:

1. Staff frontend implementation prompt
2. Staff backend implementation prompt
3. Complete Staff QC, security, offline, performance, and release-audit prompt

The Staff module must use the same SERO design system and canonical cross-role records used by residents and admins.

---

# SERO Staff App — Frontend Master Implementation Prompt

## Role

Act as a **Principal Flutter Architect, Senior Mobile Product Designer, Riverpod Expert, Design-System Engineer, Accessibility Specialist, and Frontline Operations UX Specialist**.

You are working inside the existing **SERO — AI Powered Society Management Platform** repository.

Your task is to design and implement the complete **Staff application experience** for the 32 Staff capabilities, covering:

- Visitor management
- Parcel handling
- Security operations
- SOS response
- Patrol tracking
- Complaint/task execution
- Attendance
- Leave and roster

The Staff application must use the **same SERO design language as the existing Admin application**, but it must be optimized for fast operational use at a society gate, reception desk, security post, facility area, or maintenance location.

Do not create an unrelated generic workforce app. Do not create duplicate data models that conflict with Admin, Resident, Guard, or cross-role modules.

Use:

- One shared source of truth
- One canonical visitor, parcel, complaint, attendance, patrol, and incident record
- Role-aware and assignment-aware screens
- Backend-authorized actions
- Strong offline/retry behavior
- Large touch targets and fast workflows
- The same SERO emerald/navy visual identity

---

# 1. Repository-first instructions

Before implementation, inspect:

- Existing Flutter theme and design tokens
- Admin shell and navigation
- Resident shell
- Any current staff/guard/security screens
- Visitor screens
- Complaint/task screens
- Attendance screens
- Leave screens
- Existing providers and services
- Authentication and role guards
- Shared cross-role models
- Notification routing
- QR/OTP/camera integrations
- Existing mock data
- Direct Firestore reads/writes
- Existing API contracts
- Offline storage
- Push notification setup

Produce first:

1. `STAFF_FRONTEND_AUDIT.md`
2. `STAFF_FEATURE_MATRIX_32.md`
3. `STAFF_SCREEN_MAP.md`
4. `STAFF_ROUTE_MAP.md`
5. `STAFF_COMPONENT_INVENTORY.md`
6. `STAFF_FRONTEND_BACKEND_CONTRACT.md`
7. `STAFF_OFFLINE_SYNC_PLAN.md`

Do not begin bulk UI generation until these documents are complete.

---

# 2. Preserve the SERO design system

Use the existing SERO Admin design system as the source of truth.

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
- Existing warning, success, info, and priority colors

Use the current emerald-to-navy gradient where appropriate.

## 2.2 Typography

Use **Outfit** consistently:

- Page title: 22–24 px, weight 700–800
- Section heading: 16–18 px, weight 600–700
- KPI/stat value: 20–28 px, weight 700–900
- Body: 13–14 px
- Status label: 10–12 px, weight 600–700

## 2.3 Shape and spacing

- Main cards: approximately 24 px radius
- Inputs and primary buttons: approximately 20 px radius
- Status chips: approximately 10–12 px radius
- Page horizontal padding: approximately 20 px
- Generous spacing
- Soft borders
- Subtle shadows
- Large operational touch targets
- High-contrast primary actions

## 2.4 Staff-specific UX rules

Frontline staff may work:

- In sunlight
- With gloves
- Under time pressure
- With unstable network
- While standing or walking
- On lower-end Android devices

Therefore:

- Minimum practical touch target of 48×48
- One dominant action per workflow step
- Avoid long forms
- Use scanner/camera first where appropriate
- Support save-and-resume
- Show large status text
- Keep critical actions reachable with one hand
- Provide vibration/sound feedback where supported and permitted
- Show offline/sync status continuously
- Do not hide urgent SOS or gate tasks inside menus
- Use confirmation only where operationally necessary

---

# 3. Canonical roles and staff types

Support at least:

- `staff`
- `guard`
- `security_manager`
- `facility_manager`
- `maintenance_staff`
- `housekeeping_staff`
- `reception_staff`
- `parcel_desk_staff`
- `supervisor`

Role/sub-role must come from backend membership and permissions.

Do not treat every staff member as having:

- Visitor access
- Incident access
- Payroll access
- All complaint assignments
- All patrol routes
- All society units

Create a backend-provided `StaffCapabilityContext`.

---

# 4. Staff app navigation

Create a dedicated:

- `lib/app/staff_shell.dart`
- `lib/screens/staff/**`
- `lib/providers/staff/**`
- `lib/services/staff/**`
- `lib/models/staff/**`
- `lib/widgets/staff/**`

## 4.1 Mobile bottom navigation

Use five tabs:

1. **Home**
   - Dashboard and shift summary
2. **Gate**
   - Visitors and parcels
3. **Tasks**
   - Complaints and work assignments
4. **Security**
   - SOS, incidents, patrols
5. **More**
   - Attendance, leave, roster, profile, settings

For pure maintenance/facility staff, the Gate tab may be replaced by **Work** through backend feature configuration.

## 4.2 Drawer or More menu

- Home
- Visitors
- Parcels
- Assigned Tasks
- Incidents
- SOS Alerts
- Patrols
- Attendance
- Leave
- Duty Roster
- Shift Handover
- Emergency Contacts
- Profile
- Settings
- Help
- Logout

## 4.3 Persistent operational status

Display where relevant:

- On duty/off duty
- Current shift
- Gate/post/zone assignment
- Offline/sync state
- Active SOS alert
- Unread task count
- Pending parcel count

---

# 5. Complete 32 Staff capabilities

Implement the following 32 capabilities.

## A. Visitor management — 1 to 8

1. View expected/pre-approved visitors for the current gate, date, and shift.
2. Log walk-in visitor arrival.
3. Capture visitor name, phone, purpose, host unit, person count, vehicle, and optional photo/ID metadata.
4. Request resident approval for unapproved visitors.
5. Verify visitor approval using OTP.
6. Scan and validate QR gate pass.
7. Record visitor entry with gate, timestamp, staff member, and verification method.
8. Record visitor exit and complete visitor history, including denied, expired, flagged, and overstayed states.

## B. Parcel handling — 9 to 14

9. Log an incoming parcel/package.
10. Capture courier, tracking/reference number, unit, recipient, parcel type, photo, and remarks.
11. Notify the resident or recipient through in-app/push/SMS according to configured channels.
12. Track parcel status: received, notified, stored, collected, returned, damaged, or unclaimed.
13. Complete parcel handover using recipient OTP, QR, signature, or staff-authorized exception.
14. View pending/unclaimed parcels, reminders, escalations, and parcel history.

## C. Security and incident operations — 15 to 22

15. Create an incident report with category, severity, location, people involved, description, and attachments.
16. Receive real-time SOS alerts.
17. Accept/acknowledge an SOS response assignment.
18. Navigate to or view the alert location and emergency contact instructions.
19. Update SOS state: acknowledged, responding, on scene, resolved, false alarm, escalated.
20. Start and complete assigned patrol routes.
21. Record patrol checkpoints using QR/NFC/manual fallback, timestamp, optional photo, and exception reason.
22. Maintain a shift handover/security log with unresolved incidents, observations, equipment issues, and next-shift acknowledgement.

## D. Complaint and assigned task execution — 23 to 28

23. View assigned complaints/tasks with priority, SLA, location, requester, category, and due time.
24. Accept or reject an assignment with a required reason where permitted.
25. Start, pause, resume, and update task status using the canonical complaint/work-order state machine.
26. Add resident-visible updates and permission-controlled internal notes.
27. Upload before/after photos, videos, documents, completion proof, and material/vendor requirements.
28. Mark work completed, request verification, handle rejection/rework, and view task history.

## E. Attendance, shift, and leave — 29 to 32

29. Check in and check out using permitted method: app, QR, device, geofence, or supervisor entry.
30. Start/end breaks and view current shift, assigned post/zone, lateness, and attendance status.
31. View attendance history, roster, overtime, corrections, and shift swaps where enabled.
32. Request leave, attach supporting documents, track approval, cancel allowed requests, and view leave balance.

---

# 6. Required screens

## 6.1 Staff Home Dashboard

Create `staff_dashboard_screen.dart`.

Header:

- Menu
- Notification icon
- Greeting
- Staff name
- Role/post
- Current date
- On-duty badge
- Offline/sync badge

Primary shift card:

- Shift time
- Assigned gate/post/zone
- Check-in state
- Supervisor
- Next break
- Check-in/check-out action

Urgent area:

- Active SOS alert
- High-priority complaint
- Visitor waiting for approval
- Overstayed visitor
- Unclaimed parcel escalation

KPI cards:

- Visitors today
- Parcels pending
- Assigned tasks
- Patrol progress
- Shift attendance

Quick actions:

- Log visitor
- Scan QR
- Log parcel
- File incident
- Start patrol
- Check in/out

Sections:

- Current tasks
- Expected visitors
- Pending parcel handovers
- Recent security activity
- Shift handover notes

## 6.2 Expected Visitors

- Today/upcoming/inside/overstayed tabs
- Gate/post filter
- Search by visitor, unit, phone, vehicle, pass
- Visitor card with:
  - Name
  - Host/unit
  - Expected time
  - Verification type
  - Vehicle
  - Status
- Scan QR
- Verify OTP
- Open details
- Deny/flag where permitted

## 6.3 Walk-in Visitor Entry

Use a step-by-step workflow:

1. Search host unit/resident
2. Enter visitor details
3. Capture photo/vehicle if required
4. Send approval request
5. Wait for approval with realtime state
6. Verify OTP/QR
7. Confirm entry

Provide:

- Duplicate/active visit warning
- Blacklist/watchlist warning without exposing unnecessary details
- Resident unavailable escalation
- Emergency/service-provider exception workflow
- Offline queue where policy permits
- Clear denial reason

## 6.4 Visitor Detail and Exit

- Visit timeline
- Verification evidence
- Entry gate/time
- Current inside duration
- Host
- Vehicle
- Notes
- Record exit
- Wrong-entry correction with permission
- Incident link
- Overstay alert

## 6.5 QR Scanner

- Camera permission
- Flash
- Manual code fallback
- Invalid/expired/used pass
- Wrong society/gate
- Revoked pass
- Offline behavior
- Success vibration/sound
- No raw sensitive payload shown

## 6.6 Parcel Inbox

Tabs:

- Pending
- Notified
- Ready for collection
- Collected
- Unclaimed
- Returned

Cards show:

- Unit
- Recipient
- Courier
- Received time
- Photo thumbnail
- Notification state
- Age
- Status

Actions:

- Add parcel
- Remind resident
- Start handover
- Mark damaged/returned
- Escalate unclaimed

## 6.7 Add Parcel

Fast form:

- Scan tracking barcode where possible
- Select/search unit
- Recipient
- Courier
- Package type/size
- Photo
- Remarks
- Storage location
- Save

After save:

- Show parcel code
- Notify recipient
- Print/display label if supported
- Open parcel detail

## 6.8 Parcel Handover

- Search parcel or scan parcel QR
- Verify recipient
- OTP/QR/signature method
- Multi-parcel collection
- Authorized family/domestic-help handover rules
- Exception reason
- Confirm collection
- Resident notification
- Handover receipt

## 6.9 Incident Report

Fields:

- Category
- Severity
- Location
- Time
- People involved
- Description
- Photo/video/document
- Emergency services contacted
- Related visitor/vehicle/asset/complaint
- Immediate action taken
- Escalation recipients

Support:

- Draft offline
- Submit
- Supervisor review
- Follow-up
- Restricted/private incident fields

## 6.10 SOS Center

Active alert card:

- Alert type
- Resident/user
- Location
- Time elapsed
- Emergency contacts
- Assigned responders
- Acknowledge
- Navigate/call
- Update status
- Escalate
- Resolve with notes

Requirements:

- Persistent alert banner
- Sound/vibration according to policy
- Cannot be dismissed without acknowledgement
- Multiple alert prioritization
- False alarm workflow
- Realtime updates
- Safe handling of sensitive location

## 6.11 Patrols

- Assigned routes
- Start/end
- Route map/list
- Checkpoints
- Expected time
- Missed checkpoint alerts
- Scan QR/NFC
- Add observation/photo
- Report issue
- Manual fallback with reason
- Progress
- Completion summary

Do not continuously track precise location unless policy and consent require it. Show when location tracking is active.

## 6.12 Shift Handover

- Outgoing shift notes
- Open incidents
- Visitors still inside
- Unclaimed parcels
- Equipment/key status
- Pending complaints
- Patrol exceptions
- Incoming staff acknowledgement
- Supervisor sign-off where configured

## 6.13 Assigned Tasks

Filters:

- Today
- High priority
- SLA risk
- In progress
- Waiting
- Verification
- Completed

Task card:

- ID
- Category
- Unit/location
- Priority
- SLA timer
- Assignment
- Status
- Requester contact based on permission

## 6.14 Task Detail

- Description
- Timeline
- Location
- Requester-visible messages
- Internal notes
- Assignment
- SLA
- Before/after evidence
- Materials/vendor
- Start/pause/resume
- Complete
- Verification/rework
- Related asset/work order

## 6.15 Attendance

- Current shift
- Check-in/out
- Break
- Method
- Location/post
- Attendance history
- Late/missed status
- Correction request
- Overtime
- Supervisor notes where visible

## 6.16 Leave and Roster

- Duty roster calendar/list
- Shift detail
- Leave balance
- Leave request
- Leave type
- Date/time
- Reason
- Attachment
- Approval timeline
- Cancel
- Shift swap where enabled
- Conflict warning

---

# 7. Offline-first behavior

Staff workflows must remain safe under weak connectivity.

Support offline drafts/queued actions for approved operations such as:

- Visitor details before final verification
- Parcel intake
- Incident draft
- Patrol checkpoint evidence
- Complaint update
- Attendance attempt
- Shift handover draft

Rules:

- Never pretend an OTP/QR/server authorization succeeded while offline.
- Mark records clearly as `Pending Sync`.
- Show last sync time.
- Encrypt local data.
- Limit retention.
- Retry with idempotency key.
- Detect conflicts.
- Require user resolution where automatic merge is unsafe.
- Do not duplicate visitor entry, attendance, parcel, or task updates.
- Clear local sensitive data after successful sync according to policy.

---

# 8. Shared cross-role integration

The Staff app must use the same canonical records as:

- Admin visitor management
- Resident visitor approval
- Admin parcel reports
- Resident parcel notifications
- Admin complaint assignment
- Resident complaint timeline
- Admin staff/attendance
- Admin incident/security dashboard
- Asset maintenance/work orders
- Parking/vehicle registry

Do not create separate staff-only copies.

Example:

- Resident approves visitor.
- The same visit becomes visible at the assigned gate.
- Staff verifies and records entry.
- Admin sees live status.
- Resident receives entry notification.
- Staff records exit.
- All actors see the same permitted timeline.

---

# 9. State management

Use Riverpod consistently.

Create providers/notifiers for:

- Staff session/capabilities
- Current shift
- Attendance
- Expected visitors
- Active visitors
- Visitor approval stream
- QR/OTP verification
- Parcels
- Parcel handover
- SOS alerts
- Incident reports
- Patrol routes/checkpoints
- Assigned complaints/tasks
- Evidence uploads
- Roster
- Leave
- Offline queue
- Sync state
- Notification routing

Requirements:

- Cursor pagination
- Debounced search
- Cancellation
- Auto-dispose where appropriate
- Realtime subscription lifecycle
- Request deduplication
- Optimistic update only when safe
- Rollback
- State clearing on logout, role change, society change, and post reassignment

---

# 10. Camera, QR, OTP, location, and media

## QR

- Scan only signed/backend-issued payload
- Never trust client-decoded fields alone
- Send token to backend for validation
- Handle expiry, revocation, replay, wrong society, wrong gate

## OTP

- Mask phone
- Resend cooldown
- Attempt limit
- Expiry
- Server validation
- No OTP in logs
- No offline success

## Camera/media

- Compress safely
- Preserve enough quality for evidence
- Strip unnecessary metadata
- Upload through signed URL
- Show scan/upload/processing state
- Allow retake
- Do not hold large base64 payloads in memory

## Location

- Ask only when needed
- Explain purpose
- Respect policy
- Show active tracking
- Avoid background tracking unless explicitly required
- Provide manual fallback with reason

---

# 11. Notifications

Handle:

- Visitor approval received
- Visitor denied
- Visitor overstayed
- Parcel received
- Parcel reminder
- SOS alert
- SOS reassignment
- High-priority complaint
- SLA risk
- Patrol start/missed checkpoint
- Shift starting
- Leave approved/rejected
- Roster changed
- Incident follow-up

Deep-link to the exact record.

Deduplicate notifications.

Do not expose sensitive detail on lock screen beyond policy.

---

# 12. Responsive and device behavior

Primary target:

- Android phone
- Lower/mid-range devices
- Portrait orientation

Also support:

- iPhone
- Tablet security desk
- Web/desktop supervisor view where applicable

Test:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet portrait/landscape
- 1366×768

Use responsive cards and split views on tablet/desktop.

---

# 13. Accessibility

- WCAG 2.1 AA where applicable
- Large touch targets
- Screen-reader labels
- High contrast
- Text scaling
- No color-only status
- Haptic feedback paired with visible/text feedback
- Keyboard support on tablet/web
- Accessible scanner instructions
- SOS alert semantics
- Logical focus order
- Reduced motion
- Multilingual text rendering where supported

---

# 14. Frontend security

- No service account secrets
- No raw QR trust
- No OTP logging
- No public file URLs
- No privileged direct Firestore write
- No hidden-button authorization
- No unnecessary resident PII
- No unrestricted visitor history
- No other staff payroll/private data
- Clear cached data on logout/post/society change
- Encrypt offline queue
- Redact lock-screen notifications
- Use backend request ID in errors
- Step-up authentication UI for sensitive corrections/overrides where required

---

# 15. Frontend tests

Create:

## Navigation and role

- Staff shell
- Guard subset
- Facility staff subset
- Unauthorized role
- Role change
- Society/post change

## Visitor

- Expected visitor
- Walk-in approval
- OTP
- QR
- Invalid/expired/replayed pass
- Entry
- Exit
- Overstay
- Denial
- Offline behavior
- Duplicate prevention

## Parcel

- Intake
- Photo/upload
- Notification state
- Handover OTP/QR/signature
- Multi-parcel
- Unclaimed
- Returned/damaged
- Offline sync

## Security

- Incident draft/submit
- SOS alert
- Acknowledge
- Status flow
- Patrol start
- Checkpoint
- Missed checkpoint
- Handover

## Tasks

- Assigned list
- Accept/reject
- Start/pause/resume
- Public/internal note
- Proof upload
- Complete
- Verification/rework
- SLA state

## Attendance/leave

- Check-in/out
- Duplicate attempt
- Break
- Offline attempt
- Roster
- Leave request
- Conflict
- Cancel
- Approval state

## Quality

- Loading/empty/error/offline
- Accessibility
- Responsive
- Golden tests
- Deep links
- Push routing
- State clearing
- Sync conflict

Golden screens:

- Staff dashboard
- Visitor approval waiting
- QR result
- Parcel inbox
- Parcel handover
- Active SOS
- Patrol progress
- Incident form
- Task detail
- Attendance
- Leave request
- Offline queue

---

# 16. Routes

Use a coherent hierarchy:

- `/staff`
- `/staff/dashboard`
- `/staff/visitors`
- `/staff/visitors/new`
- `/staff/visitors/scan`
- `/staff/visitors/:id`
- `/staff/parcels`
- `/staff/parcels/new`
- `/staff/parcels/:id`
- `/staff/parcels/:id/handover`
- `/staff/sos`
- `/staff/sos/:id`
- `/staff/incidents`
- `/staff/incidents/new`
- `/staff/incidents/:id`
- `/staff/patrols`
- `/staff/patrols/:id`
- `/staff/handover`
- `/staff/tasks`
- `/staff/tasks/:id`
- `/staff/attendance`
- `/staff/roster`
- `/staff/leave`
- `/staff/leave/new`
- `/staff/profile`
- `/staff/settings`

Routes must be permission-aware.

---

# 17. Deliverables

1. Staff frontend audit
2. 32-feature matrix
3. Screen and route maps
4. Dedicated Staff shell
5. Complete screens
6. Shared cross-role integration
7. Riverpod providers/services/models
8. Offline queue and conflict UX
9. QR/OTP/camera/location integration
10. Responsive/accessibility support
11. Tests
12. No production mock fallback
13. No privileged direct Firestore writes
14. `STAFF_FRONTEND_TRACEABILITY.md` mapping:
    - Feature 1–32
    - Staff type
    - Screen
    - Route
    - Provider
    - Service
    - API
    - Test
    - Status

---

# 18. Implementation sequence

## Phase 0 — Audit

- Inspect repository
- Map staff roles
- Map shared cross-role records
- Map existing APIs and mocks
- Define offline strategy

## Phase 1 — Staff foundation

- Staff shell
- Capabilities
- Navigation
- Session/post/shift state
- Shared operational components
- Offline queue

## Phase 2 — Visitor management

- Expected list
- Walk-in
- Approval
- OTP
- QR
- Entry/exit
- Overstay

## Phase 3 — Parcel handling

- Intake
- Notification
- Tracking
- Handover
- Unclaimed/return

## Phase 4 — Security

- Incidents
- SOS
- Patrols
- Shift handover

## Phase 5 — Tasks

- Assigned complaints
- Status
- Notes
- Proof
- Verification/rework

## Phase 6 — Attendance and leave

- Check-in/out
- Break
- Roster
- Corrections
- Leave

## Phase 7 — Hardening

- Offline/conflicts
- Push/deep links
- Accessibility
- Responsive
- Golden/contract tests
- Remove mocks
- Traceability

At the end of each phase report:

- Files changed
- Screens/routes
- APIs connected
- Tests/results
- Offline cases covered
- Security findings
- Remaining blockers

---

# 19. Definition of done

Complete only when:

- All 32 Staff capabilities are implemented and traced
- The app uses the same SERO design system
- Staff has a dedicated shell
- Role/post-specific permissions work
- Visitor entry/exit is canonical across resident/admin/staff
- OTP/QR validation is server-authoritative
- Parcel handover is verified and auditable
- SOS cannot be silently dismissed
- Patrol checkpoints are tamper-resistant
- Complaint/task updates use canonical state machines
- Evidence uploads are private and secure
- Attendance is duplicate-safe
- Leave/roster are synchronized
- Offline queued actions are visible and idempotent
- No production mock data remains
- No privileged direct Firestore writes remain
- Flutter analyze and all tests pass
- Existing Admin/Resident/Super Admin/Cross-role flows remain functional

Begin with the audit and feature matrix. Do not begin by creating visually disconnected screens.


---

# SERO Staff App — Backend Master Implementation Prompt

## Role

Act as a **Principal Backend Architect, Staff TypeScript Engineer, Security Systems Engineer, Workforce Operations Architect, Database Architect, and SRE**.

You are working inside the existing SERO backend.

Your task is to implement the complete backend for the 32 Staff capabilities covering:

- Visitors
- Parcels
- Incidents
- SOS
- Patrols
- Shift handover
- Assigned complaints/tasks
- Evidence uploads
- Attendance
- Roster
- Leave

The Staff backend must reuse the same canonical cross-role domain services and PostgreSQL records used by residents and admins.

Do not create separate staff-only visitor, complaint, attendance, or parcel databases.

The system must support the wider SERO target of 2,000–3,000 concurrently active users and remain reliable under gate-entry spikes, SOS events, shift changes, and network retries.

---

# 1. Repository-first audit

Inspect:

- Existing auth/RBAC
- Staff/guard role handling
- Visitor routes/services
- Parcel code
- Complaint/task routes
- Staff attendance/leave/payroll code
- Incident/SOS/patrol code
- Firestore usage
- PostgreSQL migrations
- Redis/BullMQ
- Realtime/outbox
- FCM
- File storage
- QR/OTP utilities
- Payment/visitor parking integrations
- Flutter Staff frontend contract
- Existing tests
- Firestore rules
- Rate limiting
- Audit logs

Produce:

1. `STAFF_BACKEND_AUDIT.md`
2. `STAFF_DOMAIN_ARCHITECTURE.md`
3. `STAFF_PERMISSION_MATRIX.md`
4. `STAFF_API_CONTRACT.md`
5. `STAFF_DATA_MODEL.md`
6. `STAFF_OFFLINE_IDEMPOTENCY_DESIGN.md`
7. `STAFF_THREAT_MODEL.md`

Do not start bulk implementation before the audit.

---

# 2. Architecture rules

Use the approved SERO backend foundation:

- Node.js LTS
- Strict TypeScript
- Express or existing compatible framework
- PostgreSQL source of truth
- PostgreSQL RLS
- Redis
- Redlock
- BullMQ
- Firebase Auth
- FCM
- Private object storage
- Outbox events
- OpenAPI 3.1
- Pino
- OpenTelemetry
- Sentry
- Docker
- CI/CD

Use one canonical domain service for each shared entity:

- `VisitorService`
- `ParcelService`
- `IncidentService`
- `SOSService`
- `PatrolService`
- `ShiftHandoverService`
- `ComplaintService`
- `WorkOrderService`
- `AttendanceService`
- `RosterService`
- `LeaveService`
- `NotificationService`
- `FileService`

Admin, Resident, Staff, Guard, AI tools, and realtime handlers must call the same services.

---

# 3. Staff authorization model

Support roles/sub-roles:

- `staff`
- `guard`
- `security_manager`
- `facility_manager`
- `maintenance_staff`
- `housekeeping_staff`
- `reception_staff`
- `parcel_desk_staff`
- `supervisor`

Permissions:

- `staff.dashboard.read`
- `visitor.expected.read`
- `visitor.create`
- `visitor.request_approval`
- `visitor.verify_otp`
- `visitor.verify_qr`
- `visitor.entry.record`
- `visitor.exit.record`
- `visitor.flag`
- `parcel.read`
- `parcel.create`
- `parcel.notify`
- `parcel.handover`
- `parcel.exception`
- `incident.create`
- `incident.read_assigned`
- `incident.update`
- `sos.receive`
- `sos.acknowledge`
- `sos.update`
- `sos.resolve`
- `patrol.read_assigned`
- `patrol.start`
- `patrol.checkpoint`
- `patrol.complete`
- `handover.create`
- `handover.acknowledge`
- `complaint.read_assigned`
- `complaint.accept`
- `complaint.update_status`
- `complaint.comment_public`
- `complaint.note_internal`
- `complaint.upload_proof`
- `complaint.complete`
- `attendance.check_in`
- `attendance.check_out`
- `attendance.break`
- `attendance.read_own`
- `attendance.correction_request`
- `roster.read_own`
- `leave.read_own`
- `leave.request`
- `leave.cancel`

Authorization must also evaluate:

- Society
- Active employment
- Current role
- Assigned gate/post/zone
- Current shift
- Task assignment
- Incident/SOS assignment
- Resource state
- Feature entitlement
- Step-up authentication
- Supervisor override

Do not rely only on role strings.

---

# 4. Complete 32 Staff backend capabilities

Implement:

## Visitor — 1 to 8

1. Expected/pre-approved visitor list scoped to society, gate, shift, and time.
2. Walk-in visitor registration.
3. Visitor identity/purpose/host/vehicle/photo metadata.
4. Resident approval request and realtime status.
5. OTP verification.
6. QR gate pass verification.
7. Entry recording.
8. Exit, denial, expiration, flagging, overstay, and history.

## Parcel — 9 to 14

9. Parcel intake.
10. Courier/tracking/unit/recipient/photo/storage metadata.
11. Resident notification.
12. Parcel lifecycle status.
13. Verified handover.
14. Unclaimed/return/damage/reminder/history.

## Security — 15 to 22

15. Incident creation.
16. SOS reception.
17. SOS acknowledgement/assignment.
18. Location and emergency instruction access.
19. SOS state updates and resolution.
20. Patrol route start/complete.
21. Patrol checkpoint recording.
22. Shift handover log and acknowledgement.

## Complaints/tasks — 23 to 28

23. Assigned task list.
24. Accept/reject assignment.
25. Status transitions.
26. Public/internal notes.
27. Evidence/material/vendor requirements.
28. Completion, verification, rejection, and rework.

## Attendance/leave — 29 to 32

29. Check-in/check-out.
30. Break and current shift/post state.
31. Attendance history, correction, roster, overtime, and shift swap if enabled.
32. Leave request, attachment, approval tracking, cancellation, and balance.

---

# 5. Required data model

Use or extend canonical tables.

## Staff identity and assignments

- users
- society_memberships
- staff_profiles
- staff_roles
- staff_permissions
- staff_post_assignments
- staff_zone_assignments
- staff_devices
- staff_emergency_contacts

## Visitors

- visitor_profiles
- visitor_visits
- visitor_hosts
- visitor_approvals
- visitor_verifications
- visitor_gate_events
- visitor_passes
- visitor_vehicles
- visitor_flags
- visitor_overstay_events

## Parcels

- parcels
- parcel_status_history
- parcel_notifications
- parcel_handover_attempts
- parcel_handovers
- parcel_exceptions
- parcel_reminders
- parcel_storage_locations

## Security

- incidents
- incident_participants
- incident_attachments
- incident_status_history
- sos_alerts
- sos_assignments
- sos_status_history
- sos_escalations
- patrol_routes
- patrol_route_checkpoints
- patrol_assignments
- patrol_runs
- patrol_checkpoint_events
- patrol_exceptions
- shift_handover_logs
- shift_handover_items
- shift_handover_acknowledgements

## Complaints/tasks

Reuse canonical:

- complaints
- complaint_assignments
- complaint_comments
- complaint_internal_notes
- complaint_attachments
- complaint_status_history
- complaint_verification
- complaint_rework
- work_orders
- work_order_materials
- work_order_vendors

## Attendance and leave

- shift_templates
- duty_rosters
- roster_assignments
- attendance_entries
- attendance_breaks
- attendance_attempts
- attendance_adjustments
- attendance_correction_requests
- overtime_entries
- shift_swap_requests
- leave_types
- leave_balances
- leave_requests
- leave_attachments
- leave_status_history

## Shared

- stored_files
- notifications
- notification_deliveries
- outbox_events
- idempotency_keys
- audit_logs
- access_logs
- offline_sync_commands
- device_sync_state

---

# 6. Database requirements

- UUID/ULID
- Society ID on tenant-owned records
- UTC timestamps
- Society timezone for display and shift calculation
- Geospatial type where needed
- Fixed state machines
- Unique constraints for active visitor entry, pass usage, parcel handover, attendance session, and checkpoint
- Optimistic version
- Soft delete where audit requires
- Immutable event/history tables
- RLS
- Indexes on society, gate, status, time, unit, tracking number, assignment, shift, and due time
- Partial indexes for active/inside/pending records
- Partition high-volume gate/access events if needed
- Transactions for multi-record workflows

---

# 7. API design

Use `/api/v1/staff`.

## Dashboard

- `GET /dashboard`
- `GET /capabilities`
- `GET /current-shift`
- `GET /sync-state`

## Visitors

- `GET /visitors/expected`
- `GET /visitors/inside`
- `GET /visitors/:visitId`
- `POST /visitors`
- `POST /visitors/:visitId/request-approval`
- `POST /visitors/:visitId/verify-otp`
- `POST /visitors/verify-qr`
- `POST /visitors/:visitId/entry`
- `POST /visitors/:visitId/exit`
- `POST /visitors/:visitId/deny`
- `POST /visitors/:visitId/flag`
- `POST /visitors/:visitId/correct`
- `GET /visitors/search`

## Parcels

- `GET /parcels`
- `GET /parcels/:parcelId`
- `POST /parcels`
- `POST /parcels/:parcelId/notify`
- `POST /parcels/:parcelId/remind`
- `POST /parcels/:parcelId/handover-intent`
- `POST /parcels/:parcelId/verify-otp`
- `POST /parcels/:parcelId/verify-qr`
- `POST /parcels/:parcelId/handover`
- `POST /parcels/:parcelId/mark-damaged`
- `POST /parcels/:parcelId/return`
- `POST /parcels/:parcelId/escalate-unclaimed`

## Incidents/SOS

- `GET /incidents`
- `POST /incidents`
- `GET /incidents/:incidentId`
- `PATCH /incidents/:incidentId`
- `POST /incidents/:incidentId/comment`
- `POST /incidents/:incidentId/escalate`
- `GET /sos`
- `GET /sos/:alertId`
- `POST /sos/:alertId/acknowledge`
- `POST /sos/:alertId/status`
- `POST /sos/:alertId/escalate`
- `POST /sos/:alertId/resolve`

## Patrols/handover

- `GET /patrols`
- `GET /patrols/:assignmentId`
- `POST /patrols/:assignmentId/start`
- `POST /patrols/:assignmentId/checkpoints/:checkpointId`
- `POST /patrols/:assignmentId/exception`
- `POST /patrols/:assignmentId/complete`
- `GET /shift-handover/current`
- `POST /shift-handover`
- `POST /shift-handover/:id/acknowledge`

## Tasks

- `GET /tasks`
- `GET /tasks/:taskId`
- `POST /tasks/:taskId/accept`
- `POST /tasks/:taskId/reject`
- `POST /tasks/:taskId/status`
- `POST /tasks/:taskId/public-comment`
- `POST /tasks/:taskId/internal-note`
- `POST /tasks/:taskId/evidence`
- `POST /tasks/:taskId/material-request`
- `POST /tasks/:taskId/vendor-request`
- `POST /tasks/:taskId/complete`
- `POST /tasks/:taskId/request-verification`

## Attendance/leave

- `GET /attendance/current`
- `GET /attendance/history`
- `POST /attendance/check-in`
- `POST /attendance/check-out`
- `POST /attendance/break/start`
- `POST /attendance/break/end`
- `POST /attendance/corrections`
- `GET /roster`
- `POST /roster/swap-requests`
- `GET /leave`
- `GET /leave/balance`
- `POST /leave`
- `POST /leave/:leaveId/cancel`

## Upload/sync

- `POST /uploads/intent`
- `POST /uploads/:fileId/complete`
- `POST /sync/commands`
- `GET /sync/commands/:commandId`

Use OpenAPI 3.1.

---

# 8. Visitor workflow

## 8.1 Pre-approved visitor

- Resident creates approval/pass.
- Backend generates signed, random, short-lived QR token.
- Staff scans QR.
- Backend verifies:
  - Signature
  - Pass status
  - Society
  - Gate scope
  - Time window
  - Use count
  - Visitor/host state
  - Revocation
- Staff confirms identity where required.
- Entry transaction:
  - Locks visit
  - Prevents duplicate active entry
  - Records gate/staff/time/method
  - Emits outbox event
  - Notifies host
- Exit closes the same visit.

## 8.2 Walk-in visitor

- Staff creates pending visit.
- Backend sends host approval request.
- Host approves/rejects.
- Realtime event updates gate.
- OTP is generated server-side.
- Store hash, expiry, attempt count, resend count.
- OTP verification is rate-limited and replay-safe.
- Approval/OTP does not itself record entry.
- Staff records entry after visual confirmation.

## 8.3 Security

- Do not expose resident phone unnecessarily.
- Search must be scoped and audited.
- Flag/watchlist details must be redacted by permission.
- Correction requires supervisor permission/reason.
- Overstay worker checks active visits.
- Emergency exceptions require policy, reason, and audit.

---

# 9. QR pass security

QR payload must not contain trusted plaintext business data.

Use:

- Random opaque token or signed compact token
- Short expiry
- Society/gate/use constraints
- Server-side pass record
- Revocation
- Replay protection
- Atomic use counter
- Clock-skew tolerance
- Key rotation
- Audit

Reject:

- Wrong society
- Wrong gate
- Expired
- Revoked
- Already used beyond allowance
- Unknown pass
- Tampered token

Do not allow offline QR acceptance unless an explicitly approved cryptographic offline-verification design exists with later reconciliation and risk controls.

---

# 10. Parcel workflow

Parcel creation:

- Validate staff post/permission.
- Search/select unit.
- Store parcel metadata and private photo.
- Create immutable status history.
- Notify eligible recipients asynchronously.
- Generate internal parcel code/QR.

Handover:

- Create handover intent.
- Validate parcel is collectible.
- Resolve recipient/authorized collector.
- Verify OTP/QR/signature/authorized exception.
- Lock parcel row.
- Record exactly one successful handover.
- Store staff, collector, method, timestamp, signature/evidence.
- Update status.
- Notify recipient.
- Audit.

Exception handover requires:

- Permission
- Reason
- Optional supervisor approval
- Strong audit

Unclaimed worker:

- Reminder schedule
- Escalation
- Return policy
- No duplicate notifications

---

# 11. Incident and SOS workflow

## Incidents

State machine:

- Draft
- Submitted
- Under review
- Action required
- Resolved
- Closed
- Reopened

Support:

- Category
- Severity
- Location
- Restricted visibility
- Attachments
- Linked visitor/vehicle/asset/task
- Follow-up
- Supervisor actions
- Audit

## SOS

State machine:

- Triggered
- Dispatched
- Acknowledged
- Responding
- On scene
- Escalated
- Resolved
- False alarm
- Cancelled by authorized actor

Requirements:

- Realtime fan-out
- Assignment based on society/zone/shift
- Acknowledgement timeout
- Escalation ladder
- Duplicate alert handling
- Geolocation privacy
- Emergency contact access only during valid alert
- Persistent timeline
- Notification deduplication
- Staff cannot silently delete SOS
- Resolution requires notes
- False-alarm classification and audit
- Optional emergency service integration adapter

---

# 12. Patrol workflow

- Admin defines route and checkpoints.
- Staff receives assignment.
- Start validates shift/post/time.
- Each checkpoint event includes:
  - Assignment
  - Checkpoint
  - Timestamp
  - Verification method
  - Device
  - Optional location
  - Photo/observation
  - Offline command ID
- Enforce checkpoint uniqueness/rules.
- Flag impossible sequence/time/location anomalies.
- Manual fallback requires reason.
- Missed checkpoint worker creates alert.
- Completion summarizes coverage and exceptions.
- Supervisor can review but cannot silently alter original checkpoint evidence.

Avoid unnecessary continuous tracking.

---

# 13. Shift handover

Create one handover record per post/shift transition.

Include:

- Active visitors
- Overstays
- Pending parcels
- Incidents
- SOS follow-ups
- Patrol exceptions
- Pending tasks
- Equipment/key observations
- Free-text notes
- Outgoing staff
- Incoming staff
- Acknowledgement time
- Supervisor escalation

Snapshot or reference current items consistently.

Handover must be auditable and cannot erase underlying records.

---

# 14. Complaint/task workflow

Reuse the canonical complaint/work-order service.

Staff may only access:

- Assigned tasks
- Tasks in authorized zone/category
- Fields required to perform work

State machine:

- Assigned
- Accepted
- In progress
- Paused
- Waiting on resident
- Waiting on material
- Waiting on vendor
- Completed
- Awaiting verification
- Verified
- Rework requested
- Closed
- Cancelled

Requirements:

- State transition rules
- SLA pause/resume
- Public/internal note separation
- Assignment lock/version
- Evidence scanning
- Completion proof
- Verification actor
- Rework reason
- Resident/admin notifications
- Material/vendor requests
- No access to unrelated resident data

---

# 15. Attendance workflow

## Check-in

Validate:

- Active staff
- Scheduled/allowed shift
- Society/post
- Method
- Device trust if configured
- QR/geofence if configured
- No active attendance session
- Grace period
- Supervisor override if needed

Use idempotency.

## Check-out

- Requires active session
- Closes open break
- Calculates worked duration
- Flags early/late/manual exception
- Emits payroll/attendance event
- Prevents duplicate checkout

## Break

- One active break
- Shift required
- Start/end history
- Policy limits
- Audit corrections

## Offline attempts

- Store server-issued or client-generated idempotency key
- Accept/reject on sync based on policy
- Preserve original device timestamp and server receipt timestamp
- Detect tampering/clock drift
- Never silently backdate final attendance without rule

## Corrections

- Request
- Reason/evidence
- Approval
- Immutable before/after
- Payroll recalculation event

---

# 16. Roster, leave, and shift swap

Roster:

- Templates
- Assignments
- Post/zone
- Conflicts
- Rest-period rules
- Publication/versioning
- Change notifications

Leave:

- Type
- Balance
- Dates/times
- Reason
- Attachment
- Approval workflow
- Conflict with roster
- Cancellation
- Partial leave
- Balance transaction
- Status history

Shift swap:

- Eligible counterpart
- No conflict
- Supervisor approval
- Both staff acknowledgement
- Roster update transaction
- Notification

---

# 17. Offline command API

Implement a safe command queue for limited operations.

Each command includes:

- Command ID/idempotency key
- Device ID
- User
- Society
- Resource type
- Action
- Client timestamp
- Payload
- File references
- App version
- Sequence

Backend:

- Authenticates current session
- Rechecks permission
- Deduplicates
- Validates state/version
- Executes through canonical domain service
- Returns:
  - Accepted
  - Rejected
  - Conflict
  - Requires review
- Stores processing result

Do not accept offline OTP/QR authorization as final success.

---

# 18. Realtime and notifications

Use outbox events for:

- Visitor approval
- Visitor entry/exit
- Overstay
- Parcel notification/handover
- SOS
- Incident update
- Patrol missed checkpoint
- Task assignment/status
- Attendance/roster/leave
- Shift handover

Realtime rooms:

- Society
- Gate/post
- Zone
- Staff user
- Assignment
- SOS alert

Reauthorize subscriptions.

Support reconnect/last event ID.

---

# 19. File and evidence security

Use private object storage.

- Signed upload intent
- Content MIME validation
- File size
- Malware scan
- Tenant-prefixed key
- Checksum
- Private download
- Short-lived signed URL
- Access audit
- Thumbnail
- Retention
- Redaction where required
- No public bucket
- No large in-memory buffer
- No base64 API for production evidence

Incident and complaint evidence may have restricted visibility classifications.

---

# 20. Audit requirements

Audit:

- Visitor create/approval request/verify/entry/exit/deny/flag/correct
- Parcel create/notify/handover/exception/return
- Incident submit/update
- SOS acknowledge/status/escalate/resolve
- Patrol checkpoint/manual fallback
- Shift handover
- Task status/note/proof/completion
- Attendance/break/correction
- Leave/shift swap

Include:

- Actor
- Society
- Role/post
- Resource
- Before/after
- Reason
- Request ID
- Device
- IP
- Timestamp
- Offline command ID
- Result

---

# 21. Performance and scale

Target:

- 3,000 concurrent authenticated SERO users
- 250 sustained mixed RPS
- 500 RPS burst
- 3,000 realtime connections

Staff-specific tests:

- Morning gate spike
- School bus/service staff spike
- Delivery peak
- Shift change attendance spike
- SOS broadcast
- Patrol sync after outage
- Complaint evidence uploads
- Parcel handover queue

Targets excluding external providers:

- Staff dashboard p95 under 400 ms
- Visitor search/list p95 under 300 ms
- QR/OTP validation p95 under 500 ms
- Entry/exit p95 under 500 ms
- Parcel intake/handover p95 under 600 ms
- SOS dispatch internal processing under 1 second
- Attendance p95 under 500 ms
- Error rate under 1%
- No duplicate visitor entry, parcel handover, checkpoint, or attendance

---

# 22. Security requirements

Test and implement:

- Tenant isolation
- Gate/post/assignment scoping
- BOLA/IDOR
- Field-level access
- QR forgery/replay
- OTP guessing/replay/resend abuse
- Visitor enumeration
- Resident privacy
- Parcel privacy
- Staff privacy
- SOS location privacy
- Patrol tampering
- Attendance spoofing
- Device/session revocation
- File upload
- Malware
- SQL injection
- NoSQL injection during migration
- Rate limiting
- Lock-screen notification redaction
- Offline queue tampering
- Clock manipulation
- Location spoof detection where used
- Audit immutability
- Secret scanning
- Dependency/container scanning

---

# 23. Tests

Create:

- `staff-auth-permission.spec`
- `staff-post-zone-scope.spec`
- `visitor-expected-list.spec`
- `visitor-walkin-approval.spec`
- `visitor-otp-security.spec`
- `visitor-qr-security.spec`
- `visitor-entry-exit-idempotency.spec`
- `visitor-overstay.spec`
- `parcel-intake.spec`
- `parcel-handover-idempotency.spec`
- `parcel-exception.spec`
- `incident-security.spec`
- `sos-lifecycle.spec`
- `sos-escalation.spec`
- `patrol-checkpoint.spec`
- `patrol-offline-sync.spec`
- `shift-handover.spec`
- `staff-task-state-machine.spec`
- `staff-task-field-security.spec`
- `attendance-idempotency.spec`
- `attendance-offline.spec`
- `attendance-correction.spec`
- `roster-conflict.spec`
- `leave-balance-concurrency.spec`
- `shift-swap.spec`
- `staff-file-security.spec`
- `staff-realtime-isolation.spec`
- `staff-load.js`

Use real PostgreSQL and Redis integration tests.

---

# 24. CI/CD gates

Fail on:

- Install/lockfile failure
- Type errors
- Lint
- Migration
- Test
- OpenAPI drift
- Tenant/post scope failure
- QR replay failure
- OTP abuse failure
- Visitor/parcel duplicate effect
- Attendance duplicate effect
- SOS lifecycle failure
- File-security failure
- Secret/vulnerability/container scan
- Build failure

---

# 25. Deliverables

1. Staff backend audit
2. Architecture and threat model
3. Permission matrix
4. Data model and migrations
5. Complete APIs
6. Canonical domain services
7. Realtime/outbox
8. Workers
9. Offline sync
10. Private file service
11. OpenAPI
12. Tests
13. k6 scripts
14. Runbooks
15. Backup/restore updates
16. `STAFF_BACKEND_TRACEABILITY.md` mapping:
    - Feature 1–32
    - Endpoint
    - Permission
    - Tables
    - State transition
    - Event/job
    - Test
    - Status

---

# 26. Implementation phases

## Phase 0 — Audit/threat model

- Inspect current code
- Confirm shared records
- Map permissions and APIs
- Define offline constraints

## Phase 1 — Foundation

- Staff context
- Permissions
- Shared domain services
- Audit/outbox
- File service
- Offline command base

## Phase 2 — Visitors

- Expected/walk-in
- Approval
- OTP
- QR
- Entry/exit
- Overstay

## Phase 3 — Parcels

- Intake
- Notification
- Lifecycle
- Handover
- Unclaimed/return

## Phase 4 — Security

- Incidents
- SOS
- Patrol
- Handover

## Phase 5 — Tasks

- Assignment
- Status
- Notes
- Evidence
- Completion/verification/rework

## Phase 6 — Attendance/leave

- Attendance
- Break
- Corrections
- Roster
- Leave/swap

## Phase 7 — Scale/hardening

- Load
- Failure injection
- Security
- Offline sync
- Backup/restore
- Traceability

At each phase report:

- Files/migrations
- Endpoints
- Events/workers
- Tests/results
- Security findings
- Blockers

---

# 27. Definition of done

Complete only when:

- All 32 capabilities are implemented and traced
- Staff access is role/post/zone/assignment scoped
- Resident/Admin/Staff share canonical records
- QR and OTP are replay-safe
- Visitor entry/exit is duplicate-safe
- Parcel handover is exactly once
- SOS is realtime, escalated, and auditable
- Patrol evidence is tamper-resistant
- Complaint status uses canonical state machine
- Attendance is idempotent
- Leave balance is concurrency-safe
- Offline commands are visible, deduplicated, and conflict-aware
- Files are private/scanned
- No production direct Firestore writes remain
- OpenAPI/tests/load/backup restore pass
- Zero unresolved P0/P1 defects

Begin with the audit and threat model. Do not start by adding isolated routes.


---

# SERO Staff App — Complete Frontend, Backend, Security, and Release QC Prompt

## Role

Act as an independent **Principal QA Architect, Flutter QA Engineer, Application Security Engineer, Physical-Security Workflow Auditor, Workforce Systems QA Specialist, SRE, and Performance Engineer**.

Audit the completed SERO Staff application and backend.

Your job is to prove whether:

- All 32 Staff capabilities work
- The Staff UI matches the SERO design system
- Staff roles are properly restricted
- Visitor, parcel, SOS, patrol, complaint, attendance, and leave workflows are correct
- Offline retry does not create duplicates
- Resident/Admin/Staff use the same canonical records
- Sensitive resident, visitor, staff, and incident data is protected
- The system works under gate spikes and unstable networks

Execute tests and provide evidence. Do not provide a superficial checklist.

---

# 1. Required outputs

Produce:

1. `STAFF_QC_EXECUTIVE_SUMMARY.md`
2. `STAFF_QC_FINDINGS.md`
3. `STAFF_FEATURE_TEST_MATRIX_32.md`
4. `STAFF_VISUAL_QC_REPORT.md`
5. `STAFF_SECURITY_REPORT.md`
6. `STAFF_OFFLINE_SYNC_REPORT.md`
7. `STAFF_VISITOR_PARCEL_REPORT.md`
8. `STAFF_SOS_PATROL_REPORT.md`
9. `STAFF_ATTENDANCE_LEAVE_REPORT.md`
10. `STAFF_LOAD_REPORT.md`
11. `STAFF_RELEASE_GATE.md`
12. `staff_qc_findings.json`

For every defect:

- ID
- Severity P0/P1/P2/P3
- Category
- Staff role
- Feature
- Screen/endpoint
- File/line
- Evidence
- Reproduction
- Expected
- Actual
- User/operational impact
- Security/privacy impact
- Root cause
- Fix
- Regression test
- Status

---

# 2. Release gate

Verdict:

- PASS
- PASS WITH P2/P3 EXCEPTIONS
- FAIL

Automatic FAIL:

- Cross-society data leak
- Staff accesses unauthorized unit/resident data
- Forged/replayed QR accepted
- OTP brute force/replay succeeds
- Duplicate visitor entry/exit corruption
- Duplicate parcel handover
- Parcel released to unauthorized person
- SOS can be silently dismissed or deleted
- SOS fails to reach eligible responders
- Patrol checkpoint can be trivially forged
- Resident sees internal complaint note
- Staff accesses unassigned private complaint
- Attendance can be duplicated/spoofed without detection
- Leave balance corrupts under concurrent requests
- Offline retry creates duplicate operational record
- Public/private evidence file exposure
- Clean build/test failure
- Migration failure
- Load target failure
- No backup/restore proof
- Unresolved P0/P1

---

# 3. Clean environment

Run:

- Backend clean install
- TypeScript strict compile
- Lint
- Tests
- Docker build
- Compose startup
- Fresh migration
- Upgrade migration
- Worker startup
- Flutter pub get
- Dart formatting
- Flutter analyze
- Flutter tests
- Golden tests
- Integration tests

Do not use:

- `--force`
- `--legacy-peer-deps`
- Test skips
- Mock replacement of failed production integrations
- Forced Jest termination

---

# 4. 32-feature coverage matrix

For each feature verify:

- Frontend screen
- Route
- API
- Permission
- Database
- State transition
- Audit
- Realtime/notification
- Offline behavior
- Loading
- Empty
- Error
- Accessibility
- Responsive
- Tests
- Pass/fail

Features:

1. Expected visitors
2. Walk-in visitor
3. Visitor detail capture
4. Resident approval
5. OTP verification
6. QR verification
7. Entry
8. Exit/history/overstay
9. Parcel intake
10. Parcel metadata/photo
11. Recipient notification
12. Parcel status tracking
13. Verified handover
14. Unclaimed/return/history
15. Incident report
16. Receive SOS
17. Acknowledge SOS
18. Location/emergency instructions
19. SOS status/resolution
20. Patrol route
21. Patrol checkpoint
22. Shift handover
23. Assigned tasks
24. Accept/reject
25. Task status
26. Public/internal notes
27. Proof/material/vendor
28. Complete/verify/rework
29. Attendance check-in/out
30. Break/current shift
31. Attendance/roster/correction/overtime
32. Leave request/status/balance

---

# 5. Role and scope matrix

Create:

- Guard at Gate A
- Guard at Gate B
- Parcel desk staff
- Maintenance staff
- Housekeeping staff
- Reception staff
- Facility manager
- Security manager
- Supervisor
- Main Admin
- Resident owner
- Resident tenant

Create Society A and Society B.

Test:

- Society isolation
- Gate/post restriction
- Zone restriction
- Current shift restriction
- Task assignment
- Incident visibility
- SOS assignment
- Parcel desk permission
- Attendance own-only
- Supervisor override
- Role change
- Employment termination
- Session revocation
- Device revocation

A Gate A guard must not automatically see Gate B-only or unrelated private data.

---

# 6. Frontend design QC

Compare with current SERO Admin design.

Verify:

- Deep emerald
- Navy
- Emerald accent
- Slate background/borders
- Outfit typography
- Gradient headers
- Card/button radii
- Status chips
- Spacing
- Bottom navigation
- Drawer/More
- Notification badge
- Skeleton/empty/error states

Staff UX:

- Large targets
- One-hand operation
- Sunlight contrast
- Fast scanning
- Clear active shift
- Visible offline status
- Urgent SOS prominence
- No dense desktop table on mobile
- Low-end device responsiveness

Test sizes:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet portrait/landscape
- 1366×768
- Text scaling 200%

Golden screens:

- Dashboard
- Expected visitor
- Walk-in approval
- QR result
- Parcel inbox
- Handover
- Active SOS
- Patrol
- Incident
- Task detail
- Attendance
- Leave
- Offline queue

---

# 7. Visitor QC

## Expected/pre-approved

Test:

- Correct gate/date/shift
- Search
- Multiple visitors
- Multiple entries allowed/not allowed
- Cancelled/revoked
- Expired
- Wrong society/gate

## Walk-in

Test:

- Correct host
- Invalid unit
- Resident unavailable
- Approval
- Rejection
- Timeout
- Duplicate active visitor
- Service provider
- Emergency exception
- Offline draft

## OTP

Test:

- Valid
- Invalid
- Expired
- Replayed
- Attempt limit
- Resend cooldown
- Enumeration
- Multiple devices
- Wrong visitor
- Wrong society
- Logs

## QR

Test:

- Valid
- Tampered
- Expired
- Revoked
- Replay
- Wrong gate
- Wrong society
- Wrong time window
- Excess use count
- Key rotation
- Clock skew
- Offline

## Entry/exit

Test:

- Duplicate entry requests
- Concurrent staff
- Exit without entry
- Duplicate exit
- Wrong visit
- Correction
- Overstay
- Host notification
- Realtime Admin/Resident updates

---

# 8. Parcel QC

Test:

- Valid intake
- Invalid unit
- Duplicate tracking number
- Multiple parcels with same courier reference
- Photo upload
- Recipient notification
- Notification failure/retry
- Storage location
- Status history
- Resident viewing correct parcel
- OTP handover
- QR handover
- Signature
- Authorized family collector
- Unauthorized collector
- Multi-parcel collection
- Concurrent handover attempts
- Replay
- Damaged
- Returned
- Unclaimed reminder
- Exception handover
- Cross-society access
- Deleted/terminated resident
- Offline intake/sync

Expected exactly one successful handover.

---

# 9. Incident QC

Test:

- Draft
- Submit
- Category/severity
- Location
- Attachment
- Restricted visibility
- Visitor/vehicle/asset link
- Supervisor review
- Status update
- Reopen
- Unauthorized staff
- Cross-society
- Offline draft
- Malware file
- Audit
- Retention

Resident must not receive restricted internal incident content.

---

# 10. SOS QC

Test:

- Trigger
- Dispatch
- Eligible responders
- Acknowledge
- Duplicate acknowledgement
- Multiple responders
- Timeout escalation
- Responding
- On scene
- Escalation
- Resolve
- False alarm
- Cancel permissions
- Resident location privacy
- Emergency contacts
- Notification failure
- Redis outage
- Worker restart
- Reconnect
- Multiple simultaneous alerts
- Staff off duty
- Wrong zone
- Audit

Measure internal dispatch time.

SOS must not disappear because one client closes the screen.

---

# 11. Patrol QC

Test:

- Assignment
- Wrong staff/post
- Start early/late
- QR checkpoint
- NFC checkpoint
- Manual fallback
- Replay checkpoint
- Duplicate checkpoint
- Wrong checkpoint
- Wrong route
- Impossible sequence
- Clock tampering
- Location spoof/anomaly
- Offline checkpoint
- Sync conflict
- Photo
- Observation
- Missed checkpoint alert
- Completion
- Supervisor review
- No silent evidence edit

Do not require continuous location beyond approved policy.

---

# 12. Shift handover QC

Test:

- Outgoing staff
- Incoming staff
- Wrong post
- Active visitor list
- Pending parcels
- Open incidents
- Patrol exceptions
- Pending tasks
- Equipment note
- Acknowledge
- Duplicate acknowledgement
- Missing incoming staff
- Offline draft
- Realtime update
- Audit

Underlying records must remain unchanged.

---

# 13. Complaint/task QC

Test:

- Assigned list
- Unassigned denied
- Zone/category scope
- Accept
- Reject with reason
- Start
- Pause/resume
- Waiting states
- Public comment
- Internal note
- Resident visibility
- Before/after proof
- Material request
- Vendor request
- Complete
- Request verification
- Reject/rework
- Close
- Invalid transition
- Concurrent update
- SLA pause/resume
- Notification
- Cross-society
- Offline update

---

# 14. Attendance QC

Test:

- Scheduled check-in
- Unscheduled allowed/denied
- Duplicate check-in
- Concurrent devices
- Wrong society/post
- Geofence/QR
- Device trust
- Clock spoof
- Offline attempt
- Late sync
- Check-out
- Duplicate check-out
- Open break
- Early leave
- Break start/end
- Multiple break
- History
- Correction request
- Approval
- Immutable before/after
- Payroll event
- Terminated staff

No duplicate active session.

---

# 15. Roster/leave QC

Roster:

- Publish
- Change notification
- Conflict
- Rest period
- Post/zone
- Staff reads own only
- Supervisor view
- Version

Leave:

- Balance
- Full/partial day
- Overlap
- Insufficient balance
- Concurrent requests
- Attachment
- Approval/rejection
- Cancellation
- Roster conflict
- Balance rollback
- Notification
- Terminated staff

Shift swap:

- Eligible counterpart
- Conflict
- Both acknowledgements
- Approval
- Roster update
- Duplicate request

---

# 16. Offline sync QC

Test unstable and offline conditions.

For each allowed command:

- Create offline
- Display pending sync
- App restart
- Logout/login
- Device time changes
- Duplicate send
- Out-of-order send
- Server state changed
- Permission revoked
- Shift ended
- Society/post changed
- File upload pending
- Network returns
- Conflict UI
- Manual retry
- Permanent rejection
- Encryption at rest
- Local cleanup

Specifically prove no duplicates for:

- Visitor
- Parcel
- Incident
- Patrol checkpoint
- Task status
- Attendance
- Handover

OTP/QR must never display final success solely from offline state.

---

# 17. Realtime and notifications QC

Test:

- Visitor approval
- Entry/exit
- Parcel notification
- SOS
- Incident
- Patrol alert
- Task assignment
- Roster
- Leave
- Shift handover

Test:

- Reconnect
- Last event ID
- Duplicate
- Out-of-order
- Permission revoked
- Role/post changed
- Cross-society room
- App background/resume
- Lock-screen redaction
- Deep link

---

# 18. File security QC

Test:

- MIME spoof
- Double extension
- Oversize
- Malware test file
- Zip bomb
- Active content
- Path traversal
- Cross-tenant key
- Public URL
- Expired signed URL
- Deleted file
- Thumbnail
- Metadata
- Restricted incident file
- Resident/public complaint proof
- Offline upload retry
- Checksum mismatch

---

# 19. Security QC

Test:

- IDOR/BOLA
- Function-level authorization
- Field-level access
- Society isolation
- Post/zone scope
- Visitor enumeration
- Resident phone privacy
- Parcel privacy
- Staff privacy
- OTP abuse
- QR forgery/replay
- Attendance spoof
- Patrol tampering
- Offline payload tampering
- SQL injection
- NoSQL injection during migration
- XSS in notes
- Rate-limit bypass
- Token/session revocation
- Device revocation
- Secret/log leakage
- Audit mutation

---

# 20. Performance/load QC

Use production-like PostgreSQL, Redis, queues, object storage, and realtime.

Scenarios:

1. 3,000 authenticated users
2. 250 sustained mixed RPS for 15 minutes
3. 500 RPS burst for 60 seconds
4. 3,000 realtime connections
5. Morning visitor gate spike
6. 300 QR scans/minute
7. 200 OTP attempts/minute with abuse traffic
8. Delivery peak parcel intake
9. 100 simultaneous parcel handovers
10. Shift change attendance spike
11. SOS broadcast to eligible responders
12. 100 patrol devices syncing after outage
13. Complaint photo upload spike
14. Redis restart
15. Worker crash
16. One API replica termination
17. Four-hour soak

Targets:

- Dashboard p95 < 400 ms
- Visitor list/search p95 < 300 ms
- QR/OTP p95 < 500 ms
- Entry/exit p95 < 500 ms
- Parcel intake/handover p95 < 600 ms
- SOS internal dispatch < 1 second
- Attendance p95 < 500 ms
- Error rate < 1%
- No duplicate effects
- Queue drains after recovery

Report:

- p50/p90/p95/p99
- Throughput
- Errors
- CPU/memory
- Event-loop lag
- DB pool/locks
- Redis
- Queue age
- Realtime disconnect
- File upload
- Bottlenecks

---

# 21. Failure injection

Test:

- PostgreSQL outage
- Redis outage
- FCM outage
- Object storage outage
- Scanner/camera permission denied
- Worker crash
- API crash after commit
- Network timeout
- Duplicate queue delivery
- Old/new app versions
- Clock skew
- Device offline for full shift
- SOS provider dependency failure

Verify:

- Clear UI
- Safe retry
- No duplicate
- Audit
- Alert
- Recovery
- No false success

---

# 22. Accessibility QC

Test:

- Screen reader
- Large touch targets
- High contrast
- Sunlight readability
- Text scaling
- Focus
- Keyboard on tablet
- Scanner instructions
- SOS alert announcement
- Haptic plus visible feedback
- No color-only state
- Reduced motion
- Error association

---

# 23. Backup/restore QC

Test backup and restore of:

- Visitors
- Gate events
- Parcels
- Handovers
- Incidents
- SOS
- Patrols
- Handover logs
- Tasks/evidence
- Attendance
- Roster
- Leave
- Audit
- Files/object versions

Verify referential integrity and RPO/RTO.

---

# 24. Repository-specific checks

Verify:

1. Dedicated Staff shell exists.
2. Staff roles are not routed into full Admin shell.
3. Gate/post/zone scope is enforced.
4. Visitor records are shared across Resident/Admin/Staff.
5. Complaint records are shared across Resident/Admin/Staff.
6. OTP is hashed, expiring, attempt-limited, and replay-safe.
7. QR is opaque/signed, revocable, and replay-safe.
8. Entry/exit is idempotent.
9. Parcel handover is exactly once.
10. SOS cannot be deleted/dismissed by client.
11. Patrol manual fallback requires reason.
12. Offline commands use idempotency.
13. Attendance prevents duplicate active session.
14. Leave balance uses transaction/locking.
15. Public/internal complaint notes remain separate.
16. Private files are signed and scanned.
17. No production mock data.
18. No privileged direct Firestore writes.
19. Realtime rooms are authorized.
20. Existing Admin/Resident/Super Admin/AI tests remain passing.
21. All 32 features appear in traceability.

---

# 25. Final report

End with:

## Executive verdict

- Release gate
- P0/P1/P2/P3
- Top risks
- Tested environment
- Tested scale
- Untested scope

## Feature verdict

For all 32:

- Frontend
- Backend
- Security
- Offline
- Test
- Pass/fail
- Evidence

## Design verdict

- SERO consistency
- Staff usability
- Responsive
- Accessibility

## Security verdict

- Tenant/post scope
- Visitor/parcel privacy
- OTP/QR
- SOS
- Attendance
- Files
- Audit

## Reliability verdict

- Offline sync
- Realtime
- Queues
- Failures
- Backup/restore

## Performance verdict

- Users
- RPS
- QR/OTP rate
- SOS latency
- Error
- Headroom

## Blocking actions

List exact changes required before release.

Do not state “production ready” without executed evidence.

