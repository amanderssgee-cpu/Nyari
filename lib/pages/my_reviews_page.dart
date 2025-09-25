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
        final snap =
            await FirebaseFirestore.instance
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
    final email = user?.email;

    // Single stream for *all* reviews, then filter client-side to the user.
    // For large datasets, store `uid` in the review doc and query with .where('uid', isEqualTo: uid)
    final stream =
        FirebaseFirestore.instance
            .collectionGroup('reviews')
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
              child: Text(
                tr(
                  context,
                  en: 'Something went wrong.',
                  id: 'Terjadi kesalahan.',
                ),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter reviews that belong to the current user
          final all = snapshot.data?.docs ?? const [];
          final mine =
              all.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final rUid = data['uid'] ?? data['userId']; // common keys
                final rEmail =
                    (data['reviewerEmail'] ?? data['email'])?.toString();
                if (uid != null && rUid != null && '$rUid' == uid) return true;
                if (email != null && rEmail != null && rEmail == email)
                  return true;
                return false;
              }).toList();

          if (mine.isEmpty) {
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
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              itemCount: mine.length,
              itemBuilder: (context, index) {
                final doc = mine[index];
                final data = doc.data() as Map<String, dynamic>;

                // Extract parent businessId from path: businesses/{id}/reviews/{rid}
                final businessId = doc.reference.parent.parent?.id;

                final ratingRaw = data['rating'];
                final double rating =
                    ratingRaw is int
                        ? ratingRaw.toDouble()
                        : (ratingRaw is double
                            ? ratingRaw
                            : double.tryParse('$ratingRaw') ?? 0.0);

                final commentOriginal = data['comment']?.toString() ?? '';
                final initials = data['initials']?.toString() ?? '?';
                final reviewerName = data['reviewerName']?.toString() ?? '';
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                return FutureBuilder<Map<String, dynamic>?>(
                  future:
                      businessId != null
                          ? _fetchBusiness(businessId)
                          : Future.value(null),
                  builder: (context, bizSnap) {
                    final biz = bizSnap.data;
                    final bizName =
                        biz == null
                            ? (isIndo
                                ? 'Bisnis tidak ditemukan'
                                : 'Business not found')
                            : (isIndo
                                ? (biz['name_id'] ?? biz['name'] ?? '')
                                : (biz['name'] ?? ''));
                    final imageUrl = biz?['imageUrl'] as String?;
                    final tapToOpen = tr(
                      context,
                      en: 'Open Profile',
                      id: 'Buka Profil',
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading:
                            imageUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(Icons.store, size: 40),
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
                            if (timestamp != null)
                              Text(
                                timeago.format(
                                  timestamp,
                                  locale: isIndo ? 'id' : 'en',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
                        onTap:
                            (biz == null || businessId == null)
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => BusinessProfilePage(
                                            businessId: businessId,
                                            businessData: biz,
                                          ),
                                    ),
                                  );
                                },
                        onLongPress: () {},
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
