import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/ai_provider.dart';
import 'package:sero/providers/shared/rules_provider.dart';

// Modularized Widgets
import 'package:sero/screens/admin/rules/widgets/rules_widgets.dart';
import 'package:sero/widgets/shared/branding_header.dart';
import 'package:sero/widgets/shared/hero_header.dart';
import 'package:sero/services/pdf_service.dart';
import 'package:printing/printing.dart';

class AdminRulesScreen extends ConsumerStatefulWidget {
  const AdminRulesScreen({super.key});

  @override
  ConsumerState<AdminRulesScreen> createState() => _AdminRulesScreenState();
}

class _AdminRulesScreenState extends ConsumerState<AdminRulesScreen> {
  String _selectedCategory = 'General Conduct';

  final List<String> _categories = [
    'General Conduct',
    'Parking & Transit',
    'Pet Policy',
    'Facility Usage',
    'Waste & Eco',
  ];

  void _showDraftRuleDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Quick Draft Protocol',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'Protocol Title (e.g. Quiet Hours)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Detailed content and enforcement details...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
              try {
                await ref.read(rulesProvider.notifier).addRule(
                  titleCtrl.text,
                  contentCtrl.text,
                  'general',
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Protocol drafted successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: Text('Post Rule', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _handleExportPdf(BuildContext context) async {
    final aiRules = ref.read(aiRulesProvider).value ?? [];
    final manualRules = ref.read(rulesProvider).value ?? [];
    final societyName = 'The Sero Community'; // Modernized name placeholder

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: kPrimaryGreen, strokeWidth: 2),
              const SizedBox(height: 20),
              Text(
                'Generating Society Charter...',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Synthesizing all active protocols into a PDF document.',
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    try {
      final allRulesData = [
        ...aiRules.map((r) => {
          'title': 'AI Extracted Protocol',
          'content': r['rule'],
          'section': 'AI ASSISTED',
        }),
        ...manualRules.map((r) => {
          'title': r.title,
          'content': r.content,
          'section': 'ADMIN DRAFT',
        }),
      ];

      final pdfBytes = await PdfService.generateBylaws(
        societyName: societyName,
        rules: allRulesData,
      );

      if (context.mounted) Navigator.pop(context);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'society_bylaws_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header Section ──────────────────────────────────────────────
          const BrandingHeader(),
          HeroHeader(
            title: 'Rules & Bylaws',
            label: 'GOVERNANCE CONSOLE',
            description: 'AI extracted regulations from society documents. Protocols are updated in real-time as bylaws are synced.',
            onRefresh: () {
              ref.invalidate(aiRulesProvider);
              ref.invalidate(rulesProvider);
              ref.invalidate(aiJobsProvider);
            },
          ),

          // ─── Horizontal Metrics Bar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: GovernanceMetricsBar(
              onDraftTap: () => _showDraftRuleDialog(context),
            ),
          ),

          // ─── Category Selection ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GovernanceCategorySelector(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
            ),
          ),

          // ─── Export Action Card ─────────────────────────────────────────────
          ExportBylawsCard(onTap: () => _handleExportPdf(context)),

          // ─── Protocols Title & View Options ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedCategory Protocols',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'View: List',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Unified Rules List (AI + Manual) ─────────────────────────────────
          GovernanceRulesListView(selectedCategory: _selectedCategory),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}
