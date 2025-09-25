// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../language_provider.dart';
import 'my_reviews_page.dart';
import 'admin_panel_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isIndo = context.watch<LanguageProvider>().isIndo;

    final name = user?.displayName ?? '';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, en: 'Profile', id: 'Profil'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              tr(
                context,
                en: 'Hi, ${name.isNotEmpty ? name : '!'} 👋',
                id: 'Hai, ${name.isNotEmpty ? name : '!'} 👋',
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Divider(),

            Text(
              tr(
                context,
                en:
                    "This is where you'll be able to manage your saved places, reviews, and app settings.",
                id:
                    "Di sini kamu dapat mengelola tempat tersimpan, ulasan, dan pengaturan aplikasi.",
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Divider(),

            Text(
              tr(context, en: 'Coming Soon:', id: 'Segera Hadir:'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: Text(
                tr(context, en: 'Saved Businesses', id: 'Bisnis Tersimpan'),
              ),
              onTap: () {
                // placeholder
              },
            ),

            ListTile(
              leading: const Icon(Icons.rate_review_outlined),
              title: Text(tr(context, en: 'My Reviews', id: 'Ulasan Saya')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyReviewsPage()),
                );
              },
            ),

            // Admin panel only for Amanda (kept as-is)
            if (user?.email == 'gonzales.amanda92@yahoo.com')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(tr(context, en: 'Admin Panel', id: 'Panel Admin')),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminPanelPage()),
                  );
                },
              ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(
                tr(context, en: 'App Settings', id: 'Pengaturan Aplikasi'),
              ),
              onTap: () {
                // placeholder
              },
            ),

            const Spacer(),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(tr(context, en: 'Sign Out', id: 'Keluar')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
