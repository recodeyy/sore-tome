# SERO AI Chatbot and Cross-Role Modules — Complete Prompt Pack

This pack contains:

1. Frontend implementation prompt
2. Backend implementation prompt
3. Complete QC, security, AI red-team, and release-audit prompt

The design must remain consistent with the existing SERO Admin experience. Cross-role modules must use shared canonical records and domain logic, while each role receives only permitted data, fields, and actions.

---

# SERO AI Chatbot and Cross-Role Modules — Frontend Master Implementation Prompt

## Role

Act as a **Principal Flutter Architect, AI Product Designer, Riverpod Expert, Design-System Engineer, Accessibility Specialist, and Frontend Security Engineer**.

You are working inside the existing **SERO — AI Powered Society Management Platform** repository.

Your task is to build and productionize:

1. The shared, role-aware **SERO AI Copilot / AI Chatbot**
2. The complete set of **cross-role modules** used by Admins, committee members, residents, staff, guards, and Super Admins

The feature specification explicitly requires the chatbot to support English, Hindi, and Hinglish; society-specific answers; rule lookup; event information; facility timings; and complaint guidance. It also defines shared modules for authentication/RBAC, users, notices, complaints, funds, rules/documents, events, visitors, staff, assets, parking, payments, analytics, and society governance.

Do not create duplicate screens and business logic independently for each role. Build a **shared domain-driven frontend** with:

- Shared models and repositories
- Shared reusable screens/components
- Role-specific presenters, filters, actions, and redaction
- Server-authorized permissions
- Consistent SERO design
- One canonical source of truth

The AI Copilot must use the same shared modules rather than writing separate AI-only data paths.

---

# 1. Repository-first rules

Before changing code, inspect:

- `sero/lib/app/theme.dart`
- `sero/lib/app/main_shell.dart`
- `sero/lib/app/admin_shell.dart`
- `sero/lib/app/resident_shell.dart`
- Any staff/guard/super-admin shell
- `sero/lib/screens/shared/ai_chat/**`
- `sero/lib/providers/shared/ai_provider.dart`
- `sero/lib/services/ai_service.dart`
- `sero/lib/services/chat_service.dart`
- `sero/lib/services/api_service.dart`
- `sero/lib/services/firestore_service.dart`
- All shared providers:
  - auth
  - notices
  - complaints/issues
  - funds
  - rules
  - events
  - visitors
  - staff
- Admin/resident versions of the same modules
- Authentication screens and route guards
- Existing action cards, quick actions, AI notice writer, receipt extraction, AI insights, and knowledge-base widgets
- Direct Firestore usage
- Mock data
- Role string usage
- Existing backend contracts and SSE support

Produce before implementation:

1. `AI_CROSS_ROLE_FRONTEND_AUDIT.md`
2. `CROSS_ROLE_CAPABILITY_MATRIX.md`
3. `AI_COPILOT_SCREEN_MAP.md`
4. `CROSS_ROLE_SCREEN_AND_ROUTE_MAP.md`
5. `SHARED_COMPONENT_REFACTOR_PLAN.md`
6. `FRONTEND_BACKEND_CONTRACT_AI_CROSS_ROLE.md`

Do not start generating disconnected screens before these are complete.

---

# 2. Known starting implementation leads to verify

Treat these as audit leads and confirm with exact file evidence:

- The current `AiChatScreen` is stateful and keeps conversation history locally.
- The current chat screen calls the non-streaming method even though an SSE streaming service exists.
- AI role context appears limited to broad `resident` or `admin` strings.
- The current AI screen directly reads financial summary data through a Firestore service.
- Images are converted to base64 in the Flutter process.
- Some action cards can invoke `/ai/execute-tool`.
- Shared modules have both role-specific screens and shared providers, creating duplication risk.
- `MainShell` currently routes every non-resident role into the Admin shell.
- Some production screens may still use mock data or direct Firestore access.
- API errors may be converted into chat text rather than structured error states.
- The current AI chat does not appear to persist, search, rename, or resume conversations across devices.

Confirm, document, and correct these issues.

---

# 3. Preserve the existing SERO design language

The AI and cross-role modules must look like the existing Admin application, not a separate chatbot product.

## 3.1 Design tokens

Use the repository theme as the source of truth, including:

- Deep Emerald: `#064E3B`
- Near-black Navy: `#111827`
- Deep Navy: `#1E3A8A`
- Emerald Accent: `#10B981`
- Sky Accent: `#0EA5E9`
- Slate Background: `#F8FAFC`
- Slate Border: `#E2E8F0`
- Primary text: `#1E293B`
- Secondary text: `#64748B`
- Muted text: `#94A3B8`
- Error: `#EF4444`
- Existing warning, success, information, and status colors
- Outfit typography
- Existing emerald-to-navy gradients

## 3.2 Shape and layout

- Main cards: approximately 24 px radius
- Inputs and primary buttons: approximately 20 px radius
- Chips/status badges: approximately 10–12 px radius
- Horizontal page padding: approximately 20 px
- Generous spacing
- Soft slate borders
- Subtle shadows
- Mobile-first cards rather than desktop tables squeezed onto phones

## 3.3 Shared page composition

Use:

- Existing header treatment
- Safe-area handling
- Drawer/menu behavior
- Notification badge
- Page title/subtitle
- Stat cards
- Quick actions
- Pull-to-refresh
- Skeleton loading
- Empty/error/offline states
- Responsive bottom navigation, navigation rail, or desktop sidebar

---

# 4. Core frontend architecture

Create or refactor toward:

```text
lib/
  core/
    auth/
    permissions/
    networking/
    realtime/
    storage/
    localization/
    errors/
  domains/
    users/
    notices/
    complaints/
    funds/
    rules_documents/
    events/
    visitors/
    staff/
    assets/
    parking/
    payments/
    analytics/
    governance/
  features/
    ai_copilot/
  shared/
    design_system/
    widgets/
    role_adapters/
```

If a full folder migration would be too risky, implement the same separation gradually without breaking current imports.

For every shared domain:

- Immutable canonical model
- Typed DTO
- Repository interface
- API implementation
- Riverpod providers/notifiers
- Permission-aware action model
- Shared list/detail/form widgets
- Role-specific configuration/presenter
- Loading/empty/error/offline/pagination states
- Realtime invalidation
- Tests

Do not place business logic inside widgets.

---

# 5. Canonical role model

Normalize role names.

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

During migration, safely normalize legacy role labels.

Do not treat:

- Every non-resident as Admin
- Every admin-like role as having the same actions
- Hidden UI buttons as security

Create a `RoleContext`/`PermissionContext` from backend permissions, not only a role string.

The frontend may use permissions to display actions, but the backend remains authoritative.

---

# 6. Cross-role design rule

A cross-role module is **one shared module with different permitted experiences**, not multiple unconnected products.

For each module define:

1. Shared entity and API
2. Shared status/state machine
3. Shared list/detail route
4. Role-specific fields
5. Role-specific filters
6. Role-specific allowed actions
7. Role-specific default landing view
8. Role-specific notifications
9. Field-level redaction
10. Audit/event behavior

Example:

- A complaint is one complaint record.
- A resident can create, view their complaint, add public comments, and reopen where allowed.
- Staff can see assigned complaints, update work state, add proof, and internal notes where allowed.
- Admin can assign, escalate, change priority, and resolve.
- Auditor can read timeline and SLA without editing.
- The AI Copilot uses the same complaint API and permissions.

Do not create resident complaints, staff tasks, and admin issues as separate conflicting records.

---

# 7. AI Copilot product experience

Create a shared **SERO Copilot** accessible to all authorized roles.

## 7.1 Entry points

Support:

- Dedicated Copilot screen
- Contextual “Ask SERO” action from:
  - Notice
  - Rule/document
  - Bill/payment
  - Complaint
  - Event
  - Amenity/facility
  - Visitor
  - Staff/task
  - Asset
  - Parking
  - Dashboard metric
- Optional floating Copilot button where it does not conflict with navigation
- Deep link into a conversation
- Notification action that opens relevant Copilot context

## 7.2 Chat screen

Refactor the current AI chat into a robust Riverpod-driven feature.

The screen must include:

- SERO-branded gradient hero/header
- Current role and society context
- “New chat”
- Conversation history drawer/list
- Search conversations
- Rename/archive/delete conversation
- English/Hindi/Hinglish language indicator
- Quick-action tiles based on role and permissions
- Streaming assistant output
- Stop generation
- Retry/regenerate
- Copy
- Thumbs up/down and feedback reason
- Source/citation cards
- Expandable “How this answer was found”
- Suggested follow-up chips
- Attachment preview
- Upload progress
- Structured action proposal cards
- Confirmation before execution
- Execution progress and final result
- Request/reference ID for errors
- Offline state
- Rate-limit/quota state
- Provider unavailable fallback
- Accessibility labels
- Reduced-motion behavior

## 7.3 Conversation behavior

