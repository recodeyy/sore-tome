import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/widgets/shared/sero_ui.dart';
import '../../../models/invoice.dart';
import '../../../providers/invoices_provider.dart';

/// Standalone screen wrapper. The reusable body is [InvoicesView] so it can
/// also be dropped into a tab inside the funds screen.
class AdminInvoicesScreen extends StatelessWidget {
  const AdminInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: InvoicesView()),
    );
  }
}

/// Invoices backed by the Postgres finance API (/finance): create a draft,
/// publish it (posts to the double-entry ledger), and record a payment.
class InvoicesView extends ConsumerStatefulWidget {
  const InvoicesView({super.key});

  @override
  ConsumerState<InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends ConsumerState<InvoicesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoicesProvider.notifier).fetch();
    });
  }

  String _money(int minor) => '₹${(minor / 100).toStringAsFixed(2)}';

  ChipSemantic _statusSemantic(String status) {
    switch (status) {
      case 'published':
        return ChipSemantic.success;
      case 'cancelled':
        return ChipSemantic.error;
      default:
        return ChipSemantic.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoicesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text('Invoices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(invoicesProvider.notifier).fetch(),
            child: _buildList(state),
          ),
        ),
      ],
    );
  }

  Widget _buildList(InvoicesState state) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const SkeletonList(itemCount: 5, itemHeight: 80);
    }
    if (state.errorMessage.isNotEmpty && state.invoices.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        ErrorRetryView(
          message: state.errorMessage,
          onRetry: () => ref.read(invoicesProvider.notifier).fetch(),
        ),
      ]);
    }
    if (state.invoices.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 60),
        EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No invoices yet',
          message: 'Create your first invoice to start billing members.',
          actionLabel: 'New Invoice',
          onAction: _showCreateDialog,
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: state.invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _invoiceTile(state.invoices[i]),
    );
  }

  Widget _invoiceTile(Invoice invoice) {
    return Card(
      child: ListTile(
        title: Text(invoice.number, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          _money(invoice.totalMinor),
          if (invoice.period != null) 'Period ${invoice.period}',
        ].join('  •  ')),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip(
              label: invoice.status.toUpperCase(),
              semantic: _statusSemantic(invoice.status),
            ),
            if (invoice.isDraft)
              TextButton(onPressed: () => _publish(invoice), child: const Text('Publish'))
            else if (invoice.isPublished)
              TextButton(onPressed: () => _payDialog(invoice), child: const Text('Pay')),
          ],
        ),
      ),
    );
  }

  Future<void> _publish(Invoice invoice) async {
    final ok = await ref.read(invoicesProvider.notifier).publish(invoice.id);
    _toast(ok ? 'Invoice ${invoice.number} published' : 'Publish failed');
  }

  void _showCreateDialog() {
    final numberCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Maintenance');
    final amountCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Invoice number')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (numberCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
                _toast('Enter a number and a positive amount');
                return;
              }
              Navigator.pop(ctx);
              final id = await ref.read(invoicesProvider.notifier).createInvoice(
                number: numberCtrl.text.trim(),
                lines: [
                  {'description': descCtrl.text.trim(), 'unitPriceMinor': (amount * 100).round()},
                ],
              );
              _toast(id != null ? 'Draft invoice created' : 'Create failed');
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _payDialog(Invoice invoice) {
    final amountCtrl = TextEditingController(text: (invoice.totalMinor / 100).toStringAsFixed(2));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay ${invoice.number}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) {
                _toast('Enter a positive amount');
                return;
              }
              Navigator.pop(ctx);
              final ok = await ref.read(invoicesProvider.notifier).recordPayment(
                invoiceId: invoice.id,
                amountMinor: (amount * 100).round(),
                idempotencyKey: 'pay-${invoice.id}-${DateTime.now().millisecondsSinceEpoch}',
              );
              _toast(ok ? 'Payment recorded' : 'Payment failed');
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
