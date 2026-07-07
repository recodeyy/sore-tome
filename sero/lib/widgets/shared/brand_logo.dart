import 'package:flutter/material.dart';

class SocietyLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const SocietyLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SocietyLogoPainter(color: themeColor),
      ),
    );
  }
}

class _SocietyLogoPainter extends CustomPainter {
  final Color color;

  _SocietyLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07 // Slightly thinner for absolute elegance
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // --- THE ROOF (Immediate residential recognition) ---
    path.moveTo(size.width * 0.15, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.15);
    path.lineTo(size.width * 0.85, size.height * 0.4);

    // --- THE STRUCTURAL "S" (The brand identity) ---
    // Starting from the right side of the house "wall"
    path.moveTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width * 0.25, size.height * 0.4); // Top bar of S
    path.lineTo(size.width * 0.25, size.height * 0.6); // Middle bar down
    path.lineTo(size.width * 0.75, size.height * 0.6); // Middle bar over
    path.lineTo(size.width * 0.75, size.height * 0.85); // Bottom bar down
    path.lineTo(size.width * 0.25, size.height * 0.85); // Bottom bar over

    canvas.drawPath(path, paint);

    // Minimal detail (A single "window/dot" for structural depth)
    final dotPaint = Paint()..color = color.withAlpha(200);
    // Positioned as a "door handle" or "window" to reinforce the house look
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.72), size.width * 0.025, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



