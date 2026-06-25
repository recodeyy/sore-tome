
# SERO Super Admin Complete Prompt Pack

This pack contains:

1. Super Admin frontend implementation prompt
2. Super Admin backend implementation prompt
3. Super Admin frontend/backend QC and release-audit prompt

The prompts are designed to extend the existing SERO Society Admin experience without changing its established visual language.

---

# SERO Super Admin Frontend — Master Implementation Prompt

## Role

Act as a **Principal Flutter Architect, Senior Product Designer, Design-System Engineer, Riverpod Expert, Accessibility Specialist, and Frontend QA Engineer**.

You are working inside the existing **SERO — AI Powered Society Management Platform** repository.

The existing Society Admin application already has a strong mobile-first visual language. Your task is to build the complete **Super Admin frontend/control-center experience** using the **same design system, same interaction quality, same component logic, and same navigation behavior as the current Admin screens**—while adapting the information architecture for platform-level operations across all societies.

Do not redesign the application into an unrelated dashboard. Do not create generic Material UI screens. Do not create a separate visual brand. The Super Admin module must look and feel like a natural extension of the existing Admin application.

---

# 1. Repository-first instructions

Before writing code:

1. Inspect the complete Flutter repository, especially:
   - `lib/app/theme.dart`
   - `lib/app/admin_shell.dart`
   - `lib/app/main_shell.dart`
   - `lib/app/app.dart`
   - `lib/screens/admin/**`
   - `lib/widgets/common/**`
   - `lib/widgets/shared/**`
   - `lib/providers/admin/**`
   - `lib/providers/shared/**`
   - `lib/services/admin/**`
   - `lib/services/api_client.dart`
   - Authentication and role guards
   - Existing mock data and direct Firestore access

2. Produce:
   - `SUPER_ADMIN_FRONTEND_AUDIT.md`
   - `SUPER_ADMIN_SCREEN_MAP.md`
   - `SUPER_ADMIN_ROUTE_MAP.md`
   - `SUPER_ADMIN_COMPONENT_INVENTORY.md`

3. Identify:
   - Reusable Admin widgets
   - Widgets that should become shared platform widgets
   - Current hard-coded mock data
   - Existing API contracts
   - Role-name inconsistencies such as `superadmin` versus `super_admin`
   - Responsive limitations
   - Accessibility issues
   - Screens that directly read/write Firestore

4. Do not begin bulk UI coding until the audit and screen map are complete.

---

# 2. Preserve the existing SERO design language

Use the current SERO Admin visual system as the source of truth.

## 2.1 Colors

Reuse the current design tokens:

- Deep Emerald: `#064E3B`
- Near-black Navy: `#111827`
- Deep Navy Blue: `#1E3A8A`
- Emerald Accent: `#10B981`
- Sky Accent: `#0EA5E9`
- Slate Background: `#F8FAFC`
- Slate Border: `#E2E8F0`
- Primary text: `#1E293B`
- Secondary text: `#64748B`
- Muted text: `#94A3B8`
- Error: `#EF4444`
- Warning/Amber: use the existing badge palette
- Success: use the existing green badge palette
- Information: use the existing blue badge palette

Use the existing premium gradients:

- Deep Emerald → Near-black Navy
- Deep Emerald → Deep Navy Blue

Do not introduce a random purple SaaS theme.

## 2.2 Typography

Use **Google Fonts Outfit** everywhere, matching the Admin module:

- Major page titles: 22–24 px, weight 700–800
- Section headings: 16–18 px, weight 600–700
- Card values: 20–28 px, weight 700–900
- Body: 13–14 px
- Labels and badges: 10–12 px, weight 600–700
- Use tight negative letter spacing only where the existing design does

## 2.3 Shape and spacing

- Main cards: 24 px radius
- Inputs and primary buttons: 20 px radius
- Small chips/buttons: 10–12 px radius
- Page horizontal padding: 20 px
- Card padding: generally 16–20 px
- Use subtle slate borders and low-opacity shadows
- Maintain generous whitespace
- Avoid dense enterprise tables on mobile; use cards, bottom sheets, segmented filters, and drill-down pages

## 2.4 Screen structure

Follow the current Admin screen composition:

- Deep emerald or premium-gradient top header
- Safe-area-aware top spacing
- Menu icon on the left
- Notification icon with unread badge on the right
- Greeting or page title below
- Optional subtitle/date/context
- White/slate content area
- Stat cards
- Section headers with “View All”
- Quick actions
- Status badges
- Pull-to-refresh
- Shimmer/skeleton loading
- Proper empty, error, offline, and retry states
- Bottom navigation on mobile
- Drawer for full module navigation

## 2.5 Motion

Use restrained motion consistent with the Admin experience:

- Short fade/slide entrances
- Smooth count transitions
- Animated progress bars
- Skeleton loading
- No excessive parallax or decorative animation
- Respect reduced-motion accessibility preferences

---

# 3. Super Admin role and route integration

Create a dedicated role experience rather than routing Super Admin into the Society Admin shell.

## 3.1 Canonical role

Use `super_admin` as the canonical role in frontend models and route guards.

During migration, safely accept the legacy claim `superadmin`, but normalize it immediately to `super_admin`.

Do not treat Super Admin as `main_admin`.

## 3.2 New application structure

Create:

- `lib/app/super_admin_shell.dart`
- `lib/screens/super_admin/**`
- `lib/providers/super_admin/**`
- `lib/services/super_admin/**`
- `lib/models/super_admin/**`
- `lib/widgets/super_admin/**`

Update:

- `main_shell.dart`
- `app.dart`
- `auth_guard.dart`
- Authentication user/role model
- Navigation provider
- Notification routing

The dispatcher must behave like:

- `super_admin` → `SuperAdminShell`
- Society roles → `AdminShell`
- Resident → `ResidentShell`
- Guard/staff → their restricted shell

---

# 4. Super Admin mobile navigation

Use the same five-tab bottom-navigation logic as Admin.

## Bottom tabs

1. **Overview**
   - Icon: dashboard/home
2. **Societies**
   - Icon: apartment/business
3. **Revenue**
   - Center circular green “G” action, matching the existing Admin Finance tab
4. **Support**
   - Icon: support agent/chat
5. **More**
   - Icon: more horizontal

The centered “G” button must preserve:

- Circular shape
- Emerald coloring
- Selected/unselected state
- Existing shadow logic
- Existing size and vertical alignment

## Drawer groups

### Platform
- Overview
- Societies
- Users
- Society Approvals
- KYC Verification
- Setup Progress

### Revenue
- Revenue Dashboard
- Subscriptions
- Plans and Pricing
- Invoices and Payments
- Revenue Reports
- Churn Analytics

### Operations
- Support Tickets
- Global Announcements
- Push Notifications
- Feature Controls
- White-label Management

### Platform Intelligence
- DAU/MAU Analytics
- Adoption Analytics
- AI Usage and Costs
- System Health
- Job and Queue Monitor

### Security and Administration
- Audit Logs
- Access Logs
- Impersonation Sessions
- API Access
- Integrations and Webhooks
- Security Center
- Platform Settings

### Account
- Profile
- Settings
- Logout

Use the same drawer header style as Admin, but show:

- Super Admin avatar
- Name
- `SUPER ADMIN`
- `SERO PLATFORM CONTROL`

---

# 5. Complete Super Admin capability scope

The feature document states 31 Super Admin capabilities but explicitly lists only part of them. Preserve all explicitly listed capabilities and complete the module with the platform controls required to make the stated 31-feature scope operational.

Implement these 31 capabilities end to end in the frontend.

## A. Platform overview and analytics — 1 to 7

1. View total societies with active, trial, suspended, and onboarding breakdown.
2. View total users with role and growth breakdown.
3. Monitor MRR, ARR, collections, refunds, outstanding subscription revenue, and revenue trend.
4. View Daily Active Users.
5. View Monthly Active Users.
6. Analyze churn rate, retention, reactivation, and at-risk societies.
7. View platform adoption metrics such as active modules, feature engagement, and onboarding funnel.

## B. Society lifecycle management — 8 to 13

8. View and search all societies.
9. Approve or reject new society applications.
10. Verify society KYC documents.
11. Track society setup/onboarding progress.
12. View complete society details, usage, plan, billing, administrators, health, and recent activity.
13. Suspend, reactivate, archive, or safely offboard a society with confirmation and audit reason.

## C. Subscription and revenue administration — 14 to 18

14. Monitor subscriptions, renewals, trials, grace periods, failures, upgrades, and downgrades.
15. Manage subscription plans.
16. Assign or change a society plan with effective date and proration preview.
17. View platform invoices, payments, refunds, and reconciliation status.
18. Generate and export revenue, subscription, collections, tax, and churn reports.

## D. Platform configuration — 19 to 23

19. Toggle features per society.
20. Manage feature-rollout cohorts, prerequisites, dependencies, and staged rollout.
21. Configure white-label branding per society or plan.
22. Control API access, API keys, scopes, quotas, revocation, and usage.
23. Manage platform integrations, webhooks, email/SMS/push providers, and service configuration.

