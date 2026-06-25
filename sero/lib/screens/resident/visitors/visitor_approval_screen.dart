import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/visitors_provider.dart';
import 'package:sero/models/visitor.dart';

class VisitorApprovalScreen extends ConsumerWidget {
  const VisitorApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitorsAsync = ref.watch(visitorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('My Visitors', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: visitorsAsync.when(
        data: (visitors) {
          if (visitors.isEmpty) {
            return const Center(child: Text('No recent visitors.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final v = visitors[index];
              return _VisitorCardResident(visitor: v);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _VisitorCardResident extends ConsumerStatefulWidget {
  final Visitor visitor;
  const _VisitorCardResident({required this.visitor});

  @override
  ConsumerState<_VisitorCardResident> createState() => _VisitorCardResidentState();
}

class _VisitorCardResidentState extends ConsumerState<_VisitorCardResident> {
  bool isLoading = false;

  Future<void> _handleAction(String action) async {
    setState(() => isLoading = true);
    try {
      await ref.read(visitorsProvider.notifier).actionVisitor(widget.visitor.id, action);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.visitor.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryBlue.withValues(alpha: 0.1),
                child: Icon(
                  widget.visitor.type == 'delivery' ? Icons.fastfood_outlined : Icons.person_outline,
                  color: kPrimaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.visitor.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('${widget.visitor.type.toUpperCase()} • ${widget.visitor.entryTime.hour}:${widget.visitor.entryTime.minute.toString().padLeft(2, '0')}', 
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.visitor.status.toUpperCase(), 
                  style: GoogleFonts.outfit(
                    color: isPending ? Colors.orange : Colors.grey, 
                    fontWeight: FontWeight.w800, 
                    fontSize: 10
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => _handleAction('deny'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFF1F5F9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('DENY ENTRY'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleAction('approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('APPROVE'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
