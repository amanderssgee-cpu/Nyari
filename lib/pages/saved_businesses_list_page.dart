// lib/pages/saved_businesses_list_page.dart
import 'package:flutter/material.dart';

import '../models/saves.dart';
import '../services/saves_service.dart';

class SavedBusinessesListPage extends StatelessWidget {
  /// If null => show a 3-tab page (Wishlist / Favorites / Visited).
  /// If non-null => show only that one list.
  final SaveList? filter;

  const SavedBusinessesListPage({super.key, this.filter});

  @override
  Widget build(BuildContext context) {
    // Single-list screen
    if (filter != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_titleFor(filter!))),
        body: _SavedList(filter: filter!), // <- non-null here
      );
    }

    // 3-tab screen
    final tabs = const [
      (
        label: 'Wishlist',
        icon: Icons.bookmark_add_outlined,
        kind: SaveList.wishlist
      ),
      (
        label: 'Favorites',
        icon: Icons.favorite_border,
        kind: SaveList.favorites
      ),
      (
        label: 'Visited',
        icon: Icons.check_circle_outline,
        kind: SaveList.visited
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Businesses'),
          bottom: TabBar(
            tabs: [
              for (final t in tabs) Tab(text: t.label, icon: Icon(t.icon)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final t in tabs) _SavedList(filter: t.kind),
          ],
        ),
      ),
    );
  }

  String _titleFor(SaveList k) {
    switch (k) {
      case SaveList.wishlist:
        return 'Wishlist';
      case SaveList.favorites:
        return 'Favorites';
      case SaveList.visited:
        return 'Visited';
    }
  }
}

class _SavedList extends StatelessWidget {
  final SaveList filter;
  const _SavedList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SavedEntry>>(
      stream: SavesService.streamByList(filter),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snap.data!;
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _emptyText(filter),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = entries[i];
            final title = e.businessName ?? e.businessId;
            final image = e.businessImageUrl;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: image != null && image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(image,
                            width: 48, height: 48, fit: BoxFit.cover),
                      )
                    : CircleAvatar(
                        radius: 24,
                        child: Text(
                          (title.isNotEmpty ? title[0] : '?').toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                title: Text(title),
                subtitle: Text(_subtitle(filter)),
                trailing: IconButton(
                  tooltip: 'Remove from ${_titleFor(filter)}',
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      SavesService.setFlag(e.businessId, filter, false),
                ),
                onTap: () {
                  // TODO: Navigate to business profile if desired
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessProfilePage(businessId: e.businessId)));
                },
              ),
            );
          },
        );
      },
    );
  }

  String _emptyText(SaveList k) {
    switch (k) {
      case SaveList.wishlist:
        return 'No businesses in your Wishlist yet.';
      case SaveList.favorites:
        return 'No Favorites yet.';
      case SaveList.visited:
        return 'No Visited businesses yet.';
    }
  }

  String _subtitle(SaveList k) {
    switch (k) {
      case SaveList.wishlist:
        return 'In your Wishlist';
      case SaveList.favorites:
        return 'Marked as Favorite';
      case SaveList.visited:
        return 'Marked as Visited';
    }
  }

  String _titleFor(SaveList k) {
    switch (k) {
      case SaveList.wishlist:
        return 'Wishlist';
      case SaveList.favorites:
        return 'Favorites';
      case SaveList.visited:
        return 'Visited';
    }
  }
}
