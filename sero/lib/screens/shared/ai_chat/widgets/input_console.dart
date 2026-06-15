import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';

class FloatingInputConsole extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final String? imagePath;

  const FloatingInputConsole({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onSend,
    required this.onPickImage,
    required this.onRemoveImage,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 1.0),
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(imagePath!)),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: kPrimaryGreen, width: 2),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onRemoveImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().scale(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Animated Standalone Plus Button
                GestureDetector(
                  onTap: onPickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: isFocused ? 44 : 0,
                    height: 44,
                    margin: EdgeInsets.only(right: isFocused ? 12 : 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kSlateBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isFocused ? 1.0 : 0.0,
                      child: const Center(
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          color: kPrimaryGreen,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Input Pill
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: kSlateBorder.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Plus icon inside when NOT focused
                        if (!isFocused) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: onPickImage,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            color: const Color(0xFF64748B),
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                        ] else ...[
                          const SizedBox(width: 12),
                        ],

                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onSubmitted: (_) => onSend(),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: const Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask Sero something...',
                              hintStyle: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        // Icon Group on Right
                        const Icon(
                          Icons.mic_none_outlined,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                        const SizedBox(width: 8),

                        // Waveform FAB / Send Button
                        GestureDetector(
                          onTap: onSend,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isFocused
                                  ? kPrimaryGreen
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: isFocused
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionChip extends StatelessWidget {
  final String label;
  const SuggestionChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.smart_toy_rounded, size: 14, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          'Typing...',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}










