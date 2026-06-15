import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/dashboard_stats.dart';
import 'package:sero/models/society_vitals.dart';
import 'package:sero/services/api_service.dart';

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
    try {
      // TODO: Connect to real backend API endpoint
      // Example: final response = await ApiService.get('/admin/dashboard-stats');
      
      if (kUseMockData) {
        // Return empty stats when mock data is enabled but we want to show empty state
        return DashboardStats(
          pendingApprovalsCount: 0,
          topIssues: [],
          recentUpdates: [],
          financials: Financials(
            totalCollected: 0,
            totalSpent: 0,
            balance: 0,
            target: 0,
            currency: '₹',
            percentage: 0,
          ),
          activeResidentsCount: 0,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      final response = await ApiService.get('/admin/dashboard-stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardStats.fromJson(data);
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      if (kUseMockData) {
        return DashboardStats(
          pendingApprovalsCount: 0,
          topIssues: [],
          recentUpdates: [],
          financials: Financials(
            totalCollected: 0,
            totalSpent: 0,
            balance: 0,
            target: 0,
            currency: '₹',
            percentage: 0,
          ),
          activeResidentsCount: 0,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
      rethrow;
    }
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