## E. Communication and support — 24 to 27

24. Send global announcements.
25. Send segmented push notifications.
26. Manage support tickets with SLA, priority, assignment, escalation, comments, and attachments.
27. View support analytics, backlog, response time, resolution time, CSAT, and breached tickets.

## F. Security, operations, and governance — 28 to 31

28. Access immutable audit logs and access logs.
29. Perform controlled impersonation with reason, approval where configured, expiry, persistent banner, and stop-session action.
30. Monitor platform/system health, queues, failed jobs, third-party dependencies, incidents, and maintenance windows.
31. Manage platform users, security controls, AI usage/cost limits, global settings, and compliance/data-export actions.

---

# 6. Required screens and screen behavior

## 6.1 Super Admin Overview

Create `super_admin_dashboard_screen.dart`.

### Header

- Menu icon
- Notification icon with unread badge
- Greeting: `Good Morning, <Name> 👋`
- Context: `SERO Platform`
- Date label
- Optional environment pill in non-production builds only

### First stat section

Use two rows of three compact StatCards on mobile:

- Total Societies
- Pending Approvals
- Active Users
- Monthly Revenue
- Open Support Tickets
- System Health

Each card must:

- Use an icon and soft icon background
- Show trend versus previous period
- Be tappable
- Route to filtered details

### Dashboard sections

- Quick Actions:
  - Approve Society
  - Review KYC
  - Send Announcement
  - Create Plan
  - Open Support Queue
  - View Audit Logs
- Revenue overview card
- Society onboarding funnel
- DAU/MAU trend
- Churn and at-risk societies
- Support SLA summary
- Platform health strip
- Recent platform activity
- Failed jobs/critical alerts
- AI usage and cost snapshot

All dashboard data must come from Super Admin providers and services, not `MockDashboardData`.

## 6.2 Societies List

Create:

- Search
- Filter chips:
  - All
  - Active
  - Trial
  - Onboarding
  - Suspended
  - Payment Due
- Sort:
  - Recently added
  - Highest usage
  - Revenue
  - At risk
- Infinite/cursor pagination
- Pull-to-refresh
- Society cards showing:
  - Logo
  - Name
  - City
  - Plan
  - Status
  - Members
  - MAU
  - Setup completion
  - Subscription renewal date
  - Health badge
- Multi-select only for safe bulk actions
- No destructive bulk delete

## 6.3 Society Detail

Use tabs or segmented navigation:

- Overview
- Setup
- Subscription
- Usage
- Features
- Admins
- Billing
- Support
- Activity
- Security

Actions:

- Approve/reject
- Request more information
- Change plan
- Toggle feature
- Suspend/reactivate
- Open impersonation
- Export society data
- View audit trail

Every sensitive action must show:

- Impact summary
- Required reason
- Confirmation
- Success/failure feedback
- Audit reference/request ID

## 6.4 Society Approval Queue

Cards with:

- Society name
- Applicant
- Submitted date
- City/state
- Requested plan
- Document completeness
- Risk flags
- Setup progress

Detail screen:

- Application data
- Admin identity
- Society registration data
- Uploaded documents
- Verification checklist
- Internal notes
- Approve
- Reject
- Request information

## 6.5 KYC Verification

- Queue filters
- Document preview
- Zoom/download
- Expiry
- OCR-extracted values
- Compare form versus document
- Approve/reject/request replacement
- Reason templates
- Full history
- Never expose file URLs directly

## 6.6 Setup Progress

- Overall platform onboarding metrics
- Per-society progress
- Steps:
  - Society profile
  - Structure
  - Admins
  - Members
  - Billing
  - Payment setup
  - Communication
  - Staff
  - Amenities
  - Go-live
- Blockers
- Owner
- Last activity
- Reminders/escalation

## 6.7 Revenue Dashboard

Reuse the same visual logic as Admin Finance, but platform-level.

Include:

- MRR
- ARR
- Collection this month
- Outstanding amount
- Refunds
- Failed payments
- Trial conversion
- Revenue by plan
- Revenue trend
- Renewal calendar
- Top societies by revenue
- At-risk renewals
- Drill-down and date filters

Never calculate large totals from a truncated client-side list.

## 6.8 Subscription Monitoring

- Subscription list
- Current plan
- Status
- Billing cycle
- Renewal
- Payment method status
- Grace period
- Failed attempts
- Upgrade/downgrade
- Cancellation request
- Pause/resume
- Timeline

## 6.9 Plans and Pricing

- Plan cards
- Feature matrix
- Monthly/yearly price
- Trial configuration
- Usage limits
- Overage settings
- Tax settings
- Active/inactive
- Version history
- Draft/publish lifecycle
- Prevent silent changes to existing subscriber entitlements

## 6.10 Feature Controls

- Global feature registry
- Search by module
- Feature description
- Required plan
- Dependencies
- Default state
- Society override
- Cohort rollout
- Percentage rollout
- Start/end date
- Emergency kill switch
- Change history
- Preview impact before save

## 6.11 DAU/MAU and Churn Analytics

- Date range selector
- DAU
- WAU
- MAU
- Stickiness
- New societies
- Activated societies
- Trial conversion
- Churn
- Retention cohorts
- Feature adoption
- At-risk list
- Export

Charts must have accessible labels and a list/table fallback.

## 6.12 Global Announcements

- Draft
- Preview
- Audience:
  - All societies
  - Plans
  - Regions
  - Status
  - Cohorts
  - Selected societies
- Channel:
  - In-app
  - Push
  - Email
  - Optional SMS if configured
- Schedule
- Expiry
- Acknowledgement required
- Delivery/read statistics
- Cancel scheduled announcement

## 6.13 Push Notifications

- Template selector
- Segment builder
- Preview
- Deep link target
- Schedule
- Quiet-hour warning
- Send test
- Estimated audience
- Delivery status
- Failure breakdown

## 6.14 White-label Management

- Society/plan selection
- Logo
- App name
- Primary/secondary/accent colors
- Email header/footer
- Login branding
- Domain status
- Preview in phone frame
- Accessibility contrast warning
- Draft and publish
- Rollback to previous version

White-label settings must not alter the Super Admin control-center brand.

## 6.15 Support Tickets

Screens:

- Support overview
- Ticket list
- Ticket detail
- Assignment
- SLA dashboard

Ticket detail must support:

- Society and reporter
- Priority
- Category
- Status
- Assignee/team
- SLA due time
- Timeline
- Public reply
- Internal note
- Attachments
- Linked incidents
- Escalation
- Resolve/reopen
- CSAT
- Audit trail

## 6.16 Audit and Access Logs

- Cursor pagination
- Search
- Filter by actor, society, role, module, action, result, date, IP/device
- Before/after diff viewer
- Request/correlation ID
- Export with permission
- Sensitive fields redacted
- No client-side ability to alter/delete logs

## 6.17 Impersonation

Create a dedicated secure flow:

1. Select society
2. Select eligible user/admin
3. Enter reason
4. Select duration
5. Display permissions and restrictions
6. Confirm
7. Start session

During impersonation:

- Persistent warning banner on every screen
- Show original Super Admin identity
- Show impersonated identity/society
- Countdown/expiry
- “Stop Impersonation” always visible
- Restrict prohibited actions
- Do not expose user credentials
- Do not silently hide the session

## 6.18 API Access

- API clients/keys
- Name and owner
- Society or platform scope
- Permission scopes
- Created date
- Last used
- Expiry
- Status
- Usage
- Rate-limit consumption
- Create/revoke/rotate
- Reveal secret only once
- Webhook management
- Delivery logs and retry

## 6.19 System Health

- Overall status
- API
- Database
- Redis
- Queue
- Object storage
- Firebase
- Payments
- Email/SMS/push
- AI providers
- Incident banner
- Job failures
- Queue depth
- Retry/dead-letter actions with permissions
- Maintenance windows
- No secrets in health payloads

## 6.20 Platform Users and Settings

- Super Admin users
- Support agents
- Finance operators
- Read-only auditors
- Roles and permissions
- Invite/suspend/reactivate
- MFA status
- Last login
- Session revocation
- Platform preferences
- Notification defaults
- Security settings
- Retention policies
- AI cost limits
- Compliance export/deletion workflow

---

# 7. State management and data layer

Use Riverpod consistently.

For each module create:

- Immutable model
- Query/filter model
- Repository/service
- Provider/notifier
- Loading state
- Empty state
- Error state
- Pagination state
- Refresh/invalidate behavior
- Optimistic update only where safe
- Rollback on failure

Rules:

- No business logic directly inside widgets
- No direct privileged Firestore writes
- No mock fallback in production
- Use typed DTOs
- Parse money and dates safely
- Support cancellation/disposal
- Prevent duplicate requests
- Use cursor pagination
- Preserve filters when opening details and returning
- Display backend request ID on supportable errors

---

# 8. Responsive behavior

The current product is mobile-first, but Super Admin must also work on tablet and web.

## Mobile

