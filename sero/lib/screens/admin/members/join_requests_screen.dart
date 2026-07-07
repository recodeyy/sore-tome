import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

/// Admin member-approval screen (MR §9): lists pending resident join requests
/// from GET /members-v2/join-requests and lets the admin approve / reject via
/// POST /members-v2/join-requests/:id/approve|reject. A 409 means the request
/// was already decided elsewhere — the list silently refreshes.
class JoinRequestsScreen extends StatefulWidget {
  /// When embedded inside the Members tab we hide the AppBar.
  final bool embedded;

  const JoinRequestsScreen({super.key, this.embedded = false});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  /// Ids currently being approved/rejected (disables their buttons).
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted && _error != null) setState(() => _error = null);
    try {
      final res = await ApiService.get('/members-v2/join-requests');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = (body is Map && body['data'] is Map) ? body['data'] : body;
        final list = (data is Map)
            ? (data['requests'] ?? data['request'] ?? [])
            : (body is List ? body : []);
        setState(() {
          _requests = (list is List)
              ? list
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList()
              : [];
          _loading = false;
          _error = null;
        });
      } else if (res.statusCode == 404) {
        // Endpoint not deployed yet — treat as empty, not an error wall.
        setState(() {
          _requests = [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load join requests (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the server. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _decide(Map<String, dynamic> req, bool approve) async {
    final id = '${req['id'] ?? req['_id'] ?? ''}';
    if (id.isEmpty || _busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      final res = await ApiService.post(
        '/members-v2/join-requests/$id/${approve ? 'approve' : 'reject'}',
        {},
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Request approved' : 'Request rejected'),
            backgroundColor: approve ? kPrimaryGreen : kTextPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (res.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This request was already decided.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed (${res.statusCode}). Try again.'),
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy.remove(id));
        _fetch();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      color: kPrimaryGreen,
      onRefresh: _fetch,
      child: _buildBody(),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        elevation: 0,
        title: Text(
          'Join Requests',
          style: GoogleFonts.outfit(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) return const SkeletonList(itemCount: 4, itemHeight: 120);
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          ErrorRetryView(message: _error!, onRetry: () {
            setState(() => _loading = true);
            _fetch();
          }),
        ],
      );
    }
    final pending = _requests
        .where((r) => '${r['status'] ?? 'pending'}'.toLowerCase() == 'pending')
        .toList();
    if (pending.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          EmptyState(
            icon: Icons.how_to_reg_rounded,
            title: 'No pending join requests',
            message:
                'When residents apply to join your society, their requests will appear here.',
            actionLabel: 'Refresh',
            onAction: () {
              setState(() => _loading = true);
              _fetch();
            },
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = pending[i];
        final id = '${r['id'] ?? r['_id'] ?? ''}';
        return _JoinRequestCard(
          request: r,
          busy: _busy.contains(id),
          onApprove: () => _decide(r, true),
          onReject: () => _decide(r, false),
        );
      },
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JoinRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  String get _name =>
      '${request['name'] ?? request['resident_name'] ?? request['residentName'] ?? 'Resident'}';

  String get _unit {
    final unit = request['unit_number'] ??
        request['unitNumber'] ??
        request['requested_unit'] ??
        request['requestedUnit'];
    final wing = request['wing'];
    if (unit == null || '$unit'.isEmpty) return 'Unit not specified';
    return wing != null && '$wing'.isNotEmpty ? 'Unit $wing-$unit' : 'Unit $unit';
  }

  String get _phone => '${request['phone'] ?? request['mobile'] ?? ''}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kLightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    color: kPrimaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _phone.isEmpty ? _unit : '$_unit · $_phone',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusChip(
                label: 'PENDING',
                semantic: ChipSemantic.warning,
                icon: Icons.hourglass_top_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kError,
                    side: const BorderSide(color: kError, width: 1.2),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
