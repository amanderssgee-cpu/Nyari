import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized writer for reviews. Enforces 1 review per user per business by
/// writing to: businesses/{businessId}/reviews/{userId}
class ReviewsService {
  ReviewsService._();
  static final instance = ReviewsService._();
  final _db = FirebaseFirestore.instance;

  /// If a review exists, update it and append the previous state into `history[]`.
  /// Field names match your existing reader: `rating`, `comment`, `timestamp`.
  Future<void> submitReview({
    required String businessId,
    required String userId,
    required int rating, // 1..5
    required String comment,
    String? reviewerName,
    String? reviewerEmail,
    List<String> imageUrls = const [], // HTTPS URLs only
  }) async {
    final docRef = _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .doc(userId); // <-- one-per-user

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final now = FieldValue.serverTimestamp();

      if (snap.exists) {
        final prev = snap.data() as Map<String, dynamic>;

        final historyEntry = {
          'rating': prev['rating'],
          'comment': prev['comment'],
          'imageUrls': prev['imageUrls'] ?? [],
          'timestamp': prev['timestamp'], // when that version was saved
          'updatedAt': prev['updatedAt'], // previous edit marker (if any)
        };

        tx.update(docRef, {
          'rating': rating,
          'comment': comment,
          'imageUrls': imageUrls,
          'reviewerName': reviewerName ?? prev['reviewerName'],
          'reviewerEmail': reviewerEmail ?? prev['reviewerEmail'],
          'uid': userId, // keep for your existing filtering
          'updatedAt': now,
          'edited': true,
          'history': FieldValue.arrayUnion([historyEntry]),
          // Don't touch original timestamp—keep it as "created at"
        });
      } else {
        tx.set(docRef, {
          'uid': userId, // your reader looks for uid/email
          'rating': rating,
          'comment': comment,
          'imageUrls': imageUrls,
          'reviewerName': reviewerName,
          'reviewerEmail': reviewerEmail,
          'timestamp': now, // createdAt (your list orders by this)
          'updatedAt': now,
          'edited': false,
          'history': [],
          // Optional cosmetics your UI sometimes uses:
          // 'initials': (reviewerName != null && reviewerName.isNotEmpty)
          //     ? reviewerName.trim().split(RegExp(r'\s+')).map((s) => s[0]).take(2).join().toUpperCase()
          //     : '?',
        });
      }
    });
  }
}
