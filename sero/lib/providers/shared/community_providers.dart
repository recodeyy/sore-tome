import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/community.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/classified_item.dart';
import 'package:sero/models/interest_profile.dart';
import 'package:sero/models/facility_booking.dart';
import 'package:sero/models/guest_pass.dart';
import 'package:sero/models/pulse.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/models/society_record.dart';
import 'package:sero/providers/shared/auth_provider.dart';

// --- Visitor & Guest Gate Providers ---
final activeGuestPassesProvider = StreamProvider.autoDispose<List<GuestPass>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('guest_passes')
      .where('society_id', isEqualTo: user.societyId) // Filter by society
      .where('residentId', isEqualTo: user.id) // Also filter by resident for privacy
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) => snapshot.docs
          .map((doc) => GuestPass.fromMap(doc.data(), doc.id))
          .toList());
});

final allTodayGuestPassesProvider = StreamProvider.autoDispose<List<GuestPass>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);
  
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  
  return FirebaseFirestore.instance
      .collection('guest_passes')
      .where('society_id', isEqualTo: user.societyId)
      .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) => snapshot.docs
          .map((doc) => GuestPass.fromMap(doc.data(), doc.id))
          .toList());
});

// --- Pulse Providers ---
final directPulseProvider = StreamProvider.autoDispose<Pulse?>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('pulses')
      .where('society_id', isEqualTo: user.societyId)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) => snapshot.docs.isEmpty 
          ? null 
          : Pulse.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id));
});

// --- Facility & Booking Providers ---
// CUTOVER: canonical Postgres `/amenities` ({ amenities: [...] }). The legacy
// Firestore `facilities` collection is empty under the Postgres backend, so the
// resident Facilities screen read empty. Now backed by real amenity data
// (Clubhouse, Community Hall, …) via Facility.fromAmenity.
final facilitiesProvider = FutureProvider.autoDispose<List<Facility>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  final res = await ApiService.get('/amenities');
  final data = ApiService.unwrap(res);
  final rows = data is List
      ? data
      : (data is Map ? (data['amenities'] as List? ?? const []) : const []);
  return rows
      .map((r) => Facility.fromAmenity((r as Map).cast<String, dynamic>()))
      .toList();
});

final userBookingsProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('society_id', isEqualTo: user.societyId)
      .where('userId', isEqualTo: user.id)
      .orderBy('startTime', descending: true)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) => snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList());
});

// --- Marketplace Provider ---
final marketplaceProvider = StreamProvider.autoDispose<List<ClassifiedItem>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('marketplace')
      .where('society_id', isEqualTo: user.societyId)
      .where('isSold', isEqualTo: false)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) {
    final items = snapshot.docs
        .map((doc) => ClassifiedItem.fromMap(doc.data(), doc.id))
        .toList();
    // Sort client-side
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  });
});

// --- Discovery Provider ---
final discoveryProvider = StreamProvider.autoDispose<List<InterestProfile>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('interests')
      .where('society_id', isEqualTo: user.societyId)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) => snapshot.docs
          .map((doc) => InterestProfile.fromMap(doc.data(), doc.id))
          .toList());
});

