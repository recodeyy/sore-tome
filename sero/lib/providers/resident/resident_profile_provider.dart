import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/providers/shared/auth_provider.dart';

/// Resident self-service profile data — family members, vehicles and KYC docs.
///
/// LIVE DATA (Postgres, owner/tenant-scoped on the backend):
///  - GET /resident/family   -> family_members for the caller's member record
///  - GET /resident/vehicles -> vehicles where owner_id = caller's user id
///  - GET /resident/kyc      -> kyc_documents for the caller's member record
///
/// The backend resolves the caller's own member/unit from the session; the
/// client never supplies an id, so a resident only ever sees their own rows.

class FamilyMember {
  final String name;
  final String relation;
  final String phone;
  final bool isEmergencyContact;

  const FamilyMember({
    required this.name,
    required this.relation,
    required this.phone,
    required this.isEmergencyContact,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> m) => FamilyMember(
        name: (m['name'] ?? '').toString(),
        relation: (m['relation'] ?? '').toString(),
        phone: (m['phone'] ?? '').toString(),
        isEmergencyContact: m['is_emergency_contact'] == true,
      );
}

class ResidentVehicle {
  final String plate;
  final String type;
  final String makeModel;

  const ResidentVehicle({
    required this.plate,
    required this.type,
    required this.makeModel,
  });

  factory ResidentVehicle.fromMap(Map<String, dynamic> m) => ResidentVehicle(
        plate: (m['plate'] ?? '').toString(),
        type: (m['type'] ?? '').toString(),
        makeModel: (m['make_model'] ?? '').toString(),
      );
}

class KycDocument {
  final String docType;
  final String status;
  final String rejectReason;

  const KycDocument({
    required this.docType,
    required this.status,
    required this.rejectReason,
  });

  factory KycDocument.fromMap(Map<String, dynamic> m) => KycDocument(
        docType: (m['doc_type'] ?? '').toString(),
        status: (m['status'] ?? 'pending').toString(),
        rejectReason: (m['reject_reason'] ?? '').toString(),
      );
}

List<Map<String, dynamic>> _listFrom(dynamic decoded, String key) {
  final raw = (decoded is Map<String, dynamic>) ? decoded[key] : null;
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList();
}

final residentFamilyProvider =
    FutureProvider.autoDispose<List<FamilyMember>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return const [];
  final res = await ApiService.get('/resident/family');
  if (res.statusCode != 200) return const [];
  return _listFrom(jsonDecode(res.body), 'family')
      .map(FamilyMember.fromMap)
      .toList();
});

final residentVehiclesProvider =
    FutureProvider.autoDispose<List<ResidentVehicle>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return const [];
  final res = await ApiService.get('/resident/vehicles');
  if (res.statusCode != 200) return const [];
  return _listFrom(jsonDecode(res.body), 'vehicles')
      .map(ResidentVehicle.fromMap)
      .toList();
});

final residentKycProvider =
    FutureProvider.autoDispose<List<KycDocument>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return const [];
  final res = await ApiService.get('/resident/kyc');
  if (res.statusCode != 200) return const [];
  return _listFrom(jsonDecode(res.body), 'kyc')
      .map(KycDocument.fromMap)
      .toList();
});
