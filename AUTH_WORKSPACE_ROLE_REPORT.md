# Auth, Workspace & Role Report — 2026-07-10 (live production)

## Verified live
| Account | Portal | Result |
|---|---|---|
| `9876543200` (resident_owner) | app/none | 200; activeWorkspace `resident-demo-soc-1` (approved); token+refresh+firebaseToken; `requiresWorkspaceSelection:false` |
| `admin` (main_admin) | admin | 200; workspace `admin-demo-soc-1` |
| `admin` | super-admin | 403 PORTAL_MISMATCH, `allowedPortals:["admin"]` — correct wrong-role denial |
| `superadmin` (superadmin-001, super_admin) | super-admin | 200; website session cookies set; `/super-admin/dashboard` 200 |
| bad password | — | 401 masked error; failed-attempt counter + 15-min lockout + progressive delay implemented |

## Mechanics reviewed in code
- Destinations = Postgres members ∪ Postgres staff ∪ Firestore-derived fallback (only when NO pg membership — FIND-001 anti-phantom-workspace rule).
- Super-admin destination `platform-super-admin` type `super-admin` — matches website portal string.
- JWT scoped to resolved workspace (role + society_id); `finalSocietyId` normalized to null for platform accounts (Firebase claims reject undefined).
- Refresh tokens hashed in Firestore with expiry+revocation; mobile refresh is single-flight; logout clears secure storage.
- `requireSociety` guard returns machine-readable 409 NO_ACTIVE_WORKSPACE instead of silent empty data.
- Workspace switch: `/auth/workspace/select` issues new scoped JWT + firebaseToken.

## Untested (no credentials / needs device)
- Staff/Guard, Treasurer/Secretary, tenant/family-member, multi-society, pending/rejected/suspended accounts — seed them (or record creds in LOGIN_CREDENTIALS_CHECKLIST.md) and run the same matrix. Portal mapping logic for staff verified in code only.

## Notes
- Superadmin credentials now recorded in LOGIN_CREDENTIALS_CHECKLIST.md (`superadmin`/`123456`, account superadmin-001).
- Second super_admin account (`uF8Tyx2aVZqHzIsm8NDM`) exists with a password set — identify/disable if unintended (P2).
