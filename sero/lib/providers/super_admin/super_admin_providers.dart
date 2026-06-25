import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/services/super_admin/super_admin_service.dart';

final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService();
});

final superAdminSocietyFiltersProvider =
    StateProvider<SuperAdminSocietyFilters>((ref) {
  return const SuperAdminSocietyFilters();
});

final superAdminDashboardProvider =
    AsyncNotifierProvider<SuperAdminDashboardNotifier, SuperAdminDashboard>(
  SuperAdminDashboardNotifier.new,
);

class SuperAdminDashboardNotifier extends AsyncNotifier<SuperAdminDashboard> {
  @override
  Future<SuperAdminDashboard> build() {
    return ref.read(superAdminServiceProvider).getDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(superAdminServiceProvider).getDashboard(),
    );
  }
}

final superAdminSocietiesProvider =
    AsyncNotifierProvider<SuperAdminSocietiesNotifier, SuperAdminSocietiesPage>(
  SuperAdminSocietiesNotifier.new,
);

class SuperAdminSocietiesNotifier
    extends AsyncNotifier<SuperAdminSocietiesPage> {
  @override
  Future<SuperAdminSocietiesPage> build() {
    final filters = ref.watch(superAdminSocietyFiltersProvider);
    return ref.read(superAdminServiceProvider).getSocieties(filters: filters);
  }

  Future<void> refresh() async {
    final filters = ref.read(superAdminSocietyFiltersProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(superAdminServiceProvider).getSocieties(filters: filters),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final filters = ref.read(superAdminSocietyFiltersProvider);
    final nextPage = await ref.read(superAdminServiceProvider).getSocieties(
          filters: filters,
          cursor: current.nextCursor,
        );

    state = AsyncValue.data(
      SuperAdminSocietiesPage(
        items: [...current.items, ...nextPage.items],
        nextCursor: nextPage.nextCursor,
        total: nextPage.total == 0 ? current.total : nextPage.total,
      ),
    );
  }

  Future<void> approve(String societyId, {required String reason}) async {
    await ref
        .read(superAdminServiceProvider)
        .approveSociety(societyId, reason: reason);
    await refresh();
    ref.invalidate(superAdminDashboardProvider);
  }

  Future<void> reject(String societyId, {required String reason}) async {
    await ref
        .read(superAdminServiceProvider)
        .rejectSociety(societyId, reason: reason);
    await refresh();
    ref.invalidate(superAdminDashboardProvider);
  }
}

final superAdminSocietyDetailProvider =
    FutureProvider.family<SuperAdminSociety, String>((ref, societyId) {
  return ref.read(superAdminServiceProvider).getSociety(societyId);
});

final superAdminRevenueProvider =
    AsyncNotifierProvider<SuperAdminRevenueNotifier, SuperAdminRevenueSnapshot>(
  SuperAdminRevenueNotifier.new,
);

class SuperAdminRevenueNotifier
    extends AsyncNotifier<SuperAdminRevenueSnapshot> {
  @override
  Future<SuperAdminRevenueSnapshot> build() {
    return ref.read(superAdminServiceProvider).getRevenueAnalytics();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(superAdminServiceProvider).getRevenueAnalytics(),
    );
  }
}

final superAdminSupportStatusFilterProvider = StateProvider<String>((ref) {
  return 'open';
});

final superAdminSupportPriorityFilterProvider = StateProvider<String>((ref) {
  return 'all';
});

final superAdminSupportProvider = AsyncNotifierProvider<
    SuperAdminSupportNotifier, SuperAdminSupportDashboard>(
  SuperAdminSupportNotifier.new,
);

class SuperAdminSupportNotifier
    extends AsyncNotifier<SuperAdminSupportDashboard> {
  @override
  Future<SuperAdminSupportDashboard> build() {
    final status = ref.watch(superAdminSupportStatusFilterProvider);
    final priority = ref.watch(superAdminSupportPriorityFilterProvider);
    return ref.read(superAdminServiceProvider).getSupportDashboard(
          status: status,
          priority: priority,
        );
  }

  Future<void> refresh() async {
    final status = ref.read(superAdminSupportStatusFilterProvider);
    final priority = ref.read(superAdminSupportPriorityFilterProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(superAdminServiceProvider).getSupportDashboard(
            status: status,
            priority: priority,
          ),
    );
  }

  Future<void> resolve(String ticketId, {required String resolution}) async {
    await ref
        .read(superAdminServiceProvider)
        .resolveTicket(ticketId, resolution: resolution);
    await refresh();
    ref.invalidate(superAdminDashboardProvider);
  }
}

