import 'package:sero/services/api_service.dart';

/// Service for Society Setup and configuration.
///
/// CUTOVER: backed by Postgres `/society/*` and `/structure/*` routes (raw JSON).
class AdminSocietyService {
  /// GET /society/profile — basic society profile.
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiService.get('/society/profile');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// PUT /society/profile — update society profile.
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final res = await ApiService.put('/society/profile', data);
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// GET /society/logo — logo metadata.
  static Future<Map<String, dynamic>> getLogo() async {
    final res = await ApiService.get('/society/logo');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /society/setup-progress — onboarding/setup completion state.
  static Future<Map<String, dynamic>> getSetupProgress() async {
    final res = await ApiService.get('/society/setup-progress');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /structure/summary — wings/blocks/units/occupancy counts.
  static Future<Map<String, dynamic>> getStructureSummary() async {
    final res = await ApiService.get('/structure/summary');
    final data = ApiService.unwrap(res);
    return (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  /// GET /structure/wings — list of wings.
  static Future<List<dynamic>> getWings() async {
    final res = await ApiService.get('/structure/wings');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['wings'] is List) return data['wings'] as List;
    return const [];
  }

  /// GET /structure/blocks — list of blocks.
  static Future<List<dynamic>> getBlocks() async {
    final res = await ApiService.get('/structure/blocks');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['blocks'] is List) return data['blocks'] as List;
    return const [];
  }

  /// GET /structure/units — list of flats/units.
  static Future<List<dynamic>> getUnits() async {
    final res = await ApiService.get('/structure/units');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['units'] is List) return data['units'] as List;
    return const [];
  }

  /// POST /structure/wings — create a wing.
  static Future<bool> addWing(String name) async {
    final res = await ApiService.post('/structure/wings', {'name': name});
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// POST /structure/blocks — create a block.
  static Future<bool> addBlock(String name, {String? wingId}) async {
    final res = await ApiService.post('/structure/blocks', {
      'name': name,
      if (wingId != null) 'wingId': wingId,
    });
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// POST /structure/units — create a flat/unit.
  static Future<bool> addUnit(String number, {String? wingId, String? blockId}) async {
    final res = await ApiService.post('/structure/units', {
      'number': number,
      if (wingId != null) 'wingId': wingId,
      if (blockId != null) 'blockId': blockId,
    });
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// PUT /society/logo — set the society logo URL.
  static Future<bool> updateLogo(String fileUrl) async {
    final res = await ApiService.put('/society/logo', {'fileUrl': fileUrl});
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// DELETE /society/logo — remove the society logo.
  static Future<bool> deleteLogo() async {
    final res = await ApiService.delete('/society/logo');
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// GET /members-v2/committee — committee directory (designation + member info).
  static Future<List<dynamic>> getCommittee() async {
    final res = await ApiService.get('/members-v2/committee');
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['committee'] is List) return data['committee'] as List;
    return const [];
  }

  /// GET /members-v2 — member directory (used to pick who to add to the committee).
  static Future<List<dynamic>> getMembers({String? status}) async {
    final path = (status != null && status.isNotEmpty) ? '/members-v2?status=$status' : '/members-v2';
    final res = await ApiService.get(path);
    final data = ApiService.unwrap(res);
    if (data is List) return data;
    if (data is Map && data['members'] is List) return data['members'] as List;
    return const [];
  }

  /// POST /members-v2/:id/committee — assign a committee designation to a member.
  static Future<bool> addCommitteeRole(
    String memberId,
    String designation, {
    String? termStart,
    String? termEnd,
  }) async {
    final res = await ApiService.post('/members-v2/$memberId/committee', {
      'designation': designation,
      if (termStart != null && termStart.isNotEmpty) 'termStart': termStart,
      if (termEnd != null && termEnd.isNotEmpty) 'termEnd': termEnd,
    });
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
