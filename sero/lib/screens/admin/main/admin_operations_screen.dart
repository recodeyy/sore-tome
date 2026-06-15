import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/models/society_record.dart';
import 'package:sero/providers/shared/auth_provider.dart';

class AdminOperationsScreen extends ConsumerStatefulWidget {
  const AdminOperationsScreen({super.key});

  @override
  ConsumerState<AdminOperationsScreen> createState() => _AdminOperationsScreenState();
}

class _AdminOperationsScreenState extends ConsumerState<AdminOperationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curUser = ref.watch(authProvider).value;
    final societyId = curUser?.societyId ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
        title: Text(
          "Operations Hub",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: kPrimaryGreen,
          indicatorWeight: 3,
          isScrollable: false,
          tabs: const [
            Tab(text: "REPAIRS"),
            Tab(text: "BOOKINGS"),
            Tab(text: "RECORDS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRepairsTab(societyId),
          _buildBookingsTab(),
          _buildRecordsTab(societyId),
        ],
      ),
    );
  }

  Widget _buildRepairsTab(String societyId) {
    final issuesAsync = ref.watch(allIssuesStreamProvider);
    return issuesAsync.when(
      data: (issues) {
        if (issues.isEmpty) {
          return Center(child: Text("No repairs reported", style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))));
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(20),
          itemCount: issues.length + 1,
          itemBuilder: (context, index) {
            if (index == issues.length) return const SizedBox(height: 160);
            
            final issue = issues[index];
            final isOpen = issue.status == 'open';
            final isInProgress = issue.status == 'in_progress';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isOpen ? Colors.orange : (isInProgress ? Colors.blue : Colors.green)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          issue.status.toUpperCase().replaceAll('_', ' '),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isOpen ? Colors.orange : (isInProgress ? Colors.blue : Colors.green),
                          ),
                        ),
                      ),
                      Text(
                        'by ${issue.postedBy}',
                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(issue.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    issue.description,
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (issue.status != 'resolved') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        if (isOpen)
                          Expanded(
                            child: _actionButton(
                              "IN PROGRESS",
                              Colors.blue,
                              () => CommunityActions.updateIssueStatus(issue.id, 'in_progress'),
                            ),
                          ),
                        if (isOpen || isInProgress) ...[
                          if (isOpen) const SizedBox(width: 8),
                          Expanded(
                            child: _actionButton(
                              "MARK RESOLVED",
                              kPrimaryGreen,
                              () => CommunityActions.updateIssueStatus(issue.id, 'resolved'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    final bookingsAsync = ref.watch(userBookingsProvider); // Phase 15: All bookings access needed
    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(child: Text("No facility bookings yet", style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))));
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(20),
          itemCount: bookings.length + 1,
          itemBuilder: (context, index) {
            if (index == bookings.length) return const SizedBox(height: 160);
            
            final b = bookings[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kPrimaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.sports_tennis_rounded, color: kPrimaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.userName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        Text(
                          'Requested confirm for ${b.startTime.toString().split(' ')[0]}',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  _statusPill(b.status),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _statusPill(String status) {
    bool isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPending ? Colors.orange : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: isPending ? Colors.orange : Colors.green),
      ),
    );
  }

  Widget _buildRecordsTab(String societyId) {
    final recordsAsync = ref.watch(societyRecordsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: recordsAsync.when(
        data: (records) {
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(20),
            itemCount: records.length + 1,
            itemBuilder: (context, index) {
              if (index == records.length) return const SizedBox(height: 160);
              
              final r = records[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_rounded, color: r.category == 'MOM' ? kPrimaryGreen : const Color(0xFF8B5CF6)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          Text("${r.category} • ${r.description}", style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => CommunityActions.removeRecord(r.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordDialog(societyId),
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text("ADD DOCUMENT", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddRecordDialog(String societyId) {
    String title = '';
    String category = 'Governance';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Society Record", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => title = v,
              decoration: const InputDecoration(hintText: "Document Title (e.g. AGM Minutes)"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: ['Governance', 'MOM', 'Guidelines'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => category = v ?? 'Governance',
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              if (title.isEmpty) return;
              await CommunityActions.addSocietyRecord(SocietyRecord(
                id: '',
                title: title,
                description: 'PDF • Added ${DateTime.now().toString().split(' ')[0]}',
                fileUrl: '',
                category: category,
                createdAt: DateTime.now(),
              ), societyId);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }
}
