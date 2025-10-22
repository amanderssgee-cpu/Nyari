import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PhotoService {
  static final _fs = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// Save a curated photo (you already have an HTTPS download URL).
  static Future<void> addCuratedPhotoFromUrl({
    required String businessId,
    required String url,
    String? caption,
    int? priority, // lower number shows earlier (e.g., 0..100)
  }) async {
    await _fs
        .collection('businesses')
        .doc(businessId)
        .collection('photos')
        .add({
      'url': url,
      'caption': caption ?? '',
      'source': 'curated',
      'priority': priority ?? 1000,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// If you only have a gs:// path, convert to HTTPS and save as curated.
  static Future<void> addCuratedPhotoFromGsRef({
    required String businessId,
    required String gsPathOrUrl, // e.g. 'gs://<bucket>/.../file.jpg'
    String? caption,
    int? priority,
  }) async {
    final ref = _storage.refFromURL(gsPathOrUrl);
    final https = await ref.getDownloadURL();
    await addCuratedPhotoFromUrl(
      businessId: businessId,
      url: https,
      caption: caption,
      priority: priority,
    );
  }

  /// Stream curated photos ordered by priority ASC, then createdAt DESC
  static Stream<List<Map<String, dynamic>>> curatedPhotosStream(
    String businessId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> q = _fs
        .collection('businesses')
        .doc(businessId)
        .collection('photos')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        )
        .where('source', isEqualTo: 'curated')
        .orderBy('priority')
        .orderBy('createdAt', descending: true);

    if (limit != null) q = q.limit(limit);

    return q.snapshots().map(
          (s) => s.docs.map((d) => d.data()).toList(),
        );
  }

  /// Community photos (from reviews.imageUrls[])
  static Stream<List<String>> communityPhotoUrlsStream(String businessId) {
    return _fs
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) {
      final urls = <String>[];
      for (final d in s.docs) {
        final data = d.data() as Map<String, dynamic>;
        final List<dynamic> arr =
            (data['imageUrls'] as List?) ?? const <dynamic>[];
        for (final item in arr) {
          final u = item?.toString() ?? '';
          if (u.isNotEmpty) urls.add(u);
        }
      }
      return urls;
    });
  }
}
