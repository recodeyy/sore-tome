# LIVE_DATA_SOURCE_OF_TRUTH_MAP

Per spec section 2/6 — visible elements of the admin screens → expected live source. Tenant scope: all via `tenantMiddleware` (society of authenticated admin). Permission: `authMiddleware` + `adminOnly`/`canManageContent`/`canManageFunds`. PostgreSQL is canonical.

| Screen | Visible element | Expected live source (endpoint → field) |
|---|---|---|
| Dashboard home | Pending approvals, open complaints, today collection, maintenance due, visitors today, staff on duty | GET /admin/dashboard/summary → pendingApprovalsCount, financials, recentUpdates |
| Finance dashboard | Total revenue/expenses/collection, maintenance due, pending dues | GET /finance/reports/summary; GET /finance/reports/dues (ageing) |
| Financial ledger | Income, expenses, net balance, transactions | GET /finance/reports/trial-balance |
| Payment history | Invoice/payment rows | GET /finance/invoices |
| Society info/profile | name, code, type, reg no, established, counts | GET /society/profile; GET /structure/summary |
| Society logo | logo URL/update date | GET /society/logo |
| Setup home | setup progress steps | GET /society/setup-progress |
| Wings/blocks | wings[], blocks[], totals | GET /structure/wings, /structure/blocks, /structure/summary |
| Flats/units | units[], owner/tenant/vacant counts | GET /structure/units, /structure/summary |
| Staff dashboard | total/active/present/on-leave, staff list, activity | GET /staff-v2; GET /staff-v2/reports/attendance |
| Staff list | staff rows | GET /staff-v2 |
| Amenities dashboard | total amenities, bookings, revenue, list | GET /amenities |
| Parking dashboard | total/allocated/available/reserved slots, resident/visitor vehicles, pending requests, violations | GET /parking/slots, /parking/requests, /parking/violations |
| Slot allocation | slots[], allocations[] | GET /parking/slots |
| Assets dashboard | total/operational/maintenance/out-of-service, list, logs | GET /assets |
| Lift details | asset detail | GET /assets/:id |
| Complaints dashboard | total/open/in-progress/resolved/overdue, recent | GET /complaints; GET /complaints/analytics |
| Complaint details | one complaint | GET /complaints/:id |
| Reports dashboard | reports this month, scheduled, categories, recent jobs | GET /reports/jobs, /reports/templates |
| Notices | notice list | GET /notices |
