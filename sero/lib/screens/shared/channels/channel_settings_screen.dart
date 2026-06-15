import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/shared/channels_provider.dart';
import 'package:sero/providers/admin/users_provider.dart';
import 'package:sero/services/api_service.dart';

class ChannelSettingsScreen extends ConsumerStatefulWidget {
  final Channel channel;
  const ChannelSettingsScreen({super.key, required this.channel});

  @override
  ConsumerState<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends ConsumerState<ChannelSettingsScreen> {
  late bool _isReadOnly;
  late List<String> _allowedRoles;
  late List<String> _moderatorIds;
  bool _isSaving = false;
  bool _isClearing = false;
  bool _isDeleting = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _isReadOnly = widget.channel.isReadOnly;
    _allowedRoles = List.from(widget.channel.allowedRoles);
    _moderatorIds = List.from(widget.channel.moderatorIds);
  }

  Future<void> _updateSettings() async {
    setState(() => _isSaving = true);
    try {
      final response = await ApiService.patch('/channels/${widget.channel.id}', {
        'isReadOnly': _isReadOnly,
        'allowedRoles': _allowedRoles,
        'moderatorIds': _moderatorIds,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text("Settings Synchronized!", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception("Failed to sync settings. Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync Error: Verify server is running on port 3001."),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await _showDangerDialog(
      title: "Wipe History?",
      content: "This will permanently delete all messages in '${widget.channel.name}' for every resident. This cannot be undone.",
      actionLabel: "CLEAR ALL",
    );

    if (confirm != true) return;

    setState(() => _isClearing = true);
    try {
      await ApiService.post('/channels/${widget.channel.id}/clear', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("History cleared successfully")));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to clear history")));
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  Future<void> _decommissionHub() async {
    final confirm = await _showDangerDialog(
      title: "Decommission Hub?",
      content: "This will permanently delete '${widget.channel.name}' and its history. This action is terminal.",
      actionLabel: "DELETE PERMANENTLY",
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await ApiService.delete('/channels/${widget.channel.id}');
      if (mounted) {
        Navigator.pop(context); // Close settings
        Navigator.pop(context); // Pop back to lobby
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hub decommissioned successfully")));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete Hub")));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _showDangerDialog({required String title, required String content, required String actionLabel}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(content, style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(actionLabel, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Hub Intelligence", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _updateSettings,
              child: Text("SAVE", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF345D7E))),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeroSection(),
          const SizedBox(height: 32),
          _buildSectionHeader("COMMUNICATION CONTROL"),
          _buildSettingCard(
            title: "Admin-Only Broadcast",
            subtitle: "Only Admins and Secretaries can send messages",
            trailing: Switch.adaptive(
              value: _isReadOnly,
              activeThumbColor: const Color(0xFF345D7E),
              activeTrackColor: const Color(0xFF345D7E).withValues(alpha: 0.5),
              onChanged: (v) => setState(() => _isReadOnly = v),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("SMART ENROLLMENT (ROLES)"),
          _buildRolesSelector(),
          const SizedBox(height: 32),
          _buildSectionHeader("HUB GOVERNANCE (MODERATORS)"),
          _buildModeratorManagement(),
          const SizedBox(height: 32),
          _buildSectionHeader("DANGER ZONE"),
          _buildSettingCard(
            title: "Clear Hub History",
            subtitle: "Wipe all messages for everyone",
            icon: Icons.cleaning_services_rounded,
            iconColor: Colors.orange,
            trailing: _isClearing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            onTap: _isClearing ? null : _clearHistory,
          ),
          _buildSettingCard(
            title: "Decommission Hub",
            subtitle: "Permanently delete this society channel",
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.red,
            trailing: _isDeleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            onTap: _isDeleting ? null : _decommissionHub,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.hub_rounded, size: 32, color: Color(0xFF345D7E)),
          ),
          const SizedBox(height: 16),
          Text(widget.channel.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.channel.description, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingCard({required String title, required String subtitle, Widget? trailing, IconData? icon, Color? iconColor, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: icon != null ? Icon(icon, color: iconColor) : null,
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
        trailing: trailing,
      ),
    );
  }

  Widget _buildRolesSelector() {
    final roles = ["resident", "owner", "tenant", "staff", "security"];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: roles.map((role) {
          final isSelected = _allowedRoles.contains(role);
          return FilterChip(
            label: Text(
              role.toUpperCase(), 
              style: GoogleFonts.outfit(
                fontSize: 11, 
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF345D7E) : const Color(0xFF64748B),
              )
            ),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  _allowedRoles.add(role);
                } else {
                  _allowedRoles.remove(role);
                }
              });
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF345D7E).withValues(alpha: 0.1),
            checkmarkColor: const Color(0xFF345D7E),
            showCheckmark: isSelected,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? const Color(0xFF345D7E) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeratorManagement() {
    final usersAsync = ref.watch(allUsersProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search residents...",
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          usersAsync.when(
            data: (users) {
              final filtered = users.where((u) => u.name.toLowerCase().contains(_searchQuery)).toList();
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("No residents found", style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12)),
                );
              }
              return SizedBox(
                height: 300,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    final isMod = _moderatorIds.contains(u.id);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: Text(u.name.substring(0, 1).toUpperCase(), 
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF345D7E))),
                      ),
                      title: Text(u.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                      subtitle: Text(u.flatNumber, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                      trailing: TextButton(
                        onPressed: () {
                          setState(() {
                            if (isMod) {
                              _moderatorIds.remove(u.id);
                            } else {
                              _moderatorIds.add(u.id);
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isMod ? Colors.red : const Color(0xFF345D7E),
                          textStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                        child: Text(isMod ? "REVOKE" : "PROMOTE"),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (e, _) => Text("Error loading members"),
          ),
        ],
      ),
    );
  }
}









