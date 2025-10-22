// lib/widgets/save_lists_button.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/saves.dart';
import '../services/saves_service.dart';
import '../i18n.dart'; // 👈 for tr(context, ...)

class SaveListsButton extends StatelessWidget {
  final String businessId;
  const SaveListsButton({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      // Signed-out view (disabled chip)
      return Tooltip(
        message:
            tr(context, en: 'Sign in to save', id: 'Masuk untuk menyimpan'),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEBFF),
            borderRadius: BorderRadius.circular(21),
          ),
          child:
              const Icon(Icons.bookmark_add_outlined, color: Color(0xFF201E50)),
        ),
      );
    }

    return StreamBuilder<List<String>>(
      stream: SavesService.listsStream(businessId),
      builder: (context, snap) {
        final lists = snap.data ?? const <String>[];
        final inWishlist = lists.contains(SaveList.wishlist.key);
        final inFavorites = lists.contains(SaveList.favorites.key);
        final inVisited = lists.contains(SaveList.visited.key);

        // top icon priority: favorites > wishlist > visited > add
        IconData topIcon = Icons.bookmark_add_outlined;
        Color topColor = const Color(0xFF201E50);
        if (inFavorites) {
          topIcon = Icons.favorite;
          topColor = const Color(0xFFE11D48);
        } else if (inWishlist) {
          topIcon = Icons.bookmark;
        } else if (inVisited) {
          topIcon = Icons.check_circle;
          topColor = const Color(0xFF22C55E);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: () => _openPicker(context, inWishlist, inFavorites, inVisited),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(topIcon, color: topColor),
          ),
        );
      },
    );
  }

  void _openPicker(BuildContext context, bool w, bool f, bool v) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        bool wishlist = w;
        bool favorites = f;
        bool visited = v;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> setFlag(SaveList list, bool value) async {
              setSheetState(() {
                switch (list) {
                  case SaveList.wishlist:
                    wishlist = value;
                    break;
                  case SaveList.favorites:
                    favorites = value;
                    break;
                  case SaveList.visited:
                    visited = value;
                    break;
                }
              });
              await SavesService.setFlag(businessId, list, value);
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      tr(context, en: 'Save to lists', id: 'Simpan ke daftar'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      tr(context,
                          en: 'Choose one or more',
                          id: 'Pilih satu atau lebih'),
                    ),
                  ),
                  CheckboxListTile(
                    value: wishlist,
                    onChanged: (v) => setFlag(SaveList.wishlist, v ?? false),
                    title: Text(tr(context, en: 'Wishlist', id: 'Wishlist')),
                    secondary: const Icon(Icons.bookmark_add_outlined),
                  ),
                  CheckboxListTile(
                    value: favorites,
                    onChanged: (v) => setFlag(SaveList.favorites, v ?? false),
                    title: Text(tr(context, en: 'Favorites', id: 'Favorit')),
                    secondary: const Icon(Icons.favorite_border),
                  ),
                  CheckboxListTile(
                    value: visited,
                    onChanged: (v) => setFlag(SaveList.visited, v ?? false),
                    title: Text(
                        tr(context, en: 'Visited', id: 'Pernah dikunjungi')),
                    secondary: const Icon(Icons.check_circle_outline),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await SavesService.clearAll(businessId);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(
                            tr(context, en: 'Clear all', id: 'Hapus semua')),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr(context, en: 'Done', id: 'Selesai')),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