- Persist conversations across sessions and devices
- Cursor pagination
- Resume conversation
- Save selected language
- Support contextual conversations without permanently mixing unrelated records
- Allow user to clear memory/history according to policy
- Show when the assistant uses:
  - Society documents
  - Live operational data
  - General guidance
- Never present an ungrounded answer as an official society rule
- Clearly distinguish:
  - Answer
  - Draft
  - Proposal
  - Executed action
  - Error

## 7.4 Language support

Support:

- English
- Hindi in Devanagari
- Natural Hinglish in Latin script
- Mixed-language user input
- Automatic language detection
- Manual language selector
- Preserve official names, amounts, dates, flat numbers, and rule references accurately
- Do not translate identifiers
- Allow user to request “reply only in English/Hindi/Hinglish”
- Use readable, respectful Indian English/Hindi
- Provide localized dates, currency, and time

Do not use crude word-for-word translation.

## 7.5 Role-aware quick actions

### Resident owner/tenant

- Explain my bill
- Show outstanding dues
- Payment/receipt help
- Find a society rule
- Facility timings
- Upcoming events
- Raise a complaint
- Track my complaint
- Visitor entry help
- Parking guidance
- Emergency guidance
- Explain a notice

### Main Admin/Admin

- Society summary
- Draft notice
- Summarize complaints
- Suggest complaint assignment
- SLA risks
- Finance insights
- Dues overview
- Staff attendance summary
- Asset maintenance summary
- Event/AGM preparation
- Search rules/documents
- Generate report draft

### Secretary/committee

- Draft notice
- Meeting agenda
- Resolution/minutes draft
- Poll wording
- Event communication
- Rule lookup
- Complaint summary

### Treasurer

- Collection summary
- Outstanding ageing
- Expense analysis
- Receipt extraction
- Draft expense
- Reconciliation guidance
- Budget variance
- Financial report explanation

### Staff/facility manager

- My assigned tasks
- Complaint work guidance
- Upload completion proof
- Shift/leave information
- Facility schedule
- Asset instructions

### Guard/security

- Visitor verification guidance
- Parcel workflow
- Incident report draft
- SOS procedure
- Patrol task
- Parking/vehicle lookup where permitted

### Super Admin

Use a separate platform context:

- Society onboarding summary
- Subscription/revenue analysis
- Support summary
- Platform health explanation
- Feature rollout explanation
- Audit search assistance

Super Admin Copilot must not retrieve arbitrary society-private content without explicit authorized society context.

---

# 8. AI answer and action card types

Create typed UI models and renderers for:

- `text_answer`
- `grounded_answer`
- `rule_answer`
- `event_answer`
- `facility_answer`
- `financial_explanation`
- `complaint_guidance`
- `list_result`
- `metric_summary`
- `draft_notice`
- `draft_complaint`
- `draft_expense`
- `draft_event`
- `draft_poll`
- `action_proposal`
- `action_confirmation`
- `action_progress`
- `action_success`
- `action_failure`
- `clarification_request`
- `safety_refusal`
- `rate_limit`
- `system_unavailable`

Do not use loosely typed dynamic maps throughout the UI.

## 8.1 Action proposal UX

Every write action must show:

- What will happen
- Target record/society
- Important field values
- Permission used
- Whether approval is required
- Consequences
- “Edit”
- “Confirm”
- “Cancel”

High-risk actions must never execute from a single AI response tap.

The final result must show:

- Status
- Record ID or reference
- Timestamp
- Link to open the created/updated record
- Whether notification was sent
- Error/retry guidance

---

# 9. Attachment and document UX

Support:

- Image
- PDF
- Approved office document types
- Camera/gallery where role permits
- Signed upload flow
- Upload progress
- Cancel
- Malware-scanning state
- Parsing/indexing state
- Failed state
- Retry
- Document privacy label

Do not convert large files into base64 in app memory.

Use signed uploads and backend-issued file tokens.

AI must not ingest an attachment until security scanning and authorization complete.

---

# 10. Cross-role module specifications

## 10.1 Authentication and RBAC

Shared screens:

- Login
- OTP/MFA
- Registration/invitation
- Pending approval
- Forgot/recover
- Device/session management
- Access denied
- Role/society selection for users with multiple memberships

Requirements:

- Canonical role/permission model
- Secure token storage
- Session revocation
- Logout all devices
- MFA/step-up UI
- Role change refresh
- Society switch with cache clearing
- No stale data from previous society

## 10.2 User management

Shared entity, role-specific views.

Admin capabilities:

- Invite
- Approve/reject
- Edit membership
- Assign unit
- Assign role/permissions
- Suspend/reactivate
- Move-out
- View KYC status

Resident capabilities:

- Own profile
- Family members
- Co-owner/tenant
- Emergency contact
- Privacy controls

Staff capabilities:

- Own profile
- Assigned department/shift
- Documents
- Leave

Never expose private data fields to unauthorized roles.

## 10.3 Notice board

Shared:

- Notice list/detail
- Categories
- Priority
- Attachments
- Read/unread
- Acknowledgement
- Search/filter
- Archive

Publish roles:

- Admin/secretary or permission-based roles

Resident/staff:

- Read relevant audience
- Acknowledge
- Save/share only if policy permits

AI:

- Explain notice
- Draft notice
- Suggest audience
- Never publish without confirmation and permission

## 10.4 Complaint management

Shared complaint record and timeline.

Resident:

- Create
- Attach evidence
- View public timeline
- Public comment
- Rate resolution
- Reopen where allowed

Staff:

- View assigned
- Accept/start/pause/complete
- Add internal note where permitted
- Upload proof
- Request parts/vendor/help

Admin:

- Assign/reassign
- Priority
- SLA
- Escalate
- Merge duplicate
- Resolve/close
- Reports

AI:

- Guide resident
- Draft complaint
- Suggest category/priority
- Suggest assignment
- Summarize history
- Never bypass state machine

## 10.5 Fund management

Use role-appropriate views over the same financial source.

Resident:

- High-level approved fund transparency
- Own dues/payments
- Published budget/expense summary where society policy permits

Treasurer/Admin:

- Ledger
- Collections
- Expenses
- Budget
- Reconciliation
- Approval actions

Auditor:

- Read-only ledger/report access

AI:

- Explain numbers from backend aggregates
- Never fetch arbitrary totals from a truncated list
- Expense creation remains a verified proposal

## 10.6 Rules and documents

- Categories
- Search
- Versions
- Effective dates
- Read acknowledgement
- Download permissions
- Signed access
- AI citation to exact document/version/page/section where available
- Admin upload/publish/archive
- Resident read
- Auditor history
- No public file URLs

## 10.7 Event management

Admin/committee:

- Create/edit
- RSVP policy
- Capacity
- Waitlist
- Reminder
- Attendance
- Cancel

Resident/staff:

- Discover
- RSVP/cancel
- Calendar
- QR/check-in where applicable

AI:

- Event info
- Draft event
- RSVP guidance
- Never overbook

## 10.8 Visitor management

Resident:

- Pre-approve visitor
- View own visitor history
- Domestic help management where allowed

Guard:

- Search expected visitor
- OTP/QR verification
- Check-in/out
- Incident/escalation
- Parcel workflow

Admin/security manager:

- Policies
- Logs
- Blacklist/watchlist only with strict permissions
- Analytics

AI:

- Workflow guidance
- Lookup only permitted visitor data
- No disclosure of resident/visitor personal data beyond need

## 10.9 Staff management

Admin:

- Staff list
- Role/department
- Attendance
- Roster
- Leave
- Payroll access based on permission
- Documents/training

Staff:

- Own attendance
- Shift
- Leave
- Tasks
- Payslip

Guard:

- Security-specific subset

AI:

- Shift/leave guidance
- Task summary
- No cross-staff payroll disclosure

## 10.10 Asset management

Admin/facility manager:

- Asset list/detail
- Maintenance schedule
- Work orders
- Vendor/AMC
- Downtime
- Evidence

Staff:

- Assigned work orders
- Status/proof

Resident:

- Public outage/service status only

AI:

- Maintenance guidance
- Work-order summary
- No dangerous technical instructions beyond approved documents

## 10.11 Parking management

Resident:

- Own vehicles
- Own allocation/request
- Visitor parking
- Violation view/dispute

Guard:

- Vehicle lookup
- Visitor parking check
- Violation evidence

Admin:

- Inventory
- Allocation
- Waitlist
- Transfer/release
- Violations/fines

AI:

- Parking policy guidance
- Draft request
- No allocation without authorized confirmation

## 10.12 Payment system

Resident:

- Bills
- Pay
- Receipts
- Refund status
- Autopay settings if supported

Treasurer/Admin:

- Payment records
- Reconciliation
- Failed payments
- Refund/adjustment permissions

AI:

- Explain bill
- Payment troubleshooting
- Never collect card data in chat
- Never claim payment success before verified backend status

## 10.13 Analytics dashboard

Shared metric definitions with role-based scope.

