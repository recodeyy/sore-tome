import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/models/classified_item.dart';
import 'package:sero/models/interest_profile.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/providers/shared/auth_provider.dart';

// --- 1. Marketplace View ---
class MarketplaceView extends ConsumerWidget {
  const MarketplaceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(marketplaceProvider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(
            context,
            'No items for sale yet',
            'Be the first to post something to your neighbors!',
            Icons.shopping_basket_outlined,
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return _MarketplaceCard(item: item).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1);
              },
              childCount: items.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String sub, IconData icon) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(sub, style: GoogleFonts.outfit(color: const Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {}, // Implementation later
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('POST AN ITEM', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  final ClassifiedItem item;
  const _MarketplaceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kPrimaryGreen,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "NEW",
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. Discovery View ---
class DiscoveryView extends ConsumerWidget {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(discoveryProvider);
    final user = ref.watch(authProvider).value;
    final isAdmin = user != null && ['admin', 'main_admin', 'secretary'].contains(user.role);

    return profilesAsync.when(
      data: (profiles) {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (isAdmin) _buildAdminAICard(context),
              const SizedBox(height: 16),
              if (profiles.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('Join the directory to meet neighbors!'),
                ))
              else
                ...profiles.map((p) => _DiscoveryCard(profile: p).animate().fade().slideX(begin: 0.1)),
            ]),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildAdminAICard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: kAccentGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                'SERO AI KNOWLEDGE',
                style: GoogleFonts.outfit(
                  color: kAccentGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Train Sero on your society rules and bylaws to provide accurate answers to residents.',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {}, // File picker logic
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('UPLOAD PDF BYLAWS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _DiscoveryCard extends StatelessWidget {
  final InterestProfile profile;
  const _DiscoveryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue.withValues(alpha: 0.2), kPrimaryBlue.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  profile.userName[0],
                  style: GoogleFonts.outfit(color: kPrimaryBlue, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.userName,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    ),
                    Text(
                      'Flat ${profile.flatNumber}',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: kPrimaryBlue.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {}, // Chat logic
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: kPrimaryBlue, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.interests.map((i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 4, color: kPrimaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    i,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
