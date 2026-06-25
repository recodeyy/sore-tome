import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/smart_scan_provider.dart';
import '../../providers/shared/funds_provider.dart';
import '../../models/fund.dart';

class OcrPreviewScreen extends ConsumerStatefulWidget {
  const OcrPreviewScreen({super.key});

  @override
  ConsumerState<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends ConsumerState<OcrPreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _vendorController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _dateController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final data = ref.read(smartScanProvider).extractedData ?? {};

    _vendorController = TextEditingController(text: data['vendor']?.toString() ?? '');
    _amountController = TextEditingController(text: data['amount']?.toString() ?? '');
    _categoryController = TextEditingController(text: data['category']?.toString() ?? '');
    _dateController = TextEditingController(text: data['date']?.toString() ?? '');
    _noteController = TextEditingController(text: data['note']?.toString() ?? '');
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanData = ref.watch(smartScanProvider);
    final isSaving = scanData.state == SmartScanState.saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: scanData.state == SmartScanState.error
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(scanData.errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    )
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('AI extracted the following details. Please review and correct if necessary.', 
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _vendorController,
                    decoration: const InputDecoration(labelText: 'Vendor / Provider', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onChanged: (val) => ref.read(smartScanProvider.notifier).updateField('vendor', val),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid amount' : null,
                    onChanged: (val) => ref.read(smartScanProvider.notifier).updateField('amount', double.tryParse(val)),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Expense Category', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onChanged: (val) => ref.read(smartScanProvider.notifier).updateField('category', val),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                    onChanged: (val) => ref.read(smartScanProvider.notifier).updateField('date', val),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Note (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                    onChanged: (val) => ref.read(smartScanProvider.notifier).updateField('note', val),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                      onPressed: isSaving ? null : () => _saveTransaction(scanData),
                      child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm & Save'),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Future<void> _saveTransaction(SmartScanData scanData) async {
    if (_formKey.currentState!.validate()) {
      final fundsNotifier = ref.read(fundsProvider.notifier);
      
      final success = await ref.read(smartScanProvider.notifier).commitTransaction((data) async {
        final tx = FundTransaction(
          id: '', // Backend generates
          title: data['vendor'] ?? 'Expense',
          amount: -((data['amount'] as num).toDouble()), // negative means debit
          date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
          description: data['note'] ?? '',
          category: data['category'] ?? 'Miscellaneous',
        );
        await fundsNotifier.addTransaction(tx);
      });

      if (success && mounted) {
        Navigator.pop(context); // Close preview
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense securely saved!')),
        );
      }
    }
  }
}
