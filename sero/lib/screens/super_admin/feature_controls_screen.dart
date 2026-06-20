import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';

class FeatureControlsScreen extends ConsumerStatefulWidget {
  const FeatureControlsScreen({super.key});

  @override
  ConsumerState<FeatureControlsScreen> createState() => _FeatureControlsScreenState();
}

class _FeatureControlsScreenState extends ConsumerState<FeatureControlsScreen> {
  String? _selectedSocietyId;

  @override
  Widget build(BuildContext context) {
    final societiesAsync = ref.watch(superAdminSocietiesProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: Text(
          'Feature Controls & Rollouts',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: societiesAsync.when(
        data: (page) {
          final societies = page.items;
          if (societies.isEmpty) {
            return const Center(child: Text('No societies available.'));
          }

          final activeSocietyId = _selectedSocietyId ?? societies.first.id;

          // Fetch detail to get actual features
          final detailAsync = ref.watch(superAdminSocietyDetailProvider(activeSocietyId));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Selection bar
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Select Society:',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<String>(
                            value: activeSocietyId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: societies.map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSocietyId = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Feature Override Registry',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: detailAsync.when(
                    data: (detail) {
                      final features = detail.features;
                      if (features.isEmpty) {
                        return const Center(child: Text('No features registered.'));
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: features.length,
                        itemBuilder: (context, index) {
                          final f = features[index];
                          final featureKey = f['key'] ?? '';
                          final featureName = f['name'] ?? '';
                          final enabled = f['enabled'] ?? false;

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: enabled ? kPrimaryGreen.withValues(alpha: 0.1) : Colors.grey[100],
                                    child: Icon(
                                      enabled ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                      color: enabled ? kPrimaryGreen : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          featureName,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          'Key: $featureKey',
                                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: enabled,
                                    activeColor: kPrimaryGreen,
                                    onChanged: (newVal) async {
                                      try {
                                        await ref.read(superAdminServiceProvider).setFeatureOverride(
                                          activeSocietyId,
                                          featureKey,
                                          newVal,
                                        );
                                        // Invalidate to reload Detail provider
                                        ref.invalidate(superAdminSocietyDetailProvider(activeSocietyId));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Feature "$featureName" toggled to ${newVal ? "ON" : "OFF"}.')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update feature: $e')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
