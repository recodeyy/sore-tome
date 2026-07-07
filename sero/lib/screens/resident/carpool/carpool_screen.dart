import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/providers/resident/carpool_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/common/async_state_views.dart';

/// Resident Carpool — share or find rides within the society.
class CarpoolScreen extends ConsumerWidget {
  const CarpoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(carpoolProvider);
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
        title: Text('Carpool',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Offer Ride',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(carpoolProvider),
        child: async.when(
          loading: () => const LiveLoadingView(label: 'Loading rides…'),
          error: (e, _) => LiveErrorView(
              error: e, onRetry: () => ref.invalidate(carpoolProvider)),
          data: (rides) {
            if (rides.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  LiveEmptyView(
                    icon: Icons.directions_car_outlined,
                    message:
                        'No rides yet.\nTap "Offer Ride" to share your first ride.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              itemCount: rides.length,
              itemBuilder: (context, i) => _RideCard(ride: rides[i]),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RideForm(),
    );
    if (created == true) ref.invalidate(carpoolProvider);
  }
}

String _formatRideTime(String iso) {
  if (iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour < 12 ? 'AM' : 'PM';
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]}, $h:$m $ampm';
}

class _RideCard extends StatelessWidget {
  final CarpoolRide ride;
  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final when = _formatRideTime(ride.rideTime);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trip_origin,
                  size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ride.fromLocation} → ${ride.toLocation}',
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (when.isNotEmpty)
                _meta(Icons.schedule, when),
              if (ride.seats > 0)
                _meta(Icons.event_seat, '${ride.seats} seats'),
            ],
          ),
          if (ride.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(ride.notes,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF64748B))),
          ],
          if (ride.posterName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('by ${ride.posterName}',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: const Color(0xFF94A3B8))),
          ],
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.outfit(
                fontSize: 12, color: const Color(0xFF64748B))),
      ],
    );
  }
}

class _RideForm extends StatefulWidget {
  const _RideForm();

  @override
  State<_RideForm> createState() => _RideFormState();
}

class _RideFormState extends State<_RideForm> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _seats = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _rideTime;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _seats.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _rideTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_from.text.trim().isEmpty || _to.text.trim().isEmpty) {
      setState(() => _error = 'From and To are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final seats = int.tryParse(_seats.text.trim());
    final body = <String, dynamic>{
      'fromLocation': _from.text.trim(),
      'toLocation': _to.text.trim(),
      if (_rideTime != null) 'rideTime': _rideTime!.toUtc().toIso8601String(),
      if (seats != null) 'seats': seats,
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
    };
    try {
      final res = await ApiService.post('/community/carpool', body);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(
            jsonDecode(res.body)['error'] ?? 'Failed to create ride');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Offer a ride',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _field(_from, 'From'),
          const SizedBox(height: 12),
          _field(_to, 'To'),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text(
                    _rideTime == null
                        ? 'Pick date & time (optional)'
                        : _formatRideTime(_rideTime!.toIso8601String()),
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _field(_seats, 'Seats',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _field(_notes, 'Notes', maxLines: 3),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.outfit(
                    color: const Color(0xFFEF4444), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064E3B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Post Ride',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
    );
  }
}
