import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/resident/documents_provider.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Resident Documents — read-only list of society documents.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(documentsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Documents',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(documentsProvider),
        child: async.when(
          loading: () => const LiveLoadingView(label: 'Loading documents…'),
          error: (e, _) => LiveErrorView(
              error: e, onRetry: () => ref.invalidate(documentsProvider)),
          data: (docs) {
            if (docs.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  LiveEmptyView(
                    icon: Icons.folder_outlined,
                    message: 'No documents shared yet.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: docs.length,
              itemBuilder: (context, i) => _DocCard(doc: docs[i]),
            );
          },
        ),
      ),
    );
  }
}

String _formatDate(String iso) {
  if (iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class _DocCard extends StatelessWidget {
  final SocietyDocument doc;
  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(doc.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: const Icon(Icons.description_rounded,
                color: Color(0xFF059669), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title.isNotEmpty ? doc.title : 'Document',
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (doc.docType.isNotEmpty) doc.docType.toUpperCase(),
                    if (date.isNotEmpty) date,
                  ].join(' • '),
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
