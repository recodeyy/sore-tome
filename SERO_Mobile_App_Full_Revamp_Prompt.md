# SERO Mobile App Full Revamp — MyGate / NoBrokerHood / ADDA-Level Resident, Staff, Guard, Admin-Connected App

## Role

Act as a **Principal Mobile Product Architect, Staff Flutter Engineer, React Native/Expo Migration Advisor, UI/UX Lead, FCM Engineer, Society-Management Domain Expert, Payments Engineer, and Full-Stack QA Lead**.

You are working on the current SERO repository:

`https://github.com/recodeyy/sore-tome`

The current app has serious issues:

- Many backend APIs are not connected.
- Some modules work and some do not.
- Resident section crashes or shows “Something went wrong.”
- Some screens become blank.
- Polls and cross-role flows are not working.
- Notifications are not working reliably.
- Admin actions are not consistently visible to residents.
- Staff actions are not consistently notifying residents.
- UI is not polished or user-friendly enough.
- Visitor management is far behind MyGate / NoBrokerHood style experiences.
- Billing, receipts, dues reminders, reconciliation, and payment demo flows are incomplete.
- The app is deployed on GCP but GCP is expiring, so deployment must move to free/low-cost alternatives for demo.

Your task is to **revamp the mobile app into a professional, stable, green-white, user-friendly, fully live, cross-role society-management app** while preserving all existing SERO features and connecting them properly to backend APIs.

The app should feel modern and polished like leading Indian society apps, but it must be original. Do not copy proprietary UI, brand assets, icons, names, screens, or copyrighted design.

---

# 1. Product benchmark and target quality

Use the following society-management capabilities as benchmark expectations:

- Maintenance billing with late fees
- Complaints management/helpdesk
- Visitor tracking with real-time gate security
- Invite visitor/pre-approval
- Automated dues reminders through push notifications
- Member and tenant management
- Staff and vendor management
- Vehicle management
- Digital notice board
- Online payment gateway
- Auto receipt generation
- Bank reconciliation
- Utility billing for electricity, water, and maintenance
- Statutory registers/automatic record keeping
- Family-member management
- Discover/community section
- Amenity booking
- Parking allocation
- Domestic-help check-in/check-out
- Delivery-provider notifications such as Swiggy, Zomato, BigBasket, Blinkit, Zepto, courier, cab, service provider, guest, vendor, etc.

The app must be better than a checklist. It must work smoothly across Resident, Staff/Guard, Admin, and Super Admin roles.

---

# 2. First mandatory audit

Before coding, inspect the current app and produce:

1. `MOBILE_REVAMP_CURRENT_STATE_AUDIT.md`
2. `MOBILE_REVAMP_CRASH_BLANK_SCREEN_REPORT.md`
3. `MOBILE_REVAMP_SCREEN_ROUTE_API_MATRIX.md`
4. `MOBILE_REVAMP_CROSS_ROLE_GAP_REPORT.md`
5. `MOBILE_REVAMP_NOTIFICATION_GAP_REPORT.md`
6. `MOBILE_REVAMP_UI_UX_AUDIT.md`
7. `MOBILE_REVAMP_BACKEND_DEPENDENCY_MAP.md`
8. `MOBILE_REVAMP_DEPLOYMENT_MIGRATION_PLAN.md`
9. `mobile_revamp_findings.json`

For every screen record:

- Role
- Route
- Flutter/Expo file
- Provider/state manager
- API endpoint
- Database source
- Realtime event
- Notification event
- Loading state
- Empty state
- Error state
- Crash risk
- Current issue
- Required fix
- Test

Do not start UI polishing before crash, API, and live-data gaps are mapped.

---

# 3. Technology decision

## 3.1 Default path

The current repo uses Flutter. Prefer fixing and revamping the existing Flutter app first.

Use Flutter if:

- Existing code can be stabilized.
- Existing navigation can be repaired.
- Flutter build is working.
- Current app structure can support all roles.

## 3.2 Expo fallback

