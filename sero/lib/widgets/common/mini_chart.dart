import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Revenue overview line chart widget painted on canvas
class MiniLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final double height;

  const MiniLineChart({
    super.key,
    required this.data,
    this.labels = const [],
    this.lineColor = const Color(0xFF064E3B),
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size(double.infinity, height),
            painter: _LineChartPainter(
              data: data,
              lineColor: lineColor,
            ),
          ),
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((l) => Text(
                      l,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _LineChartPainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw the curve
    final path = Path();
    final fillPath = Path();
    final widthStep = size.width / (data.length <= 1 ? 1 : data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final normalizedY = size.height - ((data[i] - minVal) / range) * (size.height * 0.85) - size.height * 0.05;

      if (i == 0) {
        path.moveTo(x, normalizedY);
        fillPath.moveTo(x, normalizedY);
      } else {
        // Use cubic bezier for smooth curves
        final prevX = (i - 1) * widthStep;
        final controlX = (prevX + x) / 2;
        final prevNormalizedY = size.height - ((data[i - 1] - minVal) / range) * (size.height * 0.85) - size.height * 0.05;
        path.cubicTo(controlX, prevNormalizedY, controlX, normalizedY, x, normalizedY);
        fillPath.cubicTo(controlX, prevNormalizedY, controlX, normalizedY, x, normalizedY);
      }
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw fill under the curve
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.15), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw data points
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final normalizedY = size.height - ((data[i] - minVal) / range) * (size.height * 0.85) - size.height * 0.05;
      canvas.drawCircle(Offset(x, normalizedY), 4, dotBorderPaint);
      canvas.drawCircle(Offset(x, normalizedY), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Donut chart widget for category distribution
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  final double size;

  const DonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(segments: segments),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerValue,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                centerLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonutSegment {
  final double value;
  final Color color;
  final String label;

  const DonutSegment({
    required this.value,
    required this.color,
    required this.label,
  });
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;

  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.25;
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);

    bool hasData = total > 0;

    if (!hasData) {
      // Draw background ring if no data
      final paint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.02, // small gap between segments
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Bar chart widget for collections trend
class MiniBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color barColor;
  final double height;

  const MiniBarChart({
    super.key,
    required this.data,
    this.labels = const [],
    this.barColor = const Color(0xFF064E3B),
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.reduce(math.max);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (i) {
              final fraction = maxVal == 0 ? 0.0 : data[i] / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: fraction * (height - 20),
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.15 + fraction * 0.85),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels
                .map((l) => Text(
                      l,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Circular progress indicator for insights (Collection Efficiency, etc.)
class CircularIndicator extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final String sublabel;
  final Color color;
  final double size;

  const CircularIndicator({
    super.key,
    required this.value,
    required this.label,
    required this.sublabel,
    this.color = const Color(0xFF064E3B),
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                color: const Color(0xFFE2E8F0),
                strokeCap: StrokeCap.round,
              ),
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                color: color,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
              ),
              Center(
                child: Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
