import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/services/ai_service.dart';
import 'action_helpers.dart';

class NoticeCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final AiService aiService;
  final VoidCallback onExecuted;

  const NoticeCard({
    super.key,
    required this.message,
    required this.aiService,
    required this.onExecuted,
  });

  @override
  State<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard> {
  bool _loading = false;
  bool _executed = false;

  @override
  Widget build(BuildContext context) {
    if (_executed || widget.message['executed'] == true) {
      return const ExecutionSuccess(message: 'Notice Posted Successfully');
    }

    final params = widget.message['params'] ?? {};

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Tag(label: 'OFFICIAL NOTICE', color: Colors.indigo),
                    const Icon(
                      Icons.campaign_outlined,
                      size: 18,
                      color: Colors.indigo,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  params['title'] ?? 'Important Announcement',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF312E81),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  params['body'] ?? 'No content provided.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF3730A3),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    MetaIcon(
                      icon: Icons.push_pin_outlined,
                      label:
                          params['type']?.toString().toUpperCase() ?? 'GENERAL',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  )
                else
                  ConfirmButton(
                    label: 'POST NOTICE TO SOCIETY',
                    color: Colors.indigo,
                    onTap: () => _execute(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _execute() async {
    setState(() => _loading = true);
    try {
      await widget.aiService.executeAction(widget.message['actionId']);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _executed = true;
        widget.message['executed'] = true;
      });
      widget.onExecuted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Post failed: $e')));
    }
  }
}









