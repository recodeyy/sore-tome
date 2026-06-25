import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

class ApiAccessScreen extends StatefulWidget {
  const ApiAccessScreen({super.key});

  @override
  State<ApiAccessScreen> createState() => _ApiAccessScreenState();
}

class _ApiAccessScreenState extends State<ApiAccessScreen> {
  String? _generatedKey;
  String? _generatedSecret;
  bool _keyGenerated = false;

  final List<Map<String, String>> _deliveryLogs = [
    {
      'event': 'payment.captured',
      'url': 'https://webhook.mysociety.com/pay',
      'status': '200 OK',
      'timestamp': '2026-06-16T03:10:00Z',
    },
    {
      'event': 'member.created',
      'url': 'https://webhook.mysociety.com/sync',
      'status': '500 Error',
      'timestamp': '2026-06-16T02:45:00Z',
    },
    {
      'event': 'notice.published',
      'url': 'https://webhook.mysociety.com/announcements',
      'status': '200 OK',
      'timestamp': '2026-06-16T01:30:00Z',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: Text(
          'API Access & Webhooks',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Integrations Control Plane',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryGreen),
            ),
            const SizedBox(height: 16),

            // Credentials Generator Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Client Credentials',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate API keys for third-party billing, utility syncing, or gate automation services. Secret keys are displayed once and cannot be recovered.',
                      style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                    ),
                    const Divider(height: 32),
                    if (_keyGenerated) ...[
                      _buildCredentialRow('Client Key ID', _generatedKey!),
                      const SizedBox(height: 12),
                      _buildCredentialRow('Secret Key', _generatedSecret!, isSecret: true),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Make sure to copy the Secret Key now. It will not be shown again.',
                                style: GoogleFonts.outfit(color: Colors.amber[900], fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _generatedKey = 'client_key_${DateTime.now().millisecondsSinceEpoch}';
                          _generatedSecret = 'sk_sero_${List.generate(32, (i) => i.toRadixString(16)).join().substring(0, 32)}';
                          _keyGenerated = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.vpn_key_rounded, size: 18),
                      label: Text('Generate New Credentials', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Webhook Timeline/Logs Card
            Text(
              'Webhook Delivery Logs',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _deliveryLogs.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final log = _deliveryLogs[index];
                  final isSuccess = log['status'] == '200 OK';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                          color: isSuccess ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    log['event']!,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    log['timestamp']!.substring(11, 16),
                                    style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['url']!,
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Response: ${log['status']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSuccess ? Colors.green : Colors.red,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, {bool isSecret = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied to clipboard.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