// --- Polls Provider ---
// CUTOVER: canonical Postgres v2 polls (/polls-v2). The list row carries no
// options/tallies, so for each open poll we fetch /polls-v2/:id (option labels
// + hasVoted) and /polls-v2/:id/results (per-option counts) and merge them via
// Poll.fromV2. Vote is cast against /polls-v2/:id/vote with { optionId }.
/// Shared loader for the canonical Postgres v2 polls (`/polls-v2`). [query] is
/// an optional querystring (e.g. '?status=open'). The list row carries no
/// options/tallies, so for each poll we fetch `/polls-v2/:id` (option labels +
/// hasVoted) and `/polls-v2/:id/results` (per-option counts) and merge them via
/// Poll.fromV2.
Future<List<Poll>> _loadPollsV2(String query) async {
  final listRes = await ApiService.get('/polls-v2$query');
  if (listRes.statusCode != 200) {
    throw Exception(jsonDecode(listRes.body)['error'] ?? 'Failed to load polls');
  }
  final rawPolls = (jsonDecode(listRes.body)['polls'] as List? ?? const []);

  final polls = <Poll>[];
  for (final raw in rawPolls) {
    final pollId = (raw as Map<String, dynamic>)['id']?.toString() ?? '';
    if (pollId.isEmpty) continue;

    // Enrich each poll independently. A single failing/slow detail or results
    // request must NOT sink the whole list — the resident still gets the poll
    // (with whatever data we could load) instead of a full-screen error.
    final labels = <String, String>{}; // optionId -> label
    final counts = <String, int>{}; // optionId -> count
    var hasVoted = false;

    try {
      // Detail → option labels (+ ids) and whether this requester has voted.
      final detailRes = await ApiService.get('/polls-v2/$pollId');
      if (detailRes.statusCode == 200) {
        final detail = jsonDecode(detailRes.body) as Map<String, dynamic>;
        hasVoted = detail['hasVoted'] == true;
        for (final o in (detail['options'] as List? ?? const [])) {
          final m = o as Map<String, dynamic>;
          labels[m['id'].toString()] = (m['label'] ?? '').toString();
        }
      }

      // Results → per-option counts (may be hidden by results_visibility; then 0).
      final resultsRes = await ApiService.get('/polls-v2/$pollId/results');
      if (resultsRes.statusCode == 200) {
        final results = jsonDecode(resultsRes.body) as Map<String, dynamic>;
        for (final o in (results['options'] as List? ?? const [])) {
          final m = o as Map<String, dynamic>;
          counts[m['id'].toString()] = (m['count'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {
      // Swallow per-poll enrichment errors; fall through with whatever we have.
    }

    final optionList = labels.entries
        .map((e) => PollOption(
              id: e.key,
              label: e.value,
              count: counts[e.key] ?? 0,
            ))
        .toList();

    polls.add(Poll.fromV2(raw, options: optionList, hasVoted: hasVoted));
  }
  return polls;
}

final pollsProvider = FutureProvider.autoDispose<List<Poll>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  return _loadPollsV2('?status=open');
});

// --- Events Provider (DEPRECATED: Use eventsProvider in events_provider.dart) ---

// --- All Polls Provider (active + closed, for admin governance views) ---
// CUTOVER: canonical Postgres `/polls-v2` (all statuses). The legacy Firestore
// `polls` collection is empty under the Postgres backend, so the admin polls
// dashboard read here.
final allPollsProvider = FutureProvider.autoDispose<List<Poll>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  return _loadPollsV2('');
});

// --- Meetings / AGM Provider (mirrors pollsProvider pattern) ---
class Meeting {
  final String id;
  final String title;
  final String type; // e.g. AGM, Committee, Emergency
  final String agenda;
  final DateTime date;
  final String status; // scheduled, completed, cancelled

  Meeting({
    required this.id,
    required this.title,
    required this.type,
    required this.agenda,
    required this.date,
    required this.status,
  });

  factory Meeting.fromMap(Map<String, dynamic> map, String id) {
    return Meeting(
      id: id,
      title: map['title'] ?? '',
      type: map['type'] ?? 'Committee',
      agenda: map['agenda'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'scheduled',
    );
  }
}

// CUTOVER: canonical Postgres `/meetings` ({ meetings: [...] }). Each row is a
// `meetings` table record (snake_case: title, type, scheduled_at, status). The
// list does not embed agenda items, so `agenda` is left blank here.
final meetingsProvider = FutureProvider.autoDispose<List<Meeting>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  final res = await ApiService.get('/meetings');
  final data = ApiService.unwrap(res);
  final rows = data is List
      ? data
      : (data is Map ? (data['meetings'] as List? ?? const []) : const []);
  final meetings = rows.map((r) {
    final m = (r as Map).cast<String, dynamic>();
    return Meeting(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      type: (m['type'] ?? 'committee').toString(),
      agenda: (m['agenda'] ?? '').toString(),
      date: DateTime.tryParse(
              (m['scheduled_at'] ?? m['created_at'] ?? '').toString()) ??
          DateTime.now(),
      status: (m['status'] ?? 'scheduled').toString(),
    );
  }).toList();
  meetings.sort((a, b) => b.date.compareTo(a.date));
  return meetings;
});

// --- Committee Provider ---
// CUTOVER: canonical Postgres `/members-v2/committee` ({ committee: [...] }).
// Each row joins committee_members (designation) to the member directory
// (member_name, member_phone). The legacy Firestore `committee` collection is
// empty under the Postgres backend.
final committeeProvider =
    FutureProvider.autoDispose<List<CommitteeMember>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  final res = await ApiService.get('/members-v2/committee');
  final data = ApiService.unwrap(res);
  final rows = data is List
      ? data
      : (data is Map ? (data['committee'] as List? ?? const []) : const []);
  return rows
      .map((r) {
        final m = (r as Map).cast<String, dynamic>();
        return CommitteeMember(
          id: (m['id'] ?? m['member_id'] ?? '').toString(),
          name: (m['member_name'] ?? m['name'] ?? '').toString(),
          role: (m['designation'] ?? m['role'] ?? '').toString(),
          phoneNumber: (m['member_phone'] ?? m['phone'])?.toString(),
        );
      })
      .where((c) => c.name.isNotEmpty)
      .toList();
});