final superAdminSystemHealthProvider =
    FutureProvider<List<SuperAdminHealthSignal>>((ref) {
  return ref.read(superAdminServiceProvider).getSystemHealth();
});

final superAdminAuditLogsProvider =
    FutureProvider<List<SuperAdminActivity>>((ref) {
  return ref.read(superAdminServiceProvider).getAuditLogs();
});

final superAdminMoreModulesProvider =
    Provider<List<SuperAdminModuleLink>>((ref) {
  return const [
    SuperAdminModuleLink(
      title: 'Analytics',
      subtitle: 'Platform command center and live signals',
      route: '/super-admin/analytics',
      group: 'Platform',
      iconKey: 'dashboard',
    ),
    SuperAdminModuleLink(
      title: 'Approval Queue',
      subtitle: 'Lifecycle, approvals, KYC, setup progress',
      route: '/super-admin/approvals',
      group: 'Platform',
      iconKey: 'societies',
    ),
    SuperAdminModuleLink(
      title: 'Approval Queue',
      subtitle: 'Review submitted societies and risk flags',
      route: '/super-admin/approvals',
      group: 'Platform',
      iconKey: 'approval',
    ),
    SuperAdminModuleLink(
      title: 'Revenue Reports',
      subtitle: 'MRR, ARR, payments, refunds, reports',
      route: '/super-admin/reports',
      group: 'Revenue',
      iconKey: 'revenue',
    ),
    SuperAdminModuleLink(
      title: 'Subscriptions',
      subtitle: 'Plans, renewals, grace periods, failures',
      route: '/super-admin/subscriptions',
      group: 'Revenue',
      iconKey: 'subscriptions',
    ),
    SuperAdminModuleLink(
      title: 'Plans and Pricing',
      subtitle: 'Plan versions, limits, draft publishing',
      route: '/super-admin/plans',
      group: 'Revenue',
      iconKey: 'plans',
    ),
    SuperAdminModuleLink(
      title: 'Feature Controls',
      subtitle: 'Registry, rollouts, overrides, kill switches',
      route: '/super-admin/features',
      group: 'Platform Intelligence',
      iconKey: 'features',
      sensitive: true,
    ),
    SuperAdminModuleLink(
      title: 'Announcements',
      subtitle: 'Global in-app, push, email campaigns',
      route: '/super-admin/announcements',
      group: 'Operations',
      iconKey: 'announcements',
    ),
    SuperAdminModuleLink(
      title: 'Support Tickets',
      subtitle: 'Queue, assignment, SLA, escalations',
      route: '/super-admin/support',
      group: 'Operations',
      iconKey: 'support',
    ),
    SuperAdminModuleLink(
      title: 'System Health',
      subtitle: 'API, database, queues, providers, jobs',
      route: '/super-admin/system-health',
      group: 'Security and Administration',
      iconKey: 'health',
      sensitive: true,
    ),
    SuperAdminModuleLink(
      title: 'Audit Logs',
      subtitle: 'Immutable platform actions and access logs',
      route: '/super-admin/audit',
      group: 'Security and Administration',
      iconKey: 'audit',
      sensitive: true,
    ),
    SuperAdminModuleLink(
      title: 'Impersonation',
      subtitle: 'Audited support access with expiry',
      route: '/super-admin/impersonation',
      group: 'Security and Administration',
      iconKey: 'impersonation',
      sensitive: true,
    ),
    SuperAdminModuleLink(
      title: 'API Access',
      subtitle: 'Clients, keys, webhooks, delivery logs',
      route: '/super-admin/api-access',
      group: 'Security and Administration',
      iconKey: 'api',
      sensitive: true,
    ),
    SuperAdminModuleLink(
      title: 'Platform Users',
      subtitle: 'Super Admins, support, finance, auditors',
      route: '/super-admin/users',
      group: 'Account',
      iconKey: 'users',
      sensitive: true,
    ),
    SuperAdminModuleLink(
      title: 'Settings',
      subtitle: 'Control-plane preferences and policies',
      route: '/super-admin/settings',
      group: 'Account',
      iconKey: 'settings',
    ),
  ];
});
