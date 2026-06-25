# SERO Separate Role Login Portals — Complete Frontend, Backend, Security, and QC Master Prompt

## Role

Act as a **Principal Flutter Architect, Identity and Access Management Architect, Backend Security Engineer, Product Designer, Accessibility Specialist, and QA Lead**.

You are working inside the existing **SERO — AI Powered Society Management Platform** repository.

Your task is to redesign and productionize the application login experience so that all major user types have **clearly separate login portals**, while still using one secure identity and authorization platform.

Create separate login experiences for:

1. **Super Admin**
2. **Society Admin and Committee**
3. **Staff and Security**
4. **Member / Resident**

The user selecting a portal must never determine their actual permissions. The backend must verify the authenticated user’s real memberships, roles, permissions, society status, employment status, and account status before allowing access.

Do not create four disconnected authentication systems. Build:

- One secure authentication foundation
- Separate role-focused login pages and URLs
- Backend-verified role routing
- Correct shell redirection
- Multi-role account handling
- MFA and step-up support
- Session/device management
- Full security and QC coverage

The design must match the existing SERO emerald/navy visual language.

---

# 1. Repository-first audit

Before implementation, inspect:

- Current login and registration screens
- Firebase Authentication integration
- Backend authentication routes
- Refresh/session logic
- Role claims
- Society memberships
- Staff employment records
- Super Admin platform roles
- Resident invitation and approval flows
- Main shell routing
- Admin shell
- Super Admin shell
- Staff shell
- Resident shell
- Auth guards
- Deep links
- Password reset
- OTP/MFA
- Secure token storage
- Existing Firestore auth/profile usage
- Mock login logic
- Hard-coded demo credentials
- Existing role names such as:
  - `superadmin`
  - `super_admin`
  - `admin`
  - `main_admin`
  - `staff`
  - `guard`
  - `resident`

Produce first:

1. `LOGIN_AUTH_AUDIT.md`
2. `LOGIN_ROLE_MATRIX.md`
3. `LOGIN_ROUTE_MAP.md`
4. `LOGIN_FRONTEND_BACKEND_CONTRACT.md`
5. `LOGIN_SECURITY_THREAT_MODEL.md`
6. `LOGIN_QC_TEST_MATRIX.md`

Do not begin bulk UI coding until the current authentication and role-routing behavior is fully mapped.

---

# 2. Required login architecture

Create one public authentication entry point:

- `/login`

The main login landing page must display four distinct role cards:

- Super Admin
- Society Admin
- Staff & Security
- Member / Resident

Each card opens a dedicated portal:

- `/login/super-admin`
- `/login/admin`
- `/login/staff`
- `/login/resident`

Also support direct deep links to each portal.

The selected portal provides context and user-facing messaging only. It must not grant or assign a role.

After successful authentication, the backend returns verified memberships, platform roles, society roles, permissions, and allowed destinations.

---

# 3. Login landing page design

Create a premium, polished SERO login landing page.

## 3.1 Visual design

Use:

- Deep Emerald `#064E3B`
- Near-black Navy `#111827`
- Deep Navy `#1E3A8A`
- Emerald Accent `#10B981`
- Sky Accent `#0EA5E9`
- Slate Background `#F8FAFC`
- Slate Border `#E2E8F0`
- Outfit typography
- Existing emerald-to-navy gradients
- 24 px card radius
- 20 px button/input radius
- Soft shadows
- Consistent SERO iconography

## 3.2 Header

Show:

- SERO logo
- `SERO`
- `AI-Powered Society Management`
- Short message:
  - `Choose how you use SERO`

## 3.3 Role cards

### Super Admin

Icon:

- Shield, platform, or control-center icon

Title:

- `Super Admin`

Subtitle:

- `Manage societies, subscriptions, support, platform security and system operations.`

Button:

- `Continue as Super Admin`

Visual treatment:

- Deep emerald/navy premium card
- Platform-level badge
- Do not show public registration

### Society Admin

Icon:

- Apartment, dashboard, or governance icon

Title:

- `Society Admin`

Subtitle:

- `Manage members, billing, complaints, staff, amenities, notices and society operations.`

Button:

- `Continue as Society Admin`

Support:

- Main Admin
- Admin
- Secretary
- Treasurer
- Committee roles

### Staff & Security

Icon:

- ID badge, security shield, or staff icon

Title:

- `Staff & Security`

Subtitle:

- `Manage visitors, parcels, tasks, incidents, patrols, attendance and shifts.`

Button:

- `Continue as Staff`

Support:

