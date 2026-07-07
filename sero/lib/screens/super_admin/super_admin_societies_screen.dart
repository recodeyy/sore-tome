import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/shared/sero_ui.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminSocietiesScreen extends ConsumerWidget {
  const SuperAdminSocietiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final societies = ref.watch(superAdminSocietiesProvider);
    final filters = ref.watch(superAdminSocietyFiltersProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(superAdminSocietiesProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) => SuperAdminHeader(
                  title: 'Societies',
                  subtitle: 'Search, monitor, and review platform tenants',
                  onMenu: () => Scaffold.of(context).openDrawer(),
                  onNotifications: () =>
                      Navigator.pushNamed(context, '/notifications'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search societies',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (value) {
                    ref.read(superAdminSocietyFiltersProvider.notifier).state =
                        filters.copyWith(query: value);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    'all',
                    'active',
                    'trial',
                    'onboarding',
                    'suspended',
                    'grace'
                  ]
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: filters.status == status,
                            label: Text(_statusLabel(status)),
                            onSelected: (_) {
                              ref
                                  .read(
                                      superAdminSocietyFiltersProvider.notifier)
                                  .state = filters.copyWith(status: status);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            societies.when(
              loading: () => const SliverToBoxAdapter(child: LiveLoadingView()),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: SuperAdminAsyncView<void>(
                  error: error,
                  onRetry: () => ref.invalidate(superAdminSocietiesProvider),
                  builder: (_) => const SizedBox.shrink(),
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.business_outlined,
                      title: 'No societies here',
                      message:
                          'No societies match this view. Try a different filter.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList.builder(
                    itemCount: page.items.length,
                    itemBuilder: (context, index) {
                      return SuperAdminSocietyCard(society: page.items[index]);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'grace':
        return 'Payment Due';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}
