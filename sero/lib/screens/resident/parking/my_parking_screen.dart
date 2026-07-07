import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/resident/my_parking_provider.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Resident "My Parking" — shows the parking slot(s) the admin has allocated to
/// this resident / their flat. Read side of the cross-role parking flow.
class MyParkingScreen extends ConsumerWidget {
  const MyParkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myParkingProvider);
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
        title: Text('My Parking',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myParkingProvider),
        child: async.when(
          loading: () => const LiveLoadingView(label: 'Loading your parking…'),
          error: (e, _) => LiveErrorView(
              error: e, onRetry: () => ref.invalidate(myParkingProvider)),
          data: (slots) {
            if (slots.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  LiveEmptyView(
                    icon: Icons.local_parking_outlined,
                    message:
                        'No parking allocated yet.\nYour society admin will assign a slot to your flat.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: slots.length,
              itemBuilder: (context, i) => _SlotCard(slot: slots[i]),
            );
          },
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final MyParkingAllocation slot;
  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: const Icon(Icons.local_parking_rounded,
                color: Color(0xFF059669), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.slotCode.isNotEmpty ? slot.slotCode : 'Slot',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (slot.slotType.isNotEmpty) slot.slotType.toUpperCase(),
                    if (slot.slotLocation.isNotEmpty) slot.slotLocation,
                  ].join(' • '),
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFF64748B)),
                ),
                if (slot.vehiclePlate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '🚗 ${slot.vehiclePlate}${slot.makeModel.isNotEmpty ? ' • ${slot.makeModel}' : ''}',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text('Allocated',
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669))),
          ),
        ],
      ),
    );
  }
}