- Existing five-tab bottom navigation
- Drawer
- Cards instead of wide tables
- Bottom sheets for filters/actions
- One-column detail layout

## Tablet

- Navigation rail or expanded drawer when appropriate
- Two-column dashboard
- Master-detail for lists where practical

## Desktop/web

- Persistent sidebar
- Three- or four-column stat grid
- Data tables with sticky headers
- Detail side panels
- Keyboard navigation
- Breadcrumbs
- Maintain the same emerald/navy visual identity

Use responsive breakpoints and shared responsive widgets, not duplicated pages.

---

# 9. Accessibility

Meet WCAG 2.1 AA where applicable:

- Minimum touch targets
- Semantic labels
- Screen-reader-friendly charts and icons
- Sufficient contrast
- Keyboard focus
- Visible focus state
- Text scaling
- No color-only status communication
- Accessible confirmation dialogs
- Reduced motion
- Logical reading order
- Proper error associations on forms

---

# 10. Security-sensitive frontend requirements

- Never store API secrets in plain text
- Never show a full secret after initial creation
- Never trust hidden buttons as authorization
- Every privileged request is still authorized server-side
- Never place tokens in URLs
- Use secure token storage
- Redact KYC and audit-sensitive values
- Block screenshots only where product/legal policy explicitly requires it
- Clear cached cross-tenant data on logout, role change, and impersonation end
- Do not allow back navigation to reveal a previous society after impersonation ends
- Add re-authentication for highly sensitive actions if required by backend
- Display impersonation banner continuously
- Do not expose internal stack traces

---

# 11. Frontend tests

Create:

- Widget tests
- Provider tests
- Repository/service contract tests
- Golden tests for major screens
- Navigation tests
- Role-routing tests
- Responsive tests
- Accessibility tests
- Empty/loading/error/offline tests
- Pagination tests
- Impersonation-banner persistence tests
- Feature-flag rendering tests
- Form-validation tests
- Destructive-action confirmation tests
- API-secret reveal-once tests
- White-label contrast tests

Critical golden screens:

- Super Admin dashboard
- Societies list
- Society detail
- Approval/KYC
- Revenue dashboard
- Plans
- Feature controls
- Support ticket detail
- Audit log detail
- Impersonation state
- System health
- Desktop dashboard

---

# 12. Required routes

Use a coherent route hierarchy such as:

- `/super-admin`
- `/super-admin/dashboard`
- `/super-admin/societies`
- `/super-admin/societies/:id`
- `/super-admin/approvals`
- `/super-admin/kyc`
- `/super-admin/setup-progress`
- `/super-admin/users`
- `/super-admin/revenue`
- `/super-admin/subscriptions`
- `/super-admin/plans`
- `/super-admin/invoices`
- `/super-admin/reports`
- `/super-admin/features`
- `/super-admin/announcements`
- `/super-admin/push`
- `/super-admin/white-label`
- `/super-admin/support`
- `/super-admin/support/:id`
- `/super-admin/analytics`
- `/super-admin/churn`
- `/super-admin/ai-usage`
- `/super-admin/audit`
- `/super-admin/access-logs`
- `/super-admin/impersonation`
- `/super-admin/api-access`
- `/super-admin/integrations`
- `/super-admin/system-health`
- `/super-admin/security`
- `/super-admin/settings`

All routes must require the Super Admin role or a narrower platform permission.

---

# 13. Deliverables

Produce:

1. Super Admin frontend audit
2. Complete screen/route map
3. Shared component refactor plan
4. New Super Admin shell
5. All screens required for the 31 capabilities
6. Models, providers, services, and typed API contracts
7. Responsive layouts
8. Loading/empty/error/offline states
9. Widget/provider/golden/accessibility tests
10. Updated role dispatcher and route guards
11. No broken Society Admin screens
12. `SUPER_ADMIN_FRONTEND_TRACEABILITY.md` mapping:
    - Feature 1–31
    - Screen
    - Route
    - Provider
    - Service method
    - API endpoint
    - Test
    - Status

---

# 14. Implementation sequence

## Phase 0 — Audit

- Inspect current Admin design and architecture
- Produce maps
- Verify role routing
- Identify reusable widgets

## Phase 1 — Foundation

- Canonical role handling
- Super Admin shell
- Navigation
- Responsive foundation
- Shared components
- API/service/provider base

## Phase 2 — Dashboard and society lifecycle

- Overview
- Societies
- Approval
- KYC
- Setup progress
- Society detail

## Phase 3 — Revenue and subscriptions

- Revenue
- Subscriptions
- Plans
- Invoices/payments
- Reports
- Churn

## Phase 4 — Platform controls

- Feature flags
- White label
- Announcements
- Push
- API access
- Integrations

## Phase 5 — Support, security, and operations

- Support
- Audit/access logs
- Impersonation
- System health
- Platform users/settings
- AI usage/costs

## Phase 6 — Hardening

- Responsive
- Accessibility
- Golden tests
- Contract tests
- Remove mocks
- Final traceability

At the end of each phase report:

- Files created/changed
- Routes added
- Providers/services added
- Screens connected to real APIs
- Tests added and results
- Remaining blockers

---

# 15. Definition of done

The Super Admin frontend is complete only when:

- It is visually consistent with the existing Admin module
- It has its own secure shell and routes
- All 31 capabilities are mapped
- Every screen has loading, empty, error, and retry behavior
- No production screen depends on mock data
- No privileged write happens directly from Firestore
- Role routing is correct
- Impersonation is always visibly indicated
- Mobile, tablet, and desktop layouts work
- Accessibility checks pass
- Flutter analyze and all tests pass
- Existing Admin/Resident/Guard flows are not broken
- Traceability is complete

Begin with the repository audit and screen map. Do not begin by generating disconnected screens.


---

# SERO Super Admin Backend — Master Implementation Prompt

## Role

Act as a **Principal Backend Architect, Staff TypeScript Engineer, SaaS Billing Architect, Security Engineer, Data Architect, and SRE**.

You are working inside the existing SERO repository. A production-grade Society Admin backend is being built using PostgreSQL, Redis, queues, Firebase Auth/FCM, object storage, OpenAPI, and strict multi-tenancy.

Your task is to implement the complete **Super Admin backend/control plane** for the 31 Super Admin capabilities while reusing the same backend foundation and domain services used by the Society Admin application.

Do not create a separate toy backend. Do not duplicate authentication, logging, notifications, billing, audit, or database infrastructure. Extend the existing backend into a properly separated:

- **Control plane:** Super Admin/platform operations
- **Tenant plane:** Society Admin/resident/staff operations

The system must safely support the whole platform under 2,000–3,000 concurrently active users.

---

# 1. Repository-first workflow

Before coding:

1. Inspect:
   - Existing Node/Express/TypeScript backend
   - PostgreSQL migrations and RLS
   - Redis/BullMQ
   - Firebase Auth and custom claims
   - Society Admin endpoints
   - Payments and ledger
   - Notifications
   - AI/RAG
   - Audit/access logs
   - Object storage
   - Flutter Super Admin API requirements
   - OpenAPI and tests

2. Produce:
   - `SUPER_ADMIN_BACKEND_AUDIT.md`
   - `CONTROL_PLANE_ARCHITECTURE.md`
   - `SUPER_ADMIN_API_CONTRACT.md`
   - `SUPER_ADMIN_DATA_MODEL.md`
   - `SUPER_ADMIN_PERMISSION_MATRIX.md`

3. Identify:
   - Existing reusable services
   - Current role inconsistency: `superadmin` versus `super_admin`
   - Current cross-tenant access patterns
   - Missing platform entities
   - Existing legacy endpoints
   - Security risks
   - Mock/stub Super Admin routes
   - Any duplicate subscription logic

Do not start bulk implementation until these documents exist.

---

# 2. Architecture principles

## 2.1 One platform, two planes

### Tenant plane

Used by Society Admin, residents, staff, and guards.

- Always society-scoped
- Uses PostgreSQL RLS
- Normal tenant context
- No arbitrary cross-tenant access

### Control plane

Used only by authorized platform operators.

- Explicit platform permissions
- Cross-tenant reads only when required
- Sensitive operations require reason
- Every cross-tenant action is separately audited
- Some actions require maker-checker approval
- Impersonation uses a temporary delegated session
- No direct database bypass from controllers

Do not disable RLS globally for Super Admin requests. Use audited, narrowly scoped platform data-access functions or an explicit privileged database context.

## 2.2 Core stack

Use the same approved stack as the Society Admin backend:

- Node.js LTS
- Strict TypeScript
- Express or existing compatible framework
- PostgreSQL source of truth
- RLS and database constraints
- Redis
- Redlock/distributed locks
- BullMQ workers
- Firebase Auth
- FCM
- S3-compatible or Firebase object storage
- OpenAPI 3.1
- Pino
- OpenTelemetry
- Sentry
- Docker
- CI/CD

---

# 3. Identity, roles, and platform permissions

## 3.1 Canonical role

Use `super_admin` as the canonical role.

