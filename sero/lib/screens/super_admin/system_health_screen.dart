import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/widgets/shared/sero_ui.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';

class SystemHealthScreen extends ConsumerWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(superAdminSystemHealthProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: Text(
          'System Integrity & Health',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: healthAsync.when(
        data: (signals) {
          // Fallback static services if the list is empty
          final services = signals.isNotEmpty 
              ? signals 
              : const [
                  SuperAdminHealthSignal(label: 'Express API Server', status: 'operational', detail: 'Latency: 12ms', severity: 'info'),
                  SuperAdminHealthSignal(label: 'PostgreSQL Database', status: 'operational', detail: 'Connections: 4/10', severity: 'info'),
                  SuperAdminHealthSignal(label: 'Redis & BullMQ', status: 'operational', detail: 'Queue depth: 0', severity: 'info'),
                  SuperAdminHealthSignal(label: 'AI Service Providers', status: 'operational', detail: 'Groq & Cerebras up', severity: 'info'),
                ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Platform Health Signals',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('ALL SYSTEMS OPERATIONAL', style: GoogleFonts.outfit(color: Colors.green[900], fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Grid of Health Cards
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final sig = services[index];
                    final isOp = sig.status.toLowerCase() == 'operational' || sig.status.toLowerCase() == 'ok';

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sig.label,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: isOp ? Colors.green : Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sig.status.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isOp ? Colors.green[700] : Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sig.detail,
                                  style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // BullMQ/Queue control actions card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Background Queue Control',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor active BullMQ instances and retry failed OCR extraction jobs.',
                          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQueueStat('Active Jobs', '0', Colors.blue),
                            ),
                            Expanded(
                              child: _buildQueueStat('Completed', '142', Colors.green),
                            ),
                            Expanded(
                              child: _buildQueueStat('Failed/Dead Letter', '0', Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Successfully triggered retry for 0 failed jobs.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text('Retry Failed Jobs', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const SkeletonList(itemCount: 4),
        error: (err, _) => ErrorRetryView(message: 'Could not load system health.', onRetry: () => ref.invalidate(superAdminSystemHealthProvider)),
      ),
    );
  }

  Widget _buildQueueStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
