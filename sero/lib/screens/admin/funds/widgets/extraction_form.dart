import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/fund.dart';

class ExtractionForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(FundTransaction) onConfirm;

  const ExtractionForm({super.key, required this.data, required this.onConfirm});

  @override
  State<ExtractionForm> createState() => _ExtractionFormState();
}

class _ExtractionFormState extends State<ExtractionForm> {
  late TextEditingController _vendorController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _noteController;
  String _category = 'Other';
  
  bool _doubleConfirm = false;
  int _secondsRemaining = 600; // 10 minutes
  Timer? _timer;

  final List<String> _categories = [
    'Maintenance', 'Utilities', 'Security', 'Repairs', 'Landscaping',
    'Stationery', 'Events', 'Sinking Fund', 'Member Dues', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final parsed = widget.data['parsed'] ?? widget.data;
    _vendorController = TextEditingController(text: parsed['vendor']?.toString() ?? '');
    _amountController = TextEditingController(text: parsed['amount']?.toString() ?? '');
    _dateController = TextEditingController(text: parsed['date']?.toString() ?? '');
    _noteController = TextEditingController(text: parsed['note']?.toString() ?? '');
    _category = parsed['category']?.toString() ?? 'Other';
    if (!_categories.contains(_category)) _category = 'Other';

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() => _secondsRemaining--);
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vendorController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final isExpired = _secondsRemaining <= 0;
    final needsDoubleConfirm = amount >= 5000;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: kPrimaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text('Verify AI Extraction', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red.shade50 : (_secondsRemaining < 120 ? Colors.orange.shade50 : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isExpired ? 'EXPIRED' : '${(_secondsRemaining / 60).floor()}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(
                      fontSize: 12, 
                      fontWeight: FontWeight.w700,
                      color: isExpired ? Colors.red : (_secondsRemaining < 120 ? Colors.orange : Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            EditableField(label: 'Vendor', controller: _vendorController),
            EditableField(label: 'Amount (₹)', controller: _amountController, isHero: true, keyboardType: TextInputType.number),
            EditableField(label: 'Date (YYYY-MM-DD)', controller: _dateController),
            
            Text('CATEGORY', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.1)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _categories.contains(_category) ? _category : 'Other',
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit(fontSize: 14)))).toList(),
              onChanged: (val) => setState(() => _category = val ?? 'Other'),
            ),
            const SizedBox(height: 16),
            EditableField(label: 'Note', controller: _noteController),

            const SizedBox(height: 32),
            
            if (_doubleConfirm)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(child: Text('⚠️ Are you sure? This is a significant amount.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blue.shade900, fontWeight: FontWeight.w600))),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isExpired ? null : () {
                  if (needsDoubleConfirm && !_doubleConfirm) {
                    setState(() => _doubleConfirm = true);
                    return;
                  }
                  
                  final tx = FundTransaction(
                    id: '', 
                    title: _vendorController.text,
                    description: _noteController.text,
                    amount: -1 * (double.tryParse(_amountController.text) ?? 0.0),
                    date: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                    category: _category,
                  );
                  
                  widget.onConfirm(tx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _doubleConfirm ? Colors.blue.shade700 : kPrimaryGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size(64, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  isExpired ? 'EXPIRED' : (_doubleConfirm ? 'YES, CONFIRM & SAVE' : '✅ CONFIRM & SAVE'), 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isHero;
  final TextInputType keyboardType;

  const EditableField({
    super.key,
    required this.label, 
    required this.controller, 
    this.isHero = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.1)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              fontSize: isHero ? 22 : 15,
              fontWeight: isHero ? FontWeight.w700 : FontWeight.w500,
              color: isHero ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
