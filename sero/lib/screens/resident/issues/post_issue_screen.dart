import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/app/theme.dart';

class PostIssueScreen extends ConsumerStatefulWidget {
  const PostIssueScreen({super.key});

  @override
  ConsumerState<PostIssueScreen> createState() => _PostIssueScreenState();
}

class _PostIssueScreenState extends ConsumerState<PostIssueScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    try {
      await ref.read(issuesProvider.notifier).addIssue(
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        'other', // Default category for now
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'New Ticket',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'ISSUE TITLE', required: true)
                        .animate()
                        .fade(delay: 50.ms)
                        .slideX(begin: -0.05),
                    const SizedBox(height: 12),
                    _buildTitleField()
                        .animate()
                        .fade(delay: 100.ms)
                        .slideY(begin: 0.05),
                    const SizedBox(height: 32),
                    _FieldLabel(label: 'DESCRIPTION', required: false)
                        .animate()
                        .fade(delay: 150.ms)
                        .slideX(begin: -0.05),
                    const SizedBox(height: 12),
                    _buildDescField()
                        .animate()
                        .fade(delay: 200.ms)
                        .slideY(begin: 0.05),
                    const SizedBox(height: 32),
                    _buildTipCard()
                        .animate()
                        .fade(delay: 250.ms)
                        .slideY(begin: 0.05),
                    const SizedBox(height: 48),
                    _buildSubmitButton()
                        .animate()
                        .fade(delay: 300.ms)
                        .slideY(begin: 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: _titleCtrl,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please enter an issue title' : null,
        decoration: InputDecoration(
          hintText: 'e.g. Lift not working — Block B',
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.edit_note_rounded,
            color: const Color(0xFF64748B),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          errorStyle: GoogleFonts.outfit(fontSize: 11, color: kBadgeRedText),
        ),
      ),
    );
  }

  Widget _buildDescField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: _descCtrl,
        maxLines: 6,
        style: GoogleFonts.outfit(
          fontSize: 15,
          color: const Color(0xFF0F172A),
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText:
              'Describe the issue in detail — location, severity, since when...',
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
            height: 1.6,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF64748B),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Include floor number, unit, and when the issue started for faster resolution.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _loading ? const Color(0xFFE2E8F0) : const Color(0xFF345D7E), // Solid Navy consistent with Screen 1
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF345D7E).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Submit Issue',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            letterSpacing: 0.1,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kBadgeRedText,
            ),
          ),
        ] else ...[
          const SizedBox(width: 6),
          Text(
            'optional',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }
}







