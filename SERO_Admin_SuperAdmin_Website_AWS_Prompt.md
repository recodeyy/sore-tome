# SERO Admin and Super Admin Web Portal — AWS-Ready Control Website with AI, Voice, Multilingual, Billing, Reports, and Cross-Role Operations

## Role

Act as a **Principal Web Architect, Senior React/Next.js Engineer, Admin UX Designer, Backend Integration Engineer, AWS Deployment Engineer, AI Assistant Engineer, Voice UX Engineer, Security Engineer, and QA Lead**.

You are building a professional web control portal for SERO that connects to the same backend and database as the mobile app.

The website is for:

- Super Admin / Platform team
- Society Admin
- Committee
- Treasurer
- Secretary
- Security Manager
- Facility Manager
- Support/Helpdesk users

The mobile app is for residents/staff daily use. The website is for serious society operations, reports, billing, approvals, and controls.

The website must be clean, modern, green-white, responsive, easy to use, multilingual, AI-assisted, voice-enabled, and ready to deploy on AWS.

Do not build a static dashboard. Every table, graph, card, report, approval, notification, bill, and CSV/PDF download must connect to live backend APIs.

---

# 1. Tech stack

Use one of these:

## Preferred

- Next.js
- TypeScript
- Tailwind CSS
- shadcn/ui or a clean custom component system
- TanStack Query
- TanStack Table
- React Hook Form
- Zod validation
- Recharts or ECharts
- i18n support
- AWS deployment

## Acceptable

- React + Vite + TypeScript for a pure SPA

Use existing backend APIs where available. Add missing endpoints only through the canonical backend.

Do not create a second database.

---

# 2. Website deployment target

Prepare for AWS hosting.

## Recommended AWS options

For a simple SPA:

- S3 + CloudFront

For Next.js with SSR:

- AWS Amplify Hosting
- AWS App Runner
- SST/OpenNext on AWS if team is comfortable

Use:

- AWS Route 53 only if domain is available
- AWS Certificate Manager for HTTPS
- AWS Secrets Manager or SSM Parameter Store for secrets
- CloudWatch logs
- WAF/rate limits where practical

Create:

1. `WEBSITE_AWS_DEPLOYMENT_PLAN.md`
2. `WEBSITE_ENVIRONMENT_MATRIX.md`
3. `WEBSITE_DEPLOYMENT_RUNBOOK.md`

For now, mobile/backend may use free or low-cost providers, but the website plan must be AWS-ready.

---

# 3. Visual design direction

Create a professional green-white SERO control portal.

Use:

- White background
- Emerald green primary
- Soft green highlights
- Navy text
- Slate borders
- Clean cards
- Professional sidebar
- Top command bar
- Status chips
- Good data tables
- Good filters
- Clean charts
- Modern modals/drawers
- Strong empty/error/loading states

The UI should feel like a polished SaaS admin product, not a college project.

Do not copy MyGate, NoBrokerHood, or ADDA screens/branding. Use them only as product-quality inspiration.

---

# 4. Website information architecture

## 4.1 Super Admin portal

Sidebar:

- Platform Dashboard
- Societies
- Approvals
- KYC Verification
- Subscriptions
- Plans and Features
- Revenue
- Usage Analytics
- Support Tickets
- Global Announcements
- Push Campaigns
- White Label
- API Access
- Audit Logs
- Impersonation
- System Health
- AI Usage
- Settings

## 4.2 Society Admin portal

Sidebar:

- Dashboard
- Society Setup
- Members and Tenants
- Committee
- Billing
- Payments
- Receipts
- Bank Reconciliation
- Utility Billing
- Expenses
- Ledger
- Reports
- Notices
- Announcements
- Polls and AGM
- Complaints
- Staff and Vendors
- Attendance and Payroll
- Visitors and Security
- Parcels
- Parking
- Vehicles
- Amenities
- Assets
- Documents and Statutory Registers
- Rules and Bylaws
- NOCs
- Discover / Community
- Notifications
- AI Assistant
- Settings

## 4.3 Role-based sidebar

Show only permitted modules.

Treasurer sees finance modules.

Secretary sees communication/governance modules.

Security manager sees visitor/security/staff modules.

