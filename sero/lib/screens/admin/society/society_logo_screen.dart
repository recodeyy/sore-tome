import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/admin/admin_domain_providers.dart';
import 'package:sero/services/admin/admin_society_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Society Logo Upload — Screen 4 of 6
/// Shows upload placeholder, current logo, and upload button.
class SocietyLogoScreen extends ConsumerWidget {
  const SocietyLogoScreen({super.key});

  /// Set the logo to a hosted image URL via PUT /society/logo.
  /// (Backend stores a fileUrl; object-storage byte upload is not yet available.)
  Future<void> _uploadLogo(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Society Logo', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'Hosted logo image URL (https://…)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await AdminSocietyService.updateLogo(url);
      if (ok) {
        ref.invalidate(societyProfileProvider);
        messenger.showSnackBar(const SnackBar(content: Text('Logo updated'), backgroundColor: Color(0xFF064E3B)));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Could not update logo'), backgroundColor: Color(0xFFB91C1C)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFB91C1C)));
    }
  }

  /// Remove the logo via DELETE /society/logo.
  Future<void> _deleteLogo(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove logo?'),
        content: const Text('This will remove the current society logo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await AdminSocietyService.deleteLogo();
      if (ok) {
        ref.invalidate(societyProfileProvider);
        messenger.showSnackBar(const SnackBar(content: Text('Logo removed'), backgroundColor: Color(0xFF064E3B)));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Could not remove logo'), backgroundColor: Color(0xFFB91C1C)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFB91C1C)));
    }
  }

  /// Bottom-sheet menu of logo actions: set/replace URL or remove.
  void _showLogoOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.upload_outlined, color: Color(0xFF064E3B)),
              title: Text('Set / Replace Logo',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
              onTap: () {
                Navigator.pop(ctx);
                _uploadLogo(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              title: Text('Remove Logo',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
              onTap: () {
                Navigator.pop(ctx);
                _deleteLogo(context, ref);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(societyProfileProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── App Bar ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Society Logo',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF1E293B)),
                  onPressed: () => _showLogoOptions(context, ref),
                ),
              ],
            ),
          ),

          Expanded(
            child: profileAsync.when(
              loading: () => const LiveLoadingView(label: 'Loading society logo…'),
              error: (e, _) => LiveErrorView(
                error: e,
                onRetry: () => ref.invalidate(societyProfileProvider),
              ),
              data: (data) {
                final profile = (data['profile'] as Map?) ?? const {};
                final name = (profile['name'] ?? '').toString();
                final logoUpdateDate =
                    (profile['logo_updated_at'] ?? profile['logoUpdatedAt'] ?? '').toString();
                return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Upload Area ──
                  GestureDetector(
                    onTap: () => _uploadLogo(context, ref),
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 2,
                          // dashed style achieved via custom paint is heavy,
                          // falling back to solid border with light color
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: Color(0xFF064E3B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload Society Logo',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG upto 2MB',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Current Logo ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Current Logo',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Color(0xFF064E3B), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                logoUpdateDate.isEmpty
                                    ? 'No logo update history'
                                    : 'Updated on $logoUpdateDate',
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _deleteLogo(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Upload Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _uploadLogo(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Upload New Logo',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
              },
            ),
          ),
        ],
      ),
    );
  }
}
