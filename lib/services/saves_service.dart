// lib/services/saves_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/saves.dart';

class SavesService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _doc(
    String uid,
    String businessId,
  ) =>
      _db.collection('users').doc(uid).collection('saved').doc(businessId);

  /// Stream the string list of lists for a single business (e.g. ['wishlist']).
  static Stream<List<String>> listsStream(String businessId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _doc(user.uid, businessId).snapshots().map((snap) {
      final data = snap.data();
      final List<dynamic> raw = (data?['lists'] as List?) ?? const [];
      return raw.map((e) => e.toString()).toList();
    });
  }

  /// Toggle a list membership for a single business.
  static Future<void> toggle(String businessId, SaveList list) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[saves] toggle aborted (no user)');
      return;
    }

    final ref = _doc(user.uid, businessId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final current = ((snap.data()?['lists']) as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            <String>{};

        if (current.contains(list.key)) {
          current.remove(list.key);
        } else {
          current.add(list.key);
        }

        if (current.isEmpty) {
          print('[saves] DELETE $businessId (now empty)');
          tx.delete(ref);
        } else {
          print('[saves] SET $businessId -> ${current.toList()}');
          tx.set(
            ref,
            {
              'lists': current.toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
    } catch (e, st) {
      print('[saves] toggle error: $e\n$st');
      rethrow;
    }
  }

  /// Explicitly set (or unset) a single list flag for a business.
  static Future<void> setFlag(
    String businessId,
    SaveList list,
    bool value,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[saves] setFlag aborted (no user)');
      return;
    }

    final ref = _doc(user.uid, businessId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final current = ((snap.data()?['lists']) as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            <String>{};

        if (value) {
          current.add(list.key);
        } else {
          current.remove(list.key);
        }

        if (current.isEmpty) {
          print('[saves] DELETE $businessId (now empty)');
          tx.delete(ref);
        } else {
          print('[saves] SET $businessId -> ${current.toList()}');
          tx.set(
            ref,
            {
              'lists': current.toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
    } catch (e, st) {
      print('[saves] setFlag error: $e\n$st');
      rethrow;
    }
  }

  /// Remove all lists for a given business (delete the doc).
  static Future<void> clearAll(String businessId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    print('[saves] CLEAR $businessId');
    await _doc(user.uid, businessId).delete();
  }

  /// Stream SavedEntry rows for a given list tab (Wishlist/Favorites/Visited).
  ///
  /// Requires a composite index:
  ///   Collection: users/{uid}/saved
  ///   Fields: lists (array), updatedAt (desc)
  static Stream<List<SavedEntry>> streamByList(SaveList filter) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final q = _db
        .collection('users')
        .doc(user.uid)
        .collection('saved')
        .where('lists', arrayContains: filter.key)
        .orderBy('updatedAt', descending: true);

    return q.snapshots().asyncMap((qs) async {
      final orderedIds = <String>[];
      for (final d in qs.docs) {
        orderedIds.add(d.id);
      }
      if (orderedIds.isEmpty) return <SavedEntry>[];

      // Batch-fetch businesses (chunks of 10 due to whereIn limit)
      final bizMap = await _fetchBusinesses(orderedIds);

      // Build result in the same order
      final result = <SavedEntry>[];
      for (final id in orderedIds) {
        final biz = bizMap[id];
        if (biz == null) continue; // Business deleted or missing
        final data = qs.docs.firstWhere((d) => d.id == id).data();
        final lists = ((data['lists'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
        result.add(
          SavedEntry(
            businessId: id,
            lists: lists,
            businessName: (biz['name'] ?? '').toString(),
            businessImageUrl: (biz['imageUrl'] ?? '').toString(),
          ),
        );
      }
      return result;
    });
  }

  /// Helper: fetch businesses by IDs (chunks of 10).
  static Future<Map<String, Map<String, dynamic>>> _fetchBusinesses(
    List<String> ids,
  ) async {
    final out = <String, Map<String, dynamic>>{};
    const chunk = 10;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice =
          ids.sublist(i, i + chunk > ids.length ? ids.length : i + chunk);
      final snap = await _db
          .collection('businesses')
          .where(FieldPath.documentId, whereIn: slice)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final d in snap.docs) {
        out[d.id] = d.data();
      }
    }
    return out;
  }
}
