import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/visitors_provider.dart';
import 'package:sero/providers/shared/staff_provider.dart';
import 'package:sero/models/visitor.dart';
import 'package:sero/models/staff.dart';
import 'package:sero/services/api_service.dart';

class GuardHome extends ConsumerStatefulWidget {
  const GuardHome({super.key});

  @override
  ConsumerState<GuardHome> createState() => _GuardHomeState();
}

class _GuardHomeState extends ConsumerState<GuardHome> {
  @override
  Widget build(BuildContext context) {
    final visitorsAsync = ref.watch(visitorsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Security Dashboard', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          bottom: TabBar(
            labelColor: kPrimaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimaryGreen,
            tabs: const [
              Tab(text: 'VISITORS'),
              Tab(text: 'STAFF (Maids)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Visitors
            visitorsAsync.when(
              data: (visitors) {
                if (visitors.isEmpty) {
                  return const Center(child: Text('No visitors today.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final v = visitors[index];
                    return _VisitorCardGuard(visitor: v);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            
            // Tab 2: Staff
            ref.watch(staffProvider).when(
              data: (staffList) {
                if (staffList.isEmpty) {
                  return const Center(child: Text('No staff registered.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return _StaffCardGuard(staff: staff);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNewEntryDialog(context),
          backgroundColor: kPrimaryGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('NEW ENTRY', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  void _showNewEntryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final flatCtrl = TextEditingController();
    String type = 'guest';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Log New Visitor', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'guest', child: Text('Guest')),
                  DropdownMenuItem(value: 'delivery', child: Text('Delivery (Swiggy/Amazon)')),
                  DropdownMenuItem(value: 'cab', child: Text('Cab (Uber/Ola)')),
                  DropdownMenuItem(value: 'maid', child: Text('Maid/Staff')),
                ],
                onChanged: isLoading ? null : (val) => setState(() => type = val!),
                decoration: const InputDecoration(labelText: 'Visitor Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: 'Name / Company'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: flatCtrl,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: 'Target Flat (e.g. 402A)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context), 
              child: const Text('CANCEL')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, foregroundColor: Colors.white),
              onPressed: isLoading ? null : () async {
                if (nameCtrl.text.isEmpty || flatCtrl.text.isEmpty) return;
                
                setState(() => isLoading = true);
                
                final v = Visitor(
                  id: '',
                  name: nameCtrl.text,
                  type: type,
                  targetFlat: flatCtrl.text,
                  vehicleNumber: '',
                  phone: '',
                  status: 'pending',
                  entryTime: DateTime.now(),
                );
                
                try {
                  await ref.read(visitorsProvider.notifier).logVisitor(v);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('CHECK IN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffCardGuard extends ConsumerStatefulWidget {
  final Staff staff;
  const _StaffCardGuard({required this.staff});

  @override
  ConsumerState<_StaffCardGuard> createState() => _StaffCardGuardState();
}

class _StaffCardGuardState extends ConsumerState<_StaffCardGuard> {
  bool _isLoading = false;

  Future<void> _toggleCheckIn() async {
    setState(() => _isLoading = true);
    try {
      final endpoint = widget.staff.isInside ? 'checkout' : 'checkin';
      final res = await ApiService.post('/staff/${widget.staff.id}/$endpoint', {});
      if (res.statusCode == 200) {
        ref.invalidate(staffProvider);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.staff.isInside ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.badge_outlined, color: statusColor),
        ),
        title: Text(widget.staff.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(widget.staff.role.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            if (widget.staff.workingFlats.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Flats: ${widget.staff.workingFlats.join(", ")}', style: GoogleFonts.outfit(fontSize: 12)),
            ]
          ],
        ),
        trailing: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                onPressed: _toggleCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.staff.isInside ? Colors.orange : kPrimaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(widget.staff.isInside ? 'CHECK OUT' : 'CHECK IN', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }
}


class _VisitorCardGuard extends ConsumerWidget {
  final Visitor visitor;
  const _VisitorCardGuard({required this.visitor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    switch (visitor.status) {
      case 'approved': statusColor = Colors.green; break;
      case 'denied': statusColor = Colors.red; break;
      case 'checked_out': statusColor = Colors.grey; break;
      default: statusColor = Colors.orange; // pending
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(
            visitor.type == 'delivery' ? Icons.local_shipping_outlined : Icons.person_outline,
            color: statusColor,
          ),
        ),
        title: Text(visitor.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        subtitle: Text('Flat ${visitor.targetFlat} • Status: ${visitor.status.toUpperCase()}', style: GoogleFonts.outfit()),
        trailing: visitor.status == 'approved'
            ? OutlinedButton(
                onPressed: () => ref.read(visitorsProvider.notifier).checkoutVisitor(visitor.id),
                child: const Text('CHECK OUT'),
              )
            : null,
      ),
    );
  }
}
