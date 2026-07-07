# EXEC_MASTER_CONFLICT_AND_PRECEDENCE_LOG

Date 2026-06-16. Applies precedence rules from Master Prompt §4.

## Precedence order (authoritative)
1. Security & tenant-isolation requirements
2. Financial & data-integrity requirements
3. Latest role-specific implementation prompt
4. Whole-platform QC prompt
5. Core backend prompt
6. Product feature source files
7. Combined packs
8. Legacy code

## Conflicts detected this pass

| # | Conflict | Sources | Resolution (per §4) | Affected IDs |
|---|----------|---------|---------------------|--------------|
| C-01 | Canonical source = individual FE/BE/QC prompts, but only combined packs exist | Master §1 vs repo | Use packs as canonical substitute (rule 7 above legacy); record fidelity risk EXEC-BLK-01. Packs embed the individual masters as sub-headings. | all |
| C-02 | Dual data stack: legacy Firestore JS routes (`society-backend/routes/*.js`) coexist with PostgreSQL `_pg` TS routes | Master §4 "PostgreSQL is source of truth" + "Live API > mock" vs legacy code | PostgreSQL/`_pg` routes WIN (rules 1,2,5 > 8). Legacy Firestore routes are obsolete-pending-removal; any privileged Firestore writes are forbidden (§6). | CORE-BE-02 |
| C-03 | Frontend renders static `MockDashboardData`/`MockFinanceData` while backend has live endpoints; `kUseMockData=true` | Master §4 "Live API data takes precedence over static/mock" vs `sero/lib/config/dev_config.dart:1` + 29 screens | Live API WINS. `kUseMockData` must become false and mock screens cut over. Owned by live-data agent — do NOT edit in this pass. | QC-02, all FE BL rows |
| C-04 | "super_admin" canonical role vs any legacy admin/superadmin variants | Master §4 canonical rules | `super_admin` is canonical; platform roles route to SuperAdminShell. Society Admin/committee -> AdminShell; Staff/Guard -> StaffShell; Resident -> ResidentShell. | LOGIN-09, SUPER-* |
| C-05 | Login portal selection could imply role grant | Master §4 "Selecting a login portal never grants a role"; backend permissions authoritative | Backend permissions authoritative; portal is presentation only. Needs negative test (portal-mismatch). | LOGIN-05 |
| C-06 | AI could bypass permissions/RLS/state machines | Master §4 + AI pack | AI uses canonical domain services only; cannot bypass permissions, RLS, state machines, approval workflows. Security rule (rank 1). | AI-BE-02/03, AI-INNOV-04 |
| C-07 | Capability counts differ by source (31/32/57) unverifiable vs missing product PDF/TXT | Master §1 vs missing sources | Use pack-stated counts (Super 31 / Staff 32 / Resident 57); flag unverifiable EXEC-BLK-02. | SUPER-*, STAFF-*, RES-* |
| C-08 | Shared cross-role modules risk duplicate records / divergent state machines | Master §4 "one canonical record + one state machine" | Single canonical record + single state machine per shared module (visitor, complaint, parcel, payment, event, etc.). | CROSS-01-14, QC-03 |

No unresolved precedence conflicts block ledger construction. C-02/C-03 are tracked as code-level work for later phases (C-03 owned by live-data agent).
