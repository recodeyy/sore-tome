import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/channels_provider.dart';

class OfficialNoticeBar extends StatelessWidget {
  final AsyncValue<List<ChatMessage>> messagesState;

  const OfficialNoticeBar({super.key, required this.messagesState});

  @override
  Widget build(BuildContext context) {
    return messagesState.maybeWhen(
      data: (messages) {
        final officialOnes = messages.where((m) => m.isOfficial && !m.isDeleted).toList();
        if (officialOnes.isEmpty) return const SizedBox.shrink();

        return IgnorePointer(
          ignoring: true,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Color(0xFFEA580C), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "PINNED: ${officialOnes.first.text}",
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF9A3412)),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFEA580C), size: 18),
              ],
            ),
          ).animate().slideY(begin: -0.2),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}









