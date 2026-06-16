import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/dashboard_stats.dart';
import 'package:sero/models/society_vitals.dart';
import 'package:sero/services/admin/admin_dashboard_service.dart';

import 'package:sero/config/dev_config.dart';

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

final societyVitalsProvider = StreamProvider<SocietyVitals>((ref) {
  if (kUseMockData) {
    // TODO: Connect to backend for real-time vitals
    return Stream.value(SocietyVitals(
      parcelsPending: 0,
      guardsOnDuty: 0,
      activeMaintenance: "None",
      systemStatus: "Awaiting Data",
      lastUpdate: DateTime.now(),
    ));
  }
  return FirebaseFirestore.instance
      .collection('societies')
      .doc('main_society')
      .collection('vitals')
      .doc('current')
      .snapshots()
      .map((snap) {
        if (!snap.exists) {
          return SocietyVitals(
            parcelsPending: 0,
            guardsOnDuty: 0,
            activeMaintenance: "None",
            systemStatus: "Stable",
            lastUpdate: DateTime.now(),
          );
        }
        return SocietyVitals.fromMap(snap.data()!);
      });
});



