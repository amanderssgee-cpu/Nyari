import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class AllReviewsPage extends StatefulWidget {
  final String businessId;
  final String
  language; // ✅ Added this to receive language from BusinessProfilePage

  const AllReviewsPage({
    super.key,
    required this.businessId,
    required this.language,
  });

  @override
  State<AllReviewsPage> createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  String _sortBy = 'recent';

  @override
  Widget build(BuildContext context) {
    final isIndo = widget.language == 'id';

    return Scaffold(
      appBar: AppBar(
        title: Text(isIndo ? 'Semua Ulasan' : 'All Reviews'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _sortBy,
              dropdownColor: const Color(0xFF201E50),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _sortBy = newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'recent',
                  child: Text(isIndo ? 'Terbaru' : 'Most Recent'),
                ),
                DropdownMenuItem(
                  value: 'rating',
                  child: Text(isIndo ? 'Tertinggi' : 'Highest Rated'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('businesses')
                .doc(widget.businessId)
                .collection('reviews')
                .orderBy(
                  _sortBy == 'recent' ? 'timestamp' : 'rating',
                  descending: true,
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                isIndo ? 'Belum ada ulasan.' : 'No reviews yet.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final comment = data['comment'] ?? '';
              final rating = data['rating']?.toDouble() ?? 0;
              final initials = data['initials'] ?? '?';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(child: Text(initials)),
                  title: Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        size: 18,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (timestamp != null)
                        Text(
                          timeago.format(timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Text(comment),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
