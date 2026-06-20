import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/dashboard_stats.dart';
import 'package:sero/models/society_vitals.dart';
import 'package:sero/services/admin/admin_dashboard_service.dart';

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardStats>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    return _fetchStats();
  }

  Future<DashboardStats> _fetchStats() async {
    // CUTOVER: real Postgres backend — GET /admin/dashboard/summary
    // (envelope unwrapped by AdminDashboardService). No mock fallback here.
    final data = await AdminDashboardService.getDashboardSummary();
    return DashboardStats.fromJson(data);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

// CUTOVER (live-data audit U-B1): now reads the tenant-scoped Postgres endpoint
// `GET /admin/dashboard/vitals` instead of the legacy hard-coded, non-tenant-scoped
// Firestore document `societies/main_society/vitals/current`.
final societyVitalsProvider = FutureProvider<SocietyVitals>((ref) async {
  final data = await AdminDashboardService.getVitals();
  return SocietyVitals.fromMap(data);
});



