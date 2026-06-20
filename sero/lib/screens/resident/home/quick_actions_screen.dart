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
import 'package:sero/screens/resident/notifications/notifications_center_screen.dart';

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
      _QA('Pay Bill', Icons.payments_rounded, (c) => const ResidentFundsScreen()),
      _QA('My Messages', Icons.forum_rounded, null),
      _QA('Visitors', Icons.people_alt_rounded, (c) => const VisitorApprovalScreen()),
      _QA('Raise Complaint', Icons.report_problem_rounded, (c) => const PostIssueScreen()),
      _QA('Amenities', Icons.pool_rounded, (c) => const FacilitiesScreen()),
      _QA('Book Slot', Icons.event_available_rounded, (c) => const FacilitiesScreen()),
      _QA('Notice Board', Icons.campaign_rounded, (c) => const ResidentChannelsScreen()),
      _QA('Events', Icons.celebration_rounded, null),
      _QA('Polls', Icons.how_to_vote_rounded, (c) => const PollsScreen()),
      _QA('Marketplace', Icons.storefront_rounded, null),
      _QA('Carpool', Icons.directions_car_rounded, null),
      _QA('Lost & Found', Icons.search_rounded, null),
      _QA('Documents', Icons.folder_rounded, null),
      _QA('Society Rules', Icons.gavel_rounded, (c) => const ResidentRulesScreen()),
      _QA('Emergency', Icons.emergency_rounded, (c) => const EmergencyHomeScreen()),
      _QA('Contact Admin', Icons.support_agent_rounded, (c) => const ResidentIssuesScreen()),
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
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: kPrimaryGreen.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(qa.icon, color: kPrimaryGreen, size: 26),
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
  _QA(this.label, this.icon, this.builder);
}
