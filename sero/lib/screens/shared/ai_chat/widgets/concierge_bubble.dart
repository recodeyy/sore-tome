import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/ai_service.dart';
import 'action_cards.dart';

class ConciergeBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isUser;
  final AiService aiService;
  final String userRole;
  final VoidCallback onActionExecuted;

  const ConciergeBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.aiService,
    required this.userRole,
    required this.onActionExecuted,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'admin';
    final content =
        message['reply'] ??
        message['content'] ??
        message['partialData'] ??
        'No response content';
    final isDraft = message['type'] == 'draft' || (message['isDraft'] ?? false);

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message['imagePath'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(File(message['imagePath'])),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: kSlateBorder.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: kPrimaryGreen,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Text(
                content,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Just now',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAdmin ? Icons.hub_rounded : Icons.smart_toy_rounded,
                size: 16,
                color: isAdmin ? const Color(0xFF1E293B) : kPrimaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                isAdmin ? 'COMMAND AI' : 'SERO AI',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: isAdmin ? const Color(0xFF1E293B) : kPrimaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              border: Border.all(color: kSlateBorder.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
                if (message['warning'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message['warning'],
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF9A3412),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isDraft &&
                    message['title'] != null &&
                    message['content'] != null) ...[
                  const SizedBox(height: 20),
                  DraftCard(
                    title: message['title'] ?? 'Draft Notice',
                    body: message['content'] ?? '',
                  ),
                ],
                if (message['type'] == 'action' &&
                    message['actionId'] != null) ...[
                  const SizedBox(height: 20),
                  if (message['tool'] == 'create_complaint')
                    ComplaintCard(
                      message: message,
                      aiService: aiService,
                      onExecuted: onActionExecuted,
                    )
                  else if (message['tool'] == 'create_notice')
                    NoticeCard(
                      message: message,
                      aiService: aiService,
                      onExecuted: onActionExecuted,
                    )
                  else if (message['tool'] == 'log_expense')
                    ExpenseCard(
                      message: message,
                      aiService: aiService,
                      onExecuted: onActionExecuted,
                    )
                  else
                    ProposedActionCard(
                      message: message,
                      aiService: aiService,
                      onExecuted: onActionExecuted,
                    ),
                ],
                if (message['sources'] != null &&
                    (message['sources'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (message['sources'] as List)
                        .map(
                          (s) => SourcesBadge(
                            file: s['file']?.toString() ?? 'Unknown',
                            page: s['page']?.toString() ?? '0',
                            snippet: s['snippet']?.toString(),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Just now',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class SourcesBadge extends StatelessWidget {
  final String file;
  final String page;
  final String? snippet;

  const SourcesBadge({
    super.key,
    required this.file,
    required this.page,
    this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 10,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$file ${page != "0" ? "(P. $page)" : ""}',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (snippet != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: snippet!,
              preferBelow: false,
              child: const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}











