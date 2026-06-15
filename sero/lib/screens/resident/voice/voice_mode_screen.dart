import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/issues_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Phase 4: Senior Citizen Voice Mode
/// A large, accessible microphone button on the home screen.
/// Resident holds it, speaks, and the AI transcribes and files a complaint.
class VoiceModeScreen extends ConsumerStatefulWidget {
  const VoiceModeScreen({super.key});

  @override
  ConsumerState<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends ConsumerState<VoiceModeScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = 'Tap & hold the mic to speak your complaint';
  String? _transcribedText;
  String? _suggestedCategory;
  String? _suggestedPriority;
  bool _isSubmitting = false;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (val) => debugPrint('STT Status: $val'),
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      await _speechToText.initialize();
    }
    setState(() {
      _isListening = true;
      _statusText = 'Listening… speak clearly';
      _transcribedText = null;
      _suggestedCategory = null;
      _suggestedPriority = null;
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    
    await _speechToText.stop();
    
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText = 'AI is understanding your complaint…';
    });

    // Simulate AI thinking time for UI effect
    await Future.delayed(const Duration(seconds: 1));

    if (_transcribedText == null || _transcribedText!.isEmpty) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Could not hear you clearly. Please try again.';
      });
      return;
    }

    // Extended Heuristic categorization mapping
    String category = 'General';
    String priority = 'Medium';
    final lower = _transcribedText!.toLowerCase();
    
    if (lower.contains('leak') || lower.contains('water') || lower.contains('pipe') || lower.contains('plumb') || lower.contains('tap') || lower.contains('sink') || lower.contains('drain')) {
      category = 'Plumbing';
    } else if (lower.contains('light') || lower.contains('wire') || lower.contains('power') || lower.contains('electric') || lower.contains('fan') || lower.contains('switch') || lower.contains('bulb')) {
      category = 'Electrical';
    } else if (lower.contains('clean') || lower.contains('trash') || lower.contains('garbage') || lower.contains('sweep') || lower.contains('dust') || lower.contains('smell') || lower.contains('dirty')) {
      category = 'Housekeeping';
    } else if (lower.contains('guard') || lower.contains('visitor') || lower.contains('security') || lower.contains('stranger') || lower.contains('gate')) {
      category = 'Security';
    } else if (lower.contains('lift') || lower.contains('elevator') || lower.contains('stuck')) {
      category = 'Elevator';
    } else if (lower.contains('noise') || lower.contains('loud') || lower.contains('music') || lower.contains('party') || lower.contains('dog')) {
      category = 'Disturbance';
    } else if (lower.contains('park') || lower.contains('car') || lower.contains('bike') || lower.contains('vehicle')) {
      category = 'Parking';
    }

    if (lower.contains('urgent') || lower.contains('badly') || lower.contains('fire') || lower.contains('fast') || lower.contains('now') || lower.contains('emergency') || lower.contains('help') || lower.contains('stuck')) {
      priority = 'High';
    }

    setState(() {
      _isProcessing = false;
      _suggestedCategory = category;
      _suggestedPriority = priority;
      _statusText = 'AI understood your complaint. Review and submit:';
    });
  }

  Future<void> _submitComplaint() async {
    if (_transcribedText == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.post('/issues', {
        'title': _transcribedText,
        'description': _transcribedText,
        'category': _suggestedCategory ?? 'General',
        'priority': _suggestedPriority?.toLowerCase() ?? 'medium',
      });

      if (res.statusCode == 201) {
        ref.invalidate(issuesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Complaint filed! We will fix this soon.'),
              backgroundColor: kPrimaryGreen,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['error'] ?? 'Submission failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Voice Mode',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Status text
              Text(
                _statusText,
                style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // Microphone button
              GestureDetector(
                onLongPressStart: (_) => _startListening(),
                onLongPressEnd: (_) => _stopListening(),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.red, Colors.redAccent]
                                : [kPrimaryGreen, kPrimaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening
                                      ? Colors.red
                                      : kPrimaryGreen)
                                  .withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening
                              ? Icons.mic
                              : Icons.mic_none_outlined,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              if (_isListening)
                Text('Release to stop…',
                    style: GoogleFonts.outfit(
                        color: Colors.redAccent, fontSize: 13))
              else if (!_isProcessing)
                Text('Hold to record',
                    style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13)),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(color: kPrimaryGreen),
                ),

              const SizedBox(height: 40),

              // Result card
              if (_transcribedText != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI UNDERSTOOD:',
                          style: GoogleFonts.outfit(
                              color: kPrimaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('"$_transcribedText"',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _chip('Category: $_suggestedCategory',
                              kPrimaryBlue),
                          const SizedBox(width: 8),
                          _chip('Priority: $_suggestedPriority',
                              Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text('SUBMIT COMPLAINT',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}
