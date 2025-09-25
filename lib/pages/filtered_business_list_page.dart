import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../i18n.dart';
import '../language_provider.dart';
import '../subcategory_locale.dart'; // 👈 add this
import 'business_profile_page.dart';

class FilteredBusinessListPage extends StatelessWidget {
  final String category;
  final String subcategory; // EN key
  final String selectedLanguage;

  const FilteredBusinessListPage({
    super.key,
    required this.category,
    required this.subcategory,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final isIndo = context.watch<LanguageProvider>().isIndo;
    final displaySub = subLabel(context, subcategory); // 👈 localized title

    final stream =
        FirebaseFirestore.instance
            .collection('businesses')
            .where('category', isEqualTo: category)
            .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(displaySub)),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                tr(context, en: 'An error occurred.', id: 'Terjadi kesalahan.'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs =
              snapshot.data?.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final sub = data['subcategory'];
                if (sub == null && category == 'Tattoos') return true;
                if (sub is List) return sub.contains(subcategory);
                if (sub is String) return sub == subcategory;
                return false;
              }).toList();

          if (docs == null || docs.isEmpty) {
            return Center(
              child: Text(
                tr(
                  context,
                  en: 'No businesses found.',
                  id: 'Tidak ada bisnis ditemukan.',
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final businessId = doc.id;
              final name =
                  isIndo
                      ? (data['name_id'] ?? data['name'] ?? '')
                      : (data['name'] ?? '');
              final imageUrl = data['imageUrl'];

              double rating = 0;
              final rawRating = data['rating'];
              if (rawRating is int)
                rating = rawRating.toDouble();
              else if (rawRating is double)
                rating = rawRating;
              else if (rawRating is String)
                rating = double.tryParse(rawRating) ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading:
                      imageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(Icons.store, size: 40),
                  title: Text(name),
                  subtitle: Row(
                    children: const [
                      Icon(Icons.location_on, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('0.5 km', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 12),
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                    ],
                  ),
                  trailing: Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BusinessProfilePage(
                              businessId: businessId,
                              businessData: data,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