Temporarily accept `superadmin` only through a migration compatibility layer. Normalize it to `super_admin`.

Never route `super_admin` through Society Admin permission shortcuts.

## 3.2 Platform roles

Support:

- `super_admin`
- `platform_owner`
- `platform_operations`
- `platform_finance`
- `platform_support`
- `platform_security`
- `platform_auditor`
- `platform_read_only`

A user can have one or more platform roles.

## 3.3 Platform permissions

At minimum:

- `platform.dashboard.read`
- `platform.societies.read`
- `platform.societies.approve`
- `platform.societies.suspend`
- `platform.societies.offboard`
- `platform.kyc.read`
- `platform.kyc.verify`
- `platform.users.read`
- `platform.users.manage`
- `platform.subscriptions.read`
- `platform.subscriptions.manage`
- `platform.plans.read`
- `platform.plans.manage`
- `platform.revenue.read`
- `platform.reports.export`
- `platform.features.read`
- `platform.features.manage`
- `platform.announcements.manage`
- `platform.push.send`
- `platform.white_label.manage`
- `platform.support.read`
- `platform.support.manage`
- `platform.audit.read`
- `platform.access_logs.read`
- `platform.impersonation.start`
- `platform.impersonation.approve`
- `platform.api_clients.manage`
- `platform.integrations.manage`
- `platform.system_health.read`
- `platform.jobs.manage`
- `platform.security.manage`
- `platform.ai_cost.read`
- `platform.ai_cost.manage`
- `platform.settings.manage`

Controllers must not check role strings directly for every action. Use permission middleware.

---

# 4. Complete Super Admin capability scope

Implement these 31 capabilities as backend workflows.

## A. Platform overview and analytics — 1 to 7

1. Total societies and status breakdown.
2. Total users and role/growth breakdown.
3. Revenue monitoring: MRR, ARR, collections, refunds, outstanding, failed payments.
4. DAU.
5. MAU.
6. Churn, retention, reactivation, and at-risk societies.
7. Platform adoption and onboarding funnel analytics.

## B. Society lifecycle — 8 to 13

8. Search/filter/paginate all societies.
9. Approve/reject/request-information for new society applications.
10. Verify KYC documents.
11. Track setup progress and blockers.
12. View global society detail including plan, usage, admins, billing, health, support, and activity.
13. Suspend/reactivate/archive/offboard a society safely.

## C. Subscription and revenue — 14 to 18

14. Monitor subscriptions and renewal/payment states.
15. Manage subscription plans.
16. Assign/change plans with effective date, proration, and entitlement snapshots.
17. View invoices, payments, refunds, and reconciliation.
18. Generate revenue/subscription/tax/churn reports.

## D. Platform configuration — 19 to 23

19. Toggle features per society.
20. Staged/cohort/percentage feature rollout.
21. White-label configuration and versioning.
22. API clients, keys, scopes, quotas, usage, rotation, revocation.
23. Integrations, webhooks, providers, and service configuration.

## E. Communication and support — 24 to 27

24. Global announcements.
25. Segmented push notifications.
26. Support tickets with SLA and escalation.
27. Support analytics and CSAT.

## F. Security and operations — 28 to 31

28. Audit and access logs.
29. Controlled impersonation.
30. System health, incidents, jobs, queues, dependencies, and maintenance.
31. Platform users, security, AI cost/usage controls, global settings, and compliance exports.

---

# 5. Required data model

Extend the existing PostgreSQL schema. Use consistent naming.

## 5.1 Platform identity and permissions

- platform_users
- platform_roles
- platform_permissions
- platform_role_permissions
- platform_user_roles
- platform_sessions
- platform_mfa_methods
- platform_access_reviews

Where possible, reuse the main `users` table plus platform membership tables rather than duplicating user identity.

## 5.2 Society lifecycle

- society_applications
- society_application_history
- society_application_notes
- society_approval_checklists
- society_kyc_documents
- society_kyc_reviews
- society_setup_steps
- society_setup_progress
- society_status_history
- society_suspensions
- society_offboarding_jobs

## 5.3 Subscription and plans

- subscription_plans
- subscription_plan_versions
- subscription_plan_features
- society_subscriptions
- subscription_changes
- subscription_usage
- subscription_invoices
- subscription_invoice_lines
- subscription_payments
- subscription_refunds
- payment_failures
- subscription_reconciliations
- tax_configurations
- pricing_coupons or discounts only if product-approved

## 5.4 Feature management

- platform_features
- feature_dependencies
- feature_entitlements
- society_feature_overrides
- feature_rollouts
- feature_rollout_targets
- feature_evaluations
- feature_change_history

## 5.5 White label

- white_label_profiles
- white_label_versions
- white_label_domains
- white_label_assets
- white_label_publish_history

## 5.6 Communication and support

- platform_announcements
- platform_announcement_segments
- platform_announcement_deliveries
- platform_push_campaigns
- platform_push_deliveries
- support_teams
- support_agents
- support_tickets
- support_ticket_assignments
- support_ticket_comments
- support_ticket_attachments
- support_ticket_status_history
- support_sla_policies
- support_sla_events
- support_escalations
- support_feedback

## 5.7 API and integrations

- api_clients
- api_client_secrets
- api_client_scopes
- api_usage_daily
- api_rate_limit_policies
- webhook_endpoints
- webhook_deliveries
- integration_connections
- integration_credentials_metadata
- provider_configurations
- provider_health_events

Never store plaintext secrets. Store a one-way hash for API keys and encrypted credentials where retrieval is required.

## 5.8 Platform operations

- platform_audit_logs
- platform_access_logs
- impersonation_requests
- impersonation_sessions
- platform_incidents
- platform_maintenance_windows
- dependency_health_checks
- job_runs
- dead_letter_jobs
- platform_alerts
- platform_settings
- retention_policies
- compliance_export_jobs
- society_export_jobs
- deletion_requests

## 5.9 Analytics and AI

- daily_society_metrics
- daily_user_activity_metrics
- subscription_metrics
- churn_events
- feature_adoption_metrics
- support_metrics
- ai_usage_daily
- ai_cost_budgets
- ai_cost_alerts

Use aggregate tables/materialized views for dashboard analytics. Do not scan raw events for every dashboard request.

---

# 6. Database rules

- Use UUID/ULID
- Use UTC
- Use fixed precision or minor units for money
- Use immutable invoice/payment/audit snapshots
- Add tenant IDs where entity is society-specific
- Add platform actor IDs to control-plane changes
- Add `reason`, `request_id`, and before/after data for sensitive actions
- Use optimistic versions
- Use unique constraints for idempotency
- Use indexes on status, date, society, plan, assignee, and renewal
- Partition large access/audit/activity tables
- Add retention rules
- Use RLS for tenant-owned records
- Use explicit privileged DB context for platform queries
- Add tests that prove normal tenant sessions cannot call control-plane functions

---

# 7. Super Admin API

Use `/api/v1/super-admin`.

## 7.1 Dashboard and analytics

- `GET /dashboard`
- `GET /analytics/activity`
- `GET /analytics/adoption`
- `GET /analytics/churn`
- `GET /analytics/retention`
- `GET /analytics/revenue`
- `GET /analytics/support`
- `GET /analytics/ai-usage`

Support:

- Date range
- Comparison period
- Currency
- Plan
- Region
- Society status
- Cursor where list data is returned

## 7.2 Societies

- `GET /societies`
- `GET /societies/:societyId`
- `POST /societies/:societyId/approve`
- `POST /societies/:societyId/reject`
- `POST /societies/:societyId/request-information`
- `POST /societies/:societyId/suspend`
- `POST /societies/:societyId/reactivate`
- `POST /societies/:societyId/archive`
- `POST /societies/:societyId/offboard`
- `GET /societies/:societyId/activity`
- `GET /societies/:societyId/health`
- `POST /societies/:societyId/export`

## 7.3 KYC and setup

- `GET /kyc`
- `GET /kyc/:reviewId`
- `POST /kyc/:reviewId/approve`
- `POST /kyc/:reviewId/reject`
- `POST /kyc/:reviewId/request-replacement`
- `GET /setup-progress`
- `GET /setup-progress/:societyId`
- `PATCH /setup-progress/:societyId/steps/:stepId`
- `POST /setup-progress/:societyId/remind`

## 7.4 Subscriptions, plans, and revenue

- `GET /subscriptions`
- `GET /subscriptions/:subscriptionId`
- `POST /subscriptions/:subscriptionId/change-plan`
- `POST /subscriptions/:subscriptionId/pause`
- `POST /subscriptions/:subscriptionId/resume`
- `POST /subscriptions/:subscriptionId/cancel`
- `GET /plans`
- `POST /plans`
- `GET /plans/:planId`
- `PATCH /plans/:planId`
- `POST /plans/:planId/publish`
- `POST /plans/:planId/archive`
- `GET /billing/invoices`
- `GET /billing/payments`
- `GET /billing/refunds`
- `GET /billing/reconciliation`
- `POST /reports`

## 7.5 Feature controls

