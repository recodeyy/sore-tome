import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

class SuperAdminApprovalsScreen extends ConsumerWidget {
  const SuperAdminApprovalsScreen({super.key});

  static const List<String> _pendingTokens = [
    'pending',
    'onboard',
    'trial',
    'review',
  ];

  List<SuperAdminSociety> _pending(List<SuperAdminSociety> items) {
    final filtered = items.where((s) {
      final status = s.status.toLowerCase();
      return _pendingTokens.any(status.contains);
    }).toList();
    return filtered.isEmpty ? items : filtered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final societiesAsync = ref.watch(superAdminSocietiesProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SuperAdminHeader(
            title: 'Approval Queue',
            subtitle: 'Review submitted societies',
            leadingIcon: Icons.arrow_back_rounded,
            onMenu: () => Navigator.maybePop(context),
            onNotifications: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SuperAdminAsyncView<SuperAdminSocietiesPage>(
              loading: societiesAsync.isLoading,
              error: societiesAsync.hasError ? societiesAsync.error : null,
              data: societiesAsync.valueOrNull,
              onRetry: () => ref.invalidate(superAdminSocietiesProvider),
              builder: (page) {
                final items = _pending(page.items);
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: SuperAdminEmptyState(
                      icon: Icons.verified_rounded,
                      title: 'Nothing to review',
                      message:
                          'There are no societies awaiting approval right now.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final s in items) _ApprovalItem(society: s),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ApprovalItem extends StatelessWidget {
  final SuperAdminSociety society;

  const _ApprovalItem({required this.society});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SuperAdminSocietyCard(society: society),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/super-admin/kyc'),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Review & Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuperGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
