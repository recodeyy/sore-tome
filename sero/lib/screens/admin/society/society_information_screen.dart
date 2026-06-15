import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';

/// Society Information — Screen 3 of 6
/// Editable form showing basic info, registration, description.
class SocietyInformationScreen extends StatefulWidget {
  const SocietyInformationScreen({super.key});

  @override
  State<SocietyInformationScreen> createState() => _SocietyInformationScreenState();
}

class _SocietyInformationScreenState extends State<SocietyInformationScreen> {
  // Form controllers initialized with mock data for easy API swap later
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _regNumberController;
  late final TextEditingController _descriptionController;
  String _selectedType = MockSocietyData.type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: MockSocietyData.name);
    _codeController = TextEditingController(text: MockSocietyData.code);
    _regNumberController = TextEditingController(text: MockSocietyData.registrationNumber);
    _descriptionController = TextEditingController(text: MockSocietyData.description);
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
                  onPressed: () {},
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
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
                            MockSocietyData.establishedOn,
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
                      onPressed: () {
                        // TODO: API integration - save society info
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Changes saved successfully'), backgroundColor: Color(0xFF064E3B)),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Save Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
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
