# SERO Separate Role Login — Security & Threat Model

This document outlines key security threats to the authentication, portal routing, and session lifecycle system and describes the countermeasures built into the SERO platform.

## 1. Threat Matrix & Mitigation Rules

| Threat / Attack Vector | Severity | Target | Mitigation & Countermeasure |
|---|---|---|---|
| **Portal Bypassing** (e.g., Resident tries to access Super Admin by deep-linking `/super-admin`) | **P0** | Routing / Access Control | Client-side `AuthGuard` evaluates the token's authenticated role. Backend APIs strictly assert claims from the validated JWT (not request body). |
| **Credential Stuffing & Brute Force** (e.g., Automated bots attempting login loops) | **P1** | Login Endpoints | Redis-backed distributed rate limiters apply progressive slowdowns (5s delay after 3 failures, 30s delay after 4, and account lockout for 15 minutes after 5 failed attempts). |
| **Workspace Selection Tampering** (e.g., Resident sends post requests selecting another unit or society) | **P1** | API Endpoint | The backend `/auth/workspace/select` endpoint compares the requested `workspaceId` against the user's verified postgres relations. It rejects foreign mappings with a 403. |
| **MFA Bypass** (e.g., Attacker has password but skips OTP submission) | **P1** | Login Flow | JWT is not issued until MFA challenges are verified. A temporary token is returned that is only valid for `/mfa/verify`. |
| **Session Hijacking via Stale Tokens** (e.g., Device lost, but tokens remain valid) | **P2** | Client Tokens | Supports immediate revocation of all sessions via `/auth/logout-all`, which deletes Firebase refresh records and adds token hashes to the Redis blacklist with instant invalidation. |
| **User Info Enumeration** (e.g., Attacker queries logins to check registered emails/phones) | **P2** | Public Endpoints | Endpoints return generic responses like "Invalid phone number or password" regardless of whether the identifier exists. Constant-time bcrypt compares against `DUMMY_HASH` to prevent timing analysis. |
| **Role Escalation via Mass Assignment** (e.g., User inserts `"role": "super_admin"` in a profile PATCH body) | **P1** | Profiles / User CRUD | Strict Zod validation schemas strip out any unpermitted fields (like `role`, `society_id`, `status`) from the request body. |

## 2. Token Security Policies
1.  **Strict Token Rotation**: Every call to `/auth/refresh` invalidates the old refresh token. If a reused refresh token is presented, the backend assumes a breach, revokes all sessions associated with that user ID, and logs a security alert.
2.  **No Credentials in Logs**: Winston/Pino logger middleware strips out the keys `password`, `token`, `refreshToken`, `otp`, and `mfaSecret` from log payloads.
