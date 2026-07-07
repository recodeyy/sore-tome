import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfService {
  static Future<Uint8List> generateBylaws({
    required String societyName,
    required List<Map<String, dynamic>> rules,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(societyName, formattedDate),
          pw.SizedBox(height: 30),
          _buildIntroduction(),
          pw.SizedBox(height: 20),
          ..._buildRulesList(rules),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 20),
          _buildFooter(formattedDate),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String societyName, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'OFFICIAL GOVERNANCE CHARTER',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey700,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          societyName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 2,
          width: 60,
          color: PdfColors.blue900,
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Document ID: SERO-BYLAW-${DateFormat('yyyyMMdd').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Issued: $date',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildIntroduction() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '1. Scope of Governance',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This document constitutes the official rules and regulations of the society. These protocols have been synthesized from historical bylaws and active administrative directives to ensure safety, harmony, and property value preservation.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildRulesList(List<Map<String, dynamic>> rules) {
    if (rules.isEmpty) return [pw.Text('No active protocols found.', style: const pw.TextStyle(fontSize: 12))];

    return [
      pw.Text(
        '2. Active Protocols & Directives',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
      ),
      pw.SizedBox(height: 16),
      ...rules.map((rule) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          border: pw.Border(left: pw.BorderSide(color: PdfColors.blue700, width: 3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  rule['title'] ?? 'General Protocol',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.Text(
                  rule['section'] ?? 'ADMIN VERIFIED',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              rule['content'] ?? '',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ],
        ),
      )),
    ];
  }

  static pw.Widget _buildFooter(String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'End of Governance Document',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated via Sero Hub Governance Console. Digital signatures applied for authenticity.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
        ),
      ],
    );
  }
}


