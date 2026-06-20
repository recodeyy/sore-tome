import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';

class WorkspaceSelectorScreen extends ConsumerStatefulWidget {
  const WorkspaceSelectorScreen({super.key});

  @override
  ConsumerState<WorkspaceSelectorScreen> createState() => _WorkspaceSelectorScreenState();
}

class _WorkspaceSelectorScreenState extends ConsumerState<WorkspaceSelectorScreen> {
  bool _selecting = false;

  Future<void> _onSelectWorkspace(Map<String, dynamic> destination) async {
    setState(() => _selecting = true);
    try {
      await ref.read(authProvider.notifier).selectWorkspace(destination);
      if (!mounted) return;

      final type = destination['type']?.toString();
      if (type == 'super-admin') {
        Navigator.pushNamedAndRemoveUntil(context, '/super-admin', (_) => false);
      } else if (type == 'admin') {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
      } else if (type == 'staff') {
        Navigator.pushNamedAndRemoveUntil(context, '/staff', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = ref.watch(authProvider.notifier).destinations;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Workspace',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
          )
        ],
      ),
      body: _selecting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account has multiple roles or society associations. Please choose a workspace to continue.',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: destinations.length,
                      itemBuilder: (context, idx) {
                        final dest = Map<String, dynamic>.from(destinations[idx]);
                        final String societyName = dest['societyName'] ?? 'Society';
                        final String type = dest['type'] ?? 'resident';
                        final String role = dest['role'] ?? '';
                        final String? unit = dest['unitId'] != null ? 'Unit: ${dest['unitId']}' : null;
                        final String status = dest['status'] ?? 'approved';

                        IconData iconData = Icons.home_rounded;
                        Color accentColor = kPrimaryGreen;

                        if (type == 'super-admin') {
                          iconData = Icons.admin_panel_settings_rounded;
                          accentColor = kPrimaryBlue;
                        } else if (type == 'admin') {
                          iconData = Icons.business_rounded;
                          accentColor = Colors.orangeAccent;
                        } else if (type == 'staff') {
                          iconData = Icons.shield_rounded;
                          accentColor = Colors.blueGrey;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.withAlpha(40)),
                          ),
                          child: InkWell(
                            onTap: () => _onSelectWorkspace(dest),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: accentColor.withAlpha(30),
                                    child: Icon(iconData, color: accentColor),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          societyName,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Role: ${role.toUpperCase()}',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (unit != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            unit,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF94A3B8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      status.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: status == 'approved' ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    backgroundColor: status == 'approved' ? kAccentGreen : Colors.amberAccent,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
