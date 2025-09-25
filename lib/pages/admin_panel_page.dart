import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_business_page.dart';

class AdminPanelPage extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> businessesRef =
      FirebaseFirestore.instance.collection('businesses');

  AdminPanelPage({super.key}); // <-- remove 'const'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: businessesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs; // List<QueryDocumentSnapshot<Map>>
          if (docs.isEmpty) {
            return const Center(child: Text('No businesses yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data(); // Map<String, dynamic>

              return ListTile(
                title: Text((data['name'] ?? '') as String),
                subtitle: Text((data['category'] ?? '') as String),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // pass the doc if your Edit page expects a DocumentSnapshot
                      builder: (_) => EditBusinessPage(business: doc),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
