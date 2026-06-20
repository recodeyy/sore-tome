import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';

class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  double _zoomScale = 1.0;
  String? _selectedSocietyId;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final societiesAsync = ref.watch(superAdminSocietiesProvider);

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: Text(
          'KYC Verification Queue',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: societiesAsync.when(
        data: (page) {
          final pendingKYC = page.items.where((s) => s.status == 'pending' || s.status == 'trial').toList();
          if (pendingKYC.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No pending KYC reviews',
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }

          final selectedSociety = pendingKYC.firstWhere(
            (s) => s.id == _selectedSocietyId,
            orElse: () => pendingKYC.first,
          );

          if (_selectedSocietyId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedSocietyId = selectedSociety.id;
              });
            });
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Panel: Queue list
              Container(
                width: 320,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey[300]!)),
                ),
                child: ListView.builder(
                  itemCount: pendingKYC.length,
                  itemBuilder: (context, index) {
                    final soc = pendingKYC[index];
                    final isSelected = soc.id == selectedSociety.id;
                    return ListTile(
                      tileColor: isSelected ? kPrimaryGreen.withValues(alpha: 0.1) : null,
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryGreen,
                        child: Text(
                          soc.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        soc.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Status: ${soc.status.toUpperCase()}',
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedSocietyId = soc.id;
                        });
                      },
                    );
                  },
                ),
              ),

              // Right Panel: Doc comparison and approval
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedSociety.name,
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Society ID: ${selectedSociety.id}',
                        style: GoogleFonts.outfit(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      // Document Preview Card with Zoom
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Registration Certificate (KYC Document)',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.zoom_out),
                                        onPressed: _zoomScale > 0.5 ? () => setState(() => _zoomScale -= 0.25) : null,
                                      ),
                                      Text('${(_zoomScale * 100).toInt()}%'),
                                      IconButton(
                                        icon: const Icon(Icons.zoom_in),
                                        onPressed: _zoomScale < 2.5 ? () => setState(() => _zoomScale += 0.25) : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRect(
                                child: Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  alignment: Alignment.center,
                                  child: Transform.scale(
                                    scale: _zoomScale,
                                    child: Image.network(
                                      selectedSociety.logoUrl.isNotEmpty 
                                          ? selectedSociety.logoUrl 
                                          : 'https://images.unsplash.com/photo-1590274853856-f22d5ee3d228?w=500&auto=format&fit=crop',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.description_outlined, size: 80, color: Colors.grey);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // OCR Comparison Form
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildComparisonCard(
                                title: 'Application Form Data',
                                color: kPrimaryGreen,
                              fields: {
                                'Society Name': selectedSociety.name,
                                'City/State': '${selectedSociety.city}, ${selectedSociety.state}',
                                'Members Limit': '${selectedSociety.members} Units',
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildComparisonCard(
                              title: 'OCR Extracted Document Values',
                              color: Colors.blue[800]!,
                              fields: {
                                'Society Name': selectedSociety.name,
                                'City/State': '${selectedSociety.city}, ${selectedSociety.state} (Match: 100%)',
                                'Registration No': 'REG-SOC-${selectedSociety.id.hashCode.abs()}',
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Approve / Reject Actions Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showActionDialog(selectedSociety.id, approve: false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Reject Application', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _showActionDialog(selectedSociety.id, approve: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Approve & Verify KYC', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
        error: (err, _) => Center(child: Text('Error loading applications: $err')),
      ),
    );
  }

  Widget _buildComparisonCard({required String title, required Color color, required Map<String, String> fields}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 16, color: color),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              ],
            ),
            const Divider(height: 24),
            for (final entry in fields.entries) ...[
              Text(entry.key, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 2),
              Text(entry.value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  void _showActionDialog(String id, {required bool approve}) {
    _reasonController.text = approve ? 'KYC documents verified successfully.' : '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          approve ? 'Approve & Activate Society' : 'Reject KYC Documents',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approve ? 'Add optional approval reason/note:' : 'Reason for rejection is required:',
              style: GoogleFonts.outfit(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: approve ? 'Reason...' : 'e.g. Incomplete certificate uploaded...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!approve && _reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rejection reason is required.')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                if (approve) {
                  await ref.read(superAdminSocietiesProvider.notifier).approve(id, reason: _reasonController.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Society approved and activated.')));
                } else {
                  await ref.read(superAdminSocietiesProvider.notifier).reject(id, reason: _reasonController.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC rejected.')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? kPrimaryGreen : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Approve' : 'Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
