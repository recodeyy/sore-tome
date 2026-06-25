import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:sero/providers/shared/channels_provider.dart';

class ChannelVaultScreen extends ConsumerWidget {
  final Channel channel;

  const ChannelVaultScreen({super.key, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(channelMessagesProvider(channel.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hub Vault", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
            Text("Official Records & Media", style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: messagesAsync.when(
        data: (messages) {
          final notices = messages.where((m) => m.isOfficial && !m.isDeleted).toList();
          final media = messages.where((m) => m.mediaUrl != null && !m.isDeleted).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: const Color(0xFF345D7E),
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    indicatorColor: const Color(0xFF345D7E),
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: "NOTICES"),
                      Tab(text: "GALLERY"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildNoticesList(notices),
                      _buildMediaGrid(media),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF345D7E))),
        error: (e, _) => Center(child: Text("Vault offline. Check connectivity.")),
      ),
    );
  }

  Widget _buildNoticesList(List<ChatMessage> notices) {
    if (notices.isEmpty) return _buildEmptyState(Icons.campaign_outlined, "No Official Notices", "Admins haven't stamped any notices yet.");

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: notices.length,
      itemBuilder: (context, index) {
        final notice = notices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFF7ED)),
            boxShadow: [
              BoxShadow(color: Colors.orange.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 16, color: Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  Text(
                    "OFFICIAL STAMP",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFEA580C), letterSpacing: 1.2),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(notice.createdAt),
                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notice.text,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              Text(
                "Authorized by ${notice.senderName}",
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ).animate().slideY(begin: 0.1, end: 0, delay: (index * 50).ms);
      },
    );
  }

  Widget _buildMediaGrid(List<ChatMessage> media) {
    if (media.isEmpty) return _buildEmptyState(Icons.image_outlined, "Gallery Empty", "No images or documents shared in this hub.");

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        if (item.mediaType == 'image') {
          return Image.network(item.mediaUrl!, fit: BoxFit.cover).animate().fadeIn(delay: (index * 30).ms);
        } else {
          return Container(
            color: const Color(0xFF345D7E).withValues(alpha: 0.1),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF345D7E)),
          );
        }
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}