- `GET /features`
- `POST /features`
- `PATCH /features/:featureId`
- `POST /features/:featureId/enable`
- `POST /features/:featureId/disable`
- `GET /societies/:societyId/features`
- `PUT /societies/:societyId/features/:featureId`
- `POST /feature-rollouts`
- `GET /feature-rollouts/:rolloutId`
- `POST /feature-rollouts/:rolloutId/start`
- `POST /feature-rollouts/:rolloutId/pause`
- `POST /feature-rollouts/:rolloutId/rollback`

## 7.6 White label

- `GET /white-label`
- `GET /white-label/:societyId`
- `PUT /white-label/:societyId/draft`
- `POST /white-label/:societyId/preview`
- `POST /white-label/:societyId/publish`
- `POST /white-label/:societyId/rollback`
- `POST /white-label/:societyId/domain/verify`

## 7.7 Announcements and push

- `GET /announcements`
- `POST /announcements`
- `GET /announcements/:id`
- `PATCH /announcements/:id`
- `POST /announcements/:id/schedule`
- `POST /announcements/:id/cancel`
- `GET /announcements/:id/delivery`
- `GET /push-campaigns`
- `POST /push-campaigns`
- `POST /push-campaigns/:id/test`
- `POST /push-campaigns/:id/schedule`
- `POST /push-campaigns/:id/cancel`
- `GET /push-campaigns/:id/delivery`

## 7.8 Support

- `GET /support/tickets`
- `POST /support/tickets`
- `GET /support/tickets/:ticketId`
- `PATCH /support/tickets/:ticketId`
- `POST /support/tickets/:ticketId/assign`
- `POST /support/tickets/:ticketId/comment`
- `POST /support/tickets/:ticketId/internal-note`
- `POST /support/tickets/:ticketId/escalate`
- `POST /support/tickets/:ticketId/resolve`
- `POST /support/tickets/:ticketId/reopen`
- `GET /support/sla`
- `GET /support/analytics`

## 7.9 Audit, impersonation, API, and operations

- `GET /audit-logs`
- `GET /access-logs`
- `GET /impersonation/eligible-users`
- `POST /impersonation/requests`
- `POST /impersonation/requests/:id/approve`
- `POST /impersonation/sessions`
- `GET /impersonation/sessions/current`
- `POST /impersonation/sessions/current/stop`
- `GET /api-clients`
- `POST /api-clients`
- `POST /api-clients/:id/rotate`
- `POST /api-clients/:id/revoke`
- `GET /api-clients/:id/usage`
- `GET /webhooks`
- `POST /webhooks`
- `POST /webhooks/:id/test`
- `POST /webhooks/:id/rotate-secret`
- `GET /system-health`
- `GET /jobs`
- `POST /jobs/:id/retry`
- `POST /jobs/:id/cancel`
- `GET /incidents`
- `POST /incidents`
- `GET /platform-users`
- `POST /platform-users/invite`
- `PATCH /platform-users/:id`
- `POST /platform-users/:id/revoke-sessions`
- `GET /settings`
- `PATCH /settings`

---

# 8. Society approval workflow

Implement an explicit state machine:

- `draft`
- `submitted`
- `information_requested`
- `under_review`
- `approved`
- `rejected`
- `withdrawn`

Rules:

- Only submitted/information-complete applications can enter review
- Reviewer cannot approve incomplete mandatory KYC
- Approval creates or activates:
  - Society
  - Initial subscription
  - Primary admin membership
  - Default setup checklist
  - Feature entitlements
  - Onboarding jobs
- Approval must be transactional
- Send notifications after commit
- Repeated approval request must be idempotent
- Rejection requires reason
- Application history is immutable

---

# 9. KYC workflow

- File metadata and checksum
- Malware scan
- OCR proposal
- Reviewer comparison
- Expiry validation
- Duplicate-document detection where legally appropriate
- Approve/reject/request replacement
- Do not store sensitive KYC values in logs
- Signed file URLs
- Access logging
- Retention policy
- Optional four-eyes review for high-risk cases

---

# 10. Subscription and billing logic

Use a separate platform subscription ledger from society maintenance accounting, while sharing core accounting utilities.

Support:

- Trial
- Active
- Grace period
- Past due
- Paused
- Cancelled
- Expired

Plan changes:

- Effective immediately or next cycle
- Proration preview
- Entitlement snapshot
- Usage limits
- Upgrade/downgrade restrictions
- Audit reason
- Idempotency
- Provider sync
- Retry/reconciliation

Plan publishing:

- Draft version
- Validation
- Publish
- Existing subscribers retain a versioned contract unless migration is explicit
- Never silently mutate historical invoices or entitlements

Payments:

- Verify provider webhooks using raw body
- Store event before processing
- Replay-safe
- Out-of-order-safe
- Exact-once financial effect
- Reconciliation jobs
- Refund and dispute handling
- No card data storage

Metrics:

- MRR
- ARR
- Expansion
- Contraction
- New MRR
- Churned MRR
- Gross and net revenue retention
- Trial conversion

Document formulas and test them.

---

# 11. Feature-flag service

Feature evaluation order:

1. Emergency global kill switch
2. Explicit society override
3. Rollout/cohort rule
4. Plan entitlement
5. Global default

Requirements:

- Deterministic percentage rollout
- Dependency validation
- Prerequisite validation
- Start/end scheduling
- Cache with event-based invalidation
- Evaluation audit for sensitive features
- Preview impacted societies before rollout
- Rollback
- No client-only enforcement
- Backend authorization/business logic must also enforce disabled features

Provide a low-latency internal feature-evaluation service used by tenant APIs.

---

# 12. White-label service

- Draft/publish/version/rollback
- Validate colors and required assets
- Asset scanning
- Domain verification
- TLS/domain status
- Cache published profile
- Invalidate cache on publish
- Do not allow tenant white-label settings to alter Super Admin control plane
- Keep history and actor/reason
- Expose a tenant-safe branding endpoint

---

# 13. Global announcements and push

Use background jobs.

Workflow:

- Draft
- Audience estimate
- Validation
- Schedule/publish
- Audience snapshot
- Batched delivery
- Retry
- Deduplicate
- Delivery/read metrics
- Cancellation before dispatch
- Expiry

Segment filters must be validated and parameterized.

Respect:

- User notification preferences
- Required operational notices
- Quiet hours
- Channel availability
- Rate limits
- Provider quotas

Do not send to a society that was excluded after audience snapshot unless campaign rules explicitly say dynamic audience.

---

# 14. Support ticket backend

State machine:

- `new`
- `open`
- `waiting_on_customer`
- `waiting_on_internal`
- `escalated`
- `resolved`
- `closed`
- `reopened`

Support:

- Priority
- Category
- Society
- Reporter
- Team
- Assignee
- SLA policy
- Due time
- Business hours
- Public comments
- Internal notes
- Attachments
- Mentions
- Linked incident
- Escalation
- Resolution code
- CSAT

SLA workers must be idempotent and avoid duplicate reminders/escalations.

---

# 15. Impersonation security model

Impersonation is a delegated session, not a login using another user’s password.

## Requirements

- Permission check
- Eligible target rules
- Required reason
- Optional approval for high-risk target
- Maximum duration
- One active impersonation session per operator
- Signed short-lived impersonation token
- Token contains:
  - Original actor
  - Target user
  - Target society
  - Session ID
  - Start/end
  - Allowed scopes
- Persistent audit trail
- All actions log both actor and effective user
- Revocable immediately
- Ends on expiry/logout/role change
- No credential exposure
- No refresh beyond approved maximum
- Prohibit:
  - Editing Super Admin permissions
  - Starting nested impersonation
  - Viewing secrets
  - Rotating API keys
  - Disabling audit
  - Certain financial/destructive actions unless explicitly allowed
- Add a `/current` endpoint so frontend can always show the banner
- Clear tenant caches/session state on stop

Maker-checker must be available for sensitive impersonation.

---

# 16. API client and webhook security

API key creation:

- Generate high-entropy secret
- Show once
- Store hash only
- Prefix for identification
- Scope
- Quota
- Expiry
- IP restrictions if configured
- Rotate/revoke
- Last used
- Usage metrics

Webhooks:

- Encrypt signing secret
- Sign payload
- Delivery ID
- Timestamp
- Replay protection
- Retry with backoff
- Dead letter
- Manual retry
- Redacted logs
- SSRF-safe destination validation
- Block private/internal network addresses unless explicitly approved
- Test delivery
- Endpoint disable after repeated failures based on policy

---

# 17. System health and job operations

Expose a safe platform operations API.

Track:

- API health
- PostgreSQL
- Redis
- Queue
- Object storage
- Firebase
- Payment provider
- Email/SMS/push
- AI providers
- Worker heartbeat
- Queue depth
- Oldest job age
- Failed/dead-letter jobs
- Deployment version
- Incident state

Never return secrets or raw credentials.

Job actions:

- Retry only idempotent jobs
- Permission check
- Reason
- Audit
- Deduplicate retry
- Do not retry a currently running job blindly

