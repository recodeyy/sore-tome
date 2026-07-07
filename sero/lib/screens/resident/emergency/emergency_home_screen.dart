import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/resident/emergency_provider.dart';
import 'package:sero/screens/resident/visitors/visitor_approval_screen.dart';
import 'package:sero/screens/resident/issues/post_issue_screen.dart';

/// Emergency Home + Emergency Contacts (design: emergency.png screens 1 & 2).
///
/// LIVE / STATIC SOURCES:
///  - National emergency NUMBERS (Ambulance 108 / Police 100 / Fire 101) are
///    fixed statutory values rendered as static content (allowed by spec).
///  - Society Contacts -> emergencyContactsProvider (probes /society/profile;
///    honest empty state when no society contacts are configured server-side).
///  - "Quick SOS": the backend exposes no SOS dispatch endpoint, so the button
///    surfaces the national numbers + a truthful note instead of faking a send.
///  - Quick Access tiles route to real existing screens (security desk ->
///    visitor approvals, raise issue -> post issue).
class EmergencyHomeScreen extends ConsumerWidget {
  const EmergencyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kSlateBg,
        appBar: AppBar(
          flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: kPremiumGradient)),
          title: Text('Emergency',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
          bottom: TabBar(
            indicatorColor: kAccentGreen,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Home'), Tab(text: 'Contacts')],
          ),
        ),
        body: const TabBarView(children: [_EmergencyHomeTab(), _EmergencyContactsTab()]),
      ),
    );
  }
}

class _EmergencyHomeTab extends StatelessWidget {
  const _EmergencyHomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── SOS banner ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In an Emergency?',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text("We're here to help.",
                        style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showSosSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.sos_rounded),
                      label: Text('Quick SOS', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 56),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _label('Quick Access'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _quickTile(context, Icons.security_rounded, 'Security\nOffice',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorApprovalScreen()))),
            _quickTile(context, Icons.medical_services_rounded, 'First Aid', null),
            _quickTile(context, Icons.local_fire_department_rounded, 'Fire\nSafety', null),
            _quickTile(context, Icons.build_rounded, 'Maintenance',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostIssueScreen()))),
          ],
        ),
        const SizedBox(height: 24),

        _label('Emergency Numbers'),
        const SizedBox(height: 12),
        _numberRow(context, Icons.local_hospital_rounded, const Color(0xFFDC2626), 'Ambulance', '108'),
        _numberRow(context, Icons.local_police_rounded, kPrimaryBlue, 'Police', '100'),
        _numberRow(context, Icons.local_fire_department_rounded, const Color(0xFFEA580C), 'Fire Brigade', '101'),
      ],
    );
  }

  void _showSosSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick SOS',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: kDeepNavy)),
            const SizedBox(height: 8),
            Text(
              'In-app SOS dispatch is not yet connected to the society control room. '
              'Please call one of the national emergency numbers below directly.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            _numberRow(context, Icons.local_hospital_rounded, const Color(0xFFDC2626), 'Ambulance', '108'),
            _numberRow(context, Icons.local_police_rounded, kPrimaryBlue, 'Police', '100'),
            _numberRow(context, Icons.local_fire_department_rounded, const Color(0xFFEA580C), 'Fire Brigade', '101'),
          ],
        ),
      ),
    );
  }

  Widget _quickTile(BuildContext context, IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap ??
          () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This contact is not yet configured for your society.'))),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: enabled ? kPrimaryGreen.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: enabled ? kPrimaryGreen : const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: kDeepNavy)),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1.2));
}

Widget _numberRow(BuildContext context, IconData icon, Color color, String label, String number) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kSlateBorder),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
        ),
        Text(number,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: color, fontSize: 18)),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF94A3B8)),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: number));
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$label number copied: $number')));
          },
        ),
      ],
    ),
  );
}

class _EmergencyContactsTab extends ConsumerWidget {
  const _EmergencyContactsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    return RefreshIndicator(
      color: kPrimaryGreen,
      onRefresh: () async => ref.invalidate(emergencyContactsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _label('Society Contacts'),
          const SizedBox(height: 12),
          contactsAsync.when(
            loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: kPrimaryGreen))),
            error: (e, _) => _emptyBox(Icons.contact_phone_outlined, 'Could not load society contacts'),
            data: (contacts) {
              if (contacts.isEmpty) {
                return _emptyBox(Icons.contact_phone_outlined,
                    'No society emergency contacts have been configured yet');
              }
              return Column(
                children: contacts
                    .map((c) => _contactRow(context, c.name, c.role, c.phone))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          _label('National Emergency Numbers'),
          const SizedBox(height: 12),
          _numberRow(context, Icons.local_hospital_rounded, const Color(0xFFDC2626), 'Ambulance', '108'),
          _numberRow(context, Icons.local_police_rounded, kPrimaryBlue, 'Police', '100'),
          _numberRow(context, Icons.local_fire_department_rounded, const Color(0xFFEA580C), 'Fire Brigade', '101'),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, String name, String role, String phone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 22, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, color: kPrimaryGreen)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Contact' : name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 14)),
                if (role.isNotEmpty)
                  Text(role, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
                Text(phone, style: GoogleFonts.outfit(color: kPrimaryGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF94A3B8)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Number copied: $phone')));
            },
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1.2));

  Widget _emptyBox(IconData icon, String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSlateBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
}
