import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

import 'profile_details_screen.dart';
import 'society_search_screen.dart' show OnboardingStepHeader;

/// Resident onboarding step 2 (MR-006): pick wing/block, floor and flat
/// number (e.g. A / 14 / 1402).
class UnitSelectScreen extends StatefulWidget {
  final String societyId;
  final String societyName;
  final String societyCity;

  const UnitSelectScreen({
    super.key,
    required this.societyId,
    required this.societyName,
    this.societyCity = '',
  });

  @override
  State<UnitSelectScreen> createState() => _UnitSelectScreenState();
}

class _UnitSelectScreenState extends State<UnitSelectScreen> {
  static const _wingOptions = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  final _wingCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  int? _floor;

  @override
  void dispose() {
    _wingCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _wingCtrl.text.trim().isNotEmpty && _floor != null && _unitCtrl.text.trim().isNotEmpty;

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
            const OnboardingStepHeader(step: 2, title: 'Select your flat'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Wing / Block'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _wingOptions.map((w) {
                      final selected = _wingCtrl.text.trim().toUpperCase() == w;
                      return ChoiceChip(
                        label: Text(w),
                        selected: selected,
                        onSelected: (_) => setState(() => _wingCtrl.text = w),
                        selectedColor: kPrimaryGreen,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : kTextPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: selected ? kPrimaryGreen : kSlateBorder),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _wingCtrl,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Or type your wing/block (e.g. A, Tower 2)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label('Floor'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _floor,
                    isExpanded: true,
                    decoration: const InputDecoration(hintText: 'Select floor'),
                    items: List.generate(51, (i) => i)
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f == 0 ? 'Ground floor' : 'Floor $f'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _floor = v),
                  ),
                  const SizedBox(height: 24),
                  _label('Flat number'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _unitCtrl,
                    keyboardType: TextInputType.text,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: 'e.g. 1402'),
                  ),
                  const SizedBox(height: 20),
                  if (_valid)
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
                              '${_wingCtrl.text.trim().toUpperCase()}-${_unitCtrl.text.trim()} • '
                              '${_floor == 0 ? 'Ground floor' : 'Floor $_floor'}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: kPrimaryGreen,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _valid
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileDetailsScreen(
                                    societyId: widget.societyId,
                                    societyName: widget.societyName,
                                    wing: _wingCtrl.text.trim().toUpperCase(),
                                    floor: _floor!,
                                    unitNumber: _unitCtrl.text.trim(),
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: const Text('Continue'),
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
