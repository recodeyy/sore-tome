import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_staff_service.dart';

/// Add Staff — registers a new staff member via POST /staff-v2.
///
/// On success it invalidates [staffDashboardProvider] and [staffListProvider]
/// so the dashboard counts and the staff list reflect the new member, then
/// pops back to the caller.
class AddStaffScreen extends ConsumerStatefulWidget {
  const AddStaffScreen({super.key});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();

  // Common society-staff roles. Stored lowercase to match backend conventions.
  static const _roles = [
    'guard',
    'security_manager',
    'supervisor',
    'maid',
    'cleaner',
    'gardener',
    'plumber',
    'electrician',
    'reception_staff',
    'facility_manager',
  ];
  String _role = 'guard';
  bool _saving = false;

  // Captured staff photo (camera or gallery). Held locally until submit.
  XFile? _photo;

  Future<void> _pickPhoto() async {
    if (_saving) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: Color(0xFF064E3B)),
              title: Text('Take Photo', style: GoogleFonts.outfit()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF064E3B)),
              title: Text('Choose from Gallery', style: GoogleFonts.outfit()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (picked != null) setState(() => _photo = picked);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _wageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      // Wage entered in rupees; backend stores minor units (paise).
      final rupees = int.tryParse(_wageCtrl.text.trim());
      // TODO: wire image upload endpoint — no reusable, side-effect-free image
      // upload route exists yet (the only ones mutate the caller's own profile
      // or require a channel messageId). Once one exists, upload [_photo] here
      // and pass the returned URL as `imageUrl` below.
      await AdminStaffService.createStaff(
        name: _nameCtrl.text.trim(),
        role: _role,
        phone: _phoneCtrl.text.trim(),
        monthlyWageMinor: rupees == null ? null : rupees * 100,
      );
      ref.invalidate(staffDashboardProvider);
      ref.invalidate(staffListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff member added'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add staff: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Add Staff',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: _photo != null
                          ? FileImage(File(_photo!.path))
                          : null,
                      child: _photo == null
                          ? const Icon(Icons.photo_camera_outlined,
                              size: 34, color: Color(0xFF064E3B))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF064E3B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _photo == null ? 'Add photo' : 'Change photo',
                style: GoogleFonts.outfit(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            _label('Full name'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('e.g. Ramesh Kumar'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _label('Role'),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: _dec(''),
              items: _roles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(_pretty(r)),
                      ))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 16),
            _label('Phone (optional)'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec('10-digit mobile'),
            ),
            const SizedBox(height: 16),
            _label('Monthly wage ₹ (optional)'),
            TextFormField(
              controller: _wageCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec('e.g. 15000'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Register staff',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF064E3B), width: 1.5)),
      );

  String _pretty(String role) => role
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
