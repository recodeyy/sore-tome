import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/community_providers.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/facility_booking.dart';

class FacilitiesScreen extends ConsumerWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Book Amenities',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: facilitiesAsync.when(
        data: (facilities) {
          if (facilities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pool_outlined,
                      size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  Text('No amenities available yet',
                      style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8), fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: facilities.length,
            itemBuilder: (context, index) => _FacilityCard(
              facility: facilities[index],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FacilityCard extends ConsumerStatefulWidget {
  final Facility facility;
  const _FacilityCard({required this.facility});

  @override
  ConsumerState<_FacilityCard> createState() => _FacilityCardState();
}

class _FacilityCardState extends ConsumerState<_FacilityCard> {
  bool isBooking = false;

  final Map<int, IconData> _facilityIcons = {
    0: Icons.sports_tennis_outlined, // Tennis
    1: Icons.pool_outlined, // Pool
    2: Icons.meeting_room_outlined, // Clubhouse
    3: Icons.fitness_center_outlined, // Gym
    4: Icons.local_parking_outlined, // Parking
  };

  void _showBookingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String startTime = '09:00';
    String endTime = '10:00';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Book ${widget.facility.name}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: GoogleFonts.outfit(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              // Time selection
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: startTime,
                      decoration:
                          const InputDecoration(labelText: 'Start Time'),
                      items: ['06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
                              '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
                              '18:00', '19:00', '20:00', '21:00', '22:00']
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => startTime = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: endTime,
                      decoration:
                          const InputDecoration(labelText: 'End Time'),
                      items: ['07:00', '08:00', '09:00', '10:00', '11:00',
                              '12:00', '13:00', '14:00', '15:00', '16:00',
                              '17:00', '18:00', '19:00', '20:00', '21:00', '22:00']
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => endTime = val!),
                    ),
                  ),
                ],
              ),
              if (widget.facility.hourlyRate > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${widget.facility.hourlyRate}/hour will be charged',
                                style: GoogleFonts.outfit(
                                    color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Amount will be added to your monthly ledger.',
                                style: GoogleFonts.outfit(
                                    color: Colors.orange.withValues(alpha: 0.8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isBooking ? null : () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isBooking
                  ? null
                  : () async {
                      setState(() => isBooking = true);
                      try {
                        final dateStr =
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                        final res = await ApiService.post(
                          '/facilities/${widget.facility.id}/book',
                          {
                            'date': dateStr,
                            'startTime': startTime,
                            'endTime': endTime,
                          },
                        );

                        if (res.statusCode == 201) {
                          ref.invalidate(userBookingsProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Booked successfully!'),
                                backgroundColor: kPrimaryGreen,
                              ),
                            );
                          }
                        } else {
                          final body = jsonDecode(res.body);
                          throw Exception(body['error'] ?? 'Booking failed');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setState(() => isBooking = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
              ),
              child: isBooking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('CONFIRM'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue.withValues(alpha: 0.8), kPrimaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(
                  _facilityIcons[widget.facility.name.length % 5] ??
                      Icons.home_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.facility.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.facility.hourlyRate > 0
                            ? '₹${widget.facility.hourlyRate}/hour'
                            : 'Free to use',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.facility.description.isNotEmpty)
                  Text(
                    widget.facility.description,
                    style: GoogleFonts.outfit(
                        color: Colors.grey[600], fontSize: 13),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      widget.facility.availabilityHours,
                      style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showBookingDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.event_available_outlined,
                        size: 18),
                    label: Text('BOOK NOW',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
