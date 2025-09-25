import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'business_profile_page.dart';
import '../widgets/status_message.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<QueryDocumentSnapshot> _searchResults = [];
  String _searchQuery = '';
  String _sortOption = 'Distance'; // or 'Rating'
  Position? _userPosition;

  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() => _userPosition = pos);
    } catch (_) {
      // silently ignore; distance will fall back
    }
  }

  void _onSearchChanged(String value) {
    final q = value.trim();
    setState(() => _searchQuery = q);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(q);
    });
  }

  Future<void> _performSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults.clear();
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('businesses')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: '$query\uf8ff')
              .get();

      if (!mounted) return;
      final docs = snap.docs.toList();

      if (_sortOption == 'Rating') {
        docs.sort((a, b) {
          final aRating = _parseDouble(a['rating']);
          final bRating = _parseDouble(b['rating']);
          return bRating.compareTo(aRating);
        });
      } else if (_sortOption == 'Distance' && _userPosition != null) {
        docs.sort((a, b) {
          final aDist = _distanceFromUser(a);
          final bDist = _distanceFromUser(b);
          return aDist.compareTo(bDist);
        });
      }

      setState(() {
        _searchResults
          ..clear()
          ..addAll(docs);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  double _distanceFromUser(QueryDocumentSnapshot doc) {
    if (_userPosition == null) return double.infinity;

    final data = doc.data() as Map<String, dynamic>;
    final geo = data['geo'];

    double? lat;
    double? lng;

    if (geo is GeoPoint) {
      lat = geo.latitude;
      lng = geo.longitude;
    } else {
      lat = _parseDouble(data['lat']);
      lng = _parseDouble(data['lng']);
      if (lat == 0 && lng == 0) {
        lat = null;
        lng = null;
      }
    }

    if (lat == null || lng == null) return double.infinity;

    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSortToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Sort by:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _sortOption,
          items:
              ['Distance', 'Rating']
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() => _sortOption = val);
            _performSearch(_searchQuery);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (v) => _performSearch(v.trim()),
              style: const TextStyle(fontSize: 16, height: 1.2),
              decoration: InputDecoration(
                hintText: 'Search for a business...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults.clear();
                            });
                          },
                        ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),
            _buildSortToggle(),
            const SizedBox(height: 10),

            Expanded(
              child: Builder(
                builder: (_) {
                  if (!hasQuery) {
                    return const StatusMessage(
                      icon: Icons.search,
                      title: 'Start typing to search',
                      message: 'Try a business name or category.',
                    );
                  }
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_searchResults.isEmpty) {
                    return const StatusMessage(
                      icon: Icons.search_off,
                      title: 'No results',
                      message: 'Try different keywords or clear filters.',
                    );
                  }

                  return ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final doc = _searchResults[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final name = (data['name'] ?? 'Unnamed').toString();
                      final location =
                          (data['location'] ?? 'Unknown').toString();
                      final hours =
                          (data['hours'] ?? 'Hours not listed').toString();
                      final rating = _parseDouble(data['rating']);

                      return ListTile(
                        leading: const Icon(Icons.store),
                        title: Text(name),
                        subtitle: Text('$location • $hours'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => BusinessProfilePage(
                                    businessId: doc.id,
                                    businessData: data,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
