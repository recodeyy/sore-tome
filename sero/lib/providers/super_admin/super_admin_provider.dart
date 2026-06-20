import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/services/super_admin/super_admin_service.dart';

final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService();
});

final superAdminDashboardProvider =
    FutureProvider.autoDispose<SuperAdminDashboard>((ref) {
  return ref.watch(superAdminServiceProvider).getDashboard();
});

final superAdminSocietyFiltersProvider =
    StateProvider<SuperAdminSocietyFilters>((ref) {
  return const SuperAdminSocietyFilters();
});

final superAdminSocietiesProvider =
    FutureProvider.autoDispose<SuperAdminSocietiesPage>((ref) {
  final filters = ref.watch(superAdminSocietyFiltersProvider);
  return ref.watch(superAdminServiceProvider).getSocieties(filters: filters);
});

final superAdminRevenueProvider =
    FutureProvider.autoDispose<SuperAdminRevenueSnapshot>((ref) {
  return ref.watch(superAdminServiceProvider).getRevenueAnalytics();
});

final superAdminSupportProvider =
    FutureProvider.autoDispose<SuperAdminSupportDashboard>((ref) {
  return ref.watch(superAdminServiceProvider).getSupportDashboard();
});

final superAdminUsersProvider =
    FutureProvider.autoDispose<List<JsonMap>>((ref) {
  return ref.watch(superAdminServiceProvider).getPlatformUsers();
});

final superAdminPlansProvider =
    FutureProvider.autoDispose<List<JsonMap>>((ref) {
  return ref.watch(superAdminServiceProvider).getPlans();
});

final superAdminReportsProvider =
    FutureProvider.autoDispose<List<JsonMap>>((ref) {
  return ref.watch(superAdminServiceProvider).getReports();
});

final superAdminFeaturesProvider =
    FutureProvider.autoDispose<List<JsonMap>>((ref) {
  return ref.watch(superAdminServiceProvider).getFeatures();
});

final superAdminAnnouncementsProvider =
    FutureProvider.autoDispose<List<JsonMap>>((ref) {
  return ref.watch(superAdminServiceProvider).getAnnouncements();
});

final superAdminAuditProvider =
    FutureProvider.autoDispose<List<SuperAdminActivity>>((ref) {
  return ref.watch(superAdminServiceProvider).getAuditLogs();
});
