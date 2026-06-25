# SERO Member / Resident App — Screen Map

This document maps all the Resident frontend UI screen files in the `sero` client.

## 1. Core Shell & Navigation
*   **File**: `lib/app/resident_shell.dart`
    *   **Description**: Holds the main 5-tab layout (Home, Community, Pay, Complaints, More) and locks screen navigation for unapproved users.
*   **File**: `lib/screens/resident/registration/registration_pending_screen.dart`
    *   **Description**: Displayed if the logged-in resident's membership is still under review or pending.

## 2. Tab 1: Home Dashboard
*   **File**: `lib/screens/resident/home/resident_home_screen.dart`
    *   **Description**: High-level overview of outstanding dues, active visitor approval alerts, new notices, and quick links to core capabilities.

## 3. Tab 2: Community Hub
*   **File**: `lib/screens/resident/channels/resident_channels_screen.dart`
    *   **Description**: Sub-navigation or tabbed interface for notices, events, marketplace, carpool, and lost-and-found posts.
*   **File**: `lib/screens/resident/channels/notices_screen.dart`
    *   **Description**: Searchable list of notices with read acknowledgements.
*   **File**: `lib/screens/resident/channels/events_screen.dart`
    *   **Description**: Lists upcoming and past community events with RSVP and guest count selection.
*   **File**: `lib/screens/resident/polls/polls_screen.dart`
    *   **Description**: Displays active/closed polls and handles cast vote logic.
*   **File**: `lib/screens/resident/channels/marketplace_screen.dart`
    *   **Description**: Browse items for sale, create listings, and contact sellers.
*   **File**: `lib/screens/resident/channels/carpool_screen.dart`
    *   **Description**: View and request to join carpools.
*   **File**: `lib/screens/resident/channels/lost_found_screen.dart`
    *   **Description**: Browse reported lost/found items and submit claims.

## 4. Tab 3: Pay Center (Circular Emerald Button)
*   **File**: `lib/screens/resident/funds/bills_screen.dart`
    *   **Description**: Landing page for payment hub showing current outstanding, invoices, auto-pay settings, and billing query options.
*   **File**: `lib/screens/resident/funds/bill_detail_screen.dart`
    *   **Description**: Breakdown of a specific invoice including charge items, previous balances, penalties, and tax.
*   **File**: `lib/screens/resident/funds/checkout_screen.dart`
    *   **Description**: Secure checkout interface displaying invoice amounts, partial-pay selection, and integration with the payment gateway status hook.
*   **File**: `lib/screens/resident/funds/autopay_screen.dart`
    *   **Description**: Manages recurring auto-pay consent mandates.
*   **File**: `lib/screens/resident/funds/receipts_screen.dart`
    *   **Description**: Lists payment history and provides download links for PDF receipts.
*   **File**: `lib/screens/resident/funds/billing_query_screen.dart`
    *   **Description**: Allows residents to submit payment disputes and track updates.

## 5. Tab 4: Complaints
*   **File**: `lib/screens/resident/issues/resident_issues_screen.dart`
    *   **Description**: Main list showing open/resolved service requests and complaints.
*   **File**: `lib/screens/resident/issues/new_complaint_screen.dart`
    *   **Description**: Form to raise complaints, specify location, assign priority, and upload photo attachments.
*   **File**: `lib/screens/resident/issues/complaint_detail_screen.dart`
    *   **Description**: Timeline-based tracker for complaints with public message chat with admins/staff, feedback rating, and reopen controls.

## 6. Tab 5: More (Utilities Grid)
*   **File**: `lib/screens/resident/more/more_menu_screen.dart`
    *   **Description**: Grid of secondary options such as Profile, Vehicles, KYC, Emergency, Documents, and NOCs.
*   **File**: `lib/screens/resident/profile/resident_profile_screen.dart`
    *   **Description**: Tabbed view managing profile editing, household/family relationships, and language preferences.
*   **File**: `lib/screens/resident/profile/vehicles_screen.dart`
    *   **Description**: Registers personal vehicles and links them to allocated parking bays.
*   **File**: `lib/screens/resident/profile/kyc_screen.dart`
    *   **Description**: Secure document camera upload and status monitoring interface.
*   **File**: `lib/screens/resident/visitors/visitors_screen.dart`
    *   **Description**: Tracks visitor records, pre-approvals, and domestic help logs.
*   **File**: `lib/screens/resident/visitors/pre_approve_visitor_screen.dart`
    *   **Description**: Form to pre-register guests and generate OTP/QR passes.
*   **File**: `lib/screens/resident/visitors/domestic_help_screen.dart`
    *   **Description**: Manages registration, access hours, and attendance logs for staff/helpers.
*   **File**: `lib/screens/resident/facilities/facilities_screen.dart`
    *   **Description**: Amenity catalog for discovering, booking slots, and submitting ratings.
*   **File**: `lib/screens/resident/facilities/bookings_screen.dart`
    *   **Description**: Manage upcoming bookings, reschedule slots, or request cancellations/refunds.
*   **File**: `lib/screens/resident/emergency/sos_screen.dart`
    *   **Description**: Trigger and monitor emergency SOS dispatches.
*   **File**: `lib/screens/resident/emergency/emergency_directory_screen.dart`
    *   **Description**: Localized emergency contacts (security desk, medical centers) cached offline.
*   **File**: `lib/screens/resident/rules/rules_documents_screen.dart`
    *   **Description**: View bylaws, society circulars, and official receipts.
*   **File**: `lib/screens/resident/rules/nocs_screen.dart`
    *   **Description**: Request certificates (NOCs) and download approved PDFs.
