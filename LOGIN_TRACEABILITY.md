# SERO — Login Traceability Matrix

> Deliverable #14 as required by `SERO_Separate_Role_Login_Master_Prompt.md` § 23  
> Tracks every login portal through the full stack: route → screen → provider → endpoint → DB checks → shell → tests.

---

## Portal → Role → Screen → Route → Provider → Endpoint → DB Checks → Shell → Test

| Portal | Role(s) | Login Screen | Flutter Route | Provider | Backend Endpoint | DB Check | Destination Shell | Test File |
|--------|---------|--------------|--------------|----------|------------------|----------|-------------------|-----------|
| **Super Admin** | `super_admin`, `platform_owner`, `platform_operations`, `platform_support`, `platform_security` | `RoleLoginFormScreen(portal:'super-admin')` | `/login/super-admin` | `authProvider.loginWithPortal('super-admin')` | `POST /auth/login` | Verify UID in `platform_users` WHERE `role IN (...)` AND `status='active'` | `SuperAdminShell` → `/super-admin` | `auth-portal-mismatch.spec` |
| **Admin** | `main_admin`, `admin`, `secretary`, `treasurer`, `committee_member` | `RoleLoginFormScreen(portal:'admin')` | `/login/admin` | `authProvider.loginWithPortal('admin')` | `POST /auth/login` | Verify UID in `members` JOIN `staff` WHERE society is `active` AND role in admin set | `AdminShell` → `/admin` | `auth-role-routing.spec` |
| **Staff / Security** | `guard`, `security_manager`, `facility_manager`, `supervisor`, `maintenance_staff`, `housekeeping_staff`, `reception_staff`, `parcel_desk_staff` | `RoleLoginFormScreen(portal:'staff')` | `/login/staff` | `authProvider.loginWithPortal('staff')` | `POST /auth/login` | Verify UID in `staff` WHERE `status='active'` AND `current_assignment IS NOT NULL` | `StaffShell` → `/staff` | `auth-staff-termination.spec` |
| **Resident** | `owner`, `tenant`, `family_member` | `RoleLoginFormScreen(portal:'resident')` | `/login/resident` | `authProvider.loginWithPortal('resident')` | `POST /auth/login` | Verify UID in `members` WHERE `status IN ('approved')` AND unit is `active` | `ResidentShell` → `/home` | `auth-resident-moveout.spec` |

---

## Portal Mismatch Enforcement

| Scenario | Backend Behaviour | HTTP Code | Flutter Behaviour |
|----------|------------------|-----------|-------------------|
| Resident UID hits `/login/super-admin` | No `platform_users` record found | `403 PORTAL_MISMATCH` | Show error snackbar, stay on login form |
| Admin UID hits `/login/staff` | No active `staff` record | `403 PORTAL_MISMATCH` | Show error snackbar |
| Staff UID hits `/login/admin` | No `members` admin role | `403 PORTAL_MISMATCH` | Show error snackbar |
| Super Admin UID hits `/login/resident` | No `members` record | `403 PORTAL_MISMATCH` | Show error snackbar |

---

## Multi-Role Workspace Selection Flow

| Trigger | Backend Response | Flutter Action | DB Check |
|---------|-----------------|----------------|----------|
| User has >1 valid destination across portals | `{ requiresWorkspaceSelection: true, destinations: [...] }` | Navigate to `/workspace-select` | Query all of: `platform_users`, `members`, `staff` for UID |
| User selects workspace | `POST /auth/workspace/select { destination_id }` | Navigate to role-specific shell | Verify destination still valid at selection time |
| Workspace switch | `POST /auth/workspace/switch { destination_id }` | Invalidate all Riverpod providers → navigate | Re-verify destination, issue new scoped JWT |

---

## Account State → Screen Mapping

| State | DB Condition | Backend Code | Flutter Screen Route | `AccountStateType` |
|-------|-------------|-------------|---------------------|-------------------|
| Staff inactive | `staff.status = 'inactive'` | `403 STAFF_INACTIVE` | Redirect to `/account-state` | `staffInactive` |
| Staff no assignment | `staff.current_assignment IS NULL` | `403 NO_ASSIGNMENT` | Redirect to `/account-state` | `staffNoAssignment` |
| Society suspended | `societies.status = 'suspended'` | `403 SOCIETY_SUSPENDED` | Redirect to `/account-state` | `societySuspended` |
| Account suspended | `members.status = 'suspended'` | `403 ACCOUNT_SUSPENDED` | Redirect to `/account-state` | `accountSuspended` |
| Resident pending | `members.status = 'pending'` | `403 PENDING_APPROVAL` | `pending_approval_screen.dart` | `pendingApproval` |
| Resident rejected | `members.status = 'rejected'` | `403 REJECTED` | Redirect to `/account-state` | `rejected` |
| Resident moved out | `members.status = 'moved_out'` | `403 MOVED_OUT` | Redirect to `/account-state` | `movedOut` |
| Session expired | JWT expired / revoked | `401 SESSION_EXPIRED` | Redirect to `/login` | `sessionExpired` |
| Rate limited | Redis counter exceeded | `429 RATE_LIMITED` | Redirect to `/account-state` | `rateLimited` |

