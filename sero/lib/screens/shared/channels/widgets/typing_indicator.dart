import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A properly lifecycle-managed typing indicator that avoids the
/// flutter_animate `onPlay: repeat` pattern which leaks AnimationControllers
/// and causes mouse_tracker.dart assertion failures on Flutter Desktop.
class TypingStatusText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const TypingStatusText({super.key, required this.text, this.style});

  @override
  State<TypingStatusText> createState() => _TypingStatusTextState();
}

class _TypingStatusTextState extends State<TypingStatusText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.text,
        style: widget.style ??
            GoogleFonts.outfit(
              fontSize: 10,
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}






