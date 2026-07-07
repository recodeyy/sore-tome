import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/widgets/shared/sero_ui.dart';

import 'unit_select_screen.dart';

/// Resident onboarding step 1 (MR-006): search-as-you-type society lookup
/// against GET /societies/search?q= (public endpoint).
class SocietySearchScreen extends StatefulWidget {
  const SocietySearchScreen({super.key});

  @override
  State<SocietySearchScreen> createState() => _SocietySearchScreenState();
}

class _SocietySearchScreenState extends State<SocietySearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/societies/search?q=${Uri.encodeQueryComponent(query)}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = (body is Map && body['data'] is Map) ? body['data'] : body;
        final list = ((data is Map ? data['societies'] : null) as List?) ?? const [];
        setState(() {
          _results = list.map((s) => (s as Map).cast<String, dynamic>()).toList();
          _searched = true;
          _loading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _error = 'Society search is not available yet. Please try again later.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Search failed (${res.statusCode}). Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the server. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Join your society',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: kTextPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingStepHeader(step: 1, title: 'Find your society'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by society name or city…',
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const SkeletonList(itemCount: 4, padding: EdgeInsets.fromLTRB(20, 8, 20, 20));
    }
    if (_error != null) {
      return ErrorRetryView(
        message: _error!,
        onRetry: () {
          final q = _searchCtrl.text.trim();
          if (q.length >= 2) _search(q);
        },
      );
    }
    if (!_searched) {
      return const EmptyState(
        icon: Icons.apartment_rounded,
        title: 'Search for your society',
        message: 'Type at least 2 characters of your society name or city to get started.',
      );
    }
    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.location_city_rounded,
        title: 'No societies found',
        message: 'Try a different spelling, or ask your society office if SERO is enabled.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final s = _results[i];
        final name = (s['name'] ?? 'Society').toString();
        final city = (s['city'] ?? '').toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kLightMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apartment_rounded, color: kPrimaryGreen),
            ),
            title: Text(
              name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary),
            ),
            subtitle: city.isEmpty
                ? null
                : Text(city, style: GoogleFonts.outfit(fontSize: 12, color: kTextSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: kTextSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UnitSelectScreen(
                    societyId: (s['id'] ?? '').toString(),
                    societyName: name,
                    societyCity: city,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Shared stepper header for the onboarding flow (Step X of 3).
class OnboardingStepHeader extends StatelessWidget {
  final int step;
  final String title;

  const OnboardingStepHeader({super.key, required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i < step;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: active ? kAccentGreen : kSlateBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            'Step $step of 3',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kAccentGreen,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
