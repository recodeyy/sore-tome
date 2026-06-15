import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

class AiJobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const AiJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final status = job['status'] ?? 'processing';
    final progress = (job['progress'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  job['document_type'] == 'rules'
                      ? Icons.gavel
                      : Icons.description_outlined,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['file_name'] ?? 'Untitled Document',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${job['document_type']?.toString().toUpperCase()} • AI V3.10 Ingestion',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          if (status == 'processing' || status == 'uploading') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: const Color(0xFFF1F5F9),
                color: kPrimaryGreen,
                minHeight: 6,
              ),
            ),
          ],
          if (status == 'failed' && job['error'] != null) ...[
            const SizedBox(height: 8),
            Text(
              job['error'],
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.redAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    Color bg = Colors.grey.shade50;

    switch (status.toLowerCase()) {
      case 'indexed':
        color = kPrimaryGreen;
        bg = const Color(0xFFF0FDF4);
        break;
      case 'processing':
      case 'uploading':
        color = Colors.blue;
        bg = const Color(0xFFEFF6FF);
        break;
      case 'failed':
        color = Colors.red;
        bg = const Color(0xFFFEF2F2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        status,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}







