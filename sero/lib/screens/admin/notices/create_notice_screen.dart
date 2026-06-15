import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/data/mock_data.dart';

/// Create Notice Screen — Communication Module (2/2)
/// Form-based screen for drafting and publishing society notices.
class CreateNoticeScreen extends StatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  String _selectedCategory = 'General';
  String _selectedVisibility = 'All Members';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text('Create Notice', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF1E293B)), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title Field ──
            _buildLabel('Title', isRequired: true),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter notice title',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF064E3B))),
              ),
            ),

            const SizedBox(height: 20),
            // ── Category Selection ──
            _buildLabel('Category', isRequired: true),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: MockCommunicationData.categories.map((cat) {
                final isSelected = _selectedCategory == cat['label'];
                return _CategorySelectCard(
                  label: cat['label'],
                  icon: IconData(cat['icon'], fontFamily: 'MaterialIcons'),
                  color: Color(cat['color']),
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedCategory = cat['label']),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            // ── Message Field ──
            _buildLabel('Message', isRequired: true),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type your notice message here...',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF064E3B))),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('0/1000', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
            ),

            const SizedBox(height: 20),
            // ── Attach Document ──
            _buildLabel('Attach Document (Optional)'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.file_upload_outlined, color: Color(0xFF64748B), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload File', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                      Text('PDF, JPG, PNG up to 5MB', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // ── Publish Date ──
            _buildLabel('Publish On', isRequired: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                   Text('17 May 2024, 10:00 AM', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                   const Spacer(),
                   const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // ── Visibility ──
            _buildLabel('Visible To', isRequired: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVisibility,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                  items: ['All Members', 'Owners Only', 'Tenants Only'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))))).toList(),
                  onChanged: (v) => setState(() => _selectedVisibility = v!),
                ),
              ),
            ),

            const SizedBox(height: 32),
            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF064E3B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save as Draft', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF064E3B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Publish Now', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          children: [
            if (isRequired)
              const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444))),
          ],
        ),
      ),
    );
  }
}

class _CategorySelectCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategorySelectCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? color : const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
