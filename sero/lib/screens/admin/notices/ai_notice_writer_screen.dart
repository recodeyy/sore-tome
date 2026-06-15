import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/notices_provider.dart';
import 'package:sero/services/api_service.dart';

class AiNoticeWriterScreen extends ConsumerStatefulWidget {
  const AiNoticeWriterScreen({super.key});

  @override
  ConsumerState<AiNoticeWriterScreen> createState() =>
      _AiNoticeWriterScreenState();
}

class _AiNoticeWriterScreenState
    extends ConsumerState<AiNoticeWriterScreen> {
  final _promptCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _isGenerating = false;
  bool _isPosting = false;
  bool _hasGenerated = false;

  Future<void> _generateNotice() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _hasGenerated = false;
    });

    try {
      final res = await ApiService.post('/notices/ai-generate', {'prompt': prompt});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _titleCtrl.text = data['title'] ?? '';
          _bodyCtrl.text = data['body'] ?? '';
          _hasGenerated = true;
        });
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['error'] ?? 'AI generation failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _postNotice() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    
    setState(() => _isPosting = true);

    try {
      final res = await ApiService.post('/notices', {
        'title': title,
        'body': body,
        'type': 'general',
      });

      if (res.statusCode == 201) {
        ref.invalidate(noticesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notice posted to all residents!'),
              backgroundColor: kPrimaryGreen,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['error'] ?? 'Failed to post notice');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryGreen, kPrimaryBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('AI Notice Writer',
                style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryGreen.withValues(alpha: 0.08),
                    kPrimaryBlue.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: kPrimaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: kPrimaryGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Type a short prompt in plain language. AI will generate a formal, trilingual (English + Hindi + Marathi) notice instantly.',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prompt input
            Text('What is the notice about?',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _promptCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. Water will be off tomorrow from 10am to 2pm',
                hintStyle: GoogleFonts.outfit(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateNotice,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _isGenerating ? 'Generating…' : 'GENERATE WITH AI',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // Generated result
            if (_hasGenerated) ...[
              const SizedBox(height: 28),
              Text('Generated Notice Preview (Editable)',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kPrimaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('AI GENERATED - EDITABLE',
                              style: GoogleFonts.outfit(
                                  color: kPrimaryGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: _bodyCtrl,
                      maxLines: null,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                          height: 1.6),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isPosting ? null : _generateNotice,
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('REGENERATE',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _postNotice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text('POST NOW',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