Super Admin sees platform modules.

Do not hide-only. Backend must authorize.

---

# 5. Key website workflows

## 5.1 Society onboarding

Super Admin:

1. View new society applications.
2. Verify documents/KYC.
3. Approve/reject/request information.
4. Enable subscription plan.
5. Toggle features.
6. Track setup progress.
7. Send onboarding notification.

Admin:

1. Configure society profile.
2. Add wings/blocks/floors/flats.
3. Import members by CSV.
4. Invite residents.
5. Approve resident requests.
6. Assign committee roles.

## 5.2 Member and tenant management

Admin can:

- Add/edit residents
- Approve/reject resident flat claims
- Manage owners/tenants/family members
- Upload/import CSV
- Export CSV
- View KYC status
- Manage vehicles
- View parking
- Deactivate/move out
- Send notification

Resident app must update after approval.

## 5.3 Billing management

Implement full billing management:

- Maintenance billing
- Late fees
- Utility billing:
  - Electricity
  - Water
  - Maintenance
- Bill templates
- Recurring billing
- Bulk bill generation
- Adjustments
- Credits
- Penalties
- GST invoice generation
- Payment status
- Dues reminders
- Auto receipt generation
- Download invoice
- Download receipt
- CSV export:
  - Who paid
  - Date
  - Amount
  - Payment mode
  - Flat
  - Receipt number
  - Outstanding
- PDF reports
- Excel export
- Resident billing disputes

## 5.4 Payment and reconciliation

Use Razorpay Test Mode for demo.

Admin website must support:

- View payment attempts
- Verify webhook status
- Bank reconciliation
- Upload bank statement/CSV for demo reconciliation
- Match transaction to resident bill
- Mark manual UPI demo payment only in staging/demo mode with audit
- Generate receipt
- Reverse/refund demo states
- Ledger reports
- Outstanding dues reports
- Defaulter report
- Collection summary

Do not simulate payment success without backend status.

## 5.5 Notices and announcements

Admin can:

- Create notice
- Select audience:
  - All residents
  - Wing
  - Floor
  - Unit
  - Owners
  - Tenants
  - Staff
- Attach files
- Schedule publication
- Require acknowledgement
- Send push notification
- Track read/acknowledgement
- Export read report

Resident app must receive it immediately.

## 5.6 Polls, voting, AGM

Admin can:

- Create poll
- Set eligibility
- Anonymous/non-anonymous
- Unit-level or user-level voting
- Start/end time
- Publish
- Send notification
- Track turnout
- View results
- Export report
- Close poll

Resident app must vote once and results must sync.

## 5.7 Complaints/helpdesk

Admin can:

- View all complaints
- Auto-route by category
- Assign staff/vendor
- Set SLA
- Escalate
- Add internal notes
- Send public update
- View attachments
- Close/reopen
- Export SLA report
- Track recurring issue clusters

Resident app sees only public updates.

Staff app receives assigned task.

## 5.8 Visitor and security management

Admin/security website can:

- View live gate activity
- Expected visitors
- Inside visitors
- Delivery-provider categories
- Domestic-help records
- Overstay alerts
- Staff guard performance
- Incident reports
- SOS alerts
- Patrol logs
- Visitor parking
- Gate settings
- QR/OTP policy

Staff app actions must update web live.

## 5.9 Staff and vendor management

Admin can:

- Add staff
- Assign role
- Assign shift/post
- Track attendance
- Process payroll
- Request/approve leave
- Manage vendors
- Vendor contracts
- Vendor performance
- Assign work orders
- Export reports

## 5.10 Parking and vehicles

Admin can:

- Create parking inventory
- Allocate slots
- Manage visitor parking
- Map vehicle to slot
- Track violations
- Manage waitlist
- Export parking list
- Notify resident

Resident app must show live allocation.

## 5.11 Assets and maintenance

Admin can:

- Add lifts/generators/pumps/CCTV/assets
- Track service schedule
- Create work orders
- Assign staff/vendor
- Upload documents
- View maintenance history
- Report downtime
- Export asset register

## 5.12 Statutory registers and documents

Admin can:

- Maintain statutory registers
- Member register
- Vehicle register
- Visitor register
- Complaint register
- Asset register
- Staff register
- Payment/receipt register
- Meeting minutes
- Rules/bylaws
- NOC templates
- Export PDF/Excel
- Audit logs

## 5.13 Discover/community/offers

Admin can:

- Create community events
- Offers
- Marketplace moderation
- Carpool moderation
- Lost & Found moderation
- Featured posts
- Community guidelines

Resident app sees Discover content.

---

# 6. AI assistant on website

Add a floating AI assistant available on all pages.

Support:

- Gemini
- Groq
- Configurable model provider
- Safe fallback
- Multilingual answers
- English
- Hindi
- Hinglish
- Society-specific context
- Role-specific permissions
- Citations
- Action proposals
- Human confirmation

## AI use cases

Admin can ask:

- “Generate maintenance dues summary for A Wing.”
- “Which flats have unpaid bills?”
- “Draft dues reminder in Hindi.”
- “Summarize complaints this week.”
- “Create notice for water shutdown tomorrow.”
- “Find residents who have not acknowledged the notice.”
- “Explain why collection dropped this month.”
- “Show parking allocation conflicts.”
- “Prepare AGM agenda.”
- “Generate vendor performance summary.”

Super Admin can ask:

- “Which societies have high churn risk?”
- “Show payment adoption by society.”
- “Draft global announcement.”
- “Which societies have setup incomplete?”
- “Find support tickets breaching SLA.”

AI must not bypass permissions or execute high-risk actions without confirmation.

---

# 7. ElevenLabs voice assistant

Add voice assistant support across the website.

## Features

- Microphone input
- Voice-to-text if configured
- Text-to-speech through ElevenLabs
- Voice response playback
- Multilingual voice support
- Voice command confirmation
- Mute/stop
- Accessibility controls
- Privacy notice

## Voice assistant examples

- “Show unpaid flats in A Wing.”
- “Create a notice for lift maintenance.”
- “Download payment report for this month.”
- “Open visitor dashboard.”
- “Read this complaint summary aloud.”
- “Send reminder to unpaid residents.”

High-impact commands must show confirmation before execution.

Do not expose API keys in browser. Use backend proxy.

---

# 8. Google Translate / multilingual website

Implement whole-site multilingual support.

Options:

1. Proper i18n translation files for core UI.
2. Google Translate widget/script for demo-level whole-site translation if acceptable.
3. Hybrid:
   - i18n for navigation/forms
   - AI/Google Translate for content/demo

Requirements:

- Language selector
- English
- Hindi
- Marathi if useful
- Gujarati if useful
- Kannada if useful
- Hinglish support in AI
- Persist preference
- Do not break forms/tables
- Do not translate internal IDs, amounts, receipt numbers, or code values incorrectly
- Support translated notice drafts

Create `WEBSITE_MULTILINGUAL_PLAN.md`.

---

# 9. Cross-role sync with mobile

The website must be the control center for the mobile app.

Prove:

- Admin creates society → Resident can request flat.
- Admin approves Resident → Resident dashboard unlocks.
- Admin publishes notice → Resident gets notification.
- Admin generates bill → Resident sees and pays.
- Admin creates poll → Resident votes.
- Admin allocates parking → Resident sees slot.
- Admin configures amenity → Resident books.
- Admin assigns complaint → Staff receives.
- Staff completes task → Admin and Resident update.
- Guard logs visitor → Resident notification.
- Resident pre-invites visitor → Staff expected visitor list.
- Super Admin toggles feature → Admin/mobile navigation changes.

---

# 10. Live data and no mock rule

Every website widget must use live data.

Search and remove production use of:

- Mock
- Dummy
- Sample
- Static cards
- Hard-coded metrics
- Placeholder charts
- Fake rows
- Random counters
- Local JSON
- Simulated payments
- Test users in production

Demo seed data must come from backend seed script only.

---

# 11. Security

Implement:

- Login/session
- Role-based access
- Tenant/society isolation
- Field-level permissions
- MFA for Super Admin
- Audit logs
- Impersonation with audit
- CSRF protection where applicable
- CORS
- Rate limits
- Secure headers
- No secrets in browser
- Signed file access
- Payment webhook security
- AI prompt-injection protection
- Voice assistant action confirmation