Use React Native Expo only if the audit proves Flutter is blocking delivery because of structural or unrecoverable issues.

If proposing Expo:

- Create `MOBILE_EXPO_MIGRATION_DECISION.md`.
- Explain why Flutter cannot be stabilized.
- Preserve API contracts.
- Preserve design system.
- Preserve all feature flows.
- Do not rewrite blindly.
- Create feature parity checklist.
- Ensure Android APK build works.
- Ensure FCM/deep links work.

Do not mix two unfinished mobile apps.

---

# 4. Visual design direction

Create a modern green-white SERO app.

## Style

- Clean white background
- Emerald/green accents
- Navy text for hierarchy
- Soft cards
- Rounded corners
- Premium but simple
- Large icons
- Friendly illustrations only if lightweight
- Smooth bottom navigation
- Modern gradients
- Consistent typography
- Clear status chips
- No dense enterprise clutter
- No random colors
- No broken alignment

## Colors

Use:

- Primary green: `#064E3B`
- Accent green: `#10B981`
- Light green: `#ECFDF5`
- White: `#FFFFFF`
- Slate background: `#F8FAFC`
- Border: `#E2E8F0`
- Navy text: `#111827`
- Secondary text: `#64748B`
- Error: `#EF4444`
- Warning: `#F59E0B`
- Info: `#0EA5E9`

## UI principles

- Resident app should be simple and friendly.
- Staff app should be fast and operational.
- Admin mobile views should be lightweight, not dense.
- Super Admin mobile views can be summary/control only.
- All heavy admin management should be best on the website.
- Every error state should be recoverable.
- No “Something went wrong” without clear reason and retry.
- No blank screens.
- No infinite loaders.
- Every core action must have visible feedback.

---

# 5. App roles and login

Keep separate login portals:

- Super Admin
- Society Admin
- Staff & Security
- Member / Resident

After login:

- Super Admin → Super Admin shell
- Admin/committee → Admin shell
- Staff/Guard → Staff shell
- Resident/tenant/family → Resident shell

The selected login portal must not grant permission. Backend must verify role.

## Resident onboarding flow

Implement this flow fully:

1. Resident opens app.
2. Resident selects or searches society.
3. Resident selects wing/block/floor/flat.
4. Resident enters profile details.
5. Resident submits request.
6. Admin receives approval request on web/admin app.
7. Admin approves/rejects.
8. Resident receives notification.
9. Approved resident dashboard unlocks.
10. Rejected/pending resident gets a clear status screen.

Example demo:

- Society: Hubtown Sunkist
- Wing: A
- Floor: 14
- Flat: 1402

---

# 6. Core app navigation

## Resident bottom tabs

1. Home
2. Community
3. Pay
4. Visitors
5. More

Center Pay button should be prominent.

## Staff/Guard bottom tabs

1. Home
2. Gate
3. Tasks
4. Security
5. More

## Admin mobile tabs

1. Dashboard
2. Members
3. Billing
4. Operations
5. More

## Super Admin mobile tabs

1. Platform
2. Societies
3. Revenue
4. Support
5. More

All tabs must be live, route-safe, and crash-free.

---

# 7. Resident experience

## 7.1 Home dashboard

Show live:

- Society and flat
- Outstanding dues
- Pay now button
- Active visitors
- Domestic help status
- Latest notice
- Pending complaints
- Upcoming amenity booking
- Polls to vote
- Events
- Parcels
- Parking slot
- Emergency shortcut
- AI assistant shortcut

No static counts.

## 7.2 Payments

Implement complete demo billing:

- View maintenance bills
- View utility bills:
  - Electricity
  - Water
  - Maintenance
- Late fee display
- Bill line items
- Due date
- Outstanding balance
- Payment status
- Razorpay Test Mode payment
- UPI demo QR code
- UPI deep link where supported
- Auto receipt generation
- Download PDF receipt
- Share receipt
- Offline saved receipt
- Payment history
- Payment failure/pending/success
- Refund/demo reversal state
- Dues reminder notification

