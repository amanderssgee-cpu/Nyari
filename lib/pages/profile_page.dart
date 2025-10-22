// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../language_provider.dart';

// Saved lists pages & enum
import '../models/saves.dart';
import 'saved_businesses_list_page.dart';

// Other pages
import 'my_reviews_page.dart';
import 'admin_panel_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  bool _isAdminEmail(String? email) {
    if (email == null) return false;
    const admins = <String>{
      'gonzales.amanda92@yahoo.com',
      'nyari.app@gmail.com',
    };
    return admins.contains(email.toLowerCase().trim());
  }

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
            Text(email,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            const Divider(),

            // Saved Businesses (opens bottom sheet with list choices)
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: Text(
                tr(context, en: 'Saved Businesses', id: 'Bisnis Tersimpan'),
              ),
              onTap: () => _openSavedSheet(context),
            ),

            // My Reviews
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

            // Admin panel (only for your two emails)
            if (_isAdminEmail(user?.email))
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

            // Settings placeholder
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(
                tr(context, en: 'App Settings', id: 'Pengaturan Aplikasi'),
              ),
              onTap: () {
                // TODO: implement settings page
              },
            ),

            const Spacer(),

            // Sign out
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(tr(context, en: 'Sign Out', id: 'Keluar')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) (context as Element).markNeedsBuild();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSavedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  tr(context, en: 'Saved Businesses', id: 'Bisnis Tersimpan'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(context,
                      en: 'Pick a list to view',
                      id: 'Pilih daftar untuk dilihat'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.all_inbox_outlined),
                title:
                    Text(tr(context, en: 'All Saved', id: 'Semua Tersimpan')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedBusinessesListPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 0),

              // Wishlist
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(tr(context, en: 'Wishlist', id: 'Wishlist')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SavedBusinessesListPage(filter: SaveList.wishlist),
                    ),
                  );
                },
              ),

              // Favorites
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: Text(tr(context, en: 'Favorites', id: 'Favorit')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SavedBusinessesListPage(filter: SaveList.favorites),
                    ),
                  );
                },
              ),

              // Visited
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title:
                    Text(tr(context, en: 'Visited', id: 'Pernah Dikunjungi')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SavedBusinessesListPage(filter: SaveList.visited),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
