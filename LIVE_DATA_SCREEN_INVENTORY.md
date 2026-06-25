# LIVE_DATA_SCREEN_INVENTORY

Role/shell: all below are **Society Admin** shell (`AdminDrawer`). Status as of this migration pass.

| Screen | Route (approx) | Data before | Data after | Provider/service |
|---|---|---|---|---|
| dashboard/dashboard_home_screen | /admin/dashboard | MockDashboardData | LIVE | dashboardProvider |
| dashboard/dashboard_revenue_screen | /admin/dashboard/revenue | MockDashboardData | LIVE | financeDashboardProvider |
| dashboard/dashboard_insights_screen | /admin/dashboard/insights | MockDashboardData | LIVE | dashboardProvider + finance/complaints |
| dashboard/dashboard_notices_screen | /admin/dashboard/notices | MockCommunicationData | LIVE | noticesProvider |
| notices/notices_screen | /admin/notices | MockCommunicationData | LIVE | noticesProvider |
| notices/create_notice_screen | /admin/notices/create | MockCommunicationData | LIVE | noticesProvider (static enum categories OK) |
| finance/finance_dashboard_screen | /admin/finance | MockFinanceData | LIVE | financeDashboardProvider |
| finance/financial_ledger_screen | /admin/finance/ledger | MockFinanceData | LIVE | financeLedgerProvider |
| finance/payment_history_screen | /admin/finance/payments | MockFinanceData | LIVE | paymentHistoryProvider |
| finance/income_reports_screen | /admin/finance/income | MockFinanceData | LIVE | financeDashboardProvider |
| finance/generate_bills_screen | /admin/finance/generate | MockFinanceData | LIVE | structureSummaryProvider |
| finance/bill_details_screen | /admin/finance/bill | MockFinanceData | PARTIAL | invoiceDetailProvider (no invoice id route wired) |
| society/society_information_screen | /admin/society/info | MockSocietyData | LIVE | societyProfileProvider |
| society/society_profile_screen | /admin/society/profile | MockSocietyData | LIVE | societyProfileProvider |
| society/society_setup_home_screen | /admin/society/setup | MockSocietyData | LIVE | setupProgressProvider |
| society/society_logo_screen | /admin/society/logo | MockSocietyData | LIVE | societyProfileProvider |
| society/wings_blocks_screen | /admin/society/wings | MockSocietyData | LIVE | structureSummaryProvider |
| society/flats_units_screen | /admin/society/units | MockSocietyData | LIVE | structureUnitsProvider |
| staff/staff_dashboard_screen | /admin/staff | MockStaffData | LIVE | staffDashboardProvider |
| staff/staff_list_screen | /admin/staff/list | MockStaffData | LIVE | staffListProvider |
| staff/amenities_dashboard_screen | /admin/amenities | MockAmenitiesData | LIVE | amenitiesDashboardProvider |
| parking/parking_dashboard_screen | /admin/parking | MockParkingData | LIVE | parkingDashboardProvider |
| parking/slot_allocation_screen | /admin/parking/allocation | MockParkingData | LIVE | parkingSlotsProvider |
| assets/assets_dashboard_screen | /admin/assets | MockAssetsData | LIVE | assetsDashboardProvider |
| assets/lift_details_screen | /admin/assets/lift | MockAssetsData | LIVE | assetDetailProvider |
| complaints/complaints_dashboard_screen | /admin/complaints | MockComplaintsData | LIVE | complaintsDashboardProvider |
| complaints/complaint_details_screen | /admin/complaints/detail | MockComplaintsData | LIVE | complaintDetailProvider |
| reports/reports_dashboard_screen | /admin/reports | MockReportsData | LIVE | reportsDashboardProvider |
| reports/financial_report_screen | /admin/reports/financial | MockReportsData | LIVE | financeDashboardProvider |
