# LIVE_DATA_REPOSITORY_AUDIT

Frontend repository/service layer audit (`sero/lib/services/admin/`). Before this pass the admin services were TODO stubs returning `[]`/`{}`. They were wired to the live PG endpoints (raw-JSON, unwrapped via `ApiService.unwrap`).

| Service | Before | After |
|---|---|---|
| admin_dashboard_service | live (existing) | unchanged + getTrends |
| admin_finance_service | stub `{}`/`[]` | getSummary, getDues, getTrialBalance, getInvoices, getInvoice, getExpenses |
| admin_society_service | stub | getProfile, getLogo, getSetupProgress, getStructureSummary, getWings, getBlocks, getUnits |
| admin_staff_service | stub | getAllStaff, getAttendanceReport |
| admin_parking_service | stub | getSlots, getViolations, getRequests, getAllocations |
| admin_asset_service | stub | getAssets, getAsset |
| admin_complaint_service | stub | getComplaints, getAnalytics, getComplaint |
| admin_amenities_service (new) | — | getAmenities |
| admin_reports_service (new) | — | getJobs, getTemplates |

Provider layer (`sero/lib/providers/admin/`): new FutureProviders added per domain (finance, society/structure, staff, parking, assets, complaints, amenities, reports). Existing `dashboardProvider`, `noticesProvider` reused.

Pattern enforced: provider → service → `ApiService.get` → `ApiService.unwrap` → typed map/list. No mock fallback in any migrated path; empty list/map only on genuinely empty backend response.