Resident:

- Personal dues/payment/complaint/event summary

Staff:

- Own tasks/attendance/service metrics

Admin:

- Society operations/finance/SLA/occupancy

Super Admin:

- Platform metrics

Every metric:

- Source
- As-of timestamp
- Date filter
- Permission scope
- Drill-down
- Accessible chart alternative

## 10.14 Society governance

Shared:

- AGM/committee meetings
- Agenda
- Attendance
- Quorum
- Polls/voting
- Resolutions
- Minutes
- Action items
- Bylaws

Resident/member:

- Eligible meetings/polls
- Vote
- View published results/minutes

Committee/admin:

- Create/manage
- Eligibility
- Quorum
- Publish

AI:

- Draft agenda/minutes/resolution
- Explain governance rule
- Never cast votes
- Never alter final minutes without confirmation

---

# 11. Routes

Use shared route hierarchy where practical:

- `/copilot`
- `/copilot/conversations`
- `/copilot/conversations/:id`
- `/users`
- `/users/:id`
- `/notices`
- `/notices/:id`
- `/complaints`
- `/complaints/:id`
- `/funds`
- `/rules`
- `/documents`
- `/documents/:id`
- `/events`
- `/events/:id`
- `/visitors`
- `/visitors/:id`
- `/staff`
- `/staff/:id`
- `/assets`
- `/assets/:id`
- `/parking`
- `/payments`
- `/analytics`
- `/governance`
- `/meetings/:id`
- `/polls/:id`

The same route may render a different permitted view by role, but the user must never briefly see unauthorized data while permissions load.

---

# 12. State management

Use Riverpod consistently.

Create:

- Auth/session context provider
- Active society provider
- Permission provider
- Feature-entitlement provider
- AI conversation list provider
- AI conversation provider
- Streaming message notifier
- AI quota/status provider
- Per-domain list/detail/form providers
- Realtime invalidation provider
- Upload job provider
- Action proposal/execution provider

Requirements:

- Cancellation
- Auto-dispose where appropriate
- Cursor pagination
- Debounced search
- Request deduplication
- Refresh
- Cache invalidation
- Optimistic updates only for safe operations
- Rollback
- No static service-level conversation history shared across users
- Clear sensitive state on logout, society switch, role change, and impersonation end

---

# 13. Realtime behavior

Use WebSocket/SSE/outbox events for:

- AI streaming
- AI action status
- Complaint updates
- Notice publish/read requirements
- Visitor approval/check-in
- Event capacity/waitlist
- Payment status
- Staff assignment
- Asset work order
- Parking allocation
- Governance result publication

Handle:

- Reconnect
- Last event ID
- Duplicate event
- Out-of-order event
- Permission revoked during connection
- Society switch
- App background/resume

---

# 14. Accessibility and responsive behavior

Support:

- 320 px mobile width
- Standard Android/iPhone sizes
- Tablet portrait/landscape
- Desktop/web

Mobile:

- Existing bottom navigation
- Drawer
- Cards
- Bottom sheets
- Full-screen chat

Tablet:

- Navigation rail
- Split conversation list/chat
- Master-detail modules

Desktop:

- Sidebar
- Conversation history column
- Main chat
- Optional source/context panel
- Keyboard shortcuts
- Resizable panels

Accessibility:

- WCAG 2.1 AA where applicable
- Screen reader semantics
- Keyboard navigation
- Focus management
- Text scaling
- High contrast
- No color-only meaning
- Accessible charts
- Reduced motion
- Announce streamed content without overwhelming screen readers

---

# 15. Frontend security requirements

- No API secrets in client
- No raw service account credentials
- No public document URLs
- No direct privileged Firestore write
- No trust in client-provided role/society context
- Do not send unnecessary full records to AI
- Redact attachments/previews
- Secure token storage
- Clear role/society caches
- Action confirmation
- Step-up authentication UI
- No card/payment data in AI messages
- No hidden impersonation
- No unauthorized data in local logs/crash reports
- Screenshot prevention only for specifically approved sensitive screens

---

# 16. Frontend tests

Create:

## AI Copilot

- Conversation list
- New/resume/rename/archive/delete
- Streaming
- Stop/regenerate
- English
- Hindi
- Hinglish
- Mixed-language input
- Citation/source card
- Attachment upload
- Upload failure
- Action proposal
- Confirmation
- Cancel
- Execution success/failure
- Permission denied
- Rate limit
- Offline
- Provider unavailable
- Conversation privacy
- State clearing

## Cross-role modules

- Role capability matrix widget tests
- Route guard tests
- Field redaction tests
- Shared state-machine UI tests
- Resident/Admin/Staff/Guard differences
- Society switch
- Role change
- Pagination
- Realtime update
- Deep link
- Loading/empty/error/offline
- Accessibility
- Responsive/golden

Golden screens:

- Resident Copilot
- Admin Copilot
- Guard Copilot
- Grounded rule answer
- Action proposal
- Action confirmation
- AI error/offline
- Shared notice list by role
- Shared complaint detail by role
- Shared event
- Shared visitor
- Shared payment
- Shared governance poll

---

# 17. Implementation phases

## Phase 0 — Audit and capability matrix

- Inspect repository
- Map duplication
- Map roles/actions/fields
- Confirm API contracts
- Identify security gaps

## Phase 1 — Shared foundation

- Canonical roles/permissions
- Shared error/networking
- Shared domain models
- Route guards
- State clearing
- Design-system refactor

## Phase 2 — AI Copilot foundation

- Conversation persistence UI
- Streaming
- Citations
- Language
- Attachments
- Typed cards
- Feedback

## Phase 3 — Shared high-use modules

- Notices
- Complaints
- Rules/documents
- Events
- Payments

## Phase 4 — Operations modules

- Visitors
- Staff
- Assets
- Parking
- Funds

## Phase 5 — Governance and analytics

- Meetings/polls/resolutions
- Role-scoped dashboards
- Contextual Copilot entry points

## Phase 6 — AI action integration

- Read tools
- Proposal cards
- Confirmed write actions
- Approval flows
- Execution updates

## Phase 7 — Hardening

- Remove mocks
- Remove direct privileged Firestore
- Accessibility
- Responsive
- Golden tests
- Contract tests
- Traceability

At the end of each phase report:

- Files changed
- Shared components created
- Duplicate code removed
- API contracts connected
- Role matrix coverage
- Tests and results
- Blockers

---

# 18. Deliverables

1. Frontend audit
2. Role-capability-field matrix
3. Shared domain architecture
4. Complete AI Copilot UI
5. All cross-role module integrations
6. Typed models/cards
7. Riverpod providers/notifiers
8. Responsive mobile/tablet/web behavior
9. Accessibility support
10. Tests
11. Updated routes/shells
12. No production mock fallback
13. No privileged direct Firestore writes
14. `AI_CROSS_ROLE_FRONTEND_TRACEABILITY.md` mapping:
    - Requirement
    - Role
    - Screen
    - Route
    - Provider
    - Repository/service
    - API
    - Test
    - Status

---

# 19. Definition of done

Complete only when:

- AI supports English, Hindi, and Hinglish naturally
- Answers are society-specific and source-grounded
- Rule, event, facility, and complaint guidance works
- Conversations persist
- Streaming works
- Sources are visible
- AI writes use proposals and confirmation
- Cross-role modules use one source of truth
- Every role sees only permitted data/actions
- Field-level redaction works
- Role/society switching clears state
- No production mock data remains
- No privileged direct Firestore access remains
- Existing SERO design is preserved
- Mobile/tablet/desktop work
- Accessibility tests pass
- Flutter analyze and all tests pass
- Existing Admin/Resident/Staff/Guard/Super Admin flows remain functional

Begin with Phase 0. Do not begin by visually rewriting the chat screen without solving shared architecture and role permissions.


---

# SERO AI Chatbot and Cross-Role Modules — Backend Master Implementation Prompt

## Role

Act as a **Principal Backend Architect, AI Systems Engineer, Staff TypeScript Engineer, Security Engineer, Database Architect, and SRE**.

You are working inside the existing SERO backend.

Your task is to productionize:

1. The **SERO role-aware AI Copilot**
2. The complete **cross-role backend architecture** for:
   - Authentication and RBAC
   - User management
   - Notice board
   - Complaint management
   - Fund management
   - Rules and documents
   - Event management
   - Visitor management
   - Staff management
   - Asset management
   - Parking management
   - Payment system
   - Analytics dashboard
   - Society governance

Use the same PostgreSQL, Redis, BullMQ, Firebase Auth/FCM, object storage, OpenAPI, outbox, logging, and observability foundation approved for Admin and Super Admin.

Do not create independent AI copies of module logic. The Copilot must call the same domain services, permission policies, state machines, validation, transactions, audit logging, and event system used by standard APIs.

---

# 1. Repository-first audit

Inspect:

