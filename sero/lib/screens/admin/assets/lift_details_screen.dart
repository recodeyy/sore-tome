import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';
import 'package:sero/widgets/common/status_badge.dart';

class LiftDetailsScreen extends StatefulWidget {
  const LiftDetailsScreen({super.key});

  @override
  State<LiftDetailsScreen> createState() => _LiftDetailsScreenState();
}

class _LiftDetailsScreenState extends State<LiftDetailsScreen> {
  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final detail = MockAssetsData.liftDetail;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lift L-1 Details',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ── Asset Summary Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withOpacity(0.1),
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
                          detail['name'],
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail['type'],
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail['location'],
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(label: detail['status'], bgColor: const Color(0xFF059669)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Tabs ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Overview', 0),
                  _buildTab('Maintenance', 1),
                  _buildTab('Service History', 2),
                  _buildTab('Documents', 3),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Detail List ──
            _buildDetailRow(Icons.business_outlined, 'Make & Model', detail['makeModel']),
            _buildDetailRow(Icons.calendar_today_outlined, 'Installation Date', detail['installationDate']),
            _buildDetailRow(Icons.fitness_center_outlined, 'Capacity', detail['capacity']),
            _buildDetailRow(Icons.history_outlined, 'Last Service', detail['lastService']),
            _buildDetailRow(Icons.access_time_outlined, 'Next Service Due', detail['nextService'], 
                secondaryText: detail['serviceDueDays'], isUrgent: true),
            _buildDetailRow(Icons.handyman_outlined, 'AMC Provider', detail['provider']),

            const SizedBox(height: 32),

            // ── Status Section ──
            Text(
              'Status',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operational',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'All systems are normal',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIndicatorCard('Door Status', detail['doorStatus'], const Color(0xFF059669)),
                      _buildIndicatorCard('Motor Status', detail['motorStatus'], const Color(0xFF059669)),
                      _buildIndicatorCard('Power Supply', detail['powerSupply'], const Color(0xFF059669)),
                      _buildIndicatorCard('Alarm', detail['alarm'], const Color(0xFF64748B)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.build_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Raise Maintenance', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('View Logs', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_rounded, 'Dashboard', false, () {}),
            _buildNavItem(context, Icons.inventory_2_outlined, 'Assets', true, () {}),
            _buildNavItem(context, Icons.build_outlined, 'Maintenance', false, () {}),
            _buildNavItem(context, Icons.description_outlined, 'Logs', false, () {}),
            _buildNavItem(context, Icons.more_horiz_rounded, 'More', false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    bool isActive = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? kPrimaryGreen : kSlateBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {String? secondaryText, bool isUrgent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
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
              if (secondaryText != null)
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

  Widget _buildIndicatorCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? kPrimaryGreen : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: isActive ? kPrimaryGreen : const Color(0xFF94A3B8),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
