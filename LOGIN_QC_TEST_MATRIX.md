# SERO Separate Role Login — Quality Control Test Matrix

This document outlines the test cases and validation scripts for the separate portal login system.

| Test ID | Category | Description | Input / Setup | Expected Outcome | Status |
|---|---|---|---|---|---|
| **L-01** | Landing | Verify landing page renders four portal choices | Navigate to `/login` | Displays cards for Super Admin, Society Admin, Staff, and Resident in Outfit typography | Pending |
| **L-02** | Landing | Responsive alignment check on various sizes | Resize browser / run on simulator | Cards stack vertically on phone, grid on tablet, no pixel overflows | Pending |
| **P-01** | Portals | Super Admin Login redirects to SuperAdminShell | Log in via `/login/super-admin` | Verified platform user goes to platform dashboard; session has MFA challenge | Pending |
| **P-02** | Portals | Society Admin Login redirects to AdminShell | Log in via `/login/admin` | Verified admin/committee member goes to admin dashboard | Pending |
| **P-03** | Portals | Staff Login redirects to StaffShell | Log in via `/login/staff` | Verified guard/desk staff goes to staff dashboard; restricted access enforced | Pending |
| **P-04** | Portals | Resident Login redirects to ResidentShell | Log in via `/login/resident` | Verified approved resident goes to resident dashboard | Pending |
| **M-01** | Portals | Portal mismatch logs warning & rejects access | Resident logs in at `/login/super-admin` | Returns 403 Forbidden, does not issue token, offers link to Resident login | Pending |
| **W-01** | Workspace | Workspace selector shown for multi-role accounts | User is Resident and Secretary | Displays selector page showing Green Heights (Resident) and Green Heights (Secretary) | Pending |
| **W-02** | Workspace | Workspace switch clears prior state | Active in Secretary, switches to Resident | Prior screen caches and active socket rooms are cleared/invalidated before loading new shell | Pending |
| **S-01** | Security | Brute force progressive delay is applied | Fail login 3 times | 4th attempt incurs a 5-second sleep delay before response | Pending |
| **S-02** | Security | Account lockout occurs | Fail login 5 times | Account is locked for 15 minutes; subsequent logins return immediate generic failure | Pending |
| **S-03** | Security | Session invalidation on termination | Revoke staff on backend | App redirects staff to login on next action or automatic token refresh | Pending |
| **S-04** | Security | Refresh token reuse revokes all sessions | Replay old refresh token | Returns 401, all database-registered refresh sessions for the user are deleted | Pending |