- Existing `/api/v1` APIs
- `src/routes/ai.ts`
- `AIChatService`
- `AIToolService`
- `AIGuardrailsService`
- `AIMemoryService`
- `AIPromptService`
- `ProviderService`
- `VectorStoreService`
- `SemanticCacheService`
- `AICostService`
- `AIEvaluationService`
- `AIQueueService`
- `AIExtractionService`
- Parser/embedding code
- Existing migrations for AI tables and `document_chunks`
- Firestore-based domain routes/services
- Auth and tenant middleware
- Role checks
- Shared module routes
- Payment service
- Outbox and workers
- Flutter frontend contracts
- Firestore rules
- Object-storage configuration
- Tests

Produce:

1. `AI_CROSS_ROLE_BACKEND_AUDIT.md`
2. `AI_SYSTEM_ARCHITECTURE.md`
3. `CROSS_ROLE_DOMAIN_ARCHITECTURE.md`
4. `ROLE_PERMISSION_FIELD_MATRIX.md`
5. `AI_TOOL_REGISTRY.md`
6. `AI_CROSS_ROLE_API_CONTRACT.md`
7. `AI_THREAT_MODEL.md`

Do not start bulk coding until the audit exists.

---

# 2. Starting implementation leads to verify and fix

Confirm with file/line evidence:

- AI uploads may make documents publicly accessible.
- URL validation may not fully prevent SSRF.
- Prompt-injection protection appears keyword-based.
- PII masking is regex-based and may over-mask or under-mask.
- Grounding validation appears based on simple word overlap.
- AI tool permissions appear hard-coded by role string.
- AI tool writes may write directly to Firestore instead of canonical domain services.
- AI actions may execute using only an `actionId` without a robust confirmation binding.
- Some AI analytics read Firestore operational data directly.
- AI rate limiting may be process-local.
- Chat history may be passed from the client and trusted too much.
- RAG tenant filtering may depend partly on metadata strings.
- File upload uses in-memory multipart buffers.
- Base64 image size checks may measure encoded characters rather than decoded file size.
- AI logs may expose parameters or sensitive prompt content.
- AI cache keys may not include all security and prompt/model/version context.
- There may be dual-write or Firestore/PostgreSQL divergence risk.
- Existing cross-role routes may duplicate logic or use inconsistent status fields.

Treat all as audit leads, not conclusions.

---

# 3. Core architecture

Use a modular monolith plus workers.

## 3.1 Shared domain services

Each cross-role module must have one canonical domain service:

- `AuthService`
- `UserService`
- `NoticeService`
- `ComplaintService`
- `FundAccountingService`
- `RuleDocumentService`
- `EventService`
- `VisitorService`
- `StaffService`
- `AssetService`
- `ParkingService`
- `PaymentService`
- `AnalyticsService`
- `GovernanceService`

Standard REST APIs and AI tools must call these services.

Do not implement an AI-specific `createNotice` that bypasses the normal notice service.

## 3.2 Policy engine

Implement centralized authorization:

- Role permissions
- Resource ownership
- Society membership
- Unit relationship
- Assignment relationship
- Field-level access
- State-dependent action
- Feature entitlement
- Step-up authentication
- Approval requirement
- Impersonation restrictions

Use a policy decision such as:

```json
{
  "allowed": true,
  "reason": "complaint.assigned_staff",
  "allowedFields": ["status", "completionNote"],
  "deniedFields": ["priority", "slaPolicyId"]
}
```

The same policy engine must protect:

- REST
- Realtime
- File access
- Exports
- AI retrieval
- AI tools

## 3.3 Data ownership

Use PostgreSQL as the authoritative source for shared operational and financial entities.

Firestore, if retained, may be:

- Authentication-related Firebase services
- Notification delivery
- Read projections

Do not maintain conflicting writes from UI, REST, and AI to separate sources.

---

# 4. Canonical identity and role model

Support:

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

Use permissions instead of scattered role arrays.

Every request context must include verified:

- Actor user ID
- Effective user ID where impersonating
- Society ID
- Membership ID
- Roles
- Permissions
- Unit relationships
- Feature entitlements
- Session ID
- MFA/step-up state
- Request ID

Never trust these values from the request body.

---

# 5. Cross-role API principle

Prefer shared endpoints with policy-scoped responses.

Examples:

- `GET /complaints`
  - Resident receives own/eligible complaints
  - Staff receives assigned complaints
  - Admin receives society-scope complaints
- `GET /notices`
  - User receives notices matching audience
- `GET /events`
  - User receives eligible events
- `GET /payments`
  - Resident receives their own payment/bill records
  - Treasurer receives society financial records

Use:

- Query policy
- Field selection/redaction
- Action links/capabilities in response
- Cursor pagination
- Consistent state machines

Do not create insecure `role=admin` query parameters.

---

# 6. AI Copilot architecture

## 6.1 Request pipeline

Implement:

1. Authentication
2. Tenant/context resolution
3. AI-specific distributed rate limit
4. Input size/type validation
5. Language detection
6. Safety classification
7. Prompt-injection analysis
8. Conversation retrieval from server
9. Permission-aware context builder
10. Retrieval/tool planning
11. Model provider call
12. Grounding/citation verification
13. Output safety
14. Typed response/event streaming
15. Cost/log/evaluation event
16. Feedback support

The server owns conversation history. Do not trust the client to submit authoritative history.

## 6.2 Provider abstraction

Support configurable providers/models with:

- Capability metadata
- Context limits
- Streaming
- Structured outputs
- Vision
- Tool calling
- Cost
- Region/data residency
- Retry/fallback policy
- Circuit breaker
- Timeout

Do not hard-code one provider throughout business logic.

## 6.3 Prompt registry

Version prompts:

- System prompt
- Role policy prompt
- Language prompt
- Retrieval prompt
- Tool-planning prompt
- Output schema
- Safety rules

Store:

- Prompt version
- Model
- Provider
- Temperature/settings
- Tool version
- Evaluation version

A response/cache/audit record must be reproducible enough for investigation.

---

# 7. AI conversation data model

Create or complete:

- `ai_conversations`
- `ai_conversation_participants`
- `ai_messages`
- `ai_message_parts`
- `ai_message_citations`
- `ai_attachments`
- `ai_feedback`
- `ai_action_proposals`
- `ai_action_confirmations`
- `ai_action_executions`
- `ai_tool_registry`
- `ai_tool_versions`
- `ai_usage_events`
- `ai_cost_daily`
- `ai_safety_events`
- `ai_evaluations`
- `ai_provider_events`
- `ai_rate_limit_events`
- `ai_memory_entries`
- `ai_memory_consents`
- `ai_document_access_events`

Fields must include:

- Society
- Actor/effective user
- Role/permission snapshot where necessary
- Language
- Model/provider
- Prompt/tool versions
- Request/correlation ID
- Token/cost
- Status
- Retention/deletion status

Do not store raw secrets, payment card data, OTPs, or unnecessary sensitive personal data.

---

# 8. AI chat APIs

Use `/api/v1/ai`.

## Conversations

- `POST /conversations`
- `GET /conversations`
- `GET /conversations/:conversationId`
- `PATCH /conversations/:conversationId`
- `DELETE /conversations/:conversationId`
- `POST /conversations/:conversationId/archive`
- `POST /conversations/:conversationId/clear-memory`

## Messages

- `POST /conversations/:conversationId/messages`
- `GET /conversations/:conversationId/messages`
- `GET /conversations/:conversationId/stream`
- `POST /messages/:messageId/regenerate`
- `POST /messages/:messageId/feedback`
- `GET /messages/:messageId/citations`

Prefer POST that returns an SSE stream or creates a generation run and streams by run ID.

## Attachments

- `POST /attachments/upload-intent`
- `POST /attachments/:id/complete`
- `GET /attachments/:id/status`
- `DELETE /attachments/:id`

## Actions

- `GET /actions/:proposalId`
- `PATCH /actions/:proposalId`
- `POST /actions/:proposalId/confirm`
- `POST /actions/:proposalId/cancel`
- `GET /actions/:proposalId/execution`

## General

- `GET /capabilities`
- `GET /quota`
- `GET /health`
- `GET /admin/logs` with strict permission
- `GET /admin/costs`
- `GET /admin/evaluations`

Deprecate unsafe legacy endpoints only after frontend migration.

---

# 9. Typed streaming protocol

Use SSE or WebSocket with typed events:

- `run.started`
- `message.delta`
- `message.completed`
- `citation.added`
- `tool.proposed`
- `tool.awaiting_confirmation`
- `tool.execution_started`
- `tool.execution_progress`
- `tool.execution_completed`
- `tool.execution_failed`
- `clarification.required`
- `safety.refusal`
- `rate_limit`
- `run.failed`
- `heartbeat`

Each event:

- Event ID
- Run ID
- Conversation ID
- Sequence
- Timestamp
- Type
- Typed data

Support reconnect with last event ID and idempotent replay.

---

# 10. Multilingual system

Implement:

