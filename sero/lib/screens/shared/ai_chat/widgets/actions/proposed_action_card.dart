import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/ai_service.dart';
import 'action_helpers.dart';

class ProposedActionCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final AiService aiService;
  final VoidCallback onExecuted;

  const ProposedActionCard({
    super.key,
    required this.message,
    required this.aiService,
    required this.onExecuted,
  });

  @override
  State<ProposedActionCard> createState() => _ProposedActionCardState();
}

class _ProposedActionCardState extends State<ProposedActionCard> {
  bool _loading = false;
  bool _executed = false;
  int _secondsRemaining = 600; // 10 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startExpiry();
  }

  void _startExpiry() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_executed || widget.message['executed'] == true) {
      return const ExecutionSuccess(message: 'Action Executed Successfully');
    }

    final isExpired = _secondsRemaining <= 0;
    final tool = widget.message['tool'] ?? 'Unnamed Tool';
    final params = widget.message['params'] ?? {};

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? Colors.red.shade100
              : kSlateBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: isExpired ? Colors.grey : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI ACTION PROPOSAL',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color:
                            isExpired ? Colors.grey : const Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  isExpired
                      ? 'EXPIRED'
                      : '${(_secondsRemaining / 60).floor()}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isExpired ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayTitle(tool, params),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getDisplaySubtitle(tool, params),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                _ProposalDetail(
                  label: 'Target',
                  value: widget.message['target']?.toString() ??
                      widget.message['societyId']?.toString() ??
                      'Current authorized society',
                ),
                _ProposalDetail(
                  label: 'Permission',
                  value: widget.message['permission']?.toString() ??
                      'Checked by backend on confirmation',
                ),
                _ProposalDetail(
                  label: 'Approval',
                  value: widget.message['approvalRequired'] == true
                      ? 'Approval required before final execution'
                      : 'No extra approval reported',
                ),
                _ProposalDetail(
                  label: 'Reference',
                  value: widget.message['requestId']?.toString() ??
                      widget.message['actionId']?.toString() ??
                      'Pending',
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: kPrimaryGreen),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isExpired
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Edit flow requires backend proposal editing support.',
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _secondsRemaining = 0);
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isExpired ? null : _confirmAction,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              )),
                          child: Text(
                            'Confirm & Save',
                            style:
                                GoogleFonts.outfit(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction() async {
    setState(() => _loading = true);
    try {
      await widget.aiService.executeAction(widget.message['actionId']);
      setState(() {
        _loading = false;
        _executed = true;
        widget.message['executed'] = true;
      });
      widget.onExecuted();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action confirmed!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Execution failed: $e')),
      );
    }
  }

  String _getDisplayTitle(String tool, Map params) {
    if (tool == 'create_notice') {
      return 'Post Notice: ${params['title'] ?? 'Draft Notice'}';
    }
    if (tool == 'log_expense') {
      return 'Log Expense: ₹${params['amount'] ?? '0'}';
    }
    if (tool == 'create_complaint') {
      return 'Report Issue: ${params['title'] ?? 'Maintenance Request'}';
    }
    return tool.replaceAll('_', ' ').toUpperCase();
  }

  String _getDisplaySubtitle(String tool, Map params) {
    if (tool == 'create_notice') {
      return params['body']?.toString().substring(0, 50) ?? 'No content';
    }
    if (tool == 'log_expense') {
      return 'Vendor: ${params['vendor']}\nCategory: ${params['category']}';
    }
    if (tool == 'create_complaint') {
      return 'Location: ${params['location'] ?? 'Common Area'}\nPriority: ${params['priority']?.toString().toUpperCase() ?? 'MEDIUM'}';
    }
    return 'Parameters: ${params.toString()}';
  }
}

class _ProposalDetail extends StatelessWidget {
  const _ProposalDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
