import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChannelPremiumCard extends StatelessWidget {
  final dynamic channel;

  const ChannelPremiumCard({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.chat_bubble_outline_rounded;
    Color color = const Color(0xFF3B82F6);
    if (channel.name.toLowerCase().contains("announcement")) {
      icon = Icons.hub_rounded;
      color = const Color(0xFF345D7E);
    } else if (channel.name.toLowerCase().contains("security")) {
      icon = Icons.shield_outlined;
      color = const Color(0xFFEF4444);
    } else if (channel.name.toLowerCase().contains("maintenance")) {
      icon = Icons.handyman_outlined;
      color = const Color(0xFF8B5CF6);
    } else if (channel.name.toLowerCase().contains("social")) {
      icon = Icons.campaign_rounded;
      color = const Color(0xFF0EA5E9);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      channel.description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ],
      ),
    );
  }
}

// SocietyOperationsHub removed as per user request

// ModeratorsCard removed - moved to Hub Intelligence settings list

// NewChannelCTA removed - replaced by compact header action button






