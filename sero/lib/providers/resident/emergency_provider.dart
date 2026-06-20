import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/providers/shared/auth_provider.dart';

/// A society-specific emergency / helpdesk contact.
class EmergencyContact {
  final String name;
  final String role;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.role,
    required this.phone,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> m) => EmergencyContact(
        name: (m['name'] ?? m['title'] ?? '').toString(),
        role: (m['role'] ?? m['designation'] ?? m['type'] ?? '').toString(),
        phone: (m['phone'] ?? m['contact'] ?? m['number'] ?? '').toString(),
      );
}

/// Society-specific emergency contacts (security office, maintenance head, etc.).
///
/// LIVE DATA: GET /resident/emergency-contacts — combines the society-configured
/// contacts (society_profiles.contacts) with the resident's own family members
/// flagged as emergency contacts, both resolved server-side and tenant/owner
/// scoped. If nothing is configured the list is empty and the UI shows a
/// truthful empty state. The national emergency NUMBERS (Ambulance 108 /
/// Police 100 / Fire 101) are fixed statutory values rendered statically in the
/// screen itself.
final emergencyContactsProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return const [];

  try {
    final res = await ApiService.get('/resident/emergency-contacts');
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body);
    final raw = (data is Map<String, dynamic>) ? data['contacts'] : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(EmergencyContact.fromMap)
        .where((c) => c.phone.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
});
