import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse('google.navigation:q=${listing.latitude},${listing.longitude}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                final web = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${listing.latitude},${listing.longitude}');
                await launchUrl(web);
              }
            },
            child: const Text('Navigate with Google Maps'),
          ),
        ]),
      ),
    );
  }
}
