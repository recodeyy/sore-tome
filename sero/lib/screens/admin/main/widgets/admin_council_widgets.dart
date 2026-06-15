import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/providers/shared/community_providers.dart';

class AdminCouncilTools extends ConsumerWidget {
  const AdminCouncilTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curUser = ref.watch(authProvider).value;
    final societyId = curUser?.societyId ?? '';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COUNCIL CONTROL',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ToolButton(
                  icon: Icons.poll_rounded,
                  label: 'Poll',
                  color: kPrimaryGreen,
                   onTap: () => _showCreatePoll(context, societyId),
                ),
                const SizedBox(width: 12),
                _ToolButton(
                  icon: Icons.event_available_rounded,
                  label: 'Event',
                  color: kPrimaryBlue,
                  onTap: () => _showCreateEvent(context, societyId),
                ),
                const SizedBox(width: 12),
                _ToolButton(
                  icon: Icons.people_alt_rounded,
                  label: 'Member',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _showAddMember(context, societyId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePoll(BuildContext context, String societyId) {
    final questionController = TextEditingController();
    final optionControllers = [TextEditingController(), TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Community Poll', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(hintText: 'Ask a question...'),
              ),
              const SizedBox(height: 16),
              ...List.generate(optionControllers.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: optionControllers[i],
                  decoration: InputDecoration(hintText: 'Option ${i + 1}'),
                ),
              )),
              TextButton.icon(
                onPressed: () => setModalState(() => optionControllers.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final options = optionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                  if (questionController.text.isNotEmpty && options.length >= 2) {
                    CommunityActions.createPoll(questionController.text, options, societyId);
                    Navigator.pop(context);
                  }
                },
                child: const Center(child: Text('Launch Poll')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateEvent(BuildContext context, String societyId) {
    final titleController = TextEditingController();
    final locController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Event Posting', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Event Title')),
            const SizedBox(height: 12),
            TextField(controller: locController, decoration: const InputDecoration(hintText: 'Location')),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(hintText: 'Brief description...')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  CommunityActions.addEvent(
                    titleController.text,
                    descController.text,
                    DateTime.now().add(const Duration(days: 1)),
                    locController.text,
                    societyId,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Center(child: Text('Post Event')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddMember(BuildContext context, String societyId) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Committee Member', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: roleController, decoration: const InputDecoration(hintText: 'Role (e.g. Secretary)')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  CommunityActions.addCommitteeMember(nameController.text, roleController.text, societyId);
                  Navigator.pop(context);
                }
              },
              child: const Center(child: Text('Add to Council')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
