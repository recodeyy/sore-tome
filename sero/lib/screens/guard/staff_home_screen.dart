import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/visitor.dart';
import 'package:sero/providers/shared/visitors_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// Staff Home tab (MR-007): current shift card with attendance check-in/out,
/// gate counts pulled from `/guard/visitors`, and a quick-actions grid that
/// jumps to the other shell tabs.
class StaffHomeScreen extends ConsumerStatefulWidget {
  /// Lets quick actions switch the surrounding [StaffShell] tab
  /// (0 Home, 1 Gate, 2 Tasks, 3 Security, 4 More).
  final ValueChanged<int>? onGoToTab;

  const StaffHomeScreen({super.key, this.onGoToTab});

  @override
  ConsumerState<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends ConsumerState<StaffHomeScreen> {
  bool _attendanceBusy = false;

  /// null = unknown (endpoint unavailable) → show both buttons.
  bool? _checkedIn;
  String? _shiftLabel;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    // Best-effort: the attendance read endpoint may not exist yet; the
    // check-in/out POST routes are the contract this card is wired to.
    try {
      final res = await ApiService.get('/staff-v2/attendance/me');
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final att = (data is Map)
            ? (data['attendance'] ?? data['data'] ?? data)
            : null;
        if (att is Map) {
          final checkIn = att['check_in'] ?? att['checkInTime'] ?? att['checkedInAt'];
          final checkOut = att['check_out'] ?? att['checkOutTime'] ?? att['checkedOutAt'];
          setState(() {
            _checkedIn = checkIn != null && checkOut == null;
            final shift = att['shift'] ?? att['shiftName'];
            if (shift != null) _shiftLabel = shift.toString();
          });
        }
      }
    } catch (_) {/* card falls back to static mode */}
  }

  Future<void> _attendance(bool checkIn) async {
    setState(() => _attendanceBusy = true);
    try {
      final res = await ApiService.post(
        checkIn ? '/staff-v2/attendance/check-in' : '/staff-v2/attendance/check-out',
        {},
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _checkedIn = checkIn);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(checkIn ? 'Checked in. Have a good shift!' : 'Checked out. See you next shift.'),
          backgroundColor: kPrimaryGreen,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Attendance update failed (${res.statusCode})'),
          backgroundColor: kError,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _attendanceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitorsAsync = ref.watch(guardVisitorsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimaryGreen,
          onRefresh: () async {
            ref.invalidate(guardVisitorsProvider);
            await _loadAttendance();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              Text(
                'On Duty',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your gate console and shift tools',
                style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
              ),
              const SizedBox(height: 16),
              _shiftCard(),
              const SizedBox(height: 16),
              _countsRow(visitorsAsync),
              const SizedBox(height: 20),
              Text(
                'Quick Actions',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _quickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shiftCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kPremiumGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shiftLabel ?? 'Current Shift — Main Gate',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _checkedIn == null
                          ? 'Mark your attendance below'
                          : (_checkedIn! ? 'You are checked in' : 'You are checked out'),
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_checkedIn != null)
                StatusChip(
                  label: _checkedIn! ? 'ON DUTY' : 'OFF DUTY',
                  semantic: _checkedIn! ? ChipSemantic.success : ChipSemantic.neutral,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_checkedIn != true)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _attendanceBusy ? null : () => _attendance(true),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              if (_checkedIn == null) const SizedBox(width: 10),
              if (_checkedIn != false)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _attendanceBusy ? null : () => _attendance(false),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Check Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                      minimumSize: const Size(0, 46),
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

  Widget _countsRow(AsyncValue<List<Visitor>> visitorsAsync) {
    return visitorsAsync.when(
      loading: () => const SkeletonCard(height: 92, margin: EdgeInsets.zero),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: kError, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Could not load gate counts',
                style: GoogleFonts.outfit(fontSize: 13, color: kTextSecondary),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(guardVisitorsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (visitors) {
        final expected = visitors
            .where((v) => v.status == 'expected' || v.status == 'pre_approved')
            .length;
        final pending = visitors.where((v) => v.status == 'pending').length;
        final inside = visitors
            .where((v) => v.status == 'approved' && v.exitTime == null)
            .length;
        return Row(
          children: [
            _countCard('Expected', expected, Icons.schedule_rounded, kInfo),
            const SizedBox(width: 10),
            _countCard('Pending', pending, Icons.hourglass_top_rounded, kWarning),
            const SizedBox(width: 10),
            _countCard('Inside', inside, Icons.meeting_room_rounded, kAccentGreen),
          ],
        );
      },
    );
  }

  Widget _countCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onGoToTab?.call(1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 11, color: kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      (Icons.person_add_alt_1_rounded, 'New Visitor', () => widget.onGoToTab?.call(1)),
      (Icons.inventory_2_outlined, 'Log Parcel', () => widget.onGoToTab?.call(1)),
      (Icons.sos_rounded, 'SOS Alerts', () => widget.onGoToTab?.call(3)),
      (Icons.fingerprint_rounded, 'Attendance', () {
        if (_checkedIn == true) {
          _attendance(false);
        } else {
          _attendance(true);
        }
      }),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: actions.map((a) {
        return InkWell(
          onTap: a.$3,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSlateBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: kLightMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a.$1, color: kPrimaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