- Language detection
- User preference
- English
- Hindi Devanagari
- Hinglish Latin script
- Code-switching
- Locale-aware INR/date/time
- Preserve identifiers
- Translation quality evaluation
- Prompt/tool schemas that use stable internal English identifiers while user-facing text is localized

Store detected/requested/response language.

Do not translate:

- IDs
- Names unless requested
- Flat/wing labels
- Invoice numbers
- Rule references
- Amounts
- Dates inaccurately

Create test fixtures for Indian society-management terminology.

---

# 11. RAG and society-specific answers

## 11.1 Knowledge sources

- Rules
- Bylaws
- Circulars
- Notices
- Meeting minutes
- Facility policies/timings
- Event details
- Approved FAQs
- Published financial policy
- Emergency procedures
- Admin-approved operational documents

## 11.2 Ingestion pipeline

1. Signed upload
2. Permission validation
3. Malware scan
4. File type validation
5. Parse
6. OCR where needed
7. Normalize
8. Classify
9. Chunk
10. Embed
11. Index with immutable metadata
12. Quality checks
13. Publish index version
14. Audit

Metadata:

- Society ID
- Document ID
- Version
- Type
- Status
- Effective date
- Visibility/audience
- Permission classification
- Page/section
- Checksum
- Index version

## 11.3 Retrieval security

Filter in SQL/vector query by:

- Society
- Document visibility
- Role/permission
- Unit/committee/staff scope where relevant
- Published/effective status
- Retention/deletion status

Never retrieve broad data and filter only after generation.

## 11.4 Citations

Answers must cite:

- Source title
- Document version
- Page/section if available
- Effective date
- Link token authorized for the user

If no reliable source exists, say so.

Do not use simplistic word overlap as the only grounding check.

Use:

- Structured claim extraction
- Citation coverage
- Entailment/grounding evaluation
- Confidence threshold
- Deterministic policy for official-rule answers

---

# 12. Prompt-injection and data-exfiltration defense

Treat uploaded documents, retrieved text, and user input as untrusted.

Implement layered defenses:

- Content boundaries
- System/tool instruction separation
- Prompt injection classifier
- Retrieval sanitization
- Tool allowlist
- Schema-constrained arguments
- Permission check after model planning
- No secrets in model context
- No raw database access
- Output DLP
- Canary tests
- Egress control
- Provider logging controls
- Sensitive source exclusion

Defend against:

- “Ignore previous instructions”
- Hidden text in documents/images
- Requests for system prompt
- Cross-society data
- Other user conversations
- Credentials
- Payment data
- KYC data
- Internal audit data
- Unauthorized tool execution

Never rely only on keyword matching.

---

# 13. AI tool registry

Register tools with:

- Tool ID
- Version
- Description
- Input schema
- Output schema
- Domain service
- Required permission
- Resource policy
- Risk level
- Confirmation policy
- Step-up auth requirement
- Approval requirement
- Idempotency requirement
- Rate limit
- Audit category
- Allowed roles only as derived from permission mapping
- Feature entitlement

## 13.1 Read tools

Examples:

- `notices.search`
- `notices.get`
- `rules.search`
- `events.list`
- `events.get`
- `facilities.get_timings`
- `complaints.get_my`
- `complaints.get_assigned`
- `payments.get_my_bills`
- `payments.get_receipt`
- `funds.get_summary`
- `staff.get_my_shift`
- `visitors.get_expected`
- `parking.get_my_allocation`
- `assets.get_service_status`
- `analytics.get_role_dashboard`
- `governance.get_meeting`
- `governance.get_poll`

## 13.2 Proposal/write tools

Examples:

- `complaints.propose_create`
- `complaints.propose_comment`
- `complaints.propose_assignment`
- `notices.propose_create`
- `events.propose_create`
- `polls.propose_create`
- `expenses.propose_create`
- `visitors.propose_preapproval`
- `parking.propose_request`
- `staff.propose_leave_request`
- `assets.propose_work_order_update`
- `governance.propose_minutes`
- `reports.propose_generation`

Do not expose a generic arbitrary CRUD tool.

---

# 14. AI action confirmation protocol

A tool write must follow:

1. Model creates proposal
2. Backend validates input
3. Backend evaluates permission/policy
4. Backend loads current resource version
5. Backend computes human-readable impact
6. Backend stores signed proposal with:
   - Proposal ID
   - Actor
   - Society
   - Tool/version
   - Arguments
   - Resource version
   - Permission snapshot
   - Expiry
   - Idempotency key
   - Risk level
7. Frontend displays proposal
8. User edits/cancels/confirms
9. Backend rechecks:
   - Identity
   - Session
   - Permission
   - Feature
   - Resource version
   - Step-up auth
   - Approval
   - Expiry
10. Domain service executes transaction
11. Audit/outbox
12. Return result

Proposal IDs must be unguessable and user/society-bound.

A confirmation must not execute altered parameters that were not shown to the user.

High-risk actions may require maker-checker and cannot complete immediately.

---

# 15. AI safety by domain

## Finance/payment

AI may:

- Explain bills
- Explain payment state
- Summarize authorized aggregates
- Draft an expense proposal
- Help reconcile

AI must not:

- Collect card details
- Mark payment successful without verified provider status
- Post an expense without confirmation/approval
- Alter immutable ledger entries
- Guess financial totals

## Complaints

AI may:

- Guide
- Draft
- Categorize
- Summarize
- Suggest assignment

It must not bypass valid transitions or expose private/internal comments.

## Visitors/security

AI may provide workflow guidance and permitted lookups.

It must not expose complete resident/visitor history without permission or weaken verification.

## Governance

AI may draft agenda/minutes/resolution.

It must never cast or alter a vote.

## Staff

AI must not reveal payroll, disciplinary, or private staff data to unauthorized users.

## Rules/documents

AI must distinguish official documents from general guidance.

---

# 16. Cross-role domain workflows

Implement shared state machines.

## 16.1 Notices

- Draft
- Scheduled
- Published
- Expired
- Archived
- Cancelled

Audience authorization, read receipts, acknowledgement, version history.

## 16.2 Complaints

- New
- Triaged
- Assigned
- Accepted
- In progress
- Waiting
- Resolved
- Closed
- Reopened
- Cancelled

Public/internal timeline separation, SLA, escalation.

## 16.3 Events

- Draft
- Published
- Full
- Cancelled
- Completed

Capacity, waitlist, RSVP, attendance.

## 16.4 Visitors

- Expected
- Pending approval
- Approved
- Rejected
- Checked in
- Checked out
- Expired
- Flagged

OTP/QR replay prevention.

## 16.5 Staff/attendance/leave

Use canonical shift, attendance, leave, task, and payroll workflows.

## 16.6 Assets/work orders

- Open
- Assigned
- In progress
- Waiting parts/vendor
- Completed
- Verified
- Closed
- Cancelled

## 16.7 Parking

Allocation/request/visitor/violation state machines with concurrency-safe unique allocation.

## 16.8 Payments

Provider intent, pending, authorized, captured, failed, refunded, disputed, reconciled.

## 16.9 Governance

Meeting, quorum, eligibility snapshot, vote, minutes, resolution, action item.

AI and REST must obey the same state machines.

---

# 17. Cross-role data and field security

Implement field-level serializers.

Examples:

- Resident sees only their bill/payment
- Guard sees visitor identity needed for verification, not full resident profile
- Staff sees assigned complaint contact data only where operationally required
- Resident cannot see internal complaint notes
- Committee cannot see payroll unless permitted
- Auditor cannot write
- Super Admin requires explicit control-plane permission and context
- AI context builder receives only fields the user could access directly

Do not send a full database entity to the model and ask it not to reveal fields.

---

# 18. File security

Replace unsafe public upload behavior.

Use:

- Signed upload intent
- Tenant-prefixed object keys
- MIME/content validation
- File-size limits
- Malware scanning
- Quarantine
- Checksum
- Metadata
- Signed short-lived download
- Access logs
- Retention/deletion
- Async parser
- No large in-memory buffers
- No public bucket/object
- SSRF-safe remote import only if truly needed

---

# 19. Memory and privacy

AI memory must be explicit and scoped.

Support:

- Conversation history
- Optional user preference memory
- Society-shared knowledge
- No silent long-term storage of sensitive content
- Consent
- View/delete memory
- Retention policy
- Deletion propagation
- Society/user offboarding
- Legal hold where required
- No cross-role or cross-society memory leakage

Memory keys must include:

- Society
- User
- Effective role/context
- Permission-sensitive scope
- Prompt/version where relevant

---

# 20. Caching

Semantic/result cache key must include as applicable:

- Society
- User or permission scope
- Role/field-access scope
- Language
- Normalized query
- Document index version
- Prompt version
- Model/provider
- Tool registry version
- Feature configuration
- Relevant live-data version

Do not cache write proposals or sensitive personalized answers broadly.

Invalidate on:

