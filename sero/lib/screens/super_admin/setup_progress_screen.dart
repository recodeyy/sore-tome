import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';

class SetupProgressScreen extends ConsumerWidget {
  const SetupProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final societiesAsync = ref.watch(superAdminSocietiesProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: Text(
          'Onboarding & Setup Progress',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: societiesAsync.when(
        data: (page) {
          final items = page.items;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final soc = items[index];
              // Simulate setup progress steps based on completion rate
              final progress = soc.setupCompletion > 0 ? soc.setupCompletion : 0.65;
              final completedStepsCount = (progress * 10).toInt();

              final steps = [
                'Society profile',
                'Structure (Blocks & Wings)',
                'Admins registration',
                'Members list',
                'Billing rules configuration',
                'Payment gateway integration',
                'Communication (Notice board/Channels)',
                'Staff & Guard setup',
                'Amenities catalog',
                'Go-live checklist'
              ];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  soc.name,
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                                ),
                                Text(
                                  'ID: ${soc.id} • Status: ${soc.status.toUpperCase()}',
                                  style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}% Done',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: kPrimaryGreen, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: kPrimaryGreen,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Onboarding Steps Checklist',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      // Grid of steps
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(steps.length, (stepIdx) {
                          final isCompleted = stepIdx < completedStepsCount;
                          return Chip(
                            backgroundColor: isCompleted ? kAccentGreen.withValues(alpha: 0.1) : Colors.grey[100],
                            side: BorderSide(
                              color: isCompleted ? kAccentGreen.withValues(alpha: 0.3) : Colors.grey[300]!,
                            ),
                            avatar: Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              size: 16,
                              color: isCompleted ? kAccentGreen : Colors.grey,
                            ),
                            label: Text(
                              steps[stepIdx],
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isCompleted ? kPrimaryGreen : Colors.grey[700],
                                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'Owner: Support Agent',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.history_rounded, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'Last activity: 2 hours ago',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Onboarding reminder sent to main admin.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kPrimaryGreen,
                              side: const BorderSide(color: kPrimaryGreen),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 14),
                            label: Text('Remind', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
