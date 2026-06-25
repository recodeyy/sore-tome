import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/models/classified_item.dart';
import 'package:sero/providers/shared/auth_provider.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pulseController = TextEditingController();
  bool _isHighPriority = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
        title: Text(
          "Society Moderation",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: kPrimaryGreen,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "DIRECT PULSE"),
            Tab(text: "MARKETPLACE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPulseTab(),
          _buildMarketplaceTab(),
        ],
      ),
    );
  }

  Widget _buildPulseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Send a News Flash",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            "This will appear instantly on the 'Sero Pulse' banner for all residents.",
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pulseController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "What's the update? (e.g., Water supply restored, Garden event starting...)",
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text("High Priority", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            subtitle: Text("Bypass automation and pin to top", style: GoogleFonts.outfit(fontSize: 12)),
            value: _isHighPriority,
            onChanged: (val) => setState(() => _isHighPriority = val),
            activeThumbColor: kPrimaryGreen,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (_pulseController.text.isEmpty) return;
                final user = ref.read(authProvider).value;
                final societyId = user?.societyId ?? '';
                await CommunityActions.postPulse(_pulseController.text, societyId, isHighPriority: _isHighPriority);
                if (!mounted) return;
                
                _pulseController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pulse sent successfully!")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("SEND FLASH UPDATE", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 48),
          _buildPulseHistory(),
        ],
      ),
    );
  }

  Widget _buildPulseHistory() {
    // Current latest pulse
    final pulseAsync = ref.watch(directPulseProvider);
    return pulseAsync.when(
      data: (pulse) {
        if (pulse == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LATEST PULSE", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pulse.content, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text("Sent ${pulse.createdAt.toString().split('.')[0]}", style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMarketplaceTab() {
    final marketplaceAsync = ref.watch(marketplaceProvider);
    return marketplaceAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(child: Text("No active listings", style: GoogleFonts.outfit()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.shopping_bag_outlined, color: kPrimaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        Text("₹${item.price} • by ${item.sellerName}", style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(item),
                  ),
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

  void _confirmDelete(ClassifiedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Listing?"),
        content: Text("This will remove '${item.title}' from the society marketplace permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await CommunityActions.removeListing(item.id);
              if (mounted) nav.pop();
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
