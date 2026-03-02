import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../providers/listing_provider.dart';
import 'listing_detail_screen.dart';

class MapViewScreen extends ConsumerWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsStreamProvider);
    final locationAccessAsync = ref.watch(locationAccessProvider);

    // Kigali default coordinates
    const kigaliLocation = LatLng(-1.9536, 30.0606);

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: locationAccessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (access) {
          final myLocationEnabled = access == LocationAccessState.granted;

          return Column(
            children: [
              if (!myLocationEnabled)
                MaterialBanner(
                  content: Text(
                    switch (access) {
                      LocationAccessState.serviceDisabled =>
                        'Location services are disabled. Enable GPS to show your position on the map.',
                      LocationAccessState.deniedForever =>
                        'Location permission is permanently denied. Enable it from app settings to show your position.',
                      _ =>
                        'Location permission is denied. You can still use the map, but your current position won’t be shown.',
                    },
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF062345),
                  actions: [
                    TextButton(
                      onPressed: () => ref.refresh(locationAccessProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              Expanded(
                child: listingsAsync.when(
                  data: (listings) {
                    if (listings.isEmpty) {
                      return const Center(
                        child: Text('No locations to display on map'),
                      );
                    }

                    final markers = listings.map((listing) {
                      return Marker(
                        markerId: MarkerId(listing.id),
                        position: LatLng(listing.latitude, listing.longitude),
                        infoWindow: InfoWindow(
                          title: listing.name,
                          snippet: listing.category,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listing: listing),
                            ),
                          );
                        },
                      );
                    }).toSet();

                    return GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: kigaliLocation,
                        zoom: 12,
                      ),
                      markers: markers,
                      myLocationEnabled: myLocationEnabled,
                      myLocationButtonEnabled: myLocationEnabled,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: true,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
