// lib/pages/home_with_map_page.dart
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../language_provider.dart';
import 'business_profile_page.dart';

class HomeWithMapPage extends StatefulWidget {
  const HomeWithMapPage({super.key});

  @override
  State<HomeWithMapPage> createState() => _HomeWithMapPageState();
}

class _HomeWithMapPageState extends State<HomeWithMapPage> {
  Position? _userLocation;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  String _searchQuery = '';
  Timer? _debounce;

  // Remember last applied markers & camera to avoid flicker/loops
  Set<String> _lastMarkerIds = {};
  String? _lastCameraKey;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _userLocation = position);
    } catch (_) {
      // leave _userLocation null; distance labels will hide
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  String _cameraKeyFor({LatLngBounds? bounds, LatLng? single}) {
    if (single != null) {
      return 'single:${single.latitude.toStringAsFixed(5)},${single.longitude.toStringAsFixed(5)}';
    }
    if (bounds != null) {
      final sw = bounds.southwest, ne = bounds.northeast;
      return 'bounds:${sw.latitude.toStringAsFixed(5)},${sw.longitude.toStringAsFixed(5)}'
          '|${ne.latitude.toStringAsFixed(5)},${ne.longitude.toStringAsFixed(5)}';
    }
    return 'none';
  }

  void _applyMarkersSafely(
    Set<Marker> newMarkers, {
    LatLngBounds? bounds,
    LatLng? single,
  }) {
    final newIds = newMarkers.map((m) => m.markerId.value).toSet();
    final camKey = _cameraKeyFor(bounds: bounds, single: single);

    final markersChanged =
        newIds.length != _lastMarkerIds.length ||
        !newIds.containsAll(_lastMarkerIds);
    final cameraChanged = camKey != _lastCameraKey;

    if (!markersChanged && !cameraChanged) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (markersChanged) {
        setState(() {
          _markers
            ..clear()
            ..addAll(newMarkers);
          _lastMarkerIds = newIds;
        });
      }

      if (_mapController != null && cameraChanged) {
        _lastCameraKey = camKey;
        try {
          if (bounds != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 60),
            );
          } else if (single != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(single, 14),
            );
          }
        } catch (_) {
          // ignore camera exceptions safely
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>().language;
    final isIndo = language == 'id';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        leadingWidth: 104,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              'assets/images/nyari_wordmark.png',
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const SizedBox.shrink(),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(context, en: 'EN', id: 'EN'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 4),
              const Text('🇬🇧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Switch(
                value: isIndo,
                onChanged: (bool value) {
                  context.read<LanguageProvider>().setLanguage(
                    value ? 'id' : 'en',
                  );
                },
                activeColor: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text('🇮🇩', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                tr(context, en: 'ID', id: 'ID'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (debounced; bilingual placeholder)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  if (!mounted) return;
                  setState(() => _searchQuery = value.trim());
                });
              },
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 16, height: 1.2),
              decoration: InputDecoration(
                hintText: tr(
                  context,
                  en: 'Search businesses...',
                  id: 'Cari bisnis...',
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: tr(context, en: 'Clear', id: 'Hapus'),
                          onPressed: () => setState(() => _searchQuery = ''),
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
          ),

          // Map view
          Expanded(
            flex: 1,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-8.65, 115.2167),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),

          // Business list
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('businesses')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      tr(
                        context,
                        en: 'Something went wrong.',
                        id: 'Terjadi kesalahan.',
                      ),
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  _applyMarkersSafely({});
                  return RefreshIndicator(
                    onRefresh:
                        () async =>
                            Future.delayed(const Duration(milliseconds: 400)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Text(
                            tr(
                              context,
                              en: 'No businesses yet.',
                              id: 'Belum ada bisnis.',
                            ),
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> filtered = [];
                final Set<Marker> updatedMarkers = {};

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final geo = data['geo'];
                  if (geo == null) continue;

                  double distance = 0;
                  if (_userLocation != null) {
                    distance = calculateDistance(
                      _userLocation!.latitude,
                      _userLocation!.longitude,
                      geo.latitude,
                      geo.longitude,
                    );
                  }

                  data['id'] = doc.id;
                  data['distance'] = distance;

                  final q = _searchQuery.toLowerCase();
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      (data['name']?.toString().toLowerCase().contains(q) ??
                          false) ||
                      (data['description']?.toString().toLowerCase().contains(
                            q,
                          ) ??
                          false) ||
                      (data['category']?.toString().toLowerCase().contains(q) ??
                          false) ||
                      // support both 'subcategory' and 'subcategories'
                      ((data['subcategory'] is List) &&
                          (data['subcategory'] as List).any(
                            (sub) => sub.toString().toLowerCase().contains(q),
                          )) ||
                      ((data['subcategories'] is List) &&
                          (data['subcategories'] as List).any(
                            (sub) => sub.toString().toLowerCase().contains(q),
                          ));

                  if (matchesSearch) {
                    filtered.add(data);
                    updatedMarkers.add(
                      Marker(
                        markerId: MarkerId(doc.id),
                        position: LatLng(geo.latitude, geo.longitude),
                        infoWindow: InfoWindow(title: data['name']),
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
                      ),
                    );
                  }
                }

                filtered.sort((a, b) => a['distance'].compareTo(b['distance']));

                // Camera target (no state yet)
                LatLngBounds? bounds;
                LatLng? single;
                if (updatedMarkers.isNotEmpty) {
                  if (updatedMarkers.length == 1) {
                    single = updatedMarkers.first.position;
                  } else {
                    final lats =
                        updatedMarkers.map((m) => m.position.latitude).toList();
                    final lngs =
                        updatedMarkers
                            .map((m) => m.position.longitude)
                            .toList();
                    final south = lats.reduce((a, b) => a < b ? a : b);
                    final north = lats.reduce((a, b) => a > b ? a : b);
                    final west = lngs.reduce((a, b) => a < b ? a : b);
                    final east = lngs.reduce((a, b) => a > b ? a : b);
                    bounds = LatLngBounds(
                      southwest: LatLng(south, west),
                      northeast: LatLng(north, east),
                    );
                  }
                }

                _applyMarkersSafely(
                  updatedMarkers,
                  bounds: bounds,
                  single: single,
                );

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh:
                        () async =>
                            Future.delayed(const Duration(milliseconds: 400)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Text(
                            tr(
                              context,
                              en: 'No matching results.',
                              id: 'Tidak ada hasil yang cocok.',
                            ),
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh:
                      () async =>
                          Future.delayed(const Duration(milliseconds: 400)),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final biz = filtered[index];

                      // Safe rating parsing
                      double ratingVal = 0;
                      final raw = biz['rating'];
                      if (raw is int)
                        ratingVal = raw.toDouble();
                      else if (raw is double)
                        ratingVal = raw;
                      else if (raw is String)
                        ratingVal = double.tryParse(raw) ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(biz['name'] ?? 'No Name'),
                          subtitle:
                              _userLocation == null
                                  ? null
                                  : Text(
                                    "${biz['distance'].toStringAsFixed(2)} "
                                    "${tr(context, en: 'km away', id: 'km dari sini')}",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                          // ⭐ Moved star to the right, next to the rating number
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ratingVal > 0
                                    ? ratingVal.toStringAsFixed(1)
                                    : '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => BusinessProfilePage(
                                      businessId: biz['id'],
                                      businessData: biz,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
