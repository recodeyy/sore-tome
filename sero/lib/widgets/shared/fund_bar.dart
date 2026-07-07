import 'package:flutter/material.dart';
import 'package:sero/app/theme.dart';

class FundBar extends StatelessWidget {
  final double percent; // 0.0 to 1.0
  final String label;
  final String percentLabel;

  const FundBar({
    super.key,
    required this.percent,
    required this.label,
    required this.percentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
            ),
            Text(
              percentLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kDarkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE5E5E5),
            valueColor: const AlwaysStoppedAnimation<Color>(kAccentGreen),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}



