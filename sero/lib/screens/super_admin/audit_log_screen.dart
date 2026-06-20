import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(superAdminAuditLogsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: Text(
          'Immutable Platform Audit Logs',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'No audit logs recorded.',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isSuccess = log.status.toLowerCase() == 'success' || log.status.toLowerCase() == 'completed' || log.status.toLowerCase() == 'proposed';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: isSuccess ? Colors.green[50] : Colors.red[50],
                        child: Icon(
                          isSuccess ? Icons.security_rounded : Icons.gpp_bad_rounded,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log.title,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (log.occurredAt != null)
                                  Text(
                                    log.occurredAt!.toLocal().toString().substring(0, 19),
                                    style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 11),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.subtitle,
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Actor: ${log.actor}',
                                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSuccess ? Colors.green[100] : Colors.red[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log.status.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSuccess ? Colors.green[900] : Colors.red[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
        error: (err, _) => Center(child: Text('Error loading audit logs: $err')),
      ),
    );
  }
}
