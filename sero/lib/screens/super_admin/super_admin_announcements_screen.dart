import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/super_admin/super_admin_models.dart';
import 'package:sero/providers/super_admin/super_admin_provider.dart';
import 'package:sero/widgets/super_admin/super_admin_widgets.dart';

const _audiences = <String>[
  'All Societies',
  'Active Only',
  'Trial Only',
  'Admins Only',
];

class SuperAdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const SuperAdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<SuperAdminAnnouncementsScreen> createState() =>
      _SuperAdminAnnouncementsScreenState();
}

class _SuperAdminAnnouncementsScreenState
    extends ConsumerState<SuperAdminAnnouncementsScreen> {
  final _annTitle = TextEditingController();
  final _annBody = TextEditingController();
  final _pushTitle = TextEditingController();
  final _pushBody = TextEditingController();

  String _annAudience = _audiences.first;
  String _pushAudience = _audiences.first;

  bool _sendingAnnouncement = false;
  bool _sendingPush = false;

  @override
  void dispose() {
    _annTitle.dispose();
    _annBody.dispose();
    _pushTitle.dispose();
    _pushBody.dispose();
    super.dispose();
  }

  Future<void> _send({required String channel}) async {
    final isPush = channel == 'push';
    final title = (isPush ? _pushTitle : _annTitle).text.trim();
    final body = (isPush ? _pushBody : _annBody).text.trim();
    final audience = isPush ? _pushAudience : _annAudience;

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Title and message are required'),
        ),
      );
      return;
    }

    setState(() {
      if (isPush) {
        _sendingPush = true;
      } else {
        _sendingAnnouncement = true;
      }
    });

    try {
      await ref.read(superAdminServiceProvider).createAnnouncement({
        'title': title,
        'body': body,
        'audience': audience,
        'channel': channel,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kSuperGreen,
          content: Text(isPush ? 'Push notification sent' : 'Announcement sent'),
        ),
      );
      (isPush ? _pushTitle : _annTitle).clear();
      (isPush ? _pushBody : _annBody).clear();
      ref.invalidate(superAdminAnnouncementsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text('Failed to send: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isPush) {
            _sendingPush = false;
          } else {
            _sendingAnnouncement = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(superAdminAnnouncementsProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SuperAdminHeader(
            title: 'Announcements & Push',
            subtitle: 'Broadcast to societies & residents',
            leadingIcon: Icons.arrow_back_rounded,
            onMenu: () => Navigator.maybePop(context),
            onNotifications: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Column(
              children: [
                SuperAdminSectionCard(
                  title: 'Global Announcement',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledField(
                        label: 'Title',
                        child: TextField(
                          controller: _annTitle,
                          decoration: const InputDecoration(
                            hintText: 'Announcement title',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Message',
                        child: TextField(
                          controller: _annBody,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Write your message...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Audience',
                        child: _AudienceDropdown(
                          value: _annAudience,
                          onChanged: (v) =>
                              setState(() => _annAudience = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SendButton(
                        label: 'Send Announcement',
                        icon: Icons.campaign_rounded,
                        sending: _sendingAnnouncement,
                        onPressed: () => _send(channel: 'in_app'),
                      ),
                    ],
                  ),
                ),
                SuperAdminSectionCard(
                  title: 'Push Notification',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledField(
                        label: 'Title',
                        child: TextField(
                          controller: _pushTitle,
                          decoration: const InputDecoration(
                            hintText: 'Notification title',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Message',
                        child: TextField(
                          controller: _pushBody,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Write your message...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledField(
                        label: 'Audience',
                        child: _AudienceDropdown(
                          value: _pushAudience,
                          onChanged: (v) =>
                              setState(() => _pushAudience = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SendButton(
                        label: 'Send Push Notification',
                        icon: Icons.notifications_active_rounded,
                        sending: _sendingPush,
                        onPressed: () => _send(channel: 'push'),
                      ),
                    ],
                  ),
                ),
                SuperAdminSectionCard(
                  title: 'Recent Announcements',
                  child: SuperAdminAsyncView<List<JsonMap>>(
                    loading: announcementsAsync.isLoading,
                    error: announcementsAsync.hasError
                        ? announcementsAsync.error
                        : null,
                    data: announcementsAsync.asData?.value,
                    onRetry: () =>
                        ref.invalidate(superAdminAnnouncementsProvider),
                    builder: (items) {
                      if (items.isEmpty) {
                        return const SuperAdminEmptyState(
                          icon: Icons.campaign_outlined,
                          title: 'No announcements yet',
                          message:
                              'Sent announcements will appear here.',
                        );
                      }
                      return Column(
                        children: [
                          for (final item in items)
                            _AnnouncementRow(item: item),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _AudienceDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _AudienceDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kSuperGreen),
      style: GoogleFonts.outfit(
        color: const Color(0xFF1E293B),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      items: [
        for (final a in _audiences)
          DropdownMenuItem(value: a, child: Text(a)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool sending;
  final VoidCallback onPressed;

  const _SendButton({
    required this.label,
    required this.icon,
    required this.sending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: sending ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kSuperGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kSuperGreen.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle:
              GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        icon: sending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(sending ? 'Sending...' : label),
      ),
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  final JsonMap item;

  const _AnnouncementRow({required this.item});

  String _relativeDate() {
    final raw = item['created_at'] ?? item['createdAt'];
    DateTime? dt;
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String && raw.isNotEmpty) {
      dt = DateTime.tryParse(raw);
    }
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? 'Untitled').toString();
    final audience = (item['audience'] ?? '').toString();
    final date = _relativeDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSlateBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kSlateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kSuperGreenSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: kSuperGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (audience.isNotEmpty) audience,
                    if (date.isNotEmpty) date,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
