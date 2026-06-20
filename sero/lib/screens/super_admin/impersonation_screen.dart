import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/super_admin/super_admin_providers.dart';

class ImpersonationScreen extends ConsumerStatefulWidget {
  const ImpersonationScreen({super.key});

  @override
  ConsumerState<ImpersonationScreen> createState() => _ImpersonationScreenState();
}

class _ImpersonationScreenState extends ConsumerState<ImpersonationScreen> {
  final _userIdController = TextEditingController(text: 'resident-user-123');
  final _reasonController = TextEditingController();
  String? _selectedSocietyId;
  int _selectedDuration = 15;

  bool _isActive = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _userIdController.dispose();
    _reasonController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() {
      _isActive = true;
      _remainingSeconds = minutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopImpersonation(expired: true);
      }
    });
  }

  Future<void> _stopImpersonation({bool expired = false}) async {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = 0;
    });

    try {
      await ref.read(superAdminServiceProvider).stopImpersonationSession();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expired ? 'Impersonation session expired.' : 'Impersonation session terminated.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final societiesAsync = ref.watch(superAdminSocietiesProvider);

    return PopScope(
      canPop: !_isActive, // Prevent back navigation while impersonation is active
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please stop impersonation session before leaving.')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: kSlateBg,
        appBar: AppBar(
          backgroundColor: _isActive ? Colors.red[800] : kPrimaryGreen,
          title: Text(
            _isActive ? 'Impersonation Active' : 'Audited Impersonation Control',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isActive) ...[
                // Warning Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gpp_maybe_rounded, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IMPERSONATION MODE ACTIVE',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red[900], fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Every action you perform is logged under your operator ID for security compliance.',
                              style: GoogleFonts.outfit(color: Colors.red[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'Time Left',
                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600]),
                          ),
                          Text(
                            '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red[900]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isActive ? 'Active Session Details' : 'Configure Impersonation Session',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(height: 32),
                      societiesAsync.when(
                        data: (page) {
                          final societies = page.items;
                          if (societies.isEmpty) return const SizedBox();
                          final activeSocId = _selectedSocietyId ?? societies.first.id;
                          if (_selectedSocietyId == null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _selectedSocietyId = activeSocId;
                              });
                            });
                          }

                          return _isActive
                              ? _buildDetailRow('Society', societies.firstWhere((s) => s.id == activeSocId).name)
                              : DropdownButtonFormField<String>(
                                  value: activeSocId,
                                  decoration: InputDecoration(
                                    labelText: 'Target Society',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: societies.map((s) {
                                    return DropdownMenuItem(value: s.id, child: Text(s.name));
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedSocietyId = val;
                                    });
                                  },
                                );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 16),
                      _isActive
                          ? _buildDetailRow('Target User ID', _userIdController.text)
                          : TextField(
                              controller: _userIdController,
                              decoration: InputDecoration(
                                labelText: 'Target User UID/Phone',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                      const SizedBox(height: 16),
                      _isActive
                          ? _buildDetailRow('Reason', _reasonController.text)
                          : TextField(
                              controller: _reasonController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Auditable Reason',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                      const SizedBox(height: 16),
                      _isActive
                          ? _buildDetailRow('Duration', '$_selectedDuration minutes')
                          : Row(
                              children: [
                                Text('Duration: ', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                Wrap(
                                  spacing: 8,
                                  children: [5, 15, 30, 60].map((d) {
                                    final isSel = _selectedDuration == d;
                                    return ChoiceChip(
                                      selectedColor: kPrimaryGreen,
                                      label: Text('$d Min', style: TextStyle(color: isSel ? Colors.white : Colors.black)),
                                      selected: isSel,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedDuration = d;
                                          });
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_isActive) {
                              await _stopImpersonation();
                              return;
                            }

                            if (_reasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Auditable reason is required.')),
                              );
                              return;
                            }

                            try {
                              await ref.read(superAdminServiceProvider).createImpersonationSession(
                                    societyId: _selectedSocietyId ?? '',
                                    userId: _userIdController.text,
                                    reason: _reasonController.text,
                                    durationMinutes: _selectedDuration,
                                  );
                              _startTimer(_selectedDuration);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Impersonation session successfully started.')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to start session: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isActive ? Colors.red : kPrimaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _isActive ? 'End Impersonation Session' : 'Initiate Audited Session',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label: ',
              style: GoogleFonts.outfit(color: Colors.grey[500], fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
