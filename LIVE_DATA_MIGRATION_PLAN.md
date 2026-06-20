# LIVE_DATA_MIGRATION_PLAN

Ordered cutover of the 29 admin screens off `data/mock_data.dart`, grouped by domain. For each: add/extend service → add provider → convert screen to Consumer + watch → loading/empty/error/retry states → remove mock import.

| # | Domain | Screens | Service | Provider | Backend |
|---|---|---|---|---|---|
| 1 | Dashboard | dashboard_home, revenue, insights, notices | admin_dashboard_service (+trends), finance | dashboardProvider, financeDashboardProvider, noticesProvider | /admin/dashboard/*, /finance/reports/*, /notices |
| 2 | Notices | notices, create_notice | (noticesProvider existing) | noticesProvider | /notices |
| 3 | Finance | finance_dashboard, ledger, payment_history, income_reports, generate_bills, financial_report, bill_details | admin_finance_service | financeDashboardProvider, financeLedgerProvider, paymentHistoryProvider, invoiceDetailProvider | /finance/* |
| 4 | Society | info, profile, setup_home, logo, wings_blocks, flats_units | admin_society_service | societyProfileProvider, setupProgressProvider, structureSummaryProvider, structureUnitsProvider | /society/*, /structure/* |
| 5 | Staff | staff_dashboard, staff_list | admin_staff_service | staffDashboardProvider, staffListProvider | /staff-v2/* |
| 6 | Amenities | amenities_dashboard | admin_amenities_service (new) | amenitiesDashboardProvider | /amenities |
| 7 | Parking | parking_dashboard, slot_allocation | admin_parking_service | parkingDashboardProvider, parkingSlotsProvider | /parking/* |
| 8 | Assets | assets_dashboard, lift_details | admin_asset_service | assetsDashboardProvider, assetDetailProvider | /assets/* |
| 9 | Complaints | complaints_dashboard, complaint_details | admin_complaint_service | complaintsDashboardProvider, complaintDetailProvider | /complaints/* |
| 10 | Reports | reports_dashboard, financial_report | admin_reports_service (new) | reportsDashboardProvider | /reports/* |

Verify: `flutter analyze` after each batch. Do NOT flip `kUseMockData` (release gate, lead-owned).
