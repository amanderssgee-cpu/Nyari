// lib/pages/my_reviews_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../i18n.dart';
import '../language_provider.dart';
import '../widgets/translated_text.dart';
import 'business_profile_page.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  // Tiny in-memory cache so we don’t refetch the same business many times
  final Map<String, Future<Map<String, dynamic>?>> _bizCache = {};

  Future<Map<String, dynamic>?> _fetchBusiness(String businessId) {
    return _bizCache.putIfAbsent(businessId, () async {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .get();
        if (!snap.exists) return null;
        return snap.data() as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIndo = context.watch<LanguageProvider>().isIndo;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(context, en: 'My Reviews', id: 'Ulasan Saya')),
        ),
        body: Center(
          child: Text(
            tr(
              context,
              en: 'Please sign in to view your reviews.',
              id: 'Silakan masuk untuk melihat ulasan Anda.',
            ),
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ✅ Server-side sorting using the index you already enabled:
    // Collection group: reviews | Fields: userId (ASC), timestamp (DESC)
    final stream = FirebaseFirestore.instance
        .collectionGroup('reviews')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, en: 'My Reviews', id: 'Ulasan Saya')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr(context,
                      en: 'Something went wrong.', id: 'Terjadi kesalahan.'),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs =
              snapshot.data?.docs ?? const <QueryDocumentSnapshot<Object?>>[];

          if (docs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {},
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Text(
                      tr(
                        context,
                        en: 'You haven’t written any reviews yet.',
                        id: 'Kamu belum menulis ulasan.',
                      ),
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                // Parent path: businesses/{id}/reviews/{uid}
                final businessId = doc.reference.parent.parent?.id;

                final ratingRaw = data['rating'];
                final double rating = ratingRaw is int
                    ? ratingRaw.toDouble()
                    : (ratingRaw is double
                        ? ratingRaw
                        : double.tryParse('$ratingRaw') ?? 0.0);

                final commentOriginal = (data['comment'] ?? '').toString();
                final initials = (data['initials'] ?? '?').toString();
                final reviewerName = (data['reviewerName'] ?? '').toString();

                // Display timestamp (createdAt). If you later prefer edits first,
                // switch to updatedAt once that index is Enabled.
                final shownTime = (data['timestamp'] as Timestamp?)?.toDate() ??
                    (data['updatedAt'] as Timestamp?)?.toDate();

                return FutureBuilder<Map<String, dynamic>?>(
                  future: businessId != null
                      ? _fetchBusiness(businessId)
                      : Future.value(null),
                  builder: (context, bizSnap) {
                    final biz = bizSnap.data;
                    final bizName = biz == null
                        ? (isIndo
                            ? 'Bisnis tidak ditemukan'
                            : 'Business not found')
                        : (isIndo
                            ? (biz['name_id'] ?? biz['name'] ?? '')
                            : (biz['name'] ?? ''));
                    final imageUrl = biz?['imageUrl'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CircleAvatar(
                                child: Text(
                                  (initials.isNotEmpty ? initials : '?')
                                      .substring(0, 1),
                                ),
                              ),
                        title: Text(
                          bizName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (shownTime != null)
                              Text(
                                timeago.format(
                                  shownTime,
                                  locale: isIndo ? 'id' : 'en',
                                ),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            if (commentOriginal.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              TranslatedText(
                                originalText: commentOriginal,
                                targetLang: isIndo ? 'id' : 'en',
                              ),
                            ],
                            if (reviewerName.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                tr(context, en: 'by', id: 'oleh') +
                                    ' $reviewerName',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                            if (bizSnap.connectionState ==
                                ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: (biz == null || businessId == null)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BusinessProfilePage(
                                      businessId: businessId,
                                      businessData: biz,
                                    ),
                                  ),
                                );
                              },
                        dense: false,
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
