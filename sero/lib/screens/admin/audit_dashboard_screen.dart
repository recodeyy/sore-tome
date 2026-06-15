import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin/audit_log_provider.dart';

class AuditDashboardScreen extends ConsumerStatefulWidget {
  const AuditDashboardScreen({super.key});

  @override
  ConsumerState<AuditDashboardScreen> createState() => _AuditDashboardScreenState();
}

class _AuditDashboardScreenState extends ConsumerState<AuditDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditLogProvider.notifier).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auditData = ref.watch(auditLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Audit & Security Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(auditLogProvider.notifier).fetchLogs(),
          )
        ],
      ),
      body: auditData.isLoading && auditData.logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (auditData.hasAnomaly)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auditData.anomalyMessage ?? 'High failure rate detected! Possible abuse or prompt injection attack.',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: auditData.logs.length,
                    itemBuilder: (context, index) {
                      final log = auditData.logs[index];
                      final isError = log.status == 'failed';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isError ? Colors.red.shade300 : Colors.grey.shade200,
                            width: isError ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            isError ? Icons.error_outline : Icons.check_circle_outline,
                            color: isError ? Colors.red : Colors.green,
                          ),
                          title: Text(
                            log.toolId.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('User: ${log.userId} • Latency: ${log.latencyMs ?? '---'} ms'),
                          trailing: Text(
                            log.createdAt.split('T').first,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Prompt/Action:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(log.action),
                                  if (isError) ...[
                                    const SizedBox(height: 12),
                                    const Text('Error Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    const SizedBox(height: 4),
                                    Text(log.errorMessage ?? 'Unknown Error', style: const TextStyle(color: Colors.red)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
