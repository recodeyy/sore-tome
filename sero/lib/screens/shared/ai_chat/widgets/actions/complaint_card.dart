import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/services/ai_service.dart';
import 'action_helpers.dart';

class ComplaintCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final AiService aiService;
  final VoidCallback onExecuted;

  const ComplaintCard({
    super.key,
    required this.message,
    required this.aiService,
    required this.onExecuted,
  });

  @override
  State<ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<ComplaintCard> {
  bool _loading = false;
  bool _executed = false;

  @override
  Widget build(BuildContext context) {
    if (_executed || widget.message['executed'] == true) {
      return const ExecutionSuccess(message: 'Complaint Filed Successfully');
    }

    final params = widget.message['params'] ?? {};
    final priority = params['priority']?.toString().toLowerCase() ?? 'medium';

    Color priorityColor = Colors.orange;
    if (priority == 'high') priorityColor = Colors.red;
    if (priority == 'low') priorityColor = Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEDD5)),
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
                    Tag(label: priority.toUpperCase(), color: priorityColor),
                    const Icon(
                      Icons.emergency_outlined,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  params['title'] ?? 'Maintenance Request',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C2D12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  params['description'] ?? 'No description provided.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF9A3412),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    MetaIcon(
                      icon: Icons.location_on_outlined,
                      label: params['location'] ?? 'Common Area',
                    ),
                    const SizedBox(width: 16),
                    const MetaIcon(
                      icon: Icons.timer_outlined,
                      label: 'Res: 24-48h',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const MetaIcon(
                  icon: Icons.person_search_outlined,
                  label: 'Unassigned (AI Triage Phase)',
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD97706)),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() => _loading = true);
                        try {
                          await widget.aiService.executeAction(
                            widget.message['actionId'],
                          );
                          setState(() {
                            _loading = false;
                            _executed = true;
                            widget.message['executed'] = true;
                          });
                          widget.onExecuted();
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _loading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to file complaint: $e'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirm Issue Report',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
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