---

# 12. Reports and downloads

Admin website must download:

- Members CSV
- Tenants CSV
- Paid/unpaid CSV
- Payment collection CSV
- Receipts PDF
- GST invoices PDF
- Bank reconciliation report
- Complaint SLA report
- Visitor register
- Staff attendance
- Payroll
- Parking allocation
- Asset register
- Statutory registers
- Poll results
- Notice read report
- Event RSVP report

Exports must be generated from live backend data.

For large exports use background job and download link.

---

# 13. UI quality

Must include:

- Professional sidebar
- Global search
- Command palette
- Breadcrumbs
- Filters
- Sort
- Pagination
- Bulk actions
- Drawer forms
- Confirmation modals
- Toasts
- Skeleton loading
- Error states
- Empty states
- Responsive layout
- Keyboard shortcuts for power users
- Clean print/download layouts

No screen should show raw JSON, default browser alerts, or broken table overflow.

---

# 14. Deployment and environment

Create:

- `.env.example`
- AWS deployment guide
- Staging/prod config
- Build script
- Preview build
- Error monitoring
- Analytics
- Health checks
- Rollback steps

Recommended:

- Website: AWS Amplify or S3 + CloudFront
- Backend demo: Railway/Render/Fly/Supabase/Neon/Upstash after checking current free-tier limits
- Files: S3/Supabase/R2
- Notifications: Firebase FCM
- Payments: Razorpay Test Mode for demo
- AI: Gemini/Groq through backend
- Voice: ElevenLabs through backend

---

# 15. Automated tests

Create:

- Unit tests
- Component tests
- Playwright E2E
- API contract tests
- Permission tests
- Cross-role tests
- Export tests
- Notification tests
- AI assistant tests
- Voice assistant tests
- Payment demo tests
- Deployment smoke tests

Required E2E:

1. Super Admin approves society.
2. Admin creates Hubtown Sunkist structure.
3. Resident requests A-1402.
4. Admin approves.
5. Admin generates bill.
6. Resident pays in app.
7. Website collection report updates.
8. Admin publishes notice.
9. Resident receives notification.
10. Guard sends delivery approval.
11. Resident approves.
12. Staff entry appears live.
13. Complaint assignment to Staff.
14. Staff completion updates website and app.
15. Poll vote and result.
16. Parking allocation.
17. CSV export.

---

# 16. Final deliverables

Produce:

1. `WEBSITE_EXECUTIVE_SUMMARY.md`
2. `WEBSITE_ARCHITECTURE.md`
3. `WEBSITE_SCREEN_ROUTE_API_MATRIX.md`
4. `WEBSITE_AWS_DEPLOYMENT_PLAN.md`
5. `WEBSITE_AI_VOICE_ASSISTANT_REPORT.md`
6. `WEBSITE_MULTILINGUAL_PLAN.md`
7. `WEBSITE_BILLING_REPORTS_REPORT.md`
8. `WEBSITE_CROSS_ROLE_SYNC_REPORT.md`
9. `WEBSITE_SECURITY_REPORT.md`
10. `WEBSITE_E2E_TEST_REPORT.md`
11. `WEBSITE_FINAL_RELEASE_GATE.md`

Final verdict:

- PASS
- PASS WITH APPROVED P2/P3 EXCEPTIONS
- FAIL

Automatic fail:

- Any website page uses fake data
- Admin action does not update mobile app
- Export downloads are not live
- AI can access unauthorized data
- Voice action executes without confirmation
- Payment report mismatches ledger
- Tenant isolation fails
- Website cannot deploy
- Any P0/P1 remains

---

# 17. Start instruction

Begin in this order:

1. Audit current repo backend APIs.
2. Decide Next.js or React SPA.
3. Build route/API matrix.
4. Implement auth and role sidebar.
5. Build core dashboard.
6. Build billing/payments/reports first.
7. Build notices/polls/events.
8. Build complaints/staff/visitor/security.
9. Add AI chatbot and voice assistant.
10. Add multilingual support.
11. Connect exports.
12. Run cross-role E2E with mobile app.
13. Deploy to AWS staging.

Do not build static admin screens. Every control must change real backend state and sync to the mobile app.
