# SERO Member / Resident App — Feature Matrix (57 Capabilities)

This document maps the 57 mandatory capabilities of the SERO Resident module, specifying the frontend screen, backend endpoint, authorization scope, and current status.

| Feature ID | Category | Description | Frontend Screen | Backend Endpoint | Authorization / Role Scope | Status |
|---|---|---|---|---|---|---|
| **A. Profile & Household** | | | | | | |
| 1 | Profile | View and update personal profile | `MyProfileTab` | `PATCH /profile` | `profile.update_own` | Pending |
| 2 | Profile | Manage family members | `HouseholdTab` (Family) | `POST /household/members` | `household.manage` | Pending |
| 3 | Profile | Manage relationships (tenant, co-owner) | `HouseholdTab` (Relationships) | `PATCH /household/members/:id` | `household.manage` | Pending |
| 4 | Profile | Manage household emergency contacts | `EmergencyContactsTab` | `POST /emergency-contacts` | `household.manage` | Pending |
| 5 | Profile | Register, edit, remove vehicles | `VehiclesScreen` | `POST /vehicles`, `DELETE /vehicles/:id` | `vehicle.manage` | Pending |
| 6 | Profile | Upload and track KYC documents | `KycScreen` | `POST /kyc/upload-intent` | `kyc.upload_own` | Pending |
| 7 | Profile | Manage settings and preferences | `PreferencesTab` | `PATCH /preferences` | `profile.update_own` | Pending |
| 8 | Profile | View unit/occupancy & verify status | `UnitDetailsTab` | `GET /profile` | `profile.read_own` | Pending |
| **B. Bills & Payments** | | | | | | |
| 9 | Bills | View current and past bills | `BillsScreen` | `GET /bills` | `bill.read_own` | Pending |
| 10 | Bills | View detailed bill components & dates | `BillDetailScreen` | `GET /bills/:billId` | `bill.read_own` | Pending |
| 11 | Payments | Pay full, partial, or combined amount | `CheckoutScreen` | `POST /payments/intents` | `payment.create` | Pending |
| 12 | Payments | Track payment success/failure state | `CheckoutScreen` (Status) | `GET /payments/:paymentId` | `payment.read_own` | Pending |
| 13 | Payments | Download and share official receipts | `ReceiptsScreen` | `GET /receipts/:receiptId` | `receipt.read_own` | Pending |
| 14 | Payments | Configure/pause/cancel auto-pay | `AutoPayScreen` | `POST /autopay/setup`, `/pause` | `autopay.manage` | Pending |
| 15 | Payments | View payment history and credits | `PaymentHistoryScreen` | `GET /payments` | `payment.read_own` | Pending |
| 16 | Payments | Receive reminders & raise billing query | `BillingQueryScreen` | `POST /billing-queries` | `payment.read_own` | Pending |
| **C. Visitors & Help** | | | | | | |
| 17 | Visitors | Pre-approve a visitor | `PreApproveVisitorScreen` | `POST /visitors` | `visitor.create` | Pending |
| 18 | Visitors | Realtime walk-in approval/rejection | `VisitorApprovalDialog` | `POST /visitors/:visitId/approve` | `visitor.approve` | Pending |
| 19 | Visitors | Generate/share QR/OTP gate pass | `PreApproveVisitorScreen` | `GET /visitors/:visitId` | `visitor.create` | Pending |
| 20 | Visitors | View visitor logs and history | `VisitorsScreen` | `GET /visitors` | `visitor.create` | Pending |
| 21 | Visitors | Receive entry/exit/overstay notices | `Notifications` | `FCM / SSE Streams` | `visitor.create` | Pending |
| 22 | Help | Add and manage domestic-help profiles | `DomesticHelpScreen` | `POST /domestic-help` | `domestic_help.manage` | Pending |
| 23 | Help | Configure schedules & access gates | `DomesticHelpDetailScreen` | `PATCH /domestic-help/:id` | `domestic_help.manage` | Pending |
| 24 | Help | Pause, revoke, check attendance logs | `DomesticHelpDetailScreen` | `POST /domestic-help/:id/pause` | `domestic_help.manage` | Pending |
| **D. Complaints** | | | | | | |
| 25 | Complaints | Raise a complaint/service request | `NewComplaintScreen` | `POST /complaints` | `complaint.create` | Pending |
| 26 | Complaints | Select category, details & upload media | `NewComplaintScreen` | `POST /complaints/:id/attachments` | `complaint.create` | Pending |
| 27 | Complaints | Track complaint status & SLA timeline | `ComplaintDetailScreen` | `GET /complaints/:id` | `complaint.read_own` | Pending |
| 28 | Complaints | Chat with Admin/Staff (public comments) | `ComplaintChatWidget` | `POST /complaints/:id/comments` | `complaint.comment` | Pending |
| 29 | Complaints | Add info/withdraw complaint | `ComplaintDetailScreen` | `POST /complaints/:id/withdraw` | `complaint.create` | Pending |
| 30 | Complaints | Reopen resolved complaints | `ComplaintDetailScreen` | `POST /complaints/:id/reopen` | `complaint.reopen` | Pending |
| 31 | Complaints | Rate resolution and submit feedback | `ComplaintRatingDialog` | `POST /complaints/:id/feedback` | `complaint.rate` | Pending |
| **E. Community** | | | | | | |
| 32 | Notices | View the notice board | `NoticesScreen` | `GET /notices` | `notice.read` | Pending |
| 33 | Notices | Open notices, check acknowledgement | `NoticeDetailScreen` | `POST /notices/:id/acknowledge` | `notice.read` | Pending |
| 34 | Events | Discover society events | `EventsScreen` | `GET /events` | `event.read` | Pending |
| 35 | Events | RSVP, join waitlist, add to calendar | `EventDetailScreen` | `POST /events/:id/rsvp` | `event.rsvp` | Pending |
| 36 | Polls | View eligible polls and cast vote | `PollsScreen` | `POST /polls/:id/votes` | `poll.vote` | Pending |
| 37 | Polls | View poll results according to rules | `PollDetailScreen` | `GET /polls/:id` | `poll.vote` | Pending |
| 38 | Market | Browse and search marketplace items | `MarketplaceScreen` | `GET /marketplace` | `marketplace.read` | Pending |
| 39 | Market | Create, edit, pause, close own listing | `CreateListingScreen` | `POST /marketplace`, `/pause` | `marketplace.create` | Pending |
| 40 | Market | Chat with listing owner safely & report | `ListingDetailScreen` | `POST /marketplace/:id/report` | `marketplace.read` | Pending |
| 41 | Carpool | Create carpool offer/request | `CarpoolScreen` | `POST /carpool` | `carpool.use` | Pending |
| 42 | Carpool | Join/leave/manage trips & seats | `CarpoolDetailScreen` | `POST /carpool/:id/join` | `carpool.use` | Pending |
| 43 | Lost/Found | Create lost/found posts & claim | `LostFoundScreen` | `POST /lost-found/:id/claim` | `lost_found.use` | Pending |
| 44 | Moderation | Report, block, flag community posts | `ReportDialog` | `POST /community/reports` | `marketplace.read` | Pending |
| **F. Amenities** | | | | | | |
| 45 | Amenities | Browse amenities, rules, hours | `AmenitiesScreen` | `GET /amenities` | `amenity.read` | Pending |
| 46 | Amenities | View live slot availability | `AmenityDetailScreen` | `GET /amenities/:id/availability` | `amenity.read` | Pending |
| 47 | Amenities | Book slot with guest/capacity details | `AmenityBookingScreen` | `POST /bookings` | `amenity.book` | Pending |
| 48 | Amenities | Pay booking fee/deposit & track status | `BookingPaymentScreen` | `POST /bookings` (with payment) | `amenity.book` | Pending |
| 49 | Amenities | View/cancel/reschedule bookings | `BookingsScreen` | `POST /bookings/:id/cancel` | `amenity.book` | Pending |
| 50 | Amenities | Write, edit, view reviews | `AmenityReviewsWidget` | `POST /amenities/:id/reviews` | `amenity.review` | Pending |
| **G. Emergency** | | | | | | |
| 51 | Emergency | Trigger an SOS alert | `SosScreen` (Active) | `POST /sos` | `sos.trigger` | Pending |
| 52 | Emergency | View SOS responder status/timeline | `SosScreen` (Timeline) | `GET /sos/:id` | `sos.read_own` | Pending |
| 53 | Emergency | Manage personal emergency contacts | `EmergencyContactsTab` | `POST /emergency-contacts` | `household.manage` | Pending |
| 54 | Emergency | Access emergency directory & guidance | `EmergencyDirectoryScreen` | `GET /emergency-directory` | `emergency.read` | Pending |
| **H. Documents** | | | | | | |
| 55 | Documents | View and search rules, bylaws | `RulesScreen` | `GET /rules` | `document.read` | Pending |
| 56 | Documents | Download receipts/account files | `DocumentsScreen` | `GET /documents` | `document.read` | Pending |
| 57 | Documents | Request/track/download NOCs | `NocsScreen` | `POST /nocs`, `GET /nocs/:id` | `noc.request` | Pending |