---

# 18. Analytics architecture

Do not compute DAU/MAU/churn from unrestricted raw production scans on every request.

Use:

- Event ingestion
- Daily aggregates
- Materialized views
- Incremental jobs
- Backfill jobs
- Data quality checks
- Metric versioning
- Documented definitions

Activity identity:

- User
- Society
- Role
- Feature/module
- Timestamp
- Session/device only when privacy policy allows

Churn must distinguish:

- Voluntary cancellation
- Involuntary payment failure
- Trial non-conversion
- Administrative termination

All metrics must support an “as of” timestamp.

---

# 19. Audit and access logs

Platform logs must include:

- Actor user
- Actor platform role
- Effective user during impersonation
- Society
- Action
- Resource type/id
- Before/after diff
- Reason
- Result
- Request ID
- IP/device/user agent
- Timestamp
- Impersonation session ID
- Approval reference where relevant

Logs must be append-only and separately permissioned.

Sensitive values must be redacted.

Audit export is itself audited.

---

# 20. Performance and scale

The control plane has fewer users than the tenant plane, but it operates over global datasets.

Requirements:

- Cursor pagination
- Aggregate/materialized analytics
- Indexed global search
- Background report generation
- Redis caching
- Cache invalidation
- No N+1 on society lists
- No client-side aggregation of platform totals
- Streaming or object-storage delivery for large exports
- Horizontal API/worker scaling
- Connection pooling
- 3,000 total platform users/connections supported across SERO
- Super Admin global dashboard p95 under 700 ms when cache is warm
- Standard Super Admin reads p95 under 400 ms
- Standard writes p95 under 700 ms excluding third parties
- Long jobs return 202 with job ID
- No blocking KYC OCR/report generation in request thread

---

# 21. Security requirements

Test and implement:

- Strict platform RBAC
- Step-up authentication for high-risk actions
- MFA for privileged users
- Session revocation
- Short session durations
- IP/device anomaly alerts
- Cross-tenant access only through audited platform permission
- RLS remains effective
- IDOR protection
- SQL injection protection
- Mass-assignment protection
- SSRF protection
- File security
- KYC privacy
- API-secret safety
- Webhook replay protection
- CORS allowlist
- Rate limiting
- Brute force protection
- CSRF where applicable
- Encryption
- Secret rotation
- Log redaction
- Retention/deletion
- Dependency/container scanning
- No debug endpoints in production

---

# 22. Events and real-time updates

Use the existing outbox/event architecture.

Events include:

- Society application submitted
- Society approved/rejected
- KYC status changed
- Setup milestone changed
- Subscription changed
- Payment failed/recovered
- Feature rollout changed
- White label published
- Announcement scheduled/published
- Support ticket updated/breached
- Impersonation started/stopped
- API key created/rotated/revoked
- Incident opened/resolved
- Job failed/recovered
- AI budget threshold reached

Super Admin realtime channels must require platform authorization.

---

# 23. Testing

Create:

- Unit tests
- Integration tests with real PostgreSQL and Redis containers
- API tests
- Permission matrix tests
- Normal tenant versus control-plane tests
- Society approval transaction tests
- KYC access tests
- Plan-version tests
- Subscription proration tests
- Payment replay tests
- Feature-evaluation tests
- Rollout determinism tests
- White-label version/rollback tests
- Announcement audience/dedup tests
- Support SLA tests
- Impersonation tests
- API-key reveal-once tests
- Webhook SSRF/replay tests
- Audit immutability tests
- Analytics formula tests
- Large export tests
- Queue retry/idempotency tests
- Load tests

Critical test files:

- `super-admin-auth.spec`
- `platform-permission-matrix.spec`
- `control-plane-isolation.spec`
- `society-approval.spec`
- `kyc-review.spec`
- `subscription-plan-versioning.spec`
- `subscription-proration.spec`
- `platform-payment-idempotency.spec`
- `feature-flag-evaluation.spec`
- `feature-rollout.spec`
- `white-label.spec`
- `global-announcement.spec`
- `support-sla.spec`
- `impersonation-security.spec`
- `api-client-security.spec`
- `webhook-security.spec`
- `platform-audit.spec`
- `system-health.spec`
- `analytics-metrics.spec`
- `super-admin-load.js`

---

# 24. CI/CD gates

Fail CI on:

- Install/lockfile failure
- Type errors
- Lint errors
- Tests
- Migration failure
- Permission-matrix failure
- Control-plane isolation failure
- OpenAPI drift
- Secret scan
- Vulnerability scan
- Container scan
- Impersonation security failure
- Payment idempotency failure
- Feature rollout nondeterminism
- Audit mutation
- Build failure

---

# 25. Deliverables

1. Super Admin backend audit
2. Control-plane architecture
3. Permission matrix
4. Database migrations
5. RLS/privileged context design
6. Complete APIs
7. OpenAPI 3.1
8. Workers and schedules
9. Analytics aggregates
10. Tests
11. Load scripts
12. Seed data
13. Docker/dev setup updates
14. Deployment/runbook updates
15. Security and impersonation documentation
16. `SUPER_ADMIN_BACKEND_TRACEABILITY.md` mapping:
    - Feature 1–31
    - Endpoint
    - Permission
    - Tables
    - Worker/event
    - Test
    - Status

---

# 26. Implementation phases

## Phase 0 — Audit and contract

- Audit repository
- Confirm frontend contracts
- Normalize role naming
- Define control-plane boundary

## Phase 1 — Platform foundation

- Platform roles/permissions
- Control-plane request context
- Audit
- Step-up auth
- Base routes
- OpenAPI

## Phase 2 — Society lifecycle

- Applications
- Approval
- KYC
- Setup progress
- Suspend/reactivate/offboard

## Phase 3 — Subscription/revenue

- Plans
- Subscriptions
- Billing
- Payments
- Reports
- Metrics

## Phase 4 — Configuration

- Features
- Rollouts
- White label
- API access
- Integrations

## Phase 5 — Communication/support

- Announcements
- Push
- Support tickets
- SLA

## Phase 6 — Security/operations

- Audit/access logs
- Impersonation
- Platform users
- Health/jobs/incidents
- AI budgets
- Compliance exports

## Phase 7 — Scale and hardening

- Load
- Failure injection
- Backup/restore
- Security audit
- Runbooks
- Final traceability

At the end of each phase report files, migrations, endpoints, tests, results, and blockers.

---

# 27. Definition of done

Complete only when:

- All 31 Super Admin capabilities are implemented and traced
- Frontend contracts are satisfied
- Super Admin has dedicated authorization
- Legacy role naming is migrated safely
- Control-plane access cannot be used by tenant users
- Cross-tenant actions require explicit platform permission and audit
- Society approval is transactional
- Subscription financial effects are idempotent
- Feature rollout is deterministic and reversible
- API secrets are reveal-once and hashed
- Impersonation is delegated, visible, expiring, revocable, and audited
- KYC files are protected
- Analytics definitions are tested
- No production mocks/stubs remain
- OpenAPI and tests pass
- Load and backup/restore evidence exists
- Zero unresolved P0/P1 security defects

Begin with the audit and control-plane architecture. Do not begin by adding a few unconnected routes.


---

# SERO Super Admin — Frontend, Backend, Security, and Release QC Prompt

## Role

Act as an independent **Principal QA Architect, Flutter QA Engineer, Application Security Engineer, SaaS Billing QA Specialist, SRE, Performance Engineer, and Code Auditor**.

You are auditing the completed SERO Super Admin module.

The module must:

- Visually match the existing Society Admin application
- Correctly implement the 31 Super Admin capabilities
- Use a dedicated Super Admin shell and permissions
- Safely operate across multiple societies
- Preserve strict tenant isolation for normal users
- Protect subscription, KYC, API-key, support, audit, and impersonation workflows
- Integrate with the same production backend foundation as the Society Admin application

Do not provide a superficial checklist. Execute the repository and report evidence.

---

# 1. Required audit method

1. Inspect:
   - Existing Admin design system
   - Super Admin Flutter screens
   - Routes and role dispatcher
   - Providers/services/models
   - Backend control-plane routes
   - Permissions
   - Migrations
   - RLS
   - Queues/workers
   - Subscription billing
   - Feature flags
   - White label
   - Support
   - Impersonation
   - API access
   - Analytics
   - Audit/access logs
   - Tests and CI

2. Run from a clean environment.

3. Record for every test:
   - Command
   - Environment
   - Exit code
   - Expected
   - Actual
   - Evidence
   - File/line
   - Screenshot or artifact where applicable

4. Do not:
   - Use `--force`
   - Use `--legacy-peer-deps`
   - Skip tests
   - Weaken assertions
   - Replace backend calls with mocks to hide defects
   - Claim a visual pass without checking actual screens
   - Claim scale without load results

---

# 2. Required outputs

Produce:

1. `SUPER_ADMIN_QC_EXECUTIVE_SUMMARY.md`
2. `SUPER_ADMIN_QC_FINDINGS.md`
3. `SUPER_ADMIN_FEATURE_TEST_MATRIX.md`
4. `SUPER_ADMIN_VISUAL_QC_REPORT.md`
5. `SUPER_ADMIN_SECURITY_REPORT.md`
6. `SUPER_ADMIN_CONTROL_PLANE_ISOLATION_REPORT.md`
7. `SUPER_ADMIN_SUBSCRIPTION_BILLING_REPORT.md`
8. `SUPER_ADMIN_IMPERSONATION_REPORT.md`
9. `SUPER_ADMIN_LOAD_REPORT.md`
10. `SUPER_ADMIN_RELEASE_GATE.md`
11. `super_admin_qc_findings.json`

For every defect include:

- ID
- Severity P0/P1/P2/P3
- Category
- Feature
- Screen/endpoint
- File and line
- Reproduction
- Expected
- Actual
- User/business impact
- Security/tenant/financial impact
- Root cause
- Recommended fix
- Regression test
- Status

---

# 3. Release gate

Verdict:

- PASS
- PASS WITH P2/P3 EXCEPTIONS
- FAIL

Automatic FAIL:

- Any unresolved P0
- Any unresolved P1 in authorization, cross-tenant access, KYC, subscription billing, impersonation, API secrets, audit, or release integrity
- Clean install/build failure
- Flutter analyze failure
- Test failure
- Migration failure
- Route guard bypass
- Normal admin can access Super Admin
- Super Admin action is not audited
- Cross-tenant data leaks to normal tenant users
- Impersonation can be hidden, nested, extended indefinitely, or started without permission
- API key can be retrieved again in plaintext
- Payment replay creates duplicate financial effect
- Feature disabled in UI but still usable through API
- Audit log can be changed/deleted
- Load target not met
- No backup/restore proof for new platform tables

---

# 4. Feature coverage test

For all 31 capabilities record:

- Frontend screen exists
- Route exists
- Correct permission
- API exists
- Database model exists
- Workflow works
- Audit event exists
- Notification/event exists where required
- Loading state
- Empty state
- Error state
- Pagination/filtering
- Responsive behavior
- Accessibility
- Unit/integration/e2e test
- Pass/fail

Capabilities:

1. Total societies
2. Total users
3. Revenue monitoring
4. DAU
5. MAU
6. Churn/retention
7. Adoption/onboarding analytics
8. Society directory
9. Society approvals
10. KYC verification
11. Setup progress
12. Society detail
13. Suspend/reactivate/offboard
14. Subscription monitoring
15. Plan management
16. Plan assignment/change
17. Platform invoices/payments/refunds
18. Revenue reports
19. Society feature toggle
20. Staged feature rollout
21. White label
22. API access
23. Integrations/webhooks
24. Global announcements
25. Push campaigns
26. Support ticket management
27. Support analytics/SLA
28. Audit/access logs
29. Impersonation
30. System health/jobs/incidents
31. Platform users/security/AI/global settings/compliance

---

# 5. Frontend design QC

Compare Super Admin against the existing Admin module.

## 5.1 Design tokens

Verify:

- Deep Emerald `#064E3B`
- Near-black Navy `#111827`
- Deep Navy `#1E3A8A`
- Emerald Accent `#10B981`
- Sky Accent `#0EA5E9`
- Slate Background `#F8FAFC`
- Slate Border `#E2E8F0`
- Outfit font
- 24 px card radius
- 20 px input/button radius
- 20 px horizontal page padding
- Existing badge colors
- Existing gradient logic

Flag:

- Random colors
- Unrelated font
- Inconsistent radius
- Dense generic dashboard tables on mobile
- Different shadow language
- Different icon style
- Different navigation behavior

## 5.2 Navigation

Test:

- Dedicated Super Admin shell
- Correct bottom tabs:
  - Overview
  - Societies
  - Revenue center G
  - Support
  - More
- Drawer grouping
- Deep links
- Back navigation
- Selected state
- Notification routing
- Logout
- State preservation
- Tablet rail
- Desktop sidebar

## 5.3 Screen states

Every screen must have:

- Loading/skeleton
- Empty
- Error
- Retry
- Offline where relevant
- Success feedback
- Validation
- Destructive confirmation

Test slow network and backend errors.

## 5.4 Responsive testing

Test at minimum:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet portrait
- Tablet landscape
- 1366×768 desktop
- 1440×900 desktop

Check:

- Overflow
- Clipped text
- Chart readability
- Bottom navigation
- Drawer/sidebar
- Keyboard
- Data tables
- Dialogs
- KYC preview
- Impersonation banner
- Text scaling 200%

## 5.5 Golden/visual regression

Generate golden images for:

- Dashboard
- Societies
- Society detail
- Approval queue
- KYC
- Revenue
- Plans
- Feature controls
- Support detail
- Audit log
- Impersonation active
- System health
- Desktop dashboard

Review intentional differences manually.

---

# 6. Frontend architecture QC

Verify:

- `super_admin_shell.dart` exists
- `screens/super_admin`
- `providers/super_admin`
- `services/super_admin`
- `models/super_admin`
- No business logic in widgets
- Riverpod lifecycle correctness
- No duplicate requests
- Cursor pagination
- Filters preserved
- API errors mapped
- Request IDs exposed for support
- No production mock fallback
- No direct privileged Firestore writes
- Secure token storage
- Cross-tenant state cleared on logout/impersonation stop
- No stale society data after switching context
- Legacy `superadmin` normalized to `super_admin`

Run:

- `flutter pub get`
- `dart format --set-exit-if-changed`
- `flutter analyze`
- Unit tests
- Widget tests
- Golden tests
- Integration tests

---

# 7. Role and permission QC

Create users:

- Super Admin
- Platform owner
- Platform operations
- Platform finance
- Platform support
- Platform security
- Platform auditor
- Platform read-only
- Main Admin Society A
- Main Admin Society B
- Resident A/B
- Staff/guard A/B

Test:

- `/super-admin` routes
- Every control-plane endpoint
- Positive permission
- Negative permission
- Role downgrade
- Disabled user
- Revoked session
- Expired token
- MFA incomplete
- Step-up authentication missing
- Legacy role claim
- Modified token
- Normal admin calling Super Admin API
- Super Admin with insufficient narrower permission
- Hidden UI action invoked directly through API

Create a complete platform permission matrix.

---

# 8. Control-plane and tenant isolation QC

The Super Admin needs cross-tenant visibility, but normal tenant roles must remain isolated.

Test Society A versus Society B for:

- Society data
- Users/admins
- KYC
- Subscription
- Billing
- Support
- Feature flags
- White label
- Exports
- Notifications
- Audit logs
- API clients
- AI usage
- Files
- Realtime events
- Cache keys
- Queue jobs

Attempt:

- Foreign ID in path
- Foreign ID in body
- Foreign cursor
- Foreign report job
- Foreign signed URL
- Foreign WebSocket channel
- Cache-key collision
- Queue payload tampering
- Legacy endpoint bypass
- Direct Firestore access
- RLS bypass
- Super Admin context accidentally reused for tenant request

Verify:

- Tenant user cannot gain control-plane access
- Super Admin cross-tenant read/write is permissioned
- Every cross-tenant action is audited
- RLS is not globally disabled
- Sensitive cross-tenant actions require reason
- Platform query functions cannot be invoked by tenant database context

---

# 9. Society lifecycle QC

## Approval

Test:

- Draft
- Submitted
- Information requested
- Under review
- Approved
- Rejected
- Withdrawn
- Missing mandatory data
- Missing KYC
- Duplicate approve request
- Concurrent reviewers
- Worker failure after commit
- Notification failure
- Retry
- Idempotency

Expected:

- One society
- One primary admin
- One initial subscription
- One checklist
- Correct entitlements
- Complete audit history

## Suspend/reactivate/offboard

Test:

- Reason required
- Permission
- Step-up auth
- Existing active sessions
- New login blocked/allowed correctly
- Payments/jobs behavior
- Feature access
- Notification
- Data export
- Retention
- Restore/reactivation
- Offboarding job retry
- No accidental hard delete

---

# 10. KYC security QC

Test:

- Unauthorized access
- Cross-society access
- Expired URL
- URL sharing
- MIME spoof
- Malware
- Oversized upload
- Duplicate document
- OCR mismatch
- Expired document
- Rejection
- Replacement
- Four-eyes approval
- Sensitive values in logs
- Download audit
- Retention deletion

KYC must never be publicly accessible.

---

# 11. Subscription and revenue QC

## Plan versioning

Test:

- Draft plan
- Publish
- Existing subscribers
- New subscribers
- Editing published plan
- Archive
- Feature entitlement
- Usage limits
- Tax
- Monthly/yearly
- Trial

Historical invoices/entitlements must not change silently.

## Plan changes

Test:

- Immediate upgrade
- Next-cycle upgrade
- Downgrade
- Proration
- Credit
- Currency
- Tax
- Grace period
- Cancel
- Resume
- Duplicate request
- Concurrent request
- Provider timeout
- Provider retry