- Document publish/archive
- Rule version
- Notice/event change
- Facility timing
- Permission change
- Society switch
- Financial update
- Complaint update
- Feature flag

---

# 21. Rate limiting and quotas

Use Redis-distributed controls.

Limit by:

- User
- Society
- IP fallback
- Endpoint
- Model cost
- Attachment ingestion
- Tool type
- Role/plan entitlement

Support:

- Burst
- Sustained
- Daily/monthly token budget
- Cost budget
- Graceful quota response
- Admin override
- Abuse alert

Do not use only process-local `express-rate-limit` for a horizontally scaled system.

---

# 22. Observability and AI operations

Track:

- Chat requests
- Streaming latency/time-to-first-token
- Completion latency
- Provider/model errors
- Token usage
- Cost
- Cache hit
- Retrieval latency
- Citation coverage
- Safety blocks
- Tool proposals
- Confirmation rate
- Tool failures
- User feedback
- Language
- Hallucination/grounding evaluation
- Queue depth
- Attachment processing
- Cross-role policy denials

Correlate:

- Request
- Conversation
- Message/run
- Tool proposal
- Domain transaction
- Outbox event
- Notification

Redact prompts/content in logs according to policy.

---

# 23. AI evaluation

Create offline and online evaluation.

Datasets:

- English
- Hindi
- Hinglish
- Mixed language
- Rules
- Events
- Facility timings
- Complaints
- Payments
- Visitors
- Staff
- Assets
- Parking
- Governance
- Cross-role authorization
- Prompt injection
- Cross-society attempts

Metrics:

- Answer correctness
- Citation correctness
- Citation completeness
- Groundedness
- Refusal correctness
- Tool selection
- Tool argument accuracy
- Authorization safety
- Language quality
- Latency
- Cost
- User feedback

Gate prompt/model changes with regression evaluation.

---

# 24. Background jobs

Use idempotent BullMQ workers for:

- Document scanning
- Parsing/OCR
- Embedding/indexing
- Evaluation
- Conversation summarization
- Retention/deletion
- Cost aggregation
- Analytics aggregation
- Report generation
- Notification
- Tool approval/execution where asynchronous
- Cache invalidation

Every job:

- Unique key
- Retry/backoff
- Timeout
- Dead letter
- Status persistence
- Correlation ID
- Tenant/user context
- Idempotent processor

---

# 25. Performance target

Support overall SERO target:

- 3,000 concurrent authenticated users/connections
- 250 sustained mixed API RPS
- 500 RPS burst
- 3,000 realtime connections

AI-specific target for production-like test configuration:

- 300 concurrent active chat sessions
- 100 simultaneous streams
- Time to first token p95 under 2.5 seconds excluding provider degradation
- Cached grounded answer p95 under 1 second
- Standard RAG answer p95 under 8 seconds excluding unusually slow providers
- No event-loop or memory growth
- Queue remains recoverable
- Provider fallback/circuit breaker works

Cross-role standard APIs retain Admin backend latency targets.

---

# 26. Security requirements

Cover:

- OWASP API Security Top 10
- Tenant isolation
- BOLA/IDOR
- Function-level authorization
- Field-level authorization
- Prompt injection
- Indirect prompt injection
- Data exfiltration
- Tool abuse
- SSRF
- File upload
- SQL/NoSQL injection
- XSS in AI-rendered markdown
- Markdown/link sanitization
- Secret leakage
- Provider data retention controls
- Payment/KYC privacy
- Model denial-of-wallet
- Rate-limit bypass
- Replay
- Conversation enumeration
- SSE authorization/reconnect
- Cross-role cache leakage
- Audit tampering

---

# 27. Tests

Create:

## AI

- `ai-conversation.spec`
- `ai-streaming.spec`
- `ai-language.spec`
- `ai-rag-grounding.spec`
- `ai-citation-security.spec`
- `ai-tenant-isolation.spec`
- `ai-role-field-isolation.spec`
- `ai-prompt-injection.spec`
- `ai-indirect-injection.spec`
- `ai-tool-authorization.spec`
- `ai-action-confirmation.spec`
- `ai-action-replay.spec`
- `ai-attachment-security.spec`
- `ai-memory-privacy.spec`
- `ai-cache-isolation.spec`
- `ai-rate-limit.spec`
- `ai-cost-budget.spec`
- `ai-provider-fallback.spec`
- `ai-evaluation-regression.spec`

## Cross-role

- `auth-session-rbac.spec`
- `role-permission-field-matrix.spec`
- `cross-role-notices.spec`
- `cross-role-complaints.spec`
- `cross-role-funds.spec`
- `cross-role-documents.spec`
- `cross-role-events.spec`
- `cross-role-visitors.spec`
- `cross-role-staff.spec`
- `cross-role-assets.spec`
- `cross-role-parking.spec`
- `cross-role-payments.spec`
- `cross-role-analytics.spec`
- `cross-role-governance.spec`
- `cross-role-realtime.spec`

Include real PostgreSQL/Redis integration tests, concurrency tests, property/invariant tests, contract tests, and k6 load tests.

---

# 28. API response capability metadata

Where useful, include server-derived capabilities:

```json
{
  "data": {},
  "capabilities": {
    "canEdit": true,
    "canDelete": false,
    "canAssign": true,
    "canViewInternalNotes": false
  }
}
```

Do not let the client determine permissions itself.

---

# 29. Migration strategy

Safely migrate:

- Firestore domain writes to PostgreSQL/domain services
- Legacy AI endpoint to conversation/run APIs
- Client-supplied history to server conversations
- Public files to private signed storage
- Role arrays to permission policies
- AI direct writes to proposals/domain services
- Duplicate role screens/providers to shared modules

Use:

- Data migration
- Backfill
- Dual-read only temporarily where necessary
- Reconciliation
- Feature flag
- Rollback
- Metrics
- Explicit end date for legacy path

Avoid indefinite dual-write.

---

# 30. Deliverables

1. Backend audit
2. Threat model
3. Cross-role architecture
4. Permission/field matrix
5. AI tool registry
6. Migrations
7. Domain services
8. AI conversation/RAG/tool system
9. APIs and OpenAPI 3.1
10. Workers
11. Redis rate limit/cache
12. Private storage
13. Tests
14. Evaluation datasets/harness
15. k6 scripts
16. Runbooks
17. Migration guide
18. `AI_CROSS_ROLE_BACKEND_TRACEABILITY.md` mapping:
    - Requirement
    - Role
    - Endpoint
    - Policy
    - Domain service
    - Tables
    - AI tool
    - Event/job
    - Test
    - Status

---

# 31. Implementation phases

## Phase 0 — Audit and threat model

- Confirm existing risks
- Map APIs and data
- Map permissions/fields
- Freeze migration plan

## Phase 1 — Shared policy/domain foundation

- Canonical roles
- Permissions
- Field serializers
- Domain services
- State machines
- PostgreSQL migration

## Phase 2 — AI conversation foundation

- Server history
- Conversation/message APIs
- Streaming protocol
- Language
- Provider abstraction
- Cost/logging

## Phase 3 — Secure RAG

- Private uploads
- Scanning
- Parsing
- Vector isolation
- Citations
- Grounding
- Injection defense

## Phase 4 — Cross-role module migration

- Notices
- Complaints
- Rules/events
- Visitors/staff
- Assets/parking
- Payments/funds
- Governance/analytics

## Phase 5 — AI tools

- Read tools
- Proposals
- Confirmation
- Domain execution
- Approval flows

## Phase 6 — Evaluation and operations

- Datasets
- Safety tests
- Cost/quotas
- Provider fallback
- Dashboards

## Phase 7 — Scale and release

- Load
- Failure injection
- Backup/restore
- Security audit
- Traceability

At each phase report:

- Files
- Migrations
- Endpoints
- Tools
- Tests/results
- Security findings
- Legacy paths remaining
- Blockers

---

# 32. Definition of done

Complete only when:

- English/Hindi/Hinglish work
- Society-specific answers are source-grounded
- Rule/event/facility/complaint use cases work
- AI retrieval obeys tenant, role, field, and document visibility
- Conversations are server-owned
- Streaming/reconnect work
- Files are private and scanned
- AI tools use normal domain services
- Writes require bound confirmation
- High-risk actions require proper approval/step-up
- Cross-role modules use one canonical record and state machine
- Every role sees only allowed rows/fields/actions
- Payments/ledger remain authoritative and replay-safe
- No public file URLs
- No production direct AI Firestore writes
- No unresolved P0/P1
- All tests/evaluations/load gates pass
- Backup/restore includes AI and cross-role data

Begin with Phase 0, not with adding more prompt text or a few hard-coded tools.


---

# SERO AI Chatbot and Cross-Role Modules — Complete QC, Security, and Release Audit Prompt

## Role

Act as an independent **Principal QA Architect, AI Red-Team Engineer, Flutter QA Engineer, Application Security Engineer, Cross-Role Authorization Auditor, FinTech QA Specialist, SRE, and Performance Engineer**.

