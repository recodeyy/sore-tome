import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// §8 Resident parcels — deliveries logged at the gate for this flat. Shows the
/// one-time collection OTP for pending parcels. Live: GET /parcels.
class ParcelsScreen extends StatefulWidget {
  const ParcelsScreen({super.key});

  @override
  State<ParcelsScreen> createState() => _ParcelsScreenState();
}

class _ParcelsScreenState extends State<ParcelsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await ApiService.get('/parcels');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return ((data['parcels'] as List?) ?? const [])
          .map((x) => (x as Map).cast<String, dynamic>())
          .toList();
    }
    throw Exception('Failed to load parcels');
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Parcels',
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4, itemHeight: 92);
          }
          if (snap.hasError) {
            return ErrorRetryView(
              message: 'Could not load your parcels.',
              onRetry: _refresh,
            );
          }
          final parcels = snap.data ?? const [];
          if (parcels.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No parcels yet',
              message:
                  'When the gate logs a delivery for your flat, it will appear here with a collection code.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: parcels.length,
              itemBuilder: (context, i) => _ParcelCard(parcel: parcels[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ParcelCard extends StatelessWidget {
  final Map<String, dynamic> parcel;
  const _ParcelCard({required this.parcel});

  @override
  Widget build(BuildContext context) {
    final status = (parcel['status'] ?? 'pending').toString();
    final pending = status == 'pending';
    final courier = (parcel['courier'] ?? 'Parcel').toString();
    final created = parcel['created_at'] != null
        ? DateFormat('d MMM, h:mm a').format(
            DateTime.tryParse(parcel['created_at'].toString())?.toLocal() ??
                DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kLightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    color: kPrimaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courier,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF0F172A))),
                    if ((parcel['description'] ?? '').toString().isNotEmpty)
                      Text(parcel['description'].toString(),
                          style: GoogleFonts.inter(
                              color: const Color(0xFF64748B), fontSize: 13)),
                    if (created.isNotEmpty)
                      Text(created,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
              ),
              StatusChip(
                label: pending ? 'To collect' : 'Collected',
                semantic: pending ? ChipSemantic.warning : ChipSemantic.success,
              ),
            ],
          ),
          if (pending && (parcel['otp'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: kLightMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vpn_key_rounded,
                      color: kPrimaryGreen, size: 18),
                  const SizedBox(width: 10),
                  Text('Collection OTP: ',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF334155),
                          fontWeight: FontWeight.w500)),
                  Text(parcel['otp'].toString(),
                      style: GoogleFonts.robotoMono(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