Important:

- Client callback is not final payment proof.
- Backend verifies Razorpay test signature/webhook.
- UI shows `Processing` until backend verifies payment.
- Duplicate taps must not duplicate payment.
- Duplicate webhooks must create one financial effect.

## 7.3 Visitors

Implement MyGate/NoBrokerHood-style flow.

### Resident pre-approval

1. Resident taps “Invite Visitor.”
2. Select visitor type:
   - Guest
   - Delivery
   - Cab
   - Service Provider
   - Vendor
   - Domestic Help
   - Other
3. Add name/mobile/vehicle/time window.
4. Generate QR/OTP pass.
5. Staff gate receives expected visitor.
6. Visitor enters faster without disturbing resident where policy allows.

### Staff-initiated approval

1. Staff selects flat A-1402.
2. Staff selects visitor type:
   - Guest
   - Swiggy
   - Zomato
   - BigBasket
   - Blinkit
   - Zepto
   - Courier
   - Cab/Driver
   - Maintenance Technician
   - Vendor
   - Other
3. Staff adds purpose/details/photo if required.
4. Resident receives push + in-app approval card immediately.
5. Resident approves/rejects.
6. Staff sees result live.
7. Entry is recorded.
8. Exit is recorded.
9. Resident receives entry/exit notification.

### Domestic help

- Add maid/driver/cook profile
- Schedule
- Gate permissions
- Check-in notification
- Check-out notification
- Access history
- Pause/revoke access
- Report issue

## 7.4 Complaints

- Raise complaint
- Add photo/video/file
- Category/location
- Track status
- Chat with Admin
- Public Staff updates
- Internal notes hidden
- Resolution proof
- Reopen
- Rating

## 7.5 Community

- Notice board
- Announcements
- Polls
- Events
- Discover section:
  - Community events
  - Offers
  - Marketplace
  - Carpool
  - Lost & Found
- Push notifications
- Deep links
- Read/acknowledged states

## 7.6 Amenities

- Browse gym/hall/clubhouse/pool
- See timings/rules/price
- Live slot availability
- Book slot
- Pay demo fee/deposit if configured
- Cancel/reschedule
- Download booking confirmation
- Reviews

## 7.7 Parking and vehicles

- Register vehicles
- View allocated parking slot
- Visitor parking request
- Parking violation notification
- Slot transfer/waitlist where configured

## 7.8 Documents

- Rules
- Bylaws
- Receipts
- NOCs
- Downloadable PDFs
- Offline saved receipts/documents
- Search

## 7.9 Emergency

- SOS button
- Emergency contacts
- Staff acknowledgement status
- Resolution timeline
- Emergency directory

---

# 8. Staff / Guard experience

Create a fast operational Staff app.

## Gate dashboard

- Current shift
- Gate assignment
- Expected visitors
- Pending approvals
- Inside visitors
- Parcels pending
- SOS alerts
- Quick actions

## Visitor flow

- Search flat by society/wing/floor/flat
- Quick select provider:
  - Swiggy
  - Zomato
  - BigBasket
  - Blinkit
  - Zepto
  - Courier
  - Cab
  - Guest
  - Vendor
  - Service
- Scan QR
- OTP verification
- Capture photo/vehicle
- Send approval
- Record entry
- Record exit
- Overstay alert
- Real-time status
- Works with resident pre-approval

## Parcel flow

- Log parcel
- Select flat
- Courier/provider
- Photo
- Notify resident
- Resident OTP/QR for collection
- Handover
- Collected notification

## Security

- SOS alerts
- Incident reports
- Patrol tracking
- Shift handover

## Staff tasks

- Assigned complaints
- Update status
- Upload proof
- Notify resident/admin

## Attendance

- Check in/out
- Break
- Leave request
- Roster

---

# 9. Admin mobile experience

Admin mobile should be useful for quick operations, while full management lives on website.

Implement:

- Dashboard
- Member approval
- Notices
- Bills summary
- Complaint routing
- Visitor/security overview
- Staff overview
- Parking quick view
- Poll/event quick create
- Push announcement
- Reports quick download/share
- AI assistant

---

# 10. Notifications and realtime

Implement one canonical NotificationService.

## Required notifications

Resident receives:

- Admin approval/rejection
- New bill
- Dues reminder
- Payment success/failure
- Receipt generated
- Visitor approval request
- Visitor entry/exit
- Domestic help check-in/out
- Parcel received/collected
- Complaint status/chat
- Notice/announcement
- Poll/event
- Amenity booking
- Parking allocation
- SOS status
- NOC/KYC update

Staff receives:

- Resident pre-approved visitor
- Complaint assignment
- SOS
- Roster/shift
- Parcel pickup/reminder
- Admin instruction

Admin receives:

- Resident registration request
- Payment received
- Complaint created/escalated
- Staff task updates
- Visitor/security exceptions
- Poll/event activity
- Parking requests
- SOS

## FCM requirements

- Register device token
- Multiple devices per user
- Remove invalid tokens
- Foreground
- Background
- Killed app
- Notification tap deep link
- Android notification channels
- Badge count
- Deduplication
- Retry/backoff
- Delivery logs
- No cross-society leakage
- Lock-screen privacy

---

# 11. Backend/API live connection

Every app feature must use real backend APIs.

Do not show fake data except controlled demo seed data.

Required APIs include:

- Auth/workspaces
- Society search/selection
- Resident approval
- Members
- Family
- Vehicles
- KYC
- Bills
- Payments
- Receipts
- Auto-pay demo
- Visitor approvals
- Staff gate events
- Domestic help
- Parcels
- Complaints/chat
- Notices
- Announcements
- Polls/votes
- Events/RSVP
- Amenities/bookings
- Parking
- Assets
- Staff/attendance/leave
- SOS/incidents/patrols
- Rules/documents/NOCs
- Notifications
- AI Copilot

Fix all legacy endpoint mismatches.

---

# 12. Demo data policy

Demo data is allowed only in staging/demo environments.

Create a high-quality demo society:

- Hubtown Sunkist
- A Wing
- Floor 14
- Flat 1402

Use it to demonstrate all workflows.

But:

- Do not hard-code demo data in UI.
- Seed via backend script.
- Data must live in database.
- UI must fetch it through API.
- Demo payment must use Razorpay Test Mode or documented UPI demo QR.
- Receipts must be generated from backend data.

---

# 13. Payment demo

Implement both:

## Razorpay Test Mode

- Backend creates order.
- Frontend opens Razorpay checkout.
- Backend verifies signature/webhook.
- Status updates live.
- Receipt generated.
- Ledger updated.
- Admin collection report updates.

## UPI demo QR

For demo only:

- Generate UPI QR/deep link from backend-controlled test merchant config.
- Clearly label as demo/test.
- Do not claim real bank settlement unless verified.
- Allow manual marking only in Admin demo mode with audit.
- Generate receipt only after verified/test-approved status.

---

# 14. Crash-free requirements

Fix every blank screen.

For every route:

- Loading state
- Empty state
- Error state
- Retry
- Offline
- Request ID
- Null-safe model parsing
- Unknown enum fallback
- No unsafe `!`
- No invalid casts
- No route missing ID crash
- No infinite loader
- No setState after dispose
- No duplicate API storm
- No stale workspace data

Run the app on two phones simultaneously:

- One Admin/Staff
- One Resident

Prove live sync.

---

# 15. Deployment without GCP

GCP is expiring. Prepare free/low-cost deployment options.

## Backend free/low-cost candidates

Evaluate and choose based on current limits:

- Railway
- Render
- Fly.io
- Supabase Edge/Functions where suitable
- AWS free tier or low-cost ECS/App Runner/Lightsail
- Any existing approved provider

## Database

Evaluate:

- Supabase Postgres
- Neon Postgres
- Railway Postgres
- AWS RDS free-tier if eligible

## Redis/queue

Evaluate:

- Upstash Redis
- Railway Redis
- Render Redis
- Supabase alternatives if queue design changes

## Files

Evaluate:

- Cloudflare R2
- Supabase Storage
- AWS S3

## Web/admin

Website can be hosted on AWS:

- AWS Amplify
- S3 + CloudFront
- App Runner if SSR/backend needed

## App distribution

For now:

- APK download through GitHub Releases or website
- Firebase App Distribution if available
- Play Store later

Create:

- `DEPLOYMENT_FREE_LOW_COST_PLAN.md`
- `DEPLOYMENT_ENV_MATRIX.md`
- `DEPLOYMENT_RUNBOOK.md`

Do not commit secrets.

---

# 16. UI QA and polish

Make the app feel professional:

- Consistent green-white UI
- Clean cards
- Smooth navigation
- Proper icons
- No overflow
- No broken alignment
- No random font sizes
- No debug text
- No ugly default error pages
- Empty states with actions
- Modern skeleton loading
- Good forms
- Good receipts
- Good visitor cards
- Good billing cards
- Good notification inbox
- Good discover cards
- Good staff gate UI

Use original design inspired by best society apps but do not copy them.

---

# 17. Required automated journeys

Create E2E tests:

1. Resident requests society/flat approval → Admin approves → Resident dashboard unlocks.
2. Admin generates maintenance bill → Resident sees → pays via Razorpay Test Mode → receipt downloads.
3. Admin publishes notice → Resident receives push → opens deep link.
4. Guard sends Swiggy/Zomato visitor request → Resident approves → Guard records entry/exit.
5. Resident pre-invites guest → Guard receives expected visitor → scan/entry works.
6. Maid/domestic help checks in → Resident receives notification → checkout notification.
7. Resident raises complaint → Admin assigns → Staff updates → Resident sees update.
8. Admin allocates parking → Resident sees parking slot.
9. Admin creates poll → Resident votes once → Admin sees result.
10. Resident books amenity → Admin sees booking → double booking blocked.
11. Resident triggers SOS → Staff acknowledges → Admin/Resident status updates.
12. AI answers current society rule/event/facility question with citation.

---

# 18. Final reports

Produce:

1. `MOBILE_REVAMP_EXECUTIVE_SUMMARY.md`
2. `MOBILE_REVAMP_FEATURE_MATRIX.md`
3. `MOBILE_REVAMP_CROSS_ROLE_TEST_REPORT.md`
4. `MOBILE_REVAMP_NOTIFICATION_TEST_REPORT.md`
5. `MOBILE_REVAMP_PAYMENT_DEMO_REPORT.md`
6. `MOBILE_REVAMP_DEPLOYMENT_PLAN.md`
7. `MOBILE_REVAMP_CRASH_FREE_REPORT.md`
8. `MOBILE_REVAMP_UI_REPORT.md`
9. `MOBILE_REVAMP_FINAL_RELEASE_GATE.md`

Final verdict:

- PASS
- PASS WITH APPROVED P2/P3 EXCEPTIONS
- FAIL

Automatic fail:

- Resident still crashes
- Any role cannot login
- Admin action does not reach Resident when required
- Staff action does not notify Resident/Admin
- Visitor approval does not work live
- Payment is only locally simulated
- Notifications fail on physical device
- Any major page is blank
- Any major feature is mock-only
- Any cross-society leak exists
- APK build fails

---

# 19. Start instruction

Start in this exact order:

1. Pull latest repo.
2. Run Flutter build/analyze/tests.
3. Run backend build/tests/migrations.
4. Reproduce Resident crashes.
5. Reproduce notification failure.
6. Create screen-route-API matrix.
7. Seed Hubtown Sunkist A-1402.
8. Fix backend live APIs and notifications before UI polish.
9. Revamp UI screen by screen.
10. Run two-device cross-role tests.
11. Prepare deployment plan away from GCP.
12. Build APK and test on physical Android.

Do not create more static screens. Do not mark complete until the app works end to end on real devices.
