import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
                  content: Text(switch (access) {
                    LocationAccessState.serviceDisabled =>
                      'Location services are disabled. Enable GPS to show your position on the map.',
                    LocationAccessState.deniedForever =>
                      'Location permission is permanently denied. Enable it from app settings to show your position.',
                    _ =>
                      'Location permission is denied. You can still use the map, but your current position won’t be shown.',
                  }, style: const TextStyle(color: Colors.white)),
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

                    // On web, avoid using the GoogleMap widget which is not
                    // properly supported in this setup. Show a helpful message instead.
                    if (kIsWeb) {
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF062345),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '📍 Interactive map is not available on web.\n\n'
                              'Use the "Get Directions" button on each listing to open navigation in Google Maps.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...listings.map(
                            (listing) => Card(
                              color: const Color(0xFF062345),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  listing.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.category,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      listing.address,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: () async {
                                    final url = Uri.parse(
                                      'https://www.google.com/maps/dir/?api=1&destination=${listing.latitude},${listing.longitude}',
                                    );
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  icon: const Icon(Icons.directions, size: 18),
                                  label: const Text('Navigate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
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
                              ),
                            ),
                          ),
                        ],
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
