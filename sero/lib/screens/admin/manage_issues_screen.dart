import 'package:flutter/material.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/services/firestore_service.dart';
import 'package:sero/widgets/admin/issue_card.dart';

class ManageIssuesScreen extends StatefulWidget {
  const ManageIssuesScreen({super.key});

  @override
  State<ManageIssuesScreen> createState() => _ManageIssuesScreenState();
}

class _ManageIssuesScreenState extends State<ManageIssuesScreen> {
  final _service = FirestoreService();
  List<Issue> _issues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final issues = await _service.getIssues();
    if (!mounted) return;
    setState(() {
      _issues = issues;
      _loading = false;
    });
  }

  Future<void> _resolve(String id) async {
    await _service.updateIssueStatus(id, 'resolved');
    final idx = _issues.indexWhere((i) => i.id == id);
    if (idx != -1) {
      setState(() {
        _issues[idx] = Issue(
          id: _issues[idx].id,
          title: _issues[idx].title,
          description: _issues[idx].description,
          postedBy: _issues[idx].postedBy,
          createdAt: _issues[idx].createdAt,
          status: 'resolved',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: const Text('Manage Issues'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _issues.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final issue = _issues[i];
                  return IssueCard(
                    issue: issue,
                    showResolveButton: issue.status != 'resolved',
                    onResolve: () => _resolve(issue.id),
                  );
                },
              ),
            ),
    );
  }
}






