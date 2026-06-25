import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sero/providers/shared/channels_provider.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/providers/shared/events_provider.dart';
import 'package:sero/widgets/shared/branding_header.dart';
import 'package:sero/app/theme.dart';
import '../../shared/channels/channel_chat_screen.dart';
import 'widgets/resident_community_widgets.dart';
import 'widgets/hub_specialized_widgets.dart';

class ResidentChannelsScreen extends ConsumerStatefulWidget {
  const ResidentChannelsScreen({super.key});

  @override
  ConsumerState<ResidentChannelsScreen> createState() => _ResidentChannelsScreenState();
}

class _ResidentChannelsScreenState extends ConsumerState<ResidentChannelsScreen> {
  int _activeTab = 0; // 0=Chats, 1=Market, 2=Discovery

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          const BrandingHeader(),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOCIETY HUB',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryGreen,
                      letterSpacing: 2.0,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Community Connect',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 600.ms).slideX(begin: -0.1),
                ],
              ),
            ),
          ),

          // --- MODERN HUB TRIAGE (Segmented Pill) ---
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _hubTab('Chats', 0, Icons.chat_bubble_rounded),
                  _hubTab('Market', 1, Icons.shopping_bag_rounded),
                  _hubTab('Discovery', 2, Icons.explore_rounded),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
          ),

          // --- NATIVE SLIVER BRANCHING (Fixes the crash) ---
          if (_activeTab == 0) ...[
            const SliverToBoxAdapter(child: DailyPulseWidget()),
            const SliverToBoxAdapter(child: CommitteeBar()),
            _buildSliverActivitySection(),
            _buildSliverDiscussionsHeader(),
            _buildSliverChannelsList(channelsAsync),
          ],

          if (_activeTab == 1) ...[
            const MarketplaceView(),
          ],

          if (_activeTab == 2) ...[
            const DiscoveryView(),
          ],
          
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      ),
    );
  }

  Widget _buildSliverActivitySection() {
    return Consumer(
      builder: (context, ref, _) {
        final polls = ref.watch(pollsProvider).value ?? [];
        final events = ref.watch(eventsProvider).value ?? [];
        
        if (polls.isEmpty && events.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Text(
                  'ACTIVE NOW',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    ...polls.map((p) => CommunityPollWidget(poll: p)),
                    ...events.map((e) => ResidentEventCard(event: e)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverDiscussionsHeader() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 40, 24, 16),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'GENERAL DISCUSSIONS',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverChannelsList(AsyncValue channelsAsync) {
    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFF1F5F9)),
                    SizedBox(height: 16),
                    Text('No active channels found', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final channel = channels[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChannelItem(channel: channel),
                );
              },
              childCount: channels.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
    );
  }

  Widget _hubTab(String label, int index, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? kPrimaryGreen : const Color(0xFF94A3B8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelItem extends StatelessWidget {
  final dynamic channel;
  const _ChannelItem({required this.channel});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.chat_bubble_outline_rounded;
    Color color = const Color(0xFF3B82F6);
    
    final name = channel.name.toLowerCase();
    if (name.contains("announcement")) {
      icon = Icons.hub_rounded;
      color = const Color(0xFF345D7E);
    } else if (name.contains("security")) {
      icon = Icons.shield_outlined;
      color = const Color(0xFFEF4444);
    } else if (name.contains("maintenance")) {
      icon = Icons.handyman_outlined;
      color = const Color(0xFF8B5CF6);
    } else if (name.contains("social")) {
      icon = Icons.campaign_rounded;
      color = const Color(0xFF0EA5E9);
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
      ),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        channel.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (name.contains("announcement"))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "OFFICIAL",
                            style: GoogleFonts.outfit(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: kPrimaryGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.description,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }
}
