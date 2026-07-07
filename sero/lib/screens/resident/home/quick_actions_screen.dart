import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/screens/resident/funds/resident_funds_screen.dart';
import 'package:sero/screens/resident/issues/resident_issues_screen.dart';
import 'package:sero/screens/resident/issues/post_issue_screen.dart';
import 'package:sero/screens/resident/facilities/facilities_screen.dart';
import 'package:sero/screens/resident/polls/polls_screen.dart';
import 'package:sero/screens/resident/visitors/visitor_approval_screen.dart';
import 'package:sero/screens/resident/rules/resident_rules_screen.dart';
import 'package:sero/screens/resident/channels/resident_channels_screen.dart';
import 'package:sero/screens/resident/emergency/emergency_home_screen.dart';
import 'package:sero/screens/resident/parking/my_parking_screen.dart';
import 'package:sero/screens/resident/events/resident_events_screen.dart';
import 'package:sero/screens/resident/notifications/notifications_center_screen.dart';
import 'package:sero/screens/resident/marketplace/marketplace_screen.dart';
import 'package:sero/screens/resident/carpool/carpool_screen.dart';
import 'package:sero/screens/resident/lost_found/lost_found_screen.dart';
import 'package:sero/screens/resident/documents/documents_screen.dart';
import 'package:sero/screens/resident/bookings/my_bookings_screen.dart';

/// Full Quick Actions grid (design: home.png screen 2) + Refer & Earn card.
///
/// Each operational tile routes to a real, already-wired resident destination
/// (issues, facilities, polls, visitors, funds, rules, community, emergency).
/// Tiles for features with NO backend yet (My Messages, Events, Marketplace,
/// Carpool, Lost & Found, Documents) open a truthful "not available" placeholder
/// rather than fabricating data.
class QuickActionsScreen extends ConsumerWidget {
  const QuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <_QA>[
      _QA('Pay Bill', Icons.payments_rounded, (c) => const ResidentFundsScreen(), const Color(0xFF10B981)),
      _QA('My Messages', Icons.forum_rounded, (c) => const ResidentChannelsScreen(), const Color(0xFF3B82F6)),
      _QA('Visitors', Icons.people_alt_rounded, (c) => const VisitorApprovalScreen(), const Color(0xFF06B6D4)),
      _QA('Raise Complaint', Icons.report_problem_rounded, (c) => const PostIssueScreen(), const Color(0xFFEF4444)),
      _QA('Amenities', Icons.pool_rounded, (c) => const FacilitiesScreen(), const Color(0xFF14B8A6)),
      _QA('Book Slot', Icons.event_available_rounded, (c) => const FacilitiesScreen(), const Color(0xFF6366F1)),
      _QA('My Parking', Icons.local_parking_rounded, (c) => const MyParkingScreen(), const Color(0xFF8B5CF6)),
      _QA('Notice Board', Icons.campaign_rounded, (c) => const ResidentChannelsScreen(), const Color(0xFFF59E0B)),
      _QA('Events', Icons.celebration_rounded, (c) => const ResidentEventsScreen(), const Color(0xFFEC4899)),
      _QA('Polls', Icons.how_to_vote_rounded, (c) => const PollsScreen(), const Color(0xFF2563EB)),
      _QA('Marketplace', Icons.storefront_rounded, (c) => const MarketplaceScreen(), const Color(0xFFF97316)),
      _QA('Carpool', Icons.directions_car_rounded, (c) => const CarpoolScreen(), const Color(0xFF059669)),
      _QA('Lost & Found', Icons.travel_explore_rounded, (c) => const LostFoundScreen(), const Color(0xFFA855F7)),
      _QA('Documents', Icons.folder_rounded, (c) => const DocumentsScreen(), const Color(0xFF0EA5E9)),
      _QA('My Bookings', Icons.event_note_rounded, (c) => const MyBookingsScreen(), const Color(0xFF65A30D)),
      _QA('Society Rules', Icons.gavel_rounded, (c) => const ResidentRulesScreen(), const Color(0xFFD97706)),
      _QA('Emergency', Icons.emergency_rounded, (c) => const EmergencyHomeScreen(), const Color(0xFFDC2626)),
      _QA('Contact Admin', Icons.support_agent_rounded, (c) => const ResidentIssuesScreen(), const Color(0xFF16A34A)),
    ];

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: kPremiumGradient)),
        title: Text('Quick Actions',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const NotificationsCenterScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (_, i) => _tile(context, actions[i]),
          ),
          const SizedBox(height: 20),
          _referCard(),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, _QA qa) {
    return GestureDetector(
      onTap: () {
        if (qa.builder != null) {
          Navigator.push(context, MaterialPageRoute(builder: (c) => qa.builder!(c)));
        } else {
          _showUnavailable(context, qa.label);
        }
      },
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [qa.color.withValues(alpha: 0.18), qa.color.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: qa.color.withValues(alpha: 0.22)),
            ),
            child: Icon(qa.icon, color: qa.color, size: 27),
          ),
          const SizedBox(height: 6),
          Text(qa.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: kDeepNavy)),
        ],
      ),
    );
  }

  void _showUnavailable(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon — not yet available for your society.')),
    );
  }

  Widget _referCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kEmeraldSkyGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Refer & Earn',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Invite your friends to join the society app',
                    style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPrimaryGreen,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
                    disabledForegroundColor: kPrimaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Refer Now (soon)', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 56),
        ],
      ),
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext)? builder;
  final Color color;
  _QA(this.label, this.icon, this.builder, [this.color = kPrimaryGreen]);
}
