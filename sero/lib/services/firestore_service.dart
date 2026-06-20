import 'dart:convert';
import 'package:sero/models/notice.dart';
import 'package:sero/models/issue.dart';
import 'package:sero/models/fund.dart';
import 'api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sero/models/society_record.dart';
import 'package:sero/models/facility_booking.dart';


class FirestoreService {
  // ---------- NOTICES ----------
  Future<List<Notice>> getNotices() async {
    final res = await ApiService.get('/notices');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['notices'] as List).map((x) => Notice.fromMap(x)).toList();
    }
    return [];
  }

  Future<void> postNotice(Notice notice) async {
    await ApiService.post('/notices', {
      'title': notice.title,
      'body': notice.body,
      'type': notice.tag,
    });
  }

  // ---------- ISSUES ----------
  Future<List<Issue>> getIssues() async {
    final res = await ApiService.get('/issues');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['issues'] as List).map((x) => Issue.fromMap(x)).toList();
    }
    return [];
  }

  Future<void> postIssue(Issue issue) async {
    await ApiService.post('/issues', {
      'title': issue.title,
      'description': issue.description,
      'category': 'other',
    });
  }

  Future<void> updateIssueStatus(String issueId, String status) async {
    await ApiService.patch('/issues/$issueId/status', {'status': status});
  }

  // ---------- FUNDS ----------
  Future<FundSummary> getFundSummary() async {
    final res = await ApiService.get('/funds/summary');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      
      final Map<String, double> breakdown = {};
      if (data['categoryBreakdown'] != null) {
        (data['categoryBreakdown'] as Map).forEach((k, v) {
          breakdown[k.toString()] = (v as num).toDouble();
        });
      }

      return FundSummary(
        totalCollected: (data['totalCollected'] ?? 0).toDouble(),
        totalSpent: (data['totalSpent'] ?? 0).toDouble(),
        categoryBreakdown: breakdown,
        outstandingDues: (data['outstandingDues'] ?? 0).toDouble(),
        overdueCount: (data['overdueCount'] ?? 0).toInt(),
        topExpenseCategories: data['topCategories'] ?? 'General Expenses',
      );
    }
    return FundSummary(totalCollected: 0, totalSpent: 0);
  }

  Future<List<FundTransaction>> getTransactions() async {
    final res = await ApiService.get('/funds/transactions');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['transactions'] as List).map((x) {
         return FundTransaction(
           id: x['id'],
           title: x['title'] ?? '',
           description: x['note'] ?? '',
           amount: x['type'] == 'credit' ? (x['amount'] as num).toDouble() : -1 * (x['amount'] as num).toDouble(),
           date: DateTime.tryParse(x['createdAt'] ?? '') ?? DateTime.now(),
         );
      }).toList();
    }
    return [];
  }

  Future<void> addTransaction(FundTransaction tx) async {
    await ApiService.post('/funds/transactions', {
      'title': tx.title,
      'amount': tx.amount.abs(),
      'type': tx.amount >= 0 ? 'credit' : 'debit',
      'category': tx.category, // V3.9: Add category
      'note': tx.description,
      'transactionId': tx.transactionId, // V3.9: Track AI/External IDs
    });
  }

  Future<List<OverdueResident>> getOverdueResidents() async {
    try {
      final res = await ApiService.get('/funds/maintenance-status');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['unpaid'] as List?; // V3.12: Null-safe guard
        if (list == null) return [];
        
        return list
            .map((x) => OverdueResident.fromMap(x))
            .toList();
      }
    } catch (e) {
      // Degraded Mode: Silent fail to prevent UI crash
      debugPrint('Error fetching overdue residents: $e');
    }
    return [];
  }

  // ---------- REAL-TIME STREAMS ----------
  Stream<List<Notice>> getNoticesStream(String societyId) {
    return FirebaseFirestore.instance
        .collection('notices')
        .where('society_id', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => Notice.fromMap(doc.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Corrected: use createdAt
          return list;
        });
  }

  Stream<List<Issue>> getIssuesStream(String userId, String societyId) {
    return FirebaseFirestore.instance
        .collection('issues')
        .where('society_id', isEqualTo: societyId)
        .where('postedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => Issue.fromMap(doc.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Issue>> getAllIssuesStream(String societyId) {
    return FirebaseFirestore.instance
        .collection('issues')
        .where('society_id', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => Issue.fromMap(doc.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Facility>> getFacilitiesStream(String societyId) {
    return FirebaseFirestore.instance
        .collection('facilities')
        .where('society_id', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Facility.fromMap(doc.data(), doc.id)).toList();
        });
  }

  Stream<List<SocietyRecord>> getRecordsStream(String societyId) {
    return FirebaseFirestore.instance
        .collection('records')
        .where('society_id', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => SocietyRecord.fromMap(doc.data(), doc.id)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ---------- OPERATIONAL ACTIONS ----------
  Future<void> updateIssueStatusAdmin(String id, String status) async {
    await FirebaseFirestore.instance.collection('issues').doc(id).update({'status': status});
  }

  Future<void> postSocietyRecord(SocietyRecord record) async {
    await FirebaseFirestore.instance.collection('records').add(record.toMap());
  }

  Stream<List<FundTransaction>> getTransactionsStream(String societyId) {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('society_id', isEqualTo: societyId)
        .where('type', isEqualTo: 'debit') // Focus on disbursements
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            return FundTransaction(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['note'] ?? '',
              amount: -1 * (data['amount'] as num).toDouble(),
              date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              category: data['category'] ?? 'Other',
            );
          }).toList();
          list.sort((a, b) => b.date.compareTo(a.date)); // Correct: uses date
          return list;
        });
  }
}


