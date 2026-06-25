import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/models/audit_log.dart';
import 'package:sero/providers/admin/audit_provider.dart';
import 'package:sero/app/theme.dart';

class AdminAccessLogsScreen extends ConsumerStatefulWidget {
  const AdminAccessLogsScreen({super.key});

  @override
  ConsumerState<AdminAccessLogsScreen> createState() => _AdminAccessLogsScreenState();
}

class _AdminAccessLogsScreenState extends ConsumerState<AdminAccessLogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AuditLogType _currentType = AuditLogType.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0: _currentType = AuditLogType.all; break;
            case 1: _currentType = AuditLogType.security; break;
            case 2: _currentType = AuditLogType.administrative; break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider(_currentType));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
        title: Text(
          "Access & Audit Logs",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF345D7E),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "ALL ACTIVITY"),
            Tab(text: "SECURITY"),
            Tab(text: "ADMIN"),
          ],
        ),
      ),
      body: logsAsync.when(
        data: (logs) => RefreshIndicator(
          onRefresh: () => ref.read(auditLogsProvider(_currentType).notifier).refresh(),
          child: logs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return _AuditLogItem(
                      log: logs[index],
                      isLast: index == logs.length - 1,
                    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1);
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text("Failed to load logs", style: GoogleFonts.outfit()),
              TextButton(
                onPressed: () => ref.read(auditLogsProvider(_currentType).notifier).refresh(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: kPillNavbarFabLocation,
      floatingActionButton: _currentType == AuditLogType.security
          ? FloatingActionButton.extended(
              onPressed: () => _showAddVisitorDialog(context),
              label: const Text("Log Visitor"),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF345D7E),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No logs found in this category",
            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showAddVisitorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final purposeController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Log Visitor Entry", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Visitor Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone (Optional)"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: purposeController,
              decoration: const InputDecoration(labelText: "Purpose (e.g. Delivery, Guest)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              try {
                await ref.read(auditLogsProvider(_currentType).notifier).logVisitor(
                  name: nameController.text,
                  purpose: purposeController.text,
                  phone: phoneController.text,
                );
                
                if (!context.mounted) return;
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Visitor entry logged successfully")),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF345D7E), foregroundColor: Colors.white),
            child: const Text("Save Entry"),
          ),
        ],
      ),
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  final AuditLogEntry log;
  final bool isLast;

  const _AuditLogItem({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getColor(log.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(log.type), color: _getColor(log.type), size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[200],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.action.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: _getColor(log.type),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        log.relativeTime,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.details,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "By ${log.actorName}",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(AuditLogType type) {
    switch (type) {
      case AuditLogType.security: return Colors.orange[800]!;
      case AuditLogType.administrative: return const Color(0xFF345D7E);
      case AuditLogType.system: return Colors.blueGrey[600]!;
      default: return Colors.grey;
    }
  }

  IconData _getIcon(AuditLogType type) {
    switch (type) {
      case AuditLogType.security: return Icons.security;
      case AuditLogType.administrative: return Icons.admin_panel_settings;
      case AuditLogType.system: return Icons.notifications_active;
      default: return Icons.info_outline;
    }
  }
}







