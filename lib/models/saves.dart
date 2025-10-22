// lib/models/saves.dart
import 'package:flutter/material.dart';

/// The three logical lists a user can save a business to.
enum SaveList { wishlist, favorites, visited }

extension SaveListX on SaveList {
  String get key {
    switch (this) {
      case SaveList.wishlist:
        return 'wishlist';
      case SaveList.favorites:
        return 'favorites';
      case SaveList.visited:
        return 'visited';
    }
  }

  String get label {
    switch (this) {
      case SaveList.wishlist:
        return 'Wishlist';
      case SaveList.favorites:
        return 'Favorites';
      case SaveList.visited:
        return 'Visited';
    }
  }

  IconData get icon {
    switch (this) {
      case SaveList.wishlist:
        return Icons.bookmark_add_outlined;
      case SaveList.favorites:
        return Icons.favorite_border;
      case SaveList.visited:
        return Icons.check_circle_outline;
    }
  }
}

/// UI model for a saved item row.
class SavedEntry {
  final String businessId;
  final List<String> lists; // e.g. ['wishlist','favorites']
  final String? businessName;
  final String? businessImageUrl;

  const SavedEntry({
    required this.businessId,
    required this.lists,
    this.businessName,
    this.businessImageUrl,
  });

  bool get inWishlist => lists.contains(SaveList.wishlist.key);
  bool get inFavorites => lists.contains(SaveList.favorites.key);
  bool get inVisited => lists.contains(SaveList.visited.key);
}
