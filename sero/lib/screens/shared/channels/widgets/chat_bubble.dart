import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:sero/providers/shared/channels_provider.dart';
import 'package:sero/app/theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final bool isCompact;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;
  final Function(String) onJoinDeal;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showSender,
    this.isCompact = false,
    this.onLongPress,
    this.onRetry,
    required this.onJoinDeal,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_flipped, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "Deleted message",
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ).animate().fade(),
      );
    }

    final bool isSystem = message.isSystemMessage || message.senderId == "system";

    if (isSystem) {
      if (message.smartType == 'ticket_conversion') {
        return _buildTicketConversionContent(context);
      }
      
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ).animate().fade().scale(duration: 300.ms),
      );
    }

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe)
          SizedBox(
            width: 36,
            height: 36,
            child: isCompact
                ? null
                : CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: Text(
                      message.senderName.isNotEmpty ? message.senderName[0] : '?',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                    ),
                  ),
          ),
        const SizedBox(width: 8),
        _buildBubbleContent(context),
      ],
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Visibility(
            visible: showSender && !isCompact,
            maintainSize: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                "${message.senderName} • ${message.senderFlat}",
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ),
          ),
        GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: EdgeInsets.all(message.mediaUrl != null ? 8 : 14),
            decoration: BoxDecoration(
              color: message.isOfficial
                  ? const Color(0xFFFFF7ED)
                  : (isMe ? const Color(0xFF345D7E) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: message.isOfficial
                  ? Border.all(color: const Color(0xFFFED7AA), width: 1.5)
                  : Border.all(color: isMe ? Colors.transparent : const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isOfficial)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFEA580C)),
                          const SizedBox(width: 4),
                          Text(
                            "OFFICIAL",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEA580C),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.mediaUrl != null) 
                    _buildMediaContent(context)
                  else if (message.smartType == 'group_buy')
                    _buildGroupBuyContent(context)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        message.text,
                        style: GoogleFonts.outfit(
                          color: message.isOfficial || !isMe ? const Color(0xFF1E293B) : Colors.white,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(message.createdAt),
                          style: GoogleFonts.outfit(
                            color: isMe && !message.isOfficial ? Colors.white70 : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                         if (isMe) ...[
                           const SizedBox(width: 4),
                           _buildStatusIndicator(context),
                         ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    bool isRead = message.readBy.isNotEmpty;
    bool isDelivered = message.deliveredCount > 0 || message.status == MessageStatus.delivered;
    bool isSent = message.status == MessageStatus.sent;

    if (message.status == MessageStatus.sending || message.metadata?['status'] == 'uploading') {
       return const Icon(Icons.access_time_rounded, size: 10, color: Colors.white70)
           .animate(onPlay: (c) => c.repeat())
           .fade(duration: 500.ms);
    }

    if (message.status == MessageStatus.error) {
       return GestureDetector(
         onTap: onRetry,
         child: const Icon(Icons.refresh_rounded, size: 14, color: Colors.orangeAccent),
       );
    }
    
    if (isRead) {
      return Icon(
        Icons.done_all_rounded,
        size: 13,
        color: message.isOfficial ? const Color(0xFFEA580C) : const Color(0xFF38BDF8),
      );
    }

    if (isDelivered) {
      return const Icon(
        Icons.done_all_rounded,
        size: 13,
        color: Colors.white70,
      );
    }

    if (isSent) {
      return const Icon(
        Icons.done_rounded,
        size: 13,
        color: Colors.white70,
      );
    }

    return const Icon(Icons.done_rounded, size: 13, color: Colors.white38);
  }

  Widget _buildMediaContent(BuildContext context) {
    if (message.mediaType == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              message.mediaUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
          ),
          if (message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Text(
                message.text,
                style: GoogleFonts.outfit(
                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? "Attachment",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "FILE",
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.download_rounded, color: Colors.white70),
          ],
        ),
      );
    }
  }

  Widget _buildGroupBuyContent(BuildContext context) {
    final meta = message.metadata ?? {};
    final title = meta['dealTitle'] ?? "Society Group Deal";
    final target = (meta['targetCount'] ?? 10) as int;
    final progress = (meta['joinedCount'] ?? 0) as int;
    final percent = (progress / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_rounded, size: 20, color: Color(0xFF345D7E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          message.text,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: const Color(0xFFE2E8F0),
          color: const Color(0xFF345D7E),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${(percent * 100).toInt()}% Reached",
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF345D7E))),
            Text("$progress/$target", style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => onJoinDeal(message.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF345D7E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("I'M IN", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketConversionContent(BuildContext context) {
    final description = message.metadata?['description'] ?? 'Official record created.';
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 14, color: kPrimaryGreen),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}











