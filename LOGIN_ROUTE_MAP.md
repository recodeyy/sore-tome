# SERO Separate Role Login — Route Map

This document maps all authentication-related routes across the client applications and the backend API server.

## 1. Client-Side Flutter Routes
All authentication routing is handled by the `MaterialApp` router in `lib/app/app.dart`.

| Route Path | Associated Screen Widget | Role Scope / Guard Rule |
|---|---|---|
| `/login` | `RoleLoginLandingScreen` | Public landing page displaying the 4 portal choices |
| `/login/super-admin` | `SuperAdminLoginScreen` | Public portal with authorized platform security warnings |
| `/login/admin` | `AdminLoginScreen` | Public portal with admin onboarding/activation assistance |
| `/login/staff` | `StaffLoginScreen` | Public portal requiring employee ID or registered credentials |
| `/login/resident` | `ResidentLoginScreen` | Public portal with options for resident registration |
| `/workspace-select` | `WorkspaceSelectorScreen` | Auth required; displayed if a user holds multiple active workspaces |
| `/pending-approval` | `PendingApprovalScreen` | Auth required; gates residents awaiting admin verification |
| `/suspended` | `SuspendedAccountScreen` | Auth required; shown if a user or society has been suspended |
| `/splash` | `SplashScreen` | Initial app loading, performs automatic session token refresh checks |

---

## 2. Backend API Routes (`/api/v1/auth`)
These endpoints are handled by `society-backend/routes/auth.js` (or translated routes).

| HTTP Method & Endpoint | Payload Structure | Auth Level | Description |
|---|---|---|---|
| `POST /auth/login` | `{ email/phone, password, portal }` | Public | Authenticates credentials and validates against the chosen portal scope. Returns a JWT, Refresh Token, and user workspace destinations. |
| `POST /auth/refresh` | `{ refreshToken }` | Public | Rotates the JWT access token and refresh token, checking Redis blacklists. |
| `POST /auth/logout` | `{ refreshToken }` | Public | Revokes the active session and blacklists the refresh token in Redis. |
| `POST /auth/logout-all` | *None* | Authenticated | Revokes all active refresh tokens for the authenticated user ID. |
| `POST /auth/workspace/select` | `{ workspaceId }` | Authenticated | Validates the user's access to the chosen workspace and returns a scoped session context. |
| `POST /auth/password/forgot` | `{ email/phone, portal }` | Public | Generates and sends a single-use password reset link or OTP. |
| `POST /auth/password/reset` | `{ token, newPassword }` | Public | Resets the password and invalidates all current sessions. |
| `POST /auth/mfa/challenge` | *None* | Authenticated | Generates an authenticator secret or SMS challenge. |
| `POST /auth/mfa/verify` | `{ code }` | Authenticated | Verifies the challenge and updates user's MFA settings. |
| `GET /auth/devices` | *None* | Authenticated | Lists all registered devices and sessions for the user. |
| `DELETE /auth/devices/:id`| *None* | Authenticated | Forcefully terminates a specific session/device token. |