// --- Society Operations Providers (Phase 15) ---
final allIssuesStreamProvider = StreamProvider.autoDispose<List<Issue>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('issues')
      .where('society_id', isEqualTo: user.societyId)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) {
        final list = snapshot.docs.map((doc) => Issue.fromMap(doc.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

final societyRecordsProvider = StreamProvider.autoDispose<List<SocietyRecord>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('records')
      .where('society_id', isEqualTo: user.societyId)
      .snapshots()
      .handleError((_) {}) // never surface Firestore permission/network errors to the UI
      .map((snapshot) {
    final list = snapshot.docs.map((doc) => SocietyRecord.fromMap(doc.data(), doc.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

// --- Actions for Admins ---
class CommunityActions {
  static Future<void> createPoll(String question, List<String> options, String societyId) async {
    final votes = {for (var i = 0; i < options.length; i++) i.toString(): 0};
    await FirebaseFirestore.instance.collection('polls').add({
      'society_id': societyId,
      'question': question,
      'options': options,
      'votes': votes,
      'votedUsers': [],
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  static Future<void> voteInPoll(String pollId, int optionIndex, String userId) async {
    final docRef = FirebaseFirestore.instance.collection('polls').doc(pollId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final votedUsers = List<String>.from(snapshot.data()?['votedUsers'] ?? []);
      if (votedUsers.contains(userId)) return;

      votedUsers.add(userId);
      final votes = Map<String, int>.from(snapshot.data()?['votes'] ?? {});
      final key = optionIndex.toString();
      votes[key] = (votes[key] ?? 0) + 1;

      transaction.update(docRef, {
        'votes': votes,
        'votedUsers': votedUsers,
      });
    });
  }

  static Future<void> addEvent(String title, String description, DateTime date, String location, String societyId) async {
    // DEPRECATED: Use EventsNotifier.addEvent instead for API consistency
  }

  static Future<void> setPollActive(String pollId, bool isActive) async {
    await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
      'isActive': isActive,
    });
  }

  // --- Meeting / AGM Actions ---
  static Future<void> createMeeting({
    required String title,
    required String type,
    required String agenda,
    required DateTime date,
    required String societyId,
  }) async {
    await FirebaseFirestore.instance.collection('meetings').add({
      'society_id': societyId,
      'title': title,
      'type': type,
      'agenda': agenda,
      'date': Timestamp.fromDate(date),
      'status': 'scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setMeetingStatus(String meetingId, String status) async {
    await FirebaseFirestore.instance.collection('meetings').doc(meetingId).update({
      'status': status,
    });
  }

  static Future<void> addCommitteeMember(String name, String role, String societyId, {String? avatarUrl, String? phone}) async {
    await FirebaseFirestore.instance.collection('committee').add({
      'society_id': societyId,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'phoneNumber': phone,
    });
  }

  // --- Visitor Actions ---
  static Future<void> createGuestPass({
    required String visitorName,
    required GuestPassCategory category,
    required String residentId,
    required String residentName,
    required String flatNumber,
    required String societyId,
  }) async {
    await FirebaseFirestore.instance.collection('guest_passes').add({
      'society_id': societyId,
      'visitorName': visitorName,
      'category': category.toString().split('.').last,
      'status': 'approved',
      'residentId': residentId,
      'residentName': residentName,
      'flatNumber': flatNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> checkInVisitor(String passId) async {
    await FirebaseFirestore.instance.collection('guest_passes').doc(passId).update({
      'status': 'arrived',
      'arrivalTime': FieldValue.serverTimestamp(),
    });
  }

  // --- Hub & Moderation Actions ---
  static Future<void> postPulse(String content, String societyId, {bool isHighPriority = false, String authorName = 'Secretary'}) async {
    await FirebaseFirestore.instance.collection('pulses').add({
      'society_id': societyId,
      'content': content,
      'authorName': authorName,
      'authorRole': 'Committee',
      'createdAt': FieldValue.serverTimestamp(),
      'isHighPriority': isHighPriority,
    });
  }

  static Future<void> removeListing(String itemId) async {
    await FirebaseFirestore.instance.collection('marketplace').doc(itemId).delete();
  }

  static Future<void> toggleListingVisibility(String itemId, bool isSold) async {
    await FirebaseFirestore.instance.collection('marketplace').doc(itemId).update({
      'isSold': isSold,
    });
  }

  // --- Operations Actions (Phase 15) ---
  static Future<void> updateIssueStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('issues').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addSocietyRecord(SocietyRecord record, String societyId) async {
    await FirebaseFirestore.instance.collection('records').add({
      ...record.toMap(),
      'society_id': societyId,
      'postedBy': 'Secretary',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeRecord(String id) async {
    await FirebaseFirestore.instance.collection('records').doc(id).delete();
  }
}
