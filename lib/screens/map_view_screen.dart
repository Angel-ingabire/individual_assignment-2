import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/listing_provider.dart';
import '../models/listing.dart';
import 'listing_detail_screen.dart';

class MapViewScreen extends ConsumerWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsStreamProvider);

    // Kigali default coordinates
    const kigaliLocation = LatLng(-1.9536, 30.0606);

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(child: Text('No locations to display on map'));
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
                    builder: (_) => ListingDetailScreen(listing: listing),
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
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
