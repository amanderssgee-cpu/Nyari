// lib/widgets/save_picker_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../i18n.dart';
import '../models/saves.dart';
import '../services/saves_service.dart';

class SavePickerBottomSheet extends StatelessWidget {
  final String businessId;
  final List<String> current; // e.g. ['wishlist','visited']

  const SavePickerBottomSheet({
    super.key,
    required this.businessId,
    required this.current,
  });

  bool _has(SaveList l) => current.contains(l.key);

  String _label(BuildContext context, SaveList list) {
    switch (list) {
      case SaveList.wishlist:
        return tr(context, en: 'Wishlist', id: 'Wishlist');
      case SaveList.favorites:
        return tr(context, en: 'Favorites', id: 'Favorit');
      case SaveList.visited:
        return tr(context, en: 'Visited', id: 'Pernah dikunjungi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = tr(context, en: 'Save to lists', id: 'Simpan ke daftar');
    final subtitle =
        tr(context, en: 'Tap to toggle', id: 'Ketuk untuk mengubah');

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle),
          ),
          _tile(context, SaveList.wishlist, Icons.bookmark_add_outlined),
          _tile(context, SaveList.favorites, Icons.favorite_border),
          _tile(context, SaveList.visited, Icons.check_circle_outline),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, SaveList list, IconData icon) {
    final selected = _has(list);
    return ListTile(
      leading: Icon(icon),
      title: Text(_label(context, list)),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: () async {
        await SavesService.toggle(businessId, list);
      },
    );
  }
}
