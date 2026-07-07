import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';
import 'package:sero/widgets/common/info_list_tile.dart';
import 'package:sero/widgets/common/stat_card.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminSupportScreen extends ConsumerWidget {
  const SuperAdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(superAdminSupportProvider);
    final status = ref.watch(superAdminSupportStatusFilterProvider);
    final priority = ref.watch(superAdminSupportPriorityFilterProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      drawer: const SuperAdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(superAdminSupportProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SupportHeader(status: status, priority: priority),
            const SizedBox(height: 18),
            _SupportFilters(
              status: status,
              priority: priority,
              onStatusChanged: (value) => ref
                  .read(superAdminSupportStatusFilterProvider.notifier)
                  .state = value,
              onPriorityChanged: (value) => ref
                  .read(superAdminSupportPriorityFilterProvider.notifier)
                  .state = value,
            ),
            const SizedBox(height: 18),
            support.when(
              loading: () => const LiveLoadingView(),
              error: (error, stackTrace) => SuperAdminAsyncError(
                error: error,
                onRetry: () =>
                    ref.read(superAdminSupportProvider.notifier).refresh(),
              ),
              data: (data) => _SupportBody(data: data),
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

}

class _SupportHeader extends StatelessWidget {
  final String status;
  final String priority;

  const _SupportHeader({
    required this.status,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: kSuperHeaderGradient,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support operations',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Status $status | Priority $priority',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.support_agent_rounded,
              color: Colors.white, size: 34),
        ],
      ),
    );
  }
}

class _SupportFilters extends StatelessWidget {
  final String status;
  final String priority;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;

  const _SupportFilters({
    required this.status,
    required this.priority,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          values: const {
            'open': 'Open',
            'pending': 'Pending',
            'escalated': 'Escalated',
            'resolved': 'Resolved',
            'all': 'All',
          },
          selected: status,
          onSelected: onStatusChanged,
        ),
        const SizedBox(height: 10),
        _ChipRow(
          values: const {
            'all': 'All priorities',
            'critical': 'Critical',
            'high': 'High',
            'normal': 'Normal',
            'low': 'Low',
          },
          selected: priority,
          onSelected: onPriorityChanged,
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final Map<String, String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChipRow({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in values.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected == entry.key,
                selectedColor: kPrimaryGreen.withValues(alpha: 0.12),
                labelStyle: GoogleFonts.outfit(
                  color: selected == entry.key
                      ? kPrimaryGreen
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => onSelected(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _SupportBody extends StatelessWidget {
  final SuperAdminSupportDashboard data;

  const _SupportBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlaStats(summary: data.summary),
        const SizedBox(height: 24),
        const SuperAdminSectionHeader(title: 'Ticket queue'),
        if (data.tickets.isEmpty)
          const SuperAdminEmptyState(
            icon: Icons.support_agent_outlined,
            title: 'No tickets in this queue',
            message:
                'Change filters or wait for support data from the backend.',
          )
        else
          ...data.tickets.map(
            (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SuperAdminSupportTicketCard(
                ticket: ticket,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/super-admin/support/${ticket.id}',
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        const SuperAdminSectionHeader(title: 'Support operations'),
        InfoListTile(
          icon: Icons.analytics_outlined,
          title: 'SLA dashboard',
          subtitle: 'Breaches, due soon, first response, CSAT',
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
          onTap: () => Navigator.pushNamed(context, '/super-admin/support'),
        ),
        const SizedBox(height: 10),
        InfoListTile(
          icon: Icons.warning_amber_rounded,
          title: 'Escalations',
          subtitle: 'Critical incidents and linked platform issues',
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFFF7ED),
          onTap: () => Navigator.pushNamed(context, '/super-admin/incidents'),
        ),
      ],
    );
  }
}

class _SlaStats extends StatelessWidget {
  final SuperAdminSupportSummary summary;

  const _SlaStats({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 4 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: MediaQuery.of(context).size.width >= 700 ? 1.55 : 1.35,
      children: [
        StatCard(
          value: summary.openTickets.toString(),
          label: 'Open tickets',
          icon: Icons.support_agent_rounded,
          trend: 'queue',
        ),
        StatCard(
          value: summary.breachedSla.toString(),
          label: 'SLA breached',
          icon: Icons.timer_off_outlined,
          trend: summary.breachedSla == 0 ? 'clear' : 'risk',
          trendUp: summary.breachedSla == 0,
        ),
        StatCard(
          value: summary.dueSoon.toString(),
          label: 'Due soon',
          icon: Icons.timer_outlined,
          trend: 'watch',
          trendUp: false,
        ),
        StatCard(
          value: summary.csat == 0 ? '-' : summary.csat.toStringAsFixed(1),
          label: 'CSAT',
          icon: Icons.sentiment_satisfied_alt_outlined,
        ),
      ],
    );
  }
}