- Guard
- Security Manager
- Facility Manager
- Maintenance Staff
- Reception Staff
- Parcel Desk Staff
- Supervisor

### Member / Resident

Icon:

- Home or resident icon

Title:

- `Member / Resident`

Subtitle:

- `Pay bills, approve visitors, raise complaints, book amenities and stay connected with your society.`

Button:

- `Continue as Resident`

Support:

- Owner
- Tenant
- Family Member
- Co-owner
- Authorized Household Member

## 3.4 Secondary actions

- `Need help signing in?`
- `Find your society`
- `Contact support`
- Privacy Policy
- Terms
- App version
- Environment indicator only in non-production builds

---

# 4. Dedicated role login screens

Each login screen must preserve the same underlying components but provide role-specific copy, help, and allowed registration paths.

## 4.1 Shared fields

- Email or mobile number
- Password
- Show/hide password
- Remember this device, if policy allows
- Sign in
- Forgot password
- OTP sign-in, if enabled
- Google/SSO only if approved
- MFA challenge
- Error message
- Support link

## 4.2 Super Admin login

Route:

- `/login/super-admin`

Requirements:

- No self-registration
- MFA required
- Shorter session lifetime
- Device/session checks
- Step-up support
- Optional IP/device anomaly checks
- Platform support contact
- Security warning:
  - `Authorized platform personnel only`

After login:

- Must have valid platform role and permission
- Route to `SuperAdminShell`
- Otherwise deny access and audit the attempt

## 4.3 Society Admin login

Route:

- `/login/admin`

Requirements:

- No open public Admin registration
- Allow invitation acceptance
- Allow first-time password setup
- Society lookup only where safe
- Support pending society onboarding
- MFA according to society/platform policy

After login:

- User must have active Admin/committee membership
- Society must be active or in an allowed onboarding state
- Route to `AdminShell`
- If multiple Admin memberships exist, show society selection

## 4.4 Staff and Security login

Route:

- `/login/staff`

Requirements:

- Employee ID, email, or phone according to backend configuration
- Password/OTP
- Invitation/activation flow
- Current employment validation
- Device registration if configured
- Staff post/zone/shift context
- No public self-registration

After login:

- Verify active staff employment and role
- Route to `StaffShell`
- Guard receives restricted Staff experience
- If no active assignment, show a clear restricted state rather than Admin access

## 4.5 Member / Resident login

Route:

- `/login/resident`

Requirements:

- Email/mobile and password/OTP
- Invitation acceptance
- Resident registration where society permits
- Pending approval state
- Owner/tenant/family onboarding
- Society and unit association
- Phone/email verification

After login:

- Verify active/pending/rejected/suspended membership
- Active resident routes to `ResidentShell`
- Pending resident routes to approval-status screen
- Rejected/suspended resident sees the appropriate state and support path
- If multiple society/unit memberships exist, show context selection

---

# 5. Multi-role account behavior

A user may legitimately hold more than one role.

Examples:

- Resident and committee member
- Resident and Staff
- Admin across two societies
- Platform support and Society Admin
- Owner of multiple units

After authentication, backend returns all allowed destinations.

If only one valid destination exists:

- Route directly to the correct shell

If multiple valid destinations exist:

Show a secure **Choose Workspace** screen with cards such as:

- SERO Platform — Super Admin
- Green Heights — Society Admin
- Green Heights — Resident, A-1204
- Lake View — Society Admin
- Green Heights — Staff, Gate 1

Each workspace card must show:

- Society/platform name
- Role
- Unit/post/department
- Status
- Last used
- Correct icon

Selecting a workspace creates or refreshes a scoped session context.

Do not allow the frontend to invent a workspace.

---

# 6. Canonical role normalization

Use canonical role values:

- `super_admin`
- `platform_owner`
- `platform_operations`
- `platform_finance`
- `platform_support`
- `platform_security`
- `platform_auditor`
- `main_admin`
- `admin`
- `secretary`
- `treasurer`
- `committee_member`
- `auditor`
- `security_manager`
- `facility_manager`
- `supervisor`
- `guard`
- `maintenance_staff`
- `housekeeping_staff`
- `reception_staff`
- `parcel_desk_staff`
- `staff`
- `resident_owner`
- `resident_tenant`
- `family_member`
- `co_owner`
- `authorized_household_member`

Normalize legacy names such as `superadmin` during migration.

Do not silently map every non-resident to Admin.

---

# 7. Backend authentication architecture

Use Firebase Auth or the approved identity provider for identity verification.

Use PostgreSQL for:

- User profile
- Platform roles
- Society memberships
- Unit relationships
- Staff employment
- Roles
- Permissions
- Session metadata
- MFA status
- Device registrations
- Invitations
- Account status
- Society status

