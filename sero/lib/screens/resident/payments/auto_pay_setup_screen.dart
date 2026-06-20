import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';

/// Auto-Pay Setup (design: payment.png screen 4).
///
/// HONEST GAP: there is NO auto-pay / e-mandate route in the backend
/// (routes/funds.js only has create-order / verify / webhook for one-off
/// Razorpay payments). Persisting an auto-pay mandate would require a
/// /funds/mandate endpoint that does not exist. Rather than store a toggle that
/// silently does nothing, this screen renders the design's controls in a clearly
/// disabled "not yet available" state, with an honest explanation. Wire the
/// Save action to the real mandate endpoint once it exists.
class AutoPaySetupScreen extends StatefulWidget {
  const AutoPaySetupScreen({super.key});

  @override
  State<AutoPaySetupScreen> createState() => _AutoPaySetupScreenState();
}

class _AutoPaySetupScreenState extends State<AutoPaySetupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: kPremiumGradient)),
        title: Text('Auto-Pay Setup',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBadgeBlueBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: kBadgeBlueText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Auto-Pay (e-mandate) is not yet available. The payments backend '
                    'currently supports one-time payments only. Setting up recurring '
                    'mandates will be enabled in an upcoming release.',
                    style: GoogleFonts.outfit(color: kBadgeBlueText, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSlateBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enable Auto-Pay',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kDeepNavy, fontSize: 15)),
                          Text('Automatically pay maintenance every month',
                              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: false,
                      onChanged: null, // disabled: no mandate endpoint
                      activeThumbColor: kPrimaryGreen,
                    ),
                  ],
                ),
                const Divider(height: 28),
                _disabledField('Payment Method', 'Add a payment method'),
                const SizedBox(height: 12),
                _disabledField('Bills to Auto-Pay', 'Maintenance, Water, Electricity'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null, // disabled until backend mandate support exists
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Save Auto-Pay Settings (unavailable)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _disabledField(String label, String hint) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSlateBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: GoogleFonts.outfit(
                    fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(hint, style: GoogleFonts.outfit(color: const Color(0xFFCBD5E1), fontSize: 13)),
          ],
        ),
      );
}
