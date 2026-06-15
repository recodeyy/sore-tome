import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../common/sparkline_widget.dart';

class AiInsightsCard extends ConsumerStatefulWidget {
  const AiInsightsCard({super.key});

  @override
  ConsumerState<AiInsightsCard> createState() => _AiInsightsCardState();
}

class _AiInsightsCardState extends ConsumerState<AiInsightsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financeProvider.notifier).fetchFinanceAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(financeProvider);

    if (finance.isLoading && finance.analysis == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }

    if (finance.errorMessage.isNotEmpty && finance.analysis == null) {
      return _buildCompactCard([
        Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Text(finance.errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: () => ref.read(financeProvider.notifier).fetchFinanceAnalysis(forceRefresh: true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          ],
        )
      ]);
    }

    final data = finance.analysis ?? {};
    final totalSpent = data['totalSpent'] ?? 0;
    final topCategory = data['topCategory'] ?? 'N/A';
    // Dummy trend data for visual purposes (backend could provide actual monthly trends)
    final trendData = <double>[0.8, 1.2, 0.9, 1.5, 1.1, 1.6, totalSpent.toDouble() % 2]; 

    return _buildCompactCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('AI FINANCIAL INSIGHTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
          InkWell(
            onTap: () => ref.read(financeProvider.notifier).fetchFinanceAnalysis(forceRefresh: true),
            child: const Icon(Icons.refresh, size: 14, color: Colors.grey),
          )
        ],
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Expense', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text('₹${totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          SparklineWidget(
            data: trendData,
            lineColor: Theme.of(context).primaryColor,
            baseColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Divider(height: 1, thickness: 1),
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(Icons.trending_up, size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Top spending category is $topCategory. Consider reviewing these expenses.',
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildCompactCard(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