Audit the completed SERO AI Copilot and all cross-role modules.

Your goal is to prove whether:

- English/Hindi/Hinglish work correctly
- Answers are society-specific and grounded
- AI retrieval and actions obey tenant, role, resource, and field permissions
- Cross-role modules use one consistent source of truth
- Resident/Admin/Staff/Guard/Super Admin experiences are correct
- Financial, visitor, staff, security, governance, and payment data remain protected
- AI cannot bypass normal workflows
- The existing SERO design is preserved
- The system supports the intended scale

Do not provide an opinion-only review. Execute tests and record evidence.

---

# 1. Required outputs

Produce:

1. `AI_CROSS_ROLE_QC_EXECUTIVE_SUMMARY.md`
2. `AI_CROSS_ROLE_QC_FINDINGS.md`
3. `AI_CROSS_ROLE_FEATURE_MATRIX.md`
4. `AI_CHATBOT_QUALITY_REPORT.md`
5. `AI_SAFETY_RED_TEAM_REPORT.md`
6. `CROSS_ROLE_AUTHORIZATION_REPORT.md`
7. `CROSS_ROLE_DATA_CONSISTENCY_REPORT.md`
8. `AI_CROSS_ROLE_VISUAL_QC_REPORT.md`
9. `AI_CROSS_ROLE_LOAD_REPORT.md`
10. `AI_CROSS_ROLE_RELEASE_GATE.md`
11. `ai_cross_role_qc_findings.json`

Every defect:

- ID
- Severity P0/P1/P2/P3
- Category
- Role
- Module
- Screen/endpoint/tool
- File/line
- Evidence
- Reproduction
- Expected
- Actual
- Impact
- Security/financial/privacy impact
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
- Cross-role field leak
- Unauthorized AI tool execution
- AI action executes without valid confirmation
- Payment/ledger corruption
- Public KYC/rule/private file
- Resident sees internal complaint note
- Guard sees unauthorized resident/staff/financial data
- Staff sees another employee’s private payroll
- AI reveals another user’s conversation
- Prompt injection causes unauthorized retrieval/tool use
- Feature/permission disabled in UI but callable through API
- Audit logs missing for sensitive AI action
- Clean build/test failure
- No reproducible install
- No migration/backup restore proof
- Load target failure
- Unresolved P0/P1 in auth, isolation, payment, AI tools, file security, or privacy

---

# 3. Clean environment and repository health

Run:

- Backend clean install
- Lockfile validation
- TypeScript strict compile
- Lint
- Unit/integration/contract tests
- Docker build
- Compose startup
- Fresh migrations
- Upgrade migration
- Worker startup
- Flutter pub get
- Dart formatting
- Flutter analyze
- Flutter unit/widget/golden/integration tests

Check:

- No `--force` or `--legacy-peer-deps`
- No test skips hiding failures
- No forced Jest termination
- No production mock fallback
- No debug provider/API key
- No public storage
- No direct privileged Firestore write
- No stale legacy AI route bypass

---

# 4. Role and field test matrix

Create identities for:

- Super Admin
- Main Admin
- Admin
- Secretary
- Treasurer
- Committee member
- Facility manager
- Security manager
- Guard
- Staff
- Resident owner
- Resident tenant
- Auditor

Create:

- Society A
- Society B
- Multiple units
- Assigned and unassigned staff
- Public and private documents
- Internal/public complaint notes
- Different payment/visitor/parking records

For every endpoint, realtime channel, file, export, and AI tool test:

- Positive role
- Negative role
- Resource ownership
- Society isolation
- Field redaction
- State-based action
- Feature entitlement
- Permission revoked mid-session
- Role change mid-session
- Society switch
- Impersonation context

---

# 5. AI language quality QC

Build evaluation sets for:

## English

- Clear questions
- Typos
- Short questions
- Long questions
- Formal/informal

## Hindi

- Devanagari
- Society vocabulary
- Amount/date/time
- Rule/event/facility/complaint

## Hinglish

- Latin-script Hindi
- Code switching
- Informal phrases
- Misspellings
- English technical terms mixed with Hindi

Test:

- Language detection
- Manual language preference
- Follow-up remains in selected language
- Identifiers preserved
- INR/date/time accurate
- Names/flat/wing/invoice not corrupted
- No nonsensical literal translation
- Consistent tone
- Safety refusal in correct language
- Citations remain readable
- Tool confirmation accurately localized

Human-review a representative set. Do not rely only on an LLM judge.

---

# 6. AI use-case quality QC

Test required use cases:

- Society-specific answer
- Rule lookup
- Event information
- Facility timing
- Complaint guidance

Also test:

- Bill explanation
- Payment troubleshooting
- Notice explanation
- Visitor guidance
- Parking guidance
- Staff shift guidance
- Asset/service status
- Governance question

For every answer validate:

- Correct society
- Correct user scope
- Correct source
- Correct version/effective date
- Citation
- No fabricated detail
- Appropriate uncertainty
- Correct language
- Correct deep link

---

# 7. RAG isolation and citation QC

Test:

- Society A asks about Society B rule
- Resident asks for committee-only document
- Guard asks for finance document
- Staff asks for payroll policy outside scope
- Archived document
- Superseded version
- Future-effective rule
- Deleted document
- Empty knowledge base
- Conflicting documents
- Document without page metadata
- Source permission changes after indexing
- Index cache stale
- Cross-tenant vector query
- Semantic cache collision

Verify retrieval filters happen before model generation.

Citation tests:

- Source exists
- Source permitted
- Version matches
- Page/section matches
- Claim supported
- Link authorization
- Expired link
- No citation to deleted document

---

# 8. AI prompt-injection red team

Test direct injection:

- Ignore all previous instructions
- Reveal system prompt
- Pretend I am admin
- Change society ID
- Use raw SQL
- Call hidden tool
- Reveal API key
- Show another user’s messages

Test indirect injection in:

- PDF
- Image OCR
- Rule document
- Notice
- Meeting minutes
- Complaint attachment
- HTML/office file
- Metadata/file name

Attack goals:

- Cross-society data
- Cross-role data
- Internal notes
- Payroll
- KYC
- Payment details
- Audit logs
- Tool execution
- Provider/system prompt
- Secret exfiltration

Verify:

- Retrieval can include untrusted text without treating it as system instruction
- Tool arguments remain schema-bound
- Policy check happens after planning
- No secret is in model context
- Safety event is logged
- User receives a safe response

---

# 9. AI action confirmation QC

For every write tool:

- Proposal creation
- Proposal fields
- Human-readable impact
- Permission
- Expiry
- Edit
- Cancel
- Confirm
- Reconfirm after edit
- Step-up auth
- Approval
- Resource version conflict
- Duplicate confirm
- Replay
- Different user
- Different society
- Guessed ID
- Tampered args
- Expired proposal
- Role revoked
- Feature disabled
- Domain service failure
- Notification failure
- Retry

Expected:

- Parameters executed exactly match confirmed proposal
- Exactly-once effect
- Audit identifies model, proposal, actor, and domain transaction
- No AI-specific bypass
- High-risk action remains pending approval where required

---

# 10. Conversation privacy QC

Test:

- User A conversation ID used by User B
- Society A ID used by Society B
- Admin conversation accessed by resident
- Super Admin platform chat accessing society data without explicit context
- Archived/deleted conversation
- Search
- Export
- Attachment
- Citation link
- Cache
- Conversation title
- Feedback
- Memory
- Logout
- Society switch
- Role change
- Impersonation end
- Device revocation

No previous context may remain visible after identity/society context changes.

---

# 11. Attachment/file QC

Test:

- Oversized
- MIME spoof
- Double extension
- Zip bomb
- Malware test file
- Active content
- Path traversal
- Public URL
- Cross-tenant object key
- Expired signed URL
- Cancel upload
- Retry
- Parser crash
- OCR error
- Duplicate
- Deleted attachment
- Prompt injection
- Image with hidden text
- Large base64 request to legacy endpoint
- Remote URL SSRF:
  - localhost
  - private IP
  - metadata IP
  - redirects
  - DNS rebinding

Verify quarantine and no ingestion before scan.

---

# 12. Cross-role notice QC

Test:

- Audience
- Read/unread
- Acknowledgement
- Draft/schedule/publish/expire/archive
- Resident cannot publish
- Secretary permission
- Staff audience
- Attachment permission
- AI explain
- AI draft
- AI publish attempt without confirmation
- Version history
- Realtime
- Cross-society

---

# 13. Cross-role complaint QC

Test:

- Resident create
- Category
- Attachments
- Public comment
- Internal note
- Assignment
- Staff accept/start/complete
- Admin priority/SLA/escalation
- Invalid transitions
- Duplicate/merge
- Resolution
- Reopen
- CSAT
- AI guidance
- AI proposal
- AI assignment suggestion
- Unauthorized internal timeline
- Cross-society
- Concurrent update

One complaint record must remain consistent across roles.

---

