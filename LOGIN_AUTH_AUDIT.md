# SERO Separate Role Login — Authentication Audit

This document reviews the current state of authentication and role-routing in the SERO platform, highlighting existing architecture and vulnerabilities that must be addressed.

## 1. Current Authentication Flow
*   **Identity Provider**: Firebase Authentication is used to handle credential validation and token signing.
*   **Database Source of Truth**: Firestore is currently used as the database in `routes/auth.js`, storing:
    *   `users`: Documents mapped by `uid` containing fields like `phone`, `password` (hashed), `role`, `status`, `society_id`, and security columns (`failedLoginAttempts`, `lockUntil`).
    *   `refresh_tokens`: Documents mapped by hashed tokens containing `userId`, `expiresAt`, `revoked`, and `society_id`.
*   **JSON Web Tokens**: The backend issues custom JWT access tokens containing `uid`, `phone`, `role`, `name`, and `society_id` with a 1-hour expiry, along with a random hex string for `refreshToken`.
*   **Client Session**: `AuthNotifier` in Riverpod watches the session. It stores tokens using `AuthService.saveTokens` and queries `/users/me` on startup.

## 2. Identified Vulnerabilities & Gaps
1.  **Single Entry-point and Fake Client Choice**: The client `login_screen.dart` offers a sliding toggle for "Resident" and "Admin". However:
    *   This is purely cosmetic. A user can type Resident credentials in the Admin form, and the backend `/auth/login` endpoint does not validate which portal the user intended to use.
    *   Selecting the "Admin" or "Resident" toggle only changes client-side validation logic (e.g., expecting phone vs username).
2.  **No Separated Portal Routes**: The client has a single `/login` route. There are no routes like `/login/super-admin`, `/login/admin`, `/login/staff`, or `/login/resident`, making deep-linking to role-specific portals impossible.
3.  **Missing Multi-Role Workspaces**: If a user holds multiple roles (e.g., a Resident who is also the Secretary of the Society), the backend login payload simply returns the static `role` from the `users` document. The system does not allow a user to choose their active workspace or role context at login.
4.  **Implicit Staff Integration**: Staff members are currently processed via Firestore or legacy endpoints without explicit capability gates. There is no `StaffShell` routing guard.
5.  **Direct Role Mapping**: The system assumes the client-side role is canonical and routes to shells (`MainShell` vs `SuperAdminShell`) based on client-trusted claims or a simple `user.role` field, which is prone to local session manipulation.
6.  **Hardcoded Custom Tokens**: On success, the backend generates a custom Firebase Token using Firebase Admin SDK containing custom claims (`role`, `society_id`). If these claims are modified in Firestore, the client session is not automatically invalidated or re-audited.

## 3. Core Remediation Strategy
1.  **Introduce Separate Routes**: Implement `/login/super-admin`, `/login/admin`, `/login/staff`, and `/login/resident` in the Flutter Router.
2.  **Implement Portal-Mismatch Guards**: Secure the backend `/auth/login` so that if a user logs in via a specific portal, the backend asserts that the user is entitled to at least one role/workspace matching that portal context.
3.  **Create Workspace Selector**: When a user logs in and possesses multiple memberships or roles, present the `WorkspaceSelector` screen to bind their active token to a specific `society_id` and `role` context.
4.  **Harden Session Invalidations**: Wire active invalidation on staff dismissal, user suspension, or resident move-out.
