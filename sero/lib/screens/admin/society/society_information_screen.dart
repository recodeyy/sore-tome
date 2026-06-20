import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_society_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';
import 'package:sero/widgets/admin/admin_actions.dart';

/// Society Information — Screen 3 of 6
/// Editable form showing basic info, registration, description.
class SocietyInformationScreen extends ConsumerStatefulWidget {
  const SocietyInformationScreen({super.key});

  @override
  ConsumerState<SocietyInformationScreen> createState() => _SocietyInformationScreenState();
}

class _SocietyInformationScreenState extends ConsumerState<SocietyInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Residential';
  bool _seeded = false;
  bool _saving = false;
  String _establishedOn = '';

  /// Persist the editable, backend-supported subset (name, registrationNo)
  /// via PUT /society/profile, then refresh the live provider.
  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final ok = await AdminSocietyService.updateProfile({
        'name': _nameController.text.trim(),
        'registrationNo': _regNumberController.text.trim(),
      });
      if (!mounted) return;
      if (ok) {
        ref.invalidate(societyProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully'), backgroundColor: Color(0xFF064E3B)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save changes. Please try again.'), backgroundColor: Color(0xFFB91C1C)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: const Color(0xFFB91C1C)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Seed controllers from live profile once data arrives.
  void _seedFromProfile(Map profile) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = (profile['name'] ?? '').toString();
    _codeController.text = (profile['code'] ?? '').toString();
    _regNumberController.text =
        (profile['registrationNumber'] ?? profile['registration_number'] ?? '').toString();
    _descriptionController.text = (profile['description'] ?? '').toString();
    _establishedOn =
        (profile['establishedOn'] ?? profile['established_on'] ?? '').toString();
    final type = (profile['type'] ?? '').toString();
    if (['Residential', 'Commercial', 'Mixed'].contains(type)) {
      _selectedType = type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _regNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(societyProfileProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── App Bar ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Society Information',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)),
                  onPressed: () => AdminActions.comingSoon(context, 'Editing society information'),
                ),
              ],
            ),
          ),

          Expanded(
            child: profileAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading society information…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(societyProfileProvider),
              ),
              data: (data) {
                final profile = (data['profile'] as Map?) ?? const {};
                _seedFromProfile(profile);
                return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Text(
                    'Basic Information',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryGreen,
                      decoration: TextDecoration.underline,
                      decorationColor: kPrimaryGreen,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Society Name
                  _FormField(label: 'Society Name', controller: _nameController),
                  const SizedBox(height: 16),

                  // Society Code
                  _FormField(label: 'Society Code', controller: _codeController),
                  const SizedBox(height: 16),

                  // Type Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            items: ['Residential', 'Commercial', 'Mixed']
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B))),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Registration Number
                  _FormField(label: 'Registration Number', controller: _regNumberController),
                  const SizedBox(height: 16),

                  // Established On (read-only)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Established On', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF064E3B)),
                          const SizedBox(width: 8),
                          Text(
                            _establishedOn,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Society Description
                  Text('Society Description', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B), height: 1.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF064E3B), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Save Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;

  const _FormField({
    required this.label,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF064E3B), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
