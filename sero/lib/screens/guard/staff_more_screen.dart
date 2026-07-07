import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/screens/guard/staff_parcels_screen.dart';

/// Staff More tab (MR-007): links to Parcel Desk, Attendance, Assistant,
/// Profile, Settings and Notifications.
class StaffMoreScreen extends StatelessWidget {
  const StaffMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.inventory_2_rounded,
        'Parcel Desk',
        'Log deliveries and hand over',
        (BuildContext ctx) => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const StaffParcelsScreen())),
      ),
      (
        Icons.fingerprint_rounded,
        'Attendance',
        'Shift check-in and check-out',
        (BuildContext ctx) => _openAttendanceSheet(ctx),
      ),
      (
        Icons.auto_awesome_rounded,
        'Assistant',
        'Ask the SERO AI assistant',
        (BuildContext ctx) => Navigator.pushNamed(ctx, '/staff/assistant'),
      ),
      (
        Icons.person_rounded,
        'Profile',
        'Your account details',
        (BuildContext ctx) => Navigator.pushNamed(ctx, '/profile'),
      ),
      (
        Icons.settings_rounded,
        'Settings',
        'App preferences and security',
        (BuildContext ctx) => Navigator.pushNamed(ctx, '/settings'),
      ),
      (
        Icons.notifications_rounded,
        'Notifications',
        'Alerts and announcements',
        (BuildContext ctx) => Navigator.pushNamed(ctx, '/notifications'),
      ),
    ];

    return Scaffold(
      backgroundColor: kSlateBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text(
              'More',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: items.map((item) {
                return InkWell(
                  onTap: () => item.$4(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kSlateBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kLightMint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.$1, color: kPrimaryGreen, size: 22),
                        ),
                        const Spacer(),
                        Text(
                          item.$2,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 11, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openAttendanceSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _AttendanceSheet(),
    );
  }
}

class _AttendanceSheet extends StatefulWidget {
  @override
  State<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<_AttendanceSheet> {
  bool _busy = false;

  Future<void> _post(bool checkIn) async {
    setState(() => _busy = true);
    try {
      final res = await ApiService.post(
        checkIn ? '/staff-v2/attendance/check-in' : '/staff-v2/attendance/check-out',
        {},
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(checkIn ? 'Checked in.' : 'Checked out.'),
          backgroundColor: kPrimaryGreen,
        ));
      } else {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Attendance update failed (${res.statusCode})'),
          backgroundColor: kError,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mark the start or end of your shift.',
            style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _post(true),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _post(false),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Check Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryGreen,
                    side: const BorderSide(color: kPrimaryGreen, width: 1.4),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