## Payment and invoice

Test:

- Valid webhook
- Invalid signature
- Replay
- Duplicate event
- Out-of-order
- Wrong amount
- Wrong currency
- Wrong society
- Refund
- Dispute
- Reconciliation
- PDF failure
- Notification failure

Expected exactly-once financial effect.

## Metrics

Verify formulas:

- MRR
- ARR
- New MRR
- Expansion
- Contraction
- Churned MRR
- Gross retention
- Net retention
- Trial conversion
- Outstanding
- Failed payments

Compare aggregate API to source records.

---

# 12. Feature flag QC

Test evaluation order:

1. Kill switch
2. Society override
3. Rollout
4. Plan
5. Default

Test:

- Deterministic percentage
- Cohort
- Start/end
- Dependency
- Prerequisite
- Cache invalidation
- Rollback
- Concurrent update
- Preview count
- Stale client
- API enforcement
- Tenant trying to modify own entitlement
- Disabled feature endpoint called directly

A UI-only feature flag is a release failure.

---

# 13. White-label QC

Test:

- Draft
- Preview
- Publish
- Rollback
- Logo format
- Malware
- Invalid colors
- Contrast
- Domain verification
- Cache invalidation
- Cross-society leakage
- Version history
- Tenant branding endpoint
- Super Admin control center remains SERO-branded

---

# 14. Announcements and push QC

Test:

- All societies
- Selected societies
- Plan cohort
- Region
- Status
- Empty audience
- Estimate
- Snapshot
- Test notification
- Schedule
- Timezone
- Quiet hours
- Duplicate send
- Retry
- Provider partial failure
- Cancellation
- Expiry
- Deep link
- Delivery/read stats
- Opt-out versus mandatory operational notice

No society outside the selected audience may receive the campaign.

---

# 15. Support and SLA QC

Test:

- Create
- Assign
- Reassign
- Public comment
- Internal note privacy
- Attachment
- Status state machine
- Business hours
- Weekend/holiday
- Pause/resume
- Escalation
- Duplicate reminder prevention
- Resolve
- Reopen
- CSAT once
- Analytics
- Society user access
- Cross-society access
- Support-agent permission boundaries

---

# 16. Impersonation QC

This is a critical release gate.

Test:

- No permission
- Eligible user
- Ineligible user
- Reason missing
- Duration too long
- Approval required
- Approval by same actor where prohibited
- Start
- Persistent banner
- Original/effective identity
- Audit
- Expiry
- Stop
- Logout
- Role change
- Session revocation
- Nested impersonation
- Refresh attempt
- Token tampering
- Prohibited actions
- Back navigation
- Cached Society A data after stop
- Multiple devices
- Concurrent session
- Reauthentication
- Action logs

Expected:

- No credential exposure
- No hidden mode
- No nested session
- No indefinite refresh
- All actions identify original and effective actors
- Session ends reliably
- Frontend clears tenant state

---

# 17. API key and webhook QC

## API keys

Test:

- Create
- Reveal once
- Database plaintext search
- Copy after navigation
- Scope
- Quota
- Expiry
- Revoke
- Rotate
- Old key
- Last used
- Rate limit
- Tenant/platform scope
- Log redaction

## Webhooks

Test:

- Destination validation
- SSRF:
  - localhost
  - metadata IP
  - private IP
  - DNS rebinding defense
- Signature
- Timestamp
- Replay
- Retry
- Dead letter
- Manual retry
- Secret rotation
- Redacted delivery log
- Disabled endpoint

---

# 18. Audit and access-log QC

Test:

- All sensitive actions generate logs
- Before/after diff
- Reason
- Request ID
- IP/device
- Original/effective actor
- Impersonation ID
- Approval reference
- Failure event
- Export event
- Redaction
- Cursor pagination
- Search/filter
- Retention/partition
- Attempted mutation/delete

Audit logs must be append-only.

---

# 19. Analytics QC

Test:

- Event ingestion
- Aggregate job
- Backfill
- Late events
- Duplicate events
- Timezone
- User deletion
- Society offboarding
- Role change
- Data quality
- “As of” time
- Metric version
- Empty data
- Large date range
- Export

Cross-check DAU/MAU/churn against independent SQL calculations.

---

# 20. System health and job QC

Test:

- PostgreSQL unavailable
- Redis unavailable
- Worker unavailable
- Payment provider unavailable
- Firebase unavailable
- Object storage unavailable
- AI provider unavailable
- Queue backlog
- Dead-letter
- Retry permission
- Duplicate retry
- Running-job retry
- Incident creation
- Maintenance window
- Health endpoint secrecy
- Alert delivery
- Recovery

Health status must be truthful and not expose secrets.

---

# 21. Performance and load QC

Use production-like PostgreSQL/Redis/object storage.

## Scenarios

1. 100 concurrent Super Admin/control-plane users
2. 3,000 total SERO authenticated users across tenant and platform roles
3. 250 sustained mixed API RPS for 15 minutes
4. 500 RPS burst for 60 seconds
5. 3,000 realtime connections
6. Global dashboard over large society dataset
7. Society search/pagination
8. Revenue analytics
9. Report/export generation
10. Global announcement to all users
11. Feature rollout to all societies
12. Subscription webhook burst with duplicates
13. Support queue spike
14. Reconnect storm
15. Redis restart
16. Worker crash and recovery
17. Four-hour soak

## Targets

- Warm global dashboard p95 < 700 ms
- Standard reads p95 < 400 ms
- Normal writes p95 < 700 ms excluding third parties
- Tenant reads retain Admin backend targets
- Error rate < 1%
- No memory leak
- No event-loop degradation
- DB pool healthy
- Queue drains after recovery
- No duplicates
- No authorization leak
- No cache cross-contamination

Report p50/p90/p95/p99, throughput, errors, CPU, memory, DB locks/pool, Redis, queue age, realtime connections, and bottlenecks.

---

# 22. Accessibility QC

Test:

- Screen reader labels
- Keyboard
- Focus
- Contrast
- Text scaling
- Touch target
- Reduced motion
- Charts with text alternative
- Status not color-only
- Error association
- KYC preview controls
- Dialog focus trap
- Impersonation banner semantics

---

# 23. Backup, restore, and migration QC

Test:

- Fresh migration
- Upgrade from previous Admin backend schema
- Rollback where supported
- Backup
- Restore to isolated environment
- Platform users/roles
- Society applications
- KYC metadata
- Subscriptions/invoices
- Feature flags
- Support
- Impersonation history
- Audit
- API clients
- Analytics aggregates
- Object files/version recovery

Measure RPO/RTO.

---

# 24. Repository-specific checks

Verify:

1. `super_admin` is canonical.
2. Legacy `superadmin` is normalized, not treated as a separate privilege.
3. `main_shell.dart` routes Super Admin to a dedicated shell.
4. Society Admin cannot open Super Admin routes.
5. Super Admin does not reuse `main_admin` shortcuts.
6. No Super Admin screen uses `MockDashboardData`.
7. No privileged direct Firestore write remains.
8. Design tokens match `theme.dart`.
9. Bottom navigation matches Admin behavior.
10. Center green “G” Revenue tab works.
11. Drawer and route state remain synchronized.
12. API paths use `/api/v1/super-admin`.
13. RLS is not globally disabled.
14. Every cross-tenant action is audited.
15. All sensitive actions require reason.
16. KYC file URLs are signed.
17. Plan versions are immutable after publish.
18. Payment webhook is raw-body verified and replay-safe.
19. Feature flags are enforced server-side.
20. Impersonation banner cannot be dismissed.
21. API secret is shown only once.
22. Webhook destinations are SSRF-safe.
23. Audit logs cannot be deleted by API.
24. Analytics do not scan full raw tables per request.
25. Large exports use jobs/object storage.
26. Queue retries are idempotent.
27. Notifications are deduplicated.
28. Support internal notes are never tenant-visible.
29. White-label data does not alter Super Admin branding.
30. Existing Admin/Resident/Guard tests still pass.
31. All 31 features appear in traceability.

---

# 25. Final report

End with:

## Executive verdict

- Release gate
- P0/P1/P2/P3 counts
- Top risks
- Tested environment
- Tested scale
- Untested scope

## Feature verdict

For features 1–31:

- Frontend
- Backend
- Security
- Tests
- Pass/fail
- Evidence

## Design verdict

- Admin design consistency
- Responsive
- Accessibility
- Visual regressions

## Security verdict

- Platform RBAC
- Control-plane isolation
- KYC
- Impersonation
- API keys/webhooks
- Audit

## Financial verdict

- Plan versioning
- Subscription change
- Invoices/payments/refunds
- Metrics
- Idempotency/reconciliation

## Reliability verdict

- Jobs
- Announcements
- Realtime
- Dependencies
- Backup/restore
- Observability

## Performance verdict

- Concurrency
- RPS
- Latency
- Error rate
- Headroom
- Bottlenecks

## Blocking actions

List exact changes required before release.

Do not conclude “production ready” without executed evidence.

