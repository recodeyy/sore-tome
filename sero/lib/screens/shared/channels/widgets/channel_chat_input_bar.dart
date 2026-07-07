import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChannelChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onPickImage;
  final VoidCallback onSendMessage;
  final Function(String) onChanged;
  final bool canChat;

  const ChannelChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onPickImage,
    required this.onSendMessage,
    required this.onChanged,
    this.canChat = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!canChat) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        width: double.infinity,
        color: Colors.white,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                "ADMINS ONLY CHANNEL",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onPickImage,
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF345D7E), size: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: onChanged,
                onSubmitted: (_) => onSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFF345D7E), shape: BoxShape.circle),
              child: IconButton(
                onPressed: onSendMessage,
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}






