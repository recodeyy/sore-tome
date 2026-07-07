import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminRevenueScreen extends ConsumerWidget {
  const SuperAdminRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenue = ref.watch(superAdminRevenueProvider);
    final plans = ref.watch(superAdminPlansProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(superAdminRevenueProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) => SuperAdminHeader(
                  title: 'Revenue',
                  subtitle: 'Subscriptions, collections, plans, and renewals',
                  onMenu: () => Scaffold.of(context).openDrawer(),
                  onNotifications: () =>
                      Navigator.pushNamed(context, '/notifications'),
                  onSettings: () =>
                      Navigator.pushNamed(context, '/super-admin/settings'),
                ),
              ),
            ),
            revenue.when(
              loading: () => const SliverToBoxAdapter(child: LiveLoadingView()),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: SuperAdminAsyncView<void>(
                  error: error,
                  onRetry: () => ref.invalidate(superAdminRevenueProvider),
                  builder: (_) => const SizedBox.shrink(),
                ),
              ),
              data: (data) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SuperAdminSectionCard(
                      title: 'Revenue Snapshot',
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _ValueCard(
                              label: 'MRR',
                              value: 'INR ${data.mrr.toStringAsFixed(0)}'),
                          _ValueCard(
                              label: 'ARR',
                              value: 'INR ${data.arr.toStringAsFixed(0)}'),
                          _ValueCard(
                              label: 'Outstanding',
                              value:
                                  'INR ${data.outstanding.toStringAsFixed(0)}'),
                          _ValueCard(
                              label: 'Failed Payments',
                              value: data.failedPayments.toString()),
                        ],
                      ),
                    ),
                    SuperAdminSectionCard(
                      title: 'Plans and Pricing',
                      child: plans.when(
                        loading: () => const LiveLoadingView(),
                        error: (error, _) => Text(
                          'Could not load plans: $error',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFFEF4444)),
                        ),
                        data: (items) => items.isEmpty
                            ? Text('No plans configured.',
                                style: GoogleFonts.outfit(
                                    color: const Color(0xFF64748B)))
                            : Column(
                                children: items.map((plan) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                        Icons.local_offer_outlined,
                                        color: kPrimaryGreen),
                                    title: Text(
                                        plan['name']?.toString() ?? 'Plan'),
                                    subtitle:
                                        Text(plan['code']?.toString() ?? ''),
                                    trailing: Text(
                                        'INR ${((num.tryParse(plan['price_minor']?.toString() ?? '0') ?? 0) / 100).toStringAsFixed(0)}'),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;

  const _ValueCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSuperGreenSoft,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: kSuperGreen, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B), fontSize: 11)),
          const SizedBox(height: 5),
          Text(value,
              style: GoogleFonts.outfit(
                  color: kSuperGreenDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
