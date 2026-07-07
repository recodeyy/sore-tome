import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/services/api_service.dart';

import 'request_status_screen.dart';
import 'society_search_screen.dart' show OnboardingStepHeader;

/// Resident onboarding step 3 (MR-006): profile details, then submit
/// POST /resident/join-requests {societyId, wing, floor, unitNumber, name, phone}.
class ProfileDetailsScreen extends ConsumerStatefulWidget {
  final String societyId;
  final String societyName;
  final String wing;
  final int floor;
  final String unitNumber;

  const ProfileDetailsScreen({
    super.key,
    required this.societyId,
    required this.societyName,
    required this.wing,
    required this.floor,
    required this.unitNumber,
  });

  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _residentType = 'owner';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill from the logged-in user when available.
    final user = ref.read(authProvider).value;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _nameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.trim().length >= 8;

  Future<void> _submit() async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      // Join requests need an account — send the visitor to the resident
      // login/register flow first.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please sign in or register first, then submit your join request.'),
        backgroundColor: kWarning,
      ));
      Navigator.pushNamed(context, '/login/resident');
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await ApiService.post('/resident/join-requests', {
        'societyId': widget.societyId,
        'wing': widget.wing,
        'floor': widget.floor,
        'unitNumber': widget.unitNumber,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'residentType': _residentType,
      });
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RequestStatusScreen()),
          (route) => route.isFirst,
        );
      } else if (res.statusCode == 404) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Join requests are not available yet. Please try again later.'),
          backgroundColor: kError,
        ));
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not submit your request (${res.statusCode}).'),
          backgroundColor: kError,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.societyName,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kTextPrimary, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const OnboardingStepHeader(step: 3, title: 'Your details'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kLightMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_rounded, color: kPrimaryGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.societyName} • ${widget.wing}-${widget.unitNumber}'
                            ' (${widget.floor == 0 ? 'Ground floor' : 'Floor ${widget.floor}'})',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: kPrimaryGreen,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label('Full name'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: 'e.g. Priya Sharma'),
                  ),
                  const SizedBox(height: 24),
                  _label('Mobile number'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: 'e.g. 9876543210'),
                  ),
                  const SizedBox(height: 24),
                  _label('I am a…'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('owner', 'Owner'),
                      ('tenant', 'Tenant'),
                      ('family', 'Family member'),
                    ].map((t) {
                      final selected = _residentType == t.$1;
                      return ChoiceChip(
                        label: Text(t.$2),
                        selected: selected,
                        onSelected: (_) => setState(() => _residentType = t.$1),
                        selectedColor: kPrimaryGreen,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : kTextPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: selected ? kPrimaryGreen : kSlateBorder),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _valid && !_submitting ? _submit : null,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Submit Join Request'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Your society admin will review and approve your request.',
                      style: GoogleFonts.outfit(fontSize: 12, color: kTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
      ),
    );
  }
}
