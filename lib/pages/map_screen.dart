import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'business_profile_page.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMarkers();
  }

  Future<void> _loadAllMarkers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('businesses').get();

      final loadedMarkers =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final lat = data['lat']?.toDouble();
                final lng = data['lng']?.toDouble();
                final name = data['name'] ?? 'No Name';

                if (lat == null || lng == null) return null;

                return Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: name,
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
              })
              .whereType<Marker>()
              .toSet();

      setState(() {
        markers = loadedMarkers;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading markers: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-8.65, 115.137), // Centered on Bali
                  zoom: 13,
                ),
                onMapCreated: (controller) => mapController = controller,
                markers: markers,
                myLocationEnabled: true,
              ),
    );
  }
}
