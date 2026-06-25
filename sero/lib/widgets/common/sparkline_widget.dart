import 'package:flutter/material.dart';

class SparklineWidget extends StatelessWidget {
  final List<double> data;
  final Color lineColor;
  final Color baseColor;

  const SparklineWidget({
    super.key,
    required this.data,
    this.lineColor = Colors.blue,
    this.baseColor = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      size: const Size(60, 24),
      painter: _SparklinePainter(data, lineColor, baseColor),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color baseColor;

  _SparklinePainter(this.data, this.lineColor, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxVal = data.reduce((curr, next) => curr > next ? curr : next);
    final minVal = data.reduce((curr, next) => curr < next ? curr : next);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final path = Path();
    final widthStep = size.width / (data.length <= 1 ? 1 : data.length - 1);

    for (int i = 0; i < data.length; i++) {
      // Normalize value to height
      final normalizedY = size.height - ((data[i] - minVal) / range) * size.height;
      final x = i * widthStep;

      if (i == 0) {
        path.moveTo(x, normalizedY);
      } else {
        path.lineTo(x, normalizedY);
      }
    }

    canvas.drawPath(path, paint);

    // Optional fill under curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [baseColor.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