---

## MFA / OTP Security

| Challenge Type | Trigger | Flutter Screen | Resend Cooldown | Max Attempts |
|---------------|---------|----------------|-----------------|-------------|
| `otp` | Phone/email OTP on login | `AuthChallengeScreen(type: AuthChallengeType.otp)` | 60 seconds | 5 attempts then lockout |
| `mfa` | TOTP authenticator app | `AuthChallengeScreen(type: AuthChallengeType.mfa)` | N/A | 5 attempts then lockout |
| `stepUp` | High-risk action (e.g. workspace switch) | `AuthChallengeScreen(type: AuthChallengeType.stepUp)` | 60 seconds | 3 attempts |

---

## Backend Endpoint Map

| Endpoint | Method | Auth Required | Purpose | Rate Limit |
|----------|--------|--------------|---------|-----------|
| `/auth/login` | POST | Firebase ID token | Portal-specific login and role verification | 5/15min per IP |
| `/auth/workspace/select` | POST | JWT | Select workspace for multi-role accounts | 10/15min |
| `/auth/workspace/switch` | POST | JWT | Switch workspace, invalidate old session | 10/15min |
| `/auth/logout` | POST | JWT | Revoke current session | Standard |
| `/auth/logout/all` | POST | JWT | Revoke all sessions for user | Standard |
| `/ai/society-pulse` | GET | JWT (admin+) | AI Society Pulse metrics | 10/min AI limiter |
| `/ai/complaint-clusters` | GET | JWT (admin+) | Complaint cluster/root-cause AI | 10/min AI limiter |
| `/ai/financial-anomalies` | GET | JWT (treasurer/admin) | Financial anomaly scan | 10/min AI limiter |
| `/ai/maintenance-predictions` | GET | JWT (admin+) | Asset failure risk predictions | 10/min AI limiter |

---

## Flutter Route Guard Matrix

| Route | `AuthGuard` Roles | Unauthenticated | Wrong Role |
|-------|------------------|-----------------|-----------|
| `/login` | — (public) | Show login | — |
| `/login/:portal` | — (public) | Show login | — |
| `/home` | All authenticated | Redirect `/login` | Redirect `/login` |
| `/admin` | admin roles | Redirect `/login` | `403` page |
| `/staff` | staff roles | Redirect `/login` | `403` page |
| `/super-admin` | super_admin roles | Redirect `/login` | `403` page |
| `/workspace-select` | Any authenticated | Redirect `/login` | — |
| `/ai/*` | admin roles | Redirect `/login` | `403` page |

---

## Status

| Item | Status |
|------|--------|
| Login landing (`/login`) | ✅ Done |
| Super Admin portal (`/login/super-admin`) | ✅ Done |
| Admin portal (`/login/admin`) | ✅ Done |
| Staff portal (`/login/staff`) | ✅ Done |
| Resident portal (`/login/resident`) | ✅ Done |
| Backend portal mismatch (`403 PORTAL_MISMATCH`) | ✅ Done |
| Workspace selector screen | ✅ Done |
| Multi-role `getUserDestinations` backend helper | ✅ Done |
| `StaffShell` route (`/staff`) | ✅ Done |
| `AdminShell` route (`/admin`) | ✅ Done |
| Account state screen (14 states) | ✅ Done |
| MFA/OTP challenge screen | ✅ Done |
| AI Society Pulse screen | ✅ Done |
| AI Complaint Intelligence screen | ✅ Done |
| AI Predictive Maintenance screen | ✅ Done |
| AI Financial Anomaly screen | ✅ Done |
| `AIInnovationService` backend | ✅ Done |
| AI backend routes (`/ai/society-pulse` etc.) | ✅ Done |
| AI features in Admin More screen | ✅ Done |
| `LOGIN_TRACEABILITY.md` | ✅ Done |
| Backend test suites | ⚠️ Partial — `auth_portal.integration.test.js` (3/3) |
| Flutter widget tests | ⚠️ Pending |
| Load testing scripts | ⚠️ Pending |
| OpenAPI spec update | ⚠️ Pending |

---

*Generated: 2026-06-16 — SERO v2 Auth & AI Innovation Release*
