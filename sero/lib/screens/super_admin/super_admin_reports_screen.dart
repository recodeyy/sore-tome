import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminReportsScreen extends ConsumerWidget {
  const SuperAdminReportsScreen({super.key});

  static const _reportTypes = <_ReportType>[
    _ReportType('Revenue', 'revenue', Icons.payments_rounded),
    _ReportType('Subscriptions', 'subscriptions', Icons.card_membership_rounded),
    _ReportType('Societies', 'societies', Icons.apartment_rounded),
    _ReportType('Payments', 'payments', Icons.receipt_long_rounded),
  ];

  Future<void> _requestReport(
      BuildContext context, WidgetRef ref, String type) async {
    try {
      await ref.read(superAdminServiceProvider).requestReport({
        'type': type,
        'period': 'this_month',
      });
      ref.invalidate(superAdminReportsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kSuperGreen,
          content: Text('Report queued'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text('Failed to queue report: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(superAdminRevenueProvider);
    final reportsAsync = ref.watch(superAdminReportsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SuperAdminHeader(
            title: 'Revenue Reports',
            subtitle: 'Generate & download platform reports',
            leadingIcon: Icons.arrow_back_rounded,
            periodLabel: 'This Month',
            onMenu: () => Navigator.maybePop(context),
            onNotifications: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Column(
              children: [
                SuperAdminSectionCard(
                  title: 'Summary',
                  child: SuperAdminAsyncView(
                    loading: revenueAsync.isLoading,
                    error:
                        revenueAsync.hasError ? revenueAsync.error : null,
                    data: revenueAsync.asData?.value,
                    onRetry: () =>
                        ref.invalidate(superAdminRevenueProvider),
                    builder: (snapshot) {
                      return Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Total Revenue',
                              value: '₹ ${_fmt(snapshot.mrr)}',
                              icon: Icons.trending_up_rounded,
                              accent: kSuperGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              label: 'Collected',
                              value:
                                  '₹ ${_fmt(snapshot.collectedThisMonth)}',
                              icon: Icons.check_circle_rounded,
                              accent: kAccentGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              label: 'Outstanding',
                              value: '₹ ${_fmt(snapshot.outstanding)}',
                              icon: Icons.schedule_rounded,
                              accent: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SuperAdminSectionCard(
                  title: 'Generate Report',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final type in _reportTypes)
                        _ReportTypeChip(
                          type: type,
                          onTap: () =>
                              _requestReport(context, ref, type.code),
                        ),
                    ],
                  ),
                ),
                SuperAdminSectionCard(
                  title: 'Recent Reports',
                  child: SuperAdminAsyncView<List<JsonMap>>(
                    loading: reportsAsync.isLoading,
                    error:
                        reportsAsync.hasError ? reportsAsync.error : null,
                    data: reportsAsync.valueOrNull,
                    onRetry: () =>
                        ref.invalidate(superAdminReportsProvider),
                    builder: (reports) {
                      if (reports.isEmpty) {
                        return const SuperAdminEmptyState(
                          icon: Icons.insert_drive_file_outlined,
                          title: 'No reports yet',
                          message:
                              'Generate a report above and it will appear here.',
                        );
                      }
                      return Column(
                        children: [
                          for (final report in reports)
                            _RecentReportRow(
                              report: report,
                              onDownload: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Download started'),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double value) {
    final whole = value.round();
    final str = whole.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _ReportType {
  final String label;
  final String code;
  final IconData icon;

  const _ReportType(this.label, this.code, this.icon);
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSlateBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTypeChip extends StatelessWidget {
  final _ReportType type;
  final VoidCallback onTap;

  const _ReportTypeChip({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kSuperGreenSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kSuperGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, color: kSuperGreenDark, size: 18),
            const SizedBox(width: 8),
            Text(
              type.label,
              style: GoogleFonts.outfit(
                color: kSuperGreenDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentReportRow extends StatelessWidget {
  final JsonMap report;
  final VoidCallback onDownload;

  const _RecentReportRow({required this.report, required this.onDownload});

  String get _title {
    final type = (report['type'] ?? 'Report').toString();
    final label = type.isEmpty
        ? 'Report'
        : '${type[0].toUpperCase()}${type.substring(1)} Report';
    final period = (report['period'] ?? '').toString();
    return period.isEmpty ? label : '$label · $period';
  }

  String get _status => (report['status'] ?? '').toString();

  String get _date {
    final raw = (report['created_at'] ?? '').toString();
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = parsed.toLocal();
    return '${d.day.toString().padLeft(2, '0')} '
        '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final date = _date;
    final subtitleParts = [
      if (status.isNotEmpty) status,
      if (date.isNotEmpty) date,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSlateBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kSuperGreenSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                color: kSuperGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, color: kSuperGreen),
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }
}
