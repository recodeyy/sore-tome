import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_staff_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Payroll Summary — lists payroll runs (GET /staff-v2/payroll) and lets an
/// admin generate a draft run for a month (POST /staff-v2/payroll/generate).
/// Amounts are stored in minor units (paise) on the backend.
class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  static String _rupees(dynamic minor) {
    final v = (minor is num) ? minor : num.tryParse('$minor') ?? 0;
    return '₹ ${(v / 100).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(payrollRunsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Payroll Summary',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: runsAsync.when(
        loading: () => const LiveLoadingView(label: 'Loading payroll…'),
        error: (e, _) => LiveErrorView(
            error: e, onRetry: () => ref.invalidate(payrollRunsProvider)),
        data: (runs) {
          if (runs.isEmpty) {
            return const LiveEmptyView(
              icon: Icons.account_balance_outlined,
              message: 'No payroll runs yet. Generate one for a month.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: runs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = runs[i] is Map
                  ? (runs[i] as Map).cast<String, dynamic>()
                  : <String, dynamic>{};
              final status = (m['status'] ?? 'draft').toString();
              final approved = status == 'approved';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((m['period'] ?? '').toString(),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Net ${_rupees(m['net_minor'])}',
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFF475569))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (approved
                                ? const Color(0xFF059669)
                                : const Color(0xFFEA580C))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status.toUpperCase(),
                          style: GoogleFonts.outfit(
                              color: approved
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFEA580C),
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generate(context, ref),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Generate',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _generate(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    // Default to the previous month (the one you'd normally run payroll for).
    final prev = DateTime(now.year, now.month - 1);
    final ctrl = TextEditingController(
        text: '${prev.year}-${prev.month.toString().padLeft(2, '0')}');
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Generate Payroll',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            enabled: !saving,
            decoration: const InputDecoration(
                labelText: 'Period (YYYY-MM)', hintText: 'e.g. 2026-05'),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final period = ctrl.text.trim();
                      if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(period)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Use format YYYY-MM'),
                            backgroundColor: Colors.red));
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        final ok =
                            await AdminStaffService.generatePayroll(period);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (ok) ref.invalidate(payrollRunsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'Payroll generated for $period'
                                  : 'Could not generate payroll'),
                              backgroundColor:
                                  ok ? const Color(0xFF059669) : Colors.red));
                        }
                      } catch (e) {
                        setState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}
