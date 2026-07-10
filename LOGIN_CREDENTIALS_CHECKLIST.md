# SERO — Login Credentials Checklist

**Updated:** 2026-06-16
**Backend (local/dev):** `http://192.168.29.180:3001/api/v1` (phone on same Wi‑Fi; firewall port 3001 must be open)
**APK:** `builds/sero-app-release-20260616.apk` (release, points at the LAN backend above)

> Login model: **phone + password + portal**. The app shows four portals
> (Super Admin / Society Admin / Staff / Resident). The backend validates that the
> account is entitled to the chosen portal (portal mismatch → `403`).

---

## A. Confirmed seeded test accounts

These were set by `society-backend/hash_and_set.js` (password hashed with bcrypt).

| # | Role / Portal | Login (phone field) | Password | Status |
|---|---------------|---------------------|----------|--------|
| 1 | **Society Admin** (`/login/admin`) | `admin` | `123456` | ✅ confirmed |
| 2 | **Resident** (`/login/resident`) | `9876543200` | `123456` | ✅ confirmed |

## B. Other roles (Super Admin / Staff / Security) — to fill in

I did **not** bulk-dump the live Firestore user collection (blocked by the safety
guard — it holds real credentials/PII). To list every account + role yourself, run:

```
! cd society-backend && node check_users.js
```

Then log in with the listed **phone** + that account's password (seeded accounts use
`123456`; reset others if unknown). Record them here:

| # | Role / Portal | Login (phone) | Password | Verified login? |
|---|---------------|---------------|----------|-----------------|
| 3 | Super Admin (`/login/super-admin`) | `superadmin` | `123456` | ✅ verified on prod website 2026-07-10 (account `superadmin-001`, role `super_admin`) |
| 4 | Staff (`/login/staff`) | ____ | ____ | ☐ |
| 5 | Security / Guard (`/login/staff`) | ____ | ____ | ☐ |
| 6 | Committee / Treasurer (`/login/admin`) | ____ | ____ | ☐ |

## C. Portal → role mapping (which roles each portal accepts)

From `LOGIN_TRACEABILITY.md`:

| Portal | Accepted roles | Lands on |
|--------|----------------|----------|
| **Super Admin** | `super_admin`, `platform_owner`, `platform_operations`, `platform_support`, `platform_security` | SuperAdminShell → `/super-admin` |
| **Society Admin** | `main_admin`, `admin`, `secretary`, `treasurer`, `committee_member` | AdminShell → `/admin` |
| **Staff / Security** | `guard`, `security_manager`, `facility_manager`, `supervisor`, `maintenance_staff`, `housekeeping_staff`, `reception_staff`, `parcel_desk_staff` | StaffShell → `/staff` |
| **Resident** | `resident` (owner/tenant), approved + active | ResidentShell → `/resident` |

## D. Per-role smoke checklist (tick as you verify on the phone)

For each account: ☐ login succeeds → ☐ correct shell opens → ☐ dashboard loads live
data (not zeros/placeholders) → ☐ a primary action works → ☐ logout clears session.

- ☐ Society Admin (`admin` / `123456`)
- ☐ Resident (`9876543200` / `123456`)
- ☐ Super Admin
- ☐ Staff
- ☐ Security / Guard

## E. Notes

- Wrong portal for a valid account → expect `403` "does not have access to the … portal".
- If login spins/network-errors: open inbound TCP **3001** in Windows Firewall (admin), and confirm phone + PC are on `192.168.29.x`.
</content>
