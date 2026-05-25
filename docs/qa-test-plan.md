# QA Test Plan
**Date:** May 25, 2026  
**Scope:** Core Feature Validation, Security Testing, Integration and Load Testing  
**Mode:** Analysis Only

---

## 1. Resident Registration & Admin Onboarding Flow

### Current State
Onboarding logic verifies if a user's phone is in `whitelisted_flats` inside `POST /users/register`. If found, they are auto-approved; otherwise, they remain pending.

### What is Good
- This workflow has logical, deterministic states (`pending`, `approved`, `rejected`) that can be tested in isolation.

### What is Missing
- **Automated Registration Integration Tests:** There are no automated integration test scripts that simulate the user registration flow, whitelist matching, and admin approval triggers.

### What Can Break
- **Registration Blockage:** Changes to database schemas or Firebase configs can break the user profile creation step, preventing new residents from logging in or registering.

### Real-World Risk
- **High:** Onboarding blockers prevent new societies from registering.

### Priority
- **P0** (Must verify before launching beta)

### Recommended Fix
- Write a Jest integration test file (`__tests__/auth.test.js`) that:
  1. Inserts a record into the `whitelisted_flats` collections.
  2. Submits a registration payload using the whitelisted phone.
  3. Verifies that the created user document status is `approved`.
  4. Submits a registration with a non-whitelisted phone and verifies that the status is `pending`.

### Files Affected
- `society-backend/routes/users.js`
- `society-backend/__tests__/auth.test.js` (Create this file)

---

## 2. Visitor Check-in & Real-Time Push Notification Flow

### Current State
Guards check in visitors (`POST /visitors/checkin`) and create a push notification entry in a Firebase `notifications` collection targeted at residents.

### What is Good
- The Firestore push notification document structure maps fields like `targetFlat` and `visitorId` cleanly, which supports reliable messaging.

### What is Missing
- **Push Notification Verification Checks:** There are no tests checking if FCM notifications reach mobile clients under varied device states (foreground, background, killed).

### What Can Break
- **Notification Dropouts:** If Firebase messaging versions mismatches or certificates expire, push notifications will fail. Guards will check in guests, but residents will never see the pop-up, causing visitors to get stuck at the gate.

### Real-World Risk
- **High:** Extreme friction at the gate, ruining society entrance security and daily utility.

### Priority
- **P0** (Must verify before launching beta)

### Recommended Fix
- Execute manual and automated push tests using Firebase console testing triggers. Ensure that the mobile Flutter client implements background handler routines that display local notifications using `flutter_local_notifications` if the app is closed.

### Files Affected
- `sero/lib/services/notification_service.dart`
- `society-backend/routes/visitors.js`

---

## 3. Financial Transaction Ledger & Razorpay Integration

### Current State
Ledger balances are updated via `db.runTransaction()` in `/payments/verify` and `/payments/webhook`.

### What is Good
- Transaction logic isolates and locks data updates, making it highly secure against race conditions.

### What is Missing
- **Razorpay Sandbox Simulation Test Suite:** There are no automated test scripts that mock Razorpay API webhook events to verify ledger math and idempotency.

### What Can Break
- **Corrupt Financial Ledgers:** Updates to Razorpay's API schemas or changes to the webhook verification routines can cause payments to succeed on the gateway but fail to update the resident's ledger, leading to double billing disputes.

### Real-World Risk
- **High:** Financial discrepancies and user trust degradation.

### Priority
- **P0** (Must verify before collecting real money)

### Recommended Fix
- Create a sandbox mock service inside `__tests__/payments.test.js` that sends valid signed webhook HMAC payloads containing mock captured payments, asserting that:
  1. The transaction is recorded in `transactions`.
  2. The balance in `society_funds_summary` updates correctly.
  3. Re-sending the identical event returns a `200 Already processed` response (Idempotency check).

### Files Affected
- `society-backend/routes/funds.js`
- `society-backend/__tests__/payments.test.js` (Create this file)
