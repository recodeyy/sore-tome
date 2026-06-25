import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/ai_service.dart';
import 'action_helpers.dart';

class ExpenseCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final AiService aiService;
  final VoidCallback onExecuted;

  const ExpenseCard({
    super.key,
    required this.message,
    required this.aiService,
    required this.onExecuted,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  bool _loading = false;
  bool _executed = false;

  @override
  Widget build(BuildContext context) {
    if (_executed || widget.message['executed'] == true) {
      return const ExecutionSuccess(message: 'Expense Logged Successfully');
    }

    final params = widget.message['params'] ?? {};

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
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
                    const Tag(label: 'FINANCIAL LOG', color: kPrimaryGreen),
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: kPrimaryGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '₹${params['amount'] ?? '0.00'}',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  params['vendor'] ?? 'Unknown Vendor',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    MetaIcon(
                      icon: Icons.category_outlined,
                      label: params['category'] ?? 'Other',
                    ),
                    MetaIcon(
                      icon: Icons.calendar_today_outlined,
                      label: params['date'] ?? 'Today',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: kPrimaryGreen),
                  )
                else
                  ConfirmButton(
                    label: 'LOG TO TREASURY',
                    color: kPrimaryGreen,
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
      ).showSnackBar(SnackBar(content: Text('Log failed: $e')));
    }
  }
}











