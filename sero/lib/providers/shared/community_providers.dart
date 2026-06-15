import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/models/community.dart';
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
      .map((snapshot) => snapshot.docs.isEmpty 
          ? null 
          : Pulse.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id));
});

// --- Facility & Booking Providers ---
final facilitiesProvider = StreamProvider.autoDispose<List<Facility>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('facilities')
      .where('society_id', isEqualTo: user.societyId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Facility.fromMap(doc.data(), doc.id))
          .toList());
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
      .map((snapshot) => snapshot.docs
          .map((doc) => InterestProfile.fromMap(doc.data(), doc.id))
          .toList());
});

// --- Polls Provider ---
final pollsProvider = StreamProvider.autoDispose<List<Poll>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('polls')
      .where('society_id', isEqualTo: user.societyId)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    final polls = snapshot.docs
        .map((doc) => Poll.fromMap(doc.data(), doc.id))
        .toList();
    // Sort client-side to avoid needing a composite index
    polls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return polls;
  });
});

// --- Events Provider (DEPRECATED: Use eventsProvider in events_provider.dart) ---

// --- Committee Provider ---
final committeeProvider = StreamProvider.autoDispose<List<CommitteeMember>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('committee')
      .where('society_id', isEqualTo: user.societyId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => CommitteeMember.fromMap(doc.data(), doc.id))
          .toList());
});

// --- Society Operations Providers (Phase 15) ---
final allIssuesStreamProvider = StreamProvider.autoDispose<List<Issue>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('issues')
      .where('society_id', isEqualTo: user.societyId)
      .snapshots()
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
