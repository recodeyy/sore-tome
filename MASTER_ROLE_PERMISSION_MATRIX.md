# MASTER_ROLE_PERMISSION_MATRIX

**Date:** 2026-06-16
**Author:** Security Lead

This document maps canonical roles in SERO to their corresponding frontend shells and backend resource actions.

## 1. Role to Shell Mapping

| Canonical Role | Target Shell | Primary Route | Description |
|---|---|---|---|
| `super_admin` | `SuperAdminShell` | `/super-admin` | Platform owner controls plane. |
| `main_admin` / `admin` | `AdminShell` | `/admin` | Society administration and setup. |
| `secretary` | `AdminShell` | `/admin` | Notices, governance, and complaints. |
| `treasurer` | `AdminShell` | `/admin` | Invoices, expenses, and anomaly radar. |
| `committee_member` | `AdminShell` | `/admin` | Read-only governance and operational access. |
| `guard` / `security_manager` | `StaffShell` | `/staff` | Visitors, patrols, and package deliveries. |
| `resident_owner` / `resident_tenant` | `ResidentShell` | `/home` | Dues payments, visitor pre-approvals. |

## 2. Resource Permission Matrix
- **Ledger & Payments:** Write access restricted to `treasurer` and `super_admin`.
- **KYC Verification:** Restrained to `super_admin` only.
- **AI Financial Anomalies:** Restricted to `treasurer` and `super_admin` roles to ensure financial discretion.
