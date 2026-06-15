import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/status_badge.dart';

/// Complaint Details Screen — Complaints Module (2/2)
/// Comprehensive view of a single complaint including description, assigned staff, SLA, and timeline.
class ComplaintDetailsScreen extends StatelessWidget {
  const ComplaintDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final detail = MockComplaintsData.sampleDetail;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Complaint Details', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(detail['id'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(6)),
                  child: Text(detail['status'], style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(detail['title'], style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(detail['location'], style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(detail['date'], style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(4)),
                  child: Text(detail['priority'], style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // ── Description ──
            Text('Description', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(
              detail['description'],
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.6),
            ),

            const SizedBox(height: 24),
            // ── Assigned Staff ──
            Text('Assigned To', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 20, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, color: Color(0xFF94A3B8))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(detail['assignedTo']['name'], style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                        Text(detail['assignedTo']['role'], style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.phone_outlined, color: Color(0xFF059669), size: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // ── SLA Progress ──
            Text('SLA Progress', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(detail['sla']['deadline'], style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
                      Text('${(detail['sla']['progress'] * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: detail['sla']['progress'],
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(detail['sla']['remaining'], style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // ── Timeline ──
            Text('Timeline', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Column(
              children: (detail['timeline'] as List).map<Widget>((tl) => _TimelineItem(
                title: tl['title'],
                desc: tl['desc'],
                time: tl['time'],
                isLast: detail['timeline'].indexOf(tl) == detail['timeline'].length - 1,
                isActive: tl['status'] == 'active',
              )).toList(),
            ),

            const SizedBox(height: 40),
            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF064E3B)),
                    label: Text('Add Update', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF064E3B))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF064E3B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Mark as Resolved', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  final bool isLast;
  final bool isActive;

  const _TimelineItem({
    required this.title,
    required this.desc,
    required this.time,
    required this.isLast,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF7C3AED) : const Color(0xFF059669);
    final icon = isActive ? Icons.hourglass_empty : Icons.check;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Center(child: Icon(icon, color: color, size: 14)),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: const Color(0xFFF1F5F9)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              Text(time, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFCBD5E1))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
