import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rules_provider.dart';
import '../../providers/shared/auth_provider.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rulesProvider.notifier).fetchRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(rulesProvider);
    final user = ref.watch(authProvider).value;
    final isAdmin = user?.role == 'admin' || user?.role == 'main_admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Rules & Bylaws'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search rules or keywords...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (val) => ref.read(rulesProvider.notifier).search(val),
            ),
          ),

          // 2. Rules List
          Expanded(
            child: rules.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : rules.filteredRules.isEmpty
                ? const Center(child: Text('No rules found matching your search.'))
                : _buildGroupedList(rules, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(RulesState state, bool isAdmin) {
    final groups = state.groupedRules;

    return ListView.builder(
      itemCount: groups.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final source = groups.keys.elementAt(index);
        final items = groups[source]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                source.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ),
            ...items.map((rule) => _RuleCard(rule: rule, isAdmin: isAdmin)),
          ],
        );
      },
    );
  }
}

class _RuleCard extends StatelessWidget {
  final Map<String, dynamic> rule;
  final bool isAdmin;

  const _RuleCard({required this.rule, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rule['rule'] ?? "",
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (isAdmin) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _suggestChange(context, rule['rule']),
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: const Text('Suggest Change'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _suggestChange(BuildContext context, String currentRule) {
    // ❗ V5.2 Governance Bridge: Open Notice Generator with prefilled context
    // In a real app, this would use Navigator to go to the CreateNotice screen
    // with a pre-filled suggestion.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening AI Notice Generator for rule update...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Future: Navigator.push(... SuggestionData(currentRule: currentRule) ...)
  }
}
