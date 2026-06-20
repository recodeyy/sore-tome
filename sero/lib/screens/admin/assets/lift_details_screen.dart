import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/common/status_badge.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';

/// Live asset (lift) detail. Expects the asset id as the route argument
/// (`Navigator.pushNamed(context, '/admin/assets/details', arguments: id)`).
/// Backed by GET /assets/:id (Postgres, tenant-scoped).
class LiftDetailsScreen extends ConsumerStatefulWidget {
  const LiftDetailsScreen({super.key});

  @override
  ConsumerState<LiftDetailsScreen> createState() => _LiftDetailsScreenState();
}

class _LiftDetailsScreenState extends ConsumerState<LiftDetailsScreen> {
  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final assetId = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Asset Details',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: assetId == null
          ? const LiveEmptyView(
              icon: Icons.inventory_2_outlined,
              message: 'Select an asset to view its details.',
            )
          : ref.watch(assetDetailProvider(assetId)).when(
                loading: () => const LiveLoadingView(label: 'Loading asset…'),
                error: (e, _) => LiveErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(assetDetailProvider(assetId)),
                ),
                data: (payload) {
                  final asset = (payload['asset'] as Map?)?.cast<String, dynamic>() ?? const {};
                  final schedules = (payload['schedules'] as List?) ?? const [];
                  final workOrders = (payload['workOrders'] as List?) ?? const [];
                  final amc = (payload['amc'] as List?) ?? const [];
                  if (asset.isEmpty) {
                    return const LiveEmptyView(
                      icon: Icons.inventory_2_outlined,
                      message: 'Asset not found.',
                    );
                  }
                  return _buildBody(context, asset, schedules, workOrders, amc);
                },
              ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, dynamic> asset,
    List<dynamic> schedules,
    List<dynamic> workOrders,
    List<dynamic> amc,
  ) {
    final status = (asset['status'] ?? 'operational').toString();
    final isOperational = status == 'operational';
    final nextSchedule = schedules.isNotEmpty
        ? (schedules.first as Map).cast<String, dynamic>()
        : null;
    final activeAmc = amc.isNotEmpty ? (amc.first as Map).cast<String, dynamic>() : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.elevator_outlined, color: kPrimaryGreen, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (asset['name'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (asset['type'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (asset['location'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: status,
                  bgColor: isOperational ? const Color(0xFF059669) : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(Icons.tag, 'Tag', (asset['tag'] ?? '—').toString()),
          _buildDetailRow(Icons.calendar_today_outlined, 'Commissioned On',
              (asset['commissioned_on'] ?? '—').toString().split('T').first),
          if (nextSchedule != null)
            _buildDetailRow(
              Icons.access_time_outlined,
              'Next Service Due',
              (nextSchedule['next_due_on'] ?? '—').toString().split('T').first,
              secondaryText: (nextSchedule['title'] ?? '').toString(),
              isUrgent: true,
            ),
          if (activeAmc != null)
            _buildDetailRow(Icons.handyman_outlined, 'AMC Ends',
                (activeAmc['end_date'] ?? '—').toString().split('T').first),
          const SizedBox(height: 24),
          Text(
            'Work Orders',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          if (workOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No work orders yet.',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
            )
          else
            ...workOrders.take(10).map((w) {
              final wo = (w as Map).cast<String, dynamic>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((wo['title'] ?? '').toString(),
                              style: GoogleFonts.outfit(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text((wo['kind'] ?? '').toString(),
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: (wo['status'] ?? '').toString(),
                      bgColor: const Color(0xFF2563EB),
                      textColor: Colors.white,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {String? secondaryText, bool isUrgent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (secondaryText != null && secondaryText.isNotEmpty)
                Text(
                  secondaryText,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
