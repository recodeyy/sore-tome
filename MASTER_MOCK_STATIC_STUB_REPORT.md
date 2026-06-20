# MASTER_MOCK_STATIC_STUB_REPORT (Master Prompt Section 6)

Audit date: 2026-06-16. Whole-repo scan of `sero/` for mock/static/stub/placeholder/TODO/localhost.

## HEADLINE
- `kUseMockData = true` globally (`sero/lib/config/dev_config.dart:1`).
- **29 admin screen files** import `sero/lib/data/mock_data.dart` and render static zeroed constants instead of live Riverpod providers/services. THIS IS THE PRIMARY RELEASE BLOCKER per Section 6 ("No production-visible mock or static operational data may remain").
- `mock_data.dart` was already neutralized to empty/zero values (header: *"Placeholder data classes — neutralized for backend integration ... TODO: Replace each field with real API data"*). Effect today: admin UI shows **blank/₹0/empty** data, not fake-but-plausible data — still a disconnected feature.

## 1. Global mock switch — BLOCKER MOCK-01
| File:line | Finding | User-visible effect | Correct live source | Fix status |
|---|---|---|---|---|
| `config/dev_config.dart:1` | `const bool kUseMockData = true;` | Gates Firebase/real APIs off; 25 lib references branch to mock/empty paths | Set `false` + wire env-driven config | OPEN |

## 2. Screens still importing `mock_data.dart` — BLOCKER MOCK-02 (29 files)
Each shows static zeroed constants (`MockDashboardData`, `MockFinanceData`, etc.). Correct replacement = the already-existing Riverpod providers/services (`providers/admin/dashboard_provider.dart`, `services/admin/admin_*_service.dart`, `providers/shared/*`). Pattern reference for a completed cutover: `dashboard_provider.dart:19-24`.

| # | File (under `sero/lib/`) | Replacement source |
|---|---|---|
| 1 | screens/admin/society/flats_units_screen.dart | admin_society_service / structure provider |
| 2 | screens/admin/society/society_setup_home_screen.dart | admin_society_service |
| 3 | screens/admin/society/society_profile_screen.dart | admin_society_service |
| 4 | screens/admin/society/wings_blocks_screen.dart | admin_society_service |
| 5 | screens/admin/society/society_logo_screen.dart | admin_society_service |
| 6 | screens/admin/society/society_information_screen.dart | admin_society_service |
| 7 | screens/admin/finance/income_reports_screen.dart | admin_finance_service (`MockFinanceData` at lines 56,62,129) |
| 8 | screens/admin/finance/finance_dashboard_screen.dart | admin_finance_service |
| 9 | screens/admin/finance/generate_bills_screen.dart | admin_finance_service |
| 10 | screens/admin/finance/bill_details_screen.dart | admin_finance_service |
| 11 | screens/admin/finance/financial_ledger_screen.dart | admin_finance_service |
| 12 | screens/admin/finance/payment_history_screen.dart | admin_finance_service |
| 13 | screens/admin/dashboard/dashboard_revenue_screen.dart | dashboardProvider |
| 14 | screens/admin/dashboard/dashboard_insights_screen.dart | dashboardProvider |
| 15 | screens/admin/dashboard/dashboard_notices_screen.dart | notices provider |
| 16 | screens/admin/dashboard/dashboard_home_screen.dart | dashboardProvider |
| 17 | screens/admin/staff/amenities_dashboard_screen.dart | amenities service/provider |
| 18 | screens/admin/staff/staff_dashboard_screen.dart | admin_staff_service |
| 19 | screens/admin/staff/staff_list_screen.dart | admin_staff_service |
| 20 | screens/admin/parking/slot_allocation_screen.dart | admin_parking_service |
| 21 | screens/admin/parking/parking_dashboard_screen.dart | admin_parking_service |
| 22 | screens/admin/complaints/complaint_details_screen.dart | admin_complaint_service |
| 23 | screens/admin/complaints/complaints_dashboard_screen.dart | admin_complaint_service |
| 24 | screens/admin/assets/assets_dashboard_screen.dart | admin_asset_service |
| 25 | screens/admin/assets/lift_details_screen.dart | admin_asset_service |
| 26 | screens/admin/reports/reports_dashboard_screen.dart | reports_pg endpoints |
| 27 | screens/admin/reports/financial_report_screen.dart | admin_finance_service / reports |
| 28 | screens/admin/notices/create_notice_screen.dart | notices provider |
| 29 | screens/admin/notices/notices_screen.dart | notices provider |

Fix status (all 29): OPEN.

## 3. Other indicators (counts from grep over `sero/lib`)
| Indicator | Count | Severity | Note |
|---|---|---|---|
| `TODO`/`FIXME` | 31 | P3 | Includes `dashboard_provider.dart:33` vitals TODO and mock_data.dart header |
| `Future.delayed` (possible simulated delay) | 8 | P3 | Review each — some are legit debounce/animation |
| `Coming Soon` / `Not Implemented` | 0 | — | None found (good) |
| Demo credentials (`demo@`, `admin@admin`, hardcoded `123` pw) | 0 | — | None found (good) |
| `localhost`/`10.0.2.2` URLs | `config/env.dart:5,10` (dev default), `sse_manager`, `api_client` derive from Environment | P1 | Dev-only base URL must be replaced with prod config before release — MOCK-03 |

## 4. Verdict
Section 6 gate: **FAIL.** Production-visible static operational data remains (29 screens), global mock flag on, dev base URL. No fabricated business data is shown (it is zeroed), but disconnected screens violate the live-data rule.