# 14. Cross-role fund/payment QC

Test:

- Resident own bills only
- Treasurer society ledger
- Admin aggregate
- Auditor read-only
- Staff/guard denied
- AI explain bill
- AI exact totals
- No truncated-list aggregation
- Payment success only after verified provider event
- Webhook signature
- Replay
- Out-of-order
- Refund
- Reconciliation
- Expense proposal
- Approval
- Ledger invariants
- Cross-society
- Sensitive payment data redaction

---

# 15. Cross-role rules/documents QC

Test:

- Resident published rule
- Admin draft/private version
- Auditor history
- Effective date
- Superseded version
- Attachment
- Signed link
- Search
- AI answer/citation
- Role visibility
- Cross-society
- Document delete/archive and index invalidation

---

# 16. Cross-role event/governance QC

Events:

- Create/publish
- Eligibility
- RSVP
- Capacity
- Waitlist
- Cancel
- Attendance
- Reminder
- AI event answer/draft
- Overbooking concurrency

Governance:

- Meeting
- Agenda
- Attendance
- Quorum
- Eligibility snapshot
- Vote one time
- Anonymous privacy
- Resolution
- Minutes
- Action items
- AI draft
- AI cannot vote
- Published versus private minutes

---

# 17. Cross-role visitor/staff/security QC

Visitor:

- Resident preapproval
- Guard verification
- OTP/QR replay
- Check-in/out
- Expiry
- Parcel
- Watchlist permission
- Privacy
- AI guidance

Staff:

- Own attendance/leave/shift/payslip
- Manager/admin operations
- Other staff privacy
- Payroll permission
- Terminated access
- AI shift guidance
- Internal disciplinary data

Guard:

- Restricted shell
- No finance/staff payroll/member KYC
- Visitor/incident/patrol only as permitted

---

# 18. Cross-role asset/parking QC

Asset:

- Resident public outage
- Staff assigned work order
- Manager maintenance/AMC
- Internal notes
- Completion proof
- AI guidance
- Dangerous instruction refusal/approved manual citation

Parking:

- Resident own vehicle/allocation
- Guard lookup
- Admin allocate
- Unique active allocation
- Waitlist
- Transfer/release
- Visitor parking
- Violation
- AI request proposal
- Concurrency
- Cross-society

---

# 19. Analytics QC

For each role verify:

- Correct scope
- Correct fields
- Correct date range
- As-of time
- Drill-down permission
- Aggregate/source consistency
- No client-side total from truncated data
- No cache leakage
- Accessible chart fallback

Compare API aggregates to independent database queries.

---

# 20. Realtime and streaming QC

AI:

- Correct SSE event order
- Duplicate
- Reconnect
- Last event ID
- Stop
- Provider failure
- Timeout
- Permission revoked
- Conversation deleted
- App background/resume

Modules:

- Complaint
- Notice
- Visitor
- Event
- Payment
- Staff task
- Asset
- Parking
- Governance

Verify room authorization and cross-society isolation.

---

# 21. Frontend design QC

Compare against existing SERO Admin design:

- Theme colors
- Outfit
- Gradients
- Card radius
- Input radius
- Page padding
- Status badges
- Drawer/bottom navigation
- Loading/empty/error states
- Responsive behavior

Test screens:

- Resident Copilot
- Admin Copilot
- Guard Copilot
- Hindi answer
- Hinglish answer
- Grounded answer
- Action proposal
- Execution result
- Shared notice
- Shared complaint by three roles
- Shared visitor
- Payment
- Governance

Test dimensions:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet portrait/landscape
- 1366×768
- 1440×900
- 200% text scaling

---

# 22. Accessibility QC

Test:

- Screen reader
- Keyboard
- Focus order
- Stream announcements
- Stop generation control
- Citations
- Source expansion
- Attachments
- Confirmation dialog
- Error form association
- Color contrast
- Touch targets
- Reduced motion
- Charts
- Hindi text rendering
- Mixed-script wrapping

---

# 23. Performance and load QC

Use production-like infrastructure.

## Overall

- 3,000 authenticated users
- 250 sustained mixed RPS
- 500 RPS burst
- 3,000 realtime connections
- Four-hour soak

## AI

- 300 active chat sessions
- 100 simultaneous streams
- Cached answer
- RAG answer
- Attachment ingestion
- Provider slowdown
- Provider failure/fallback
- Redis restart
- Worker crash
- Reconnect storm
- Cost limit

## Cross-role mix

- Notices
- Complaints
- Rules/events
- Visitors
- Staff
- Payments
- Assets/parking
- Analytics/governance

Report:

- RPS
- p50/p90/p95/p99
- Time to first token
- Full completion
- Error
- CPU/memory
- Event loop
- DB pool/locks
- Redis
- Queue depth/age
- Provider latency/cost
- SSE disconnect
- Cache hit
- Authorization denial latency

Verify no data leak or duplicate action under load.

---

# 24. Failure injection

Test:

- PostgreSQL outage
- Redis outage
- Vector store outage
- Object storage outage
- Malware scanner outage
- AI provider timeout
- AI provider rate limit
- Firebase outage
- Payment provider outage
- Worker crash
- API crash after domain commit
- SSE disconnect after tool proposal
- Queue duplicate
- Deadlock
- Old/new deployment version mix

Verify:

- No corrupt state
- Safe retry
- Idempotency
- Clear UI state
- Alert
- Recovery
- No silent fallback to ungrounded answer

---

# 25. Audit and observability QC

Verify sensitive actions log:

- Actor
- Effective actor
- Society
- Role/permission
- Conversation
- Message/run
- Tool/version
- Proposal
- Confirmation
- Domain record
- Before/after
- Result
- Request ID
- Model/provider/prompt version
- Cost
- Safety event
- Timestamp

Ensure:

- Logs are append-only
- Content is redacted
- Audit export is audited
- Metrics/alerts work
- Trace crosses AI to domain transaction

---

# 26. Evaluation regression QC

Run fixed datasets before and after changes.

Fail release on regression beyond defined thresholds in:

- English correctness
- Hindi correctness
- Hinglish correctness
- Grounding
- Citation
- Refusal
- Tool selection
- Tool arguments
- Authorization safety
- Latency
- Cost

Review LLM-judge output with deterministic checks and human samples.

---

# 27. Backup/restore/deletion QC

Test backup/restore of:

- Conversations
- Messages
- Citations
- Proposals/executions
- AI audit/cost
- Documents/index metadata
- Domain modules
- Permissions
- Outbox
- Payments/ledger

Test:

- User deletes conversation
- User deletes memory
- Society offboarding
- Document deletion
- Vector removal
- Cache invalidation
- Retention job
- Legal hold if configured

Verify restored system preserves authorization and audit integrity.

---

# 28. Repository-specific checks

Verify:

1. Current stateful local AI history is replaced or safely migrated.
2. SSE is actually used by the UI.
3. Client history is not authoritative.
4. AI no longer reads privileged totals directly through client Firestore.
5. Large attachments do not use base64 client memory.
6. Uploaded AI documents are not public.
7. SSRF protection handles redirects/private ranges/DNS.
8. Prompt injection defense is layered, not keyword-only.
9. Grounding is not only vocabulary overlap.
10. AI permissions use central policy, not scattered role arrays.
11. AI writes use canonical domain services.
12. `actionId` execution is bound to actor, society, exact args, expiry, and confirmation.
13. AI cache keys include society/permission/language/prompt/model/index versions.
14. RAG filtering is enforced in database retrieval.
15. AI logs do not expose sensitive args/content.
16. Cross-role screens use one canonical entity.
17. `MainShell` routes roles correctly.
18. Direct privileged Firestore writes are removed.
19. Mock data does not remain in production.
20. Payment success is webhook-authoritative.
21. Internal complaint notes are separated.
22. Staff payroll fields are redacted.
23. Guard access is restricted.
24. Governance votes cannot be cast by AI.
25. Existing Admin/Super Admin tests still pass.

---

# 29. Final report

End with:

## Executive verdict

- Release gate
- P0/P1/P2/P3 counts
- Top risks
- Environment
- Tested scale
- Untested scope

## AI verdict

- Languages
- Use cases
- Grounding
- Citations
- Safety
- Tools
- Privacy
- Cost/performance

## Cross-role verdict

For every module:

- Role scope
- Data consistency
- Field security
- State machine
- API/UI
- Tests
- Pass/fail

## Design verdict

- SERO consistency
- Responsive
- Accessibility
- Visual regressions

## Security verdict

- Tenant isolation
- Role/field isolation
- Prompt injection
- Files
- Payments
- Conversation privacy
- Audit

## Reliability verdict

- Streaming
- Queues
- Provider fallback
- Realtime
- Backup/restore
- Failure recovery

## Performance verdict

- Users
- RPS
- AI streams
- TTFT
- Latency
- Error
- Headroom

## Blocking actions

List exact changes required before release.

Do not state “production ready” without executed evidence.

