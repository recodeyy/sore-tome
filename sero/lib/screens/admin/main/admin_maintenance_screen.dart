import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'dart:convert';

final maintenanceStatusProvider = FutureProvider<Map<String, List<dynamic>>>((ref) async {
  final res = await ApiService.get('/funds/maintenance-status');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return {
      'paid': data['paid'] as List<dynamic>,
      'unpaid': data['unpaid'] as List<dynamic>,
      'exempt': data['exempt'] as List<dynamic>,
    };
  }
  throw Exception('Failed to fetch maintenance status');
});

class AdminMaintenanceScreen extends ConsumerWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(maintenanceStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Tracking')),
      body: statusAsync.when(
        data: (data) {
          final paid = data['paid']!;
          final unpaid = data['unpaid']!;
          final exempt = data['exempt']!;

          return ListView(
            children: [
              _buildSection('Unpaid This Month (${unpaid.length})', unpaid, Colors.red),
              _buildSection('Paid This Month (${paid.length})', paid, Colors.green),
              _buildSection('Exempt / Out (${exempt.length})', exempt, Colors.grey),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> list, Color color) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: list.isEmpty
          ? [const Padding(padding: EdgeInsets.all(16), child: Text('No residents in this category.'))]
          : list.map((res) => ListTile(
                leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(Icons.home, color: color)),
                title: Text('Flat: ${res['flatNumber']}'),
                subtitle: Text(res['name']),
              )).toList(),
    );
  }
}







