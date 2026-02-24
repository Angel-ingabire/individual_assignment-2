import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/listing.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final LatLng pos = LatLng(listing.latitude, listing.longitude);
    return Scaffold(
      appBar: AppBar(title: Text(listing.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(listing.category, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(listing.address),
          const SizedBox(height: 8),
          Text('Contact: ${listing.contactNumber}'),
          const SizedBox(height: 8),
          Text(listing.description),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 15),
              markers: {Marker(markerId: MarkerId(listing.id), position: pos)},
            ),
          ),
        ]),
      ),
    );
  }
}