Backend login/session response must include only verified context.

Example:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "name": "Example User",
      "email": "user@example.com"
    },
    "destinations": [
      {
        "workspaceId": "signed-or-server-id",
        "type": "resident",
        "societyId": "uuid",
        "societyName": "Green Heights",
        "role": "resident_owner",
        "unit": "A-1204",
        "permissions": ["bill.read_own", "visitor.approve"]
      }
    ],
    "requiresWorkspaceSelection": false,
    "session": {
      "expiresAt": "ISO timestamp"
    }
  }
}
```

Do not accept role or society from the login request as authorization.

---

# 8. Required authentication APIs

Use `/api/v1/auth`.

- `POST /login`
- `POST /login/otp/request`
- `POST /login/otp/verify`
- `POST /refresh`
- `POST /logout`
- `POST /logout-all`
- `GET /session`
- `GET /destinations`
- `POST /workspace/select`
- `POST /workspace/switch`
- `POST /password/forgot`
- `POST /password/reset`
- `POST /invitation/validate`
- `POST /invitation/accept`
- `POST /mfa/challenge`
- `POST /mfa/verify`
- `POST /step-up/challenge`
- `POST /step-up/verify`
- `GET /devices`
- `DELETE /devices/:deviceId`
- `GET /login-help/config`

Optional registration:

- `POST /resident/register`
- Only when the society permits public resident applications

Do not expose open registration for Super Admin, Admin, or Staff.

---

# 9. Portal mismatch behavior

A valid user may use the wrong login portal.

Example:

- Resident enters credentials on Admin login

Behavior:

1. Authenticate identity safely.
2. Do not reveal unnecessary role information before authentication.
3. After authentication, detect that the selected portal is not allowed.
4. Show:
   - `This account does not have access to the Society Admin portal.`
5. Offer verified allowed destinations:
   - `Continue to Member / Resident`
6. Audit repeated suspicious portal mismatch attempts.
7. Do not grant temporary access based on selected portal.

For a multi-role user, route only to allowed workspaces.

---

# 10. Login state screens

Create polished screens for:

- Loading/authentication in progress
- MFA required
- Step-up required
- Invitation expired
- Invitation already used
- Pending resident approval
- Society onboarding pending
- Society suspended
- Staff account inactive
- Staff assignment missing
- Account suspended
- Password expired
- Session expired
- No permitted workspace
- Service temporarily unavailable
- Offline
- Too many attempts/rate limited
- Support/contact assistance

Each state must have:

- Clear explanation
- Correct action
- Retry/help
- No internal stack trace
- Request/reference ID where useful

---

# 11. Password, OTP, MFA, and recovery

## Password

- Secure password policy
- Breached-password checks where supported
- No password in logs
- Show/hide control
- Proper autofill hints
- Password manager compatibility
- Rate limiting
- Generic error to prevent enumeration

## OTP

- Server-generated
- Hashed
- Short expiry
- Attempt limit
- Resend cooldown
- Rate limiting by user/phone/IP/device
- Replay prevention
- No OTP logs
- No client-only validation

## MFA

Mandatory for:

- Super Admin
- Platform privileged roles
- High-risk Society Admin roles when policy requires

Support:

- Authenticator app
- SMS only if approved as fallback
- Recovery codes
- Device trust according to policy

## Recovery

- Generic response
- Time-limited token
- Single use
- Device/session revocation after sensitive reset where configured
- Audit event

---

# 12. Session and workspace security

Support:

- Access token
- Refresh token rotation
- Token revocation
- Device/session inventory
- Logout one device
- Logout all devices
- Session expiry
- Idle timeout
- Role change invalidation
- Society suspension invalidation
- Staff termination invalidation
- Resident move-out invalidation
- Workspace switch
- Secure token storage

On workspace switch:

- Clear previous providers
- Clear cached pages
- Close realtime subscriptions
- Clear local files where required
- Fetch new permissions
- Reconnect to authorized rooms
- Prevent back navigation from revealing previous workspace data

---

# 13. Frontend implementation requirements

Create shared components:

- `RoleLoginLanding`
- `RolePortalCard`
- `RoleLoginForm`
- `WorkspaceSelector`
- `MfaChallengeView`
- `OtpChallengeView`
- `InvitationAcceptanceView`
- `AccountStateView`
- `AuthErrorView`
- `SecurePasswordField`
- `LoginSupportSheet`

Use Riverpod providers/notifiers for:

- Auth state
- Login portal
- Login form
- OTP
- MFA
- Invitation
- Destinations
- Workspace selection
- Session
- Device list
- Password recovery
- Offline/connectivity

No authentication business logic directly inside widgets.

---

# 14. Correct shell routing

After verified workspace selection:

- Platform roles → `SuperAdminShell`
- Society Admin/committee roles → `AdminShell`
- Staff/Guard roles → `StaffShell`
- Resident roles → `ResidentShell`

Do not route:

- Guard into full Admin
- Staff into full Admin
- Super Admin into Society Admin by default
- Pending resident into active Resident dashboard
- Suspended society user into live operational pages

Add route guards at:

- Application shell
- Route level
- API level

---

# 15. Login page live-data requirements

The login system may display dynamic configuration such as:

- App version
- Maintenance notice
- Support contact
- Enabled login methods
- Resident registration availability
- SSO availability
- Society-specific invitation branding

All dynamic content must come from backend configuration.

Do not hard-code:

- Demo credentials
- Fake societies
- Sample users
- Static maintenance warnings
- Placeholder support numbers
- Fake OTP

---

# 16. Accessibility and responsive behavior

Support:

- 320×568
- 360×800
- 390×844
- 412×915
- Tablet portrait/landscape
- Desktop/web

Mobile:

- Role cards in vertical layout
- Clear back navigation
- Keyboard-safe forms
- No overflow when keyboard opens

Tablet/web:

- Two-by-two role card grid
- Centered login panel
- Optional illustration panel
- Proper focus order

Accessibility:

- WCAG 2.1 AA where applicable
- Screen-reader labels
- Visible focus
- Keyboard navigation
- Autofill semantics
- Password visibility semantics
- Error association
- High contrast
- Text scaling
- Large touch targets
- Reduced motion
- No color-only portal distinction

---

# 17. Security requirements

Test and implement:

- Credential stuffing protection
- Brute force protection
- Account enumeration prevention
- OTP abuse prevention
- MFA bypass prevention
- Session fixation prevention
- Refresh token replay prevention
- CSRF where cookie auth is used
- CORS allowlist
- Secure headers
- Rate limiting through Redis
- Device/session revocation
- Token leakage prevention
- Log redaction
- Secret management
- Invitation token security
- Portal mismatch abuse
- Role escalation
- Workspace tampering
- Deep-link bypass
- Open redirect prevention
- Password reset poisoning prevention
- SSO callback validation if used
- Firebase token verification
- Disabled/deleted user behavior
- Society suspension
- Staff termination
- Resident move-out

---

# 18. Required QC tests

## Landing page

- All four cards visible
- Correct design
- Correct route
- Back navigation
- Deep link
- Responsive
- Accessibility
- No static demo data

## Super Admin

- Valid platform user
- MFA
- Non-platform user denied
- Suspended platform user
- Role revoked
- Correct shell
- Session timeout

## Admin

- Main Admin
- Secretary
- Treasurer
- Committee member
- Resident-only account mismatch
- Pending society
- Suspended society
- Multiple societies
- Invitation acceptance

## Staff

- Guard
- Maintenance
- Security manager
- Inactive staff
- No current assignment
- Wrong society
- Device revocation
- Correct restricted shell

## Resident

- Owner
- Tenant
- Family member
- Pending approval
- Rejected
- Suspended
- Moved out
- Multiple units
- Registration/invitation
- Correct shell

## Multi-role

- Resident + Admin
- Resident + Staff
- Admin in two societies
- Platform + Admin
- Workspace selection
- Workspace switch
- Cache clearing
- Back navigation
- Realtime reconnect

## Password/OTP/MFA

- Correct
- Incorrect
- Expired
- Replay
- Attempt limit
- Resend cooldown
- Rate limit
- Recovery
- Session revocation

## UI failure states

- Slow backend
- Offline
- 401
- 403
- 429
- 500
- Timeout
- Malformed response
- App background/resume
- Double submit
- Keyboard
- Loader timeout
- Retry

---

# 19. Backend tests

Create:

- `auth-login.spec`
- `auth-portal-mismatch.spec`
- `auth-role-routing.spec`
- `auth-workspace-selection.spec`
- `auth-workspace-tampering.spec`
- `auth-multi-role.spec`
- `auth-session-rotation.spec`
- `auth-session-revocation.spec`
- `auth-password-recovery.spec`
- `auth-otp-security.spec`
- `auth-mfa.spec`
- `auth-invitation.spec`
- `auth-society-suspension.spec`
- `auth-staff-termination.spec`
- `auth-resident-moveout.spec`
- `auth-rate-limit.spec`
- `auth-deep-link.spec`
- `auth-cross-tenant.spec`

Use real PostgreSQL and Redis integration tests.

---

# 20. Flutter tests

Create:

- Landing-page widget test
- Four portal card tests
- Golden tests for mobile/tablet/desktop
- Login form tests
- Password visibility
- Validation
- OTP screen
- MFA screen
- Workspace selector
- Pending/rejected/suspended states
- Route guard tests
- Shell routing tests
- Multi-role workspace switch
- Cache/state clearing
- Offline/error/retry
- Accessibility
- Text scaling
- Keyboard overflow
- Deep links

Golden screens:

- Login landing
- Super Admin login
- Admin login
- Staff login
- Resident login
- MFA
- Workspace selector
- Pending approval
- Suspended account
- Offline/error

---

# 21. Performance targets

Test:

- 3,000 concurrent authenticated users
- 5,000 concurrent authenticated users
- Morning login spike
- 500 login attempts/second burst in a controlled test environment
- OTP request spike
- Refresh-token spike
- Workspace selection spike
- Realtime reconnection after login
- Redis restart
- Firebase identity-provider slowdown
- Database slowdown

Targets excluding identity-provider delay:

- Login backend processing p95 under 1 second
- Session validation p95 under 200 ms
- Workspace selection p95 under 300 ms
- Refresh p95 under 300 ms
- Error rate under 1%
- No session duplication
- No role leakage
- No DB pool exhaustion
- Rate limiting remains distributed
- Legitimate users behind shared NAT are not incorrectly blocked

---

# 22. Observability and audit

Audit:

- Successful login
- Failed login category without sensitive detail
- MFA success/failure
- OTP abuse
- Password reset
- Invitation acceptance
- Workspace selection/switch
- Portal mismatch
- Session revocation
- Logout all
- Role denial
- Society suspension denial
- Staff termination denial
- Resident move-out denial
- Suspicious device/IP

Include:

- User ID when known
- Request ID
- Portal
- Result
- Device/session
- IP
- Timestamp
- Reason code

Do not log:

- Password
- OTP
- Token
- Recovery code
- Full invitation secret

---

# 23. Deliverables

1. Authentication audit
2. Separate login landing page
3. Four dedicated login portals
4. Workspace selector
5. Correct role-shell routing
6. Backend APIs
7. Role normalization
8. Session/device management
9. MFA/OTP/recovery
10. Tests
11. Load scripts
12. OpenAPI updates
13. Security documentation
14. `LOGIN_TRACEABILITY.md` mapping:
    - Login portal
    - Role
    - Screen
    - Route
    - Provider
    - Endpoint
    - Database checks
    - Destination shell
    - Test
    - Status

---

# 24. Implementation phases

## Phase 0 — Audit

- Inspect current auth
- Map roles
- Map shells
- Identify security and routing defects

## Phase 1 — Auth foundation

- Canonical roles
- Session/destination API
- Workspace model
- Route guards
- Audit

## Phase 2 — Landing and role portals

- Login landing
- Super Admin
- Admin
- Staff
- Resident

## Phase 3 — Multi-role and onboarding states

- Workspace selection
- Invitations
- Pending/rejected/suspended
- Multiple society/unit contexts

## Phase 4 — Security

- MFA
- OTP
- Password recovery
- Device/session management
- Rate limiting
- Revocation

## Phase 5 — QC and scale

- Widget/golden/integration tests
- Security tests
- Load
- Failure injection
- Traceability

At each phase report:

- Files changed
- Routes/screens
- APIs
- Tests/results
- Security findings
- Remaining blockers

---

# 25. Definition of done

Complete only when:

- The login landing clearly shows four separate portals
- Each portal has its own route and role-specific copy
- All portals use one secure authentication backend
- Selecting a portal never grants a role
- Backend verifies actual destinations
- Super Admin routes to SuperAdminShell
- Admin routes to AdminShell
- Staff/Guard routes to StaffShell
- Resident routes to ResidentShell
- Multi-role users get a verified workspace selector
- Pending/rejected/suspended states route correctly
- Staff termination and resident move-out revoke access
- Workspace switching clears previous data and subscriptions
- MFA/OTP/recovery are secure
- No demo credentials/static users exist
- No wrong-role page flashes
- No stuck loader
- Mobile/tablet/desktop layouts work
- Accessibility passes
- Flutter/backend tests pass
- 3,000–5,000-user login load passes
- Zero unresolved P0/P1 authentication defects remain

Begin with the authentication audit and role matrix. Do not begin only by adding four visual buttons without fixing backend role verification and shell routing.
