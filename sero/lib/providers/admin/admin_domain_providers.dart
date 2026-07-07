import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sero/services/admin/admin_finance_service.dart';
import 'package:sero/services/admin/admin_society_service.dart';
import 'package:sero/services/admin/admin_staff_service.dart';
import 'package:sero/services/admin/admin_parking_service.dart';
import 'package:sero/services/admin/admin_asset_service.dart';
import 'package:sero/services/admin/admin_complaint_service.dart';
import 'package:sero/services/admin/admin_amenities_service.dart';
import 'package:sero/services/admin/admin_reports_service.dart';

/// Live admin domain providers.
///
/// CUTOVER: each provider calls its admin service → real Postgres endpoint.
/// No mock fallback. Screens watch these and render loading/empty/error states.
/// `.autoDispose` so state is cleared on logout / society switch / navigation.

// ── Finance ────────────────────────────────────────────────────────────────
/// Combined finance dashboard payload: { summary, dues }.
final financeDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final summary = await AdminFinanceService.getSummary();
  final dues = await AdminFinanceService.getDues();
  return {'summary': summary, 'dues': dues};
});

final financeLedgerProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return AdminFinanceService.getTrialBalance();
});

final paymentHistoryProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return AdminFinanceService.getInvoices();
});

final invoiceDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  return AdminFinanceService.getInvoice(id);
});

// ── Society / structure ──────────────────────────────────────────────────────
/// { profile, structure } combined for info/profile screens.
final societyProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final profile = await AdminSocietyService.getProfile();
  final structure = await AdminSocietyService.getStructureSummary();
  return {'profile': profile, 'structure': structure};
});

final setupProgressProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return AdminSocietyService.getSetupProgress();
});

/// { wings, blocks, summary } for the wings/blocks screen + bill dropdowns.
final structureSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final wings = await AdminSocietyService.getWings();
  final blocks = await AdminSocietyService.getBlocks();
  final summary = await AdminSocietyService.getStructureSummary();
  return {'wings': wings, 'blocks': blocks, 'summary': summary};
});

final structureUnitsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final units = await AdminSocietyService.getUnits();
  final summary = await AdminSocietyService.getStructureSummary();
  return {'units': units, 'summary': summary};
});

// ── Staff ────────────────────────────────────────────────────────────────────
/// { staff, attendance } for the staff dashboard.
final staffDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final staff = await AdminStaffService.getAllStaff();
  final attendance = await AdminStaffService.getAttendanceReport();
  return {'staff': staff, 'attendance': attendance};
});

final staffListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return AdminStaffService.getAllStaff();
});

/// Leave-approval queue. Defaults to pending requests (the admin's action list).
final leaveRequestsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return AdminStaffService.getLeaveRequests(status: 'pending');
});

/// Duty roster (today onward).
final dutyRosterProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return AdminStaffService.getRoster();
});

/// Payroll runs (newest period first).
final payrollRunsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return AdminStaffService.getPayrollRuns();
});

// ── Amenities ────────────────────────────────────────────────────────────────
final amenitiesDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return AdminAmenitiesService.getAmenities();
});

// ── Parking ──────────────────────────────────────────────────────────────────
/// { slots, requests, violations } for the parking dashboard.
final parkingDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final slots = await AdminParkingService.getSlots();
  final requests = await AdminParkingService.getRequests();
  final violations = await AdminParkingService.getViolations();
  return {'slots': slots, 'requests': requests, 'violations': violations};
});

final parkingSlotsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return AdminParkingService.getSlots();
});

// ── Assets ───────────────────────────────────────────────────────────────────
/// Aggregated assets dashboard: { totals, categories, upcomingMaintenance, recentActivity }.
final assetsDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return AdminAssetService.getDashboard();
});

final assetDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  return AdminAssetService.getAsset(id);
});

// ── Complaints ───────────────────────────────────────────────────────────────
/// { complaints, analytics } for the complaints dashboard.
final complaintsDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final complaints = await AdminComplaintService.getComplaints();
  final analytics = await AdminComplaintService.getAnalytics();
  return {'complaints': complaints, 'analytics': analytics};
});

final complaintDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  return AdminComplaintService.getComplaint(id);
});

// ── Reports ──────────────────────────────────────────────────────────────────
/// { jobs, templates } for the reports dashboard.
final reportsDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final jobs = await AdminReportsService.getJobs();
  final templates = await AdminReportsService.getTemplates();
  return {'jobs': jobs, 'templates': templates};
});

// ── Committee ────────────────────────────────────────────────────────────────
/// Committee directory (designation + joined member info) for the society.
final committeeProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return AdminSocietyService.getCommittee();
});
