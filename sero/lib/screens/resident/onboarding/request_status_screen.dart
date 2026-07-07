import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

import 'society_search_screen.dart';

/// Resident onboarding step 4 (MR-006): join-request status. Polls
/// GET /resident/join-requests/my and renders pending / approved / rejected /
/// no-request states. Also used as the resident shell gate for accounts with
/// no active society membership yet.
class RequestStatusScreen extends ConsumerStatefulWidget {
  const RequestStatusScreen({super.key});

  @override
  ConsumerState<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends ConsumerState<RequestStatusScreen> {
  Timer? _poller;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  /// null → no join request on record.
  Map<String, dynamic>? _request;

  /// True when the endpoint itself is missing (backend not deployed yet):
  /// fall back to a generic waiting card instead of an error wall.
  bool _endpointMissing = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _poller = Timer.periodic(const Duration(seconds: 30), (_) => _fetch(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    if (!silent && mounted) setState(() => _refreshing = true);
    try {
      final res = await ApiService.get('/resident/join-requests/my');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = (body is Map && body['data'] is Map) ? body['data'] : body;
        final req = (data is Map) ? data['request'] : null;
        setState(() {
          _request = req is Map ? req.cast<String, dynamic>() : null;
          _endpointMissing = false;
          _error = null;
          _loading = false;
          _refreshing = false;
        });
      } else if (res.statusCode == 404) {
        // Either "no request yet" or the endpoint is not deployed — both are
        // handled as friendly non-error states.
        setState(() {
          _request = null;
          _endpointMissing = true;
          _error = null;
          _loading = false;
          _refreshing = false;
        });
      } else {
        setState(() {
          _error = 'Could not check your request status (${res.statusCode}).';
          _loading = false;
          _refreshing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_request == null && !_endpointMissing) {
          _error = 'Could not reach the server. Check your connection.';
        }
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _continueToApp() async {
    await ref.read(authProvider.notifier).refreshUser();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  void _reApply() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SocietySearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryGreen))
              : _error != null
                  ? ErrorRetryView(message: _error!, onRetry: _fetch)
                  : Column(
                      children: [
                        Expanded(child: Center(child: _stateCard(user?.status))),
                        TextButton(
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                          child: Text(
                            'Logout',
                            style: GoogleFonts.outfit(
                              color: kTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _stateCard(String? accountStatus) {
    final status = (_request?['status'] ?? '').toString();

    if (_request == null) {
      // No join request on record. If the account itself is pending admin
      // approval (legacy register flow), show the waiting card; otherwise
      // invite the user to find their society.
      if (accountStatus == 'pending') {
        return _waitingCard(
          title: 'Approval Pending',
          message:
              'Your profile is being reviewed by your society admin. We will unlock your dashboard once approved.',
        );
      }
      return _panel(
        icon: Icons.apartment_rounded,
        iconColor: kAccentGreen,
        iconBg: kLightMint,
        title: 'Join your society',
        message:
            'You are not part of a society yet. Search for your society and request to join your flat.',
        primary: ('Find My Society', _reApply),
      );
    }

    switch (status) {
      case 'approved':
        return _panel(
          icon: Icons.check_circle_rounded,
          iconColor: kAccentGreen,
          iconBg: kLightMint,
          title: 'You are approved!',
          message:
              'Your society admin approved your request. Welcome home — your resident dashboard is ready.',
          primary: ('Continue', _continueToApp),
        );
      case 'rejected':
        final reason = (_request?['reason'] ?? '').toString();
        return _panel(
          icon: Icons.cancel_rounded,
          iconColor: kError,
          iconBg: const Color(0xFFFEE2E2),
          title: 'Request declined',
          message: reason.isNotEmpty
              ? 'Reason: $reason'
              : 'Your join request was declined by the society admin. You can re-apply with the correct details.',
          primary: ('Re-apply', _reApply),
        );
      default: // pending
        return _waitingCard(
          title: 'Request Pending',
          message:
              'Your join request${_unitLabel()} is waiting for the society admin to approve it. This usually takes less than a day.',
        );
    }
  }

  String _unitLabel() {
    final unit = (_request?['unitNumber'] ?? '').toString();
    return unit.isEmpty ? '' : ' for flat $unit';
  }

  Widget _waitingCard({required String title, required String message}) {
    return _panel(
      icon: Icons.hourglass_top_rounded,
      iconColor: kWarning,
      iconBg: const Color(0xFFFEF3C7),
      title: title,
      message: message,
      primary: (
        _refreshing ? 'Checking…' : 'Refresh Status',
        _refreshing ? null : () => _fetch(),
      ),
    );
  }

  Widget _panel({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    (String, VoidCallback?)? primary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSlateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: iconColor, size: 40),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13.5, color: kTextSecondary, height: 1.55),
          ),
          if (primary != null) ...[
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: primary.$2,
                child: Text(primary.$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
