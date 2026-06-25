# Live Data Blockers

| file:line | screen | missing endpoint |
| --- | --- | --- |
| sero/lib/screens/admin/finance/bill_details_screen.dart:18 | Bill Details | No invoice id wired into route/navigation; screen accepts optional invoiceId/route arg, shows "No invoice selected." empty state when absent |
| sero/lib/screens/admin/finance/income_reports_screen.dart:87 | Income Reports | No income-by-category breakdown endpoint (summary lacks `categories`); donut shows empty state |
| sero/lib/screens/admin/finance/income_reports_screen.dart:120 | Income Reports | No top-collections endpoint (summary lacks `top_collections`); list shows empty state |
| sero/lib/screens/admin/dashboard/dashboard_home_screen.dart:92 | Dashboard Home | DashboardStats has no greeting (adminName/societyName), visitors-today, or staff-on-duty fields; greeting genericised, counts shown as 0 |
| sero/lib/screens/admin/dashboard/dashboard_revenue_screen.dart:324 | Dashboard Revenue | /finance/reports/summary has no time-series (revenue line / collections trend) or category breakdown; charts empty, category panel shows empty state |
| sero/lib/screens/admin/dashboard/dashboard_insights_screen.dart:104 | Dashboard Insights | DashboardStats lacks complaint status split, resolution %, occupancy %, and visitor check-in/out counts; shown as 0 |
| sero/lib/screens/admin/dashboard/dashboard_notices_screen.dart:144 | Dashboard Notices | Quick-stats (totalMembers/flats/staff/vehicles) have no source on this screen; shown as 0 |
| sero/lib/screens/admin/staff/staff_dashboard_screen.dart:139 | Staff Dashboard | /staff-v2/reports/attendance lacks pending_payroll, overtime_hours, and recent_activity fields; Overview cards (Pending Payroll/Overtime) and Recent Activity shown as 0/empty |
| sero/lib/screens/admin/staff/amenities_dashboard_screen.dart:66 | Amenities Dashboard | /amenities returns amenity list only; no todays_bookings, pending_approval, month_revenue, or upcoming_bookings fields; metrics shown as 0 and bookings list empty |
