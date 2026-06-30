import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_society_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Committee Members
/// Lists the society committee (president, secretary, treasurer, …) joined to
/// the member directory, with an action to assign a new committee designation.
///
/// Backed by `/members/committee` (list) and `POST /members/:id/committee`
/// (assign a designation to an existing member).
class CommitteeMembersScreen extends ConsumerStatefulWidget {
  const CommitteeMembersScreen({super.key});

  @override
  ConsumerState<CommitteeMembersScreen> createState() => _CommitteeMembersScreenState();
}

class _CommitteeMembersScreenState extends ConsumerState<CommitteeMembersScreen> {
  /// Pick a member + designation, then POST a new committee role.
  Future<void> _showAddDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    List<dynamic> members;
    try {
      members = await AdminSocietyService.getMembers();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load members: $e'), backgroundColor: const Color(0xFFB91C1C)),
      );
      return;
    }
    if (!mounted) return;
    if (members.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No members available. Add members first.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    final designationController = TextEditingController();
    String? selectedMemberId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Add Committee Member', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedMemberId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Member'),
                items: members.map((m) {
                  final map = (m as Map?) ?? const {};
                  final id = (map['id'] ?? '').toString();
                  final name = (map['name'] ?? map['member_name'] ?? 'Member').toString();
                  return DropdownMenuItem(
                    value: id,
                    child: Text(name, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (v) => setLocal(() => selectedMemberId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  hintText: 'President, Secretary, Treasurer…',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final memberId = selectedMemberId;
    final designation = designationController.text.trim();
    if (memberId == null || memberId.isEmpty || designation.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select a member and enter a designation.'), backgroundColor: Color(0xFFB91C1C)),
      );
      return;
    }
    try {
      final ok = await AdminSocietyService.addCommitteeRole(memberId, designation);
      if (!mounted) return;
      if (ok) {
        ref.invalidate(committeeProvider);
        messenger.showSnackBar(
          SnackBar(content: Text('$designation added'), backgroundColor: const Color(0xFF064E3B)),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not add committee member'), backgroundColor: Color(0xFFB91C1C)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFB91C1C)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final committeeAsync = ref.watch(committeeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── App Bar ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Committee Members',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                ),
                GestureDetector(
                  onTap: _showAddDialog,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPrimaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: committeeAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading committee…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(committeeProvider),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return const LiveEmptyView(
                    icon: Icons.groups_outlined,
                    message: 'No committee members yet.\nTap + to assign a designation.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(committeeProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final m = (members[index] as Map?) ?? const {};
                      final name = (m['member_name'] ?? m['name'] ?? '—').toString();
                      final designation = (m['designation'] ?? '').toString();
                      final phone = (m['member_phone'] ?? m['phone'] ?? '').toString();
                      final termStart = (m['term_start'] ?? m['termStart'] ?? '').toString();
                      final termEnd = (m['term_end'] ?? m['termEnd'] ?? '').toString();
                      final term = [termStart, termEnd].where((t) => t.isNotEmpty).join(' → ');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_outline, color: Color(0xFF064E3B), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [if (phone.isNotEmpty) phone, if (term.isNotEmpty) term].join(' · '),
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            if (designation.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  designation,
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimaryGreen),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
