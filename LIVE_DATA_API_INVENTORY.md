# LIVE_DATA_API_INVENTORY

Backend: `society-backend`, mounted at `/api/v1` (and legacy `/`). Postgres-backed routes under `src/routes/*_pg.ts` / `*.ts`. Most non-legacy routes return raw JSON (e.g. `{slots:[...]}`), NOT the `{success,data,meta}` envelope — `ApiService.unwrap()` returns the decoded body as-is for these (it only unwraps when a `success` key is present).

## Endpoints consumed by admin live-data migration
| Domain | Method + Path | Returns | Frontend service.method |
|---|---|---|---|
| Dashboard | GET /admin/dashboard/summary | data map | AdminDashboardService.getDashboardSummary (existing) |
| Dashboard | GET /admin/dashboard/trends | trends | AdminDashboardService.getTrends (added) |
| Finance | GET /finance/reports/summary | summary obj | AdminFinanceService.getSummary |
| Finance | GET /finance/reports/dues | dues+ageing | AdminFinanceService.getDues |
| Finance | GET /finance/reports/trial-balance | accounts[] | AdminFinanceService.getTrialBalance |
| Finance | GET /finance/invoices | invoices[] | AdminFinanceService.getInvoices |
| Finance | GET /finance/invoices/:id | invoice | AdminFinanceService.getInvoice |
| Finance | GET /finance/expenses | expenses[] | AdminFinanceService.getExpenses |
| Society | GET /society/profile | profile | AdminSocietyService.getProfile |
| Society | GET /society/logo | logo meta | AdminSocietyService.getLogo |
| Society | GET /society/setup-progress | progress | AdminSocietyService.getSetupProgress |
| Structure | GET /structure/summary | counts | AdminSocietyService.getStructureSummary |
| Structure | GET /structure/wings | {wings:[]} | AdminSocietyService.getWings |
| Structure | GET /structure/blocks | {blocks:[]} | AdminSocietyService.getBlocks |
| Structure | GET /structure/units | {units:[]} | AdminSocietyService.getUnits |
| Staff | GET /staff-v2 | {staff:[]} | AdminStaffService.getAllStaff |
| Staff | GET /staff-v2/reports/attendance | report | AdminStaffService.getAttendanceReport |
| Parking | GET /parking/slots | {slots:[]} | AdminParkingService.getSlots |
| Parking | GET /parking/violations | {violations:[]} | AdminParkingService.getViolations |
| Parking | GET /parking/requests | {requests:[]} | AdminParkingService.getRequests |
| Assets | GET /assets | {assets:[]} | AdminAssetService.getAssets |
| Assets | GET /assets/:id | asset | AdminAssetService.getAsset |
| Complaints | GET /complaints | {complaints:[]} | AdminComplaintService.getComplaints |
| Complaints | GET /complaints/analytics | analytics | AdminComplaintService.getAnalytics |
| Complaints | GET /complaints/:id | complaint | AdminComplaintService.getComplaint |
| Amenities | GET /amenities | amenities/bookings | AdminAmenitiesService.getAmenities |
| Reports | GET /reports/jobs | {jobs:[]} | AdminReportsService.getJobs |
| Reports | GET /reports/templates | {templates:[]} | AdminReportsService.getTemplates |
| Notices | GET /notices | {notices:[]} | noticesProvider (existing) |

## Notable backend mutation endpoints available (for forms, future)
POST /finance/invoices, /finance/payments, /finance/expenses; POST /structure/wings|blocks|units; POST /staff-v2, /staff-v2/attendance/check-in; POST /parking/slots|allocations|violations; POST /assets, /assets/work-orders; PATCH /complaints/:id/status, POST /complaints/:id/assign; PUT /society/profile|logo.
