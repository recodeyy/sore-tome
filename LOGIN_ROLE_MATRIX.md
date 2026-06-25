# SERO Separate Role Login — Role Mapping Matrix

This document maps all canonical roles to their corresponding login portals, target navigation shells, and access privileges.

| Canonical Role | Login Portal | Target Shell | Workspace Scope | Key Permissions & Capabilities |
|---|---|---|---|---|
| `super_admin` | `/login/super-admin` | `SuperAdminShell` | Platform Control Plane | Global society onboarding, platform settings, support impersonation, platform audit logs |
| `platform_owner` | `/login/super-admin` | `SuperAdminShell` | Platform Control Plane | Platform configuration, financial controls, database administration |
| `platform_support` | `/login/super-admin` | `SuperAdminShell` | Platform Control Plane | Support tickets, safe read-only impersonation |
| `main_admin` | `/login/admin` | `AdminShell` | Society-level | Manage members, edit settings, approve residents, allocate parking, configure billing |
| `admin` | `/login/admin` | `AdminShell` | Society-level | View members, manage bookings, notice approvals |
| `secretary` | `/login/admin` | `AdminShell` | Society-level | Post official notices, draft bylaws, issue NOC approvals |
| `treasurer` | `/login/admin` | `AdminShell` | Society-level | Issue invoices, reconcile payments, review billing disputes |
| `committee_member` | `/login/admin` | `AdminShell` | Society-level | Vote on rules, review resident complaints |
| `security_manager` | `/login/staff` | `StaffShell` | Society / Gate | Guard shift assignment, visitor overstay logs, gate configuration |
| `guard` | `/login/staff` | `StaffShell` | Gate / Checkpoint | Register walk-ins, scan visitor QR, log parcel handovers, trigger emergency SOS |
| `parcel_desk_staff` | `/login/staff` | `StaffShell` | Society Desk | Log incoming parcels, verify resident OTP on pickup |
| `resident_owner` | `/login/resident` | `ResidentShell` | Flat / Unit | Pay bills, pre-approve visitors, raise complaints, book amenities, vote in polls, invite family members |
| `resident_tenant` | `/login/resident` | `ResidentShell` | Flat / Unit | Pay bills (if responsible), pre-approve visitors, book amenities, raise complaints |
| `family_member` | `/login/resident` | `ResidentShell` | Flat / Unit | Pre-approve visitors, book amenities, raise complaints, trigger SOS |
| `co_owner` | `/login/resident` | `ResidentShell` | Flat / Unit | Co-sign rules, view household documents |
| `authorized_household_member` | `/login/resident` | `ResidentShell` | Flat / Unit | Pre-approve visitors, raise complaints, view notices |

## Portal Validation Rules
1.  **Strict Portal Enforcement**: When logging in, the portal context is passed. The backend verifies the user's role. If a resident logs in via `/login/super-admin`, the request is denied with a `403 Portal Mismatch` error, and the client is prompted to redirect to `/login/resident`.
2.  **Multi-Role Handling**: If a user is both `resident_owner` and `secretary` in a society, they can log in via `/login/resident` OR `/login/admin`. They will be presented with a **Workspace Selection** screen listing both roles and units, loading the correct shell on choice.
