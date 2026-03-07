import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/listing_provider.dart';
import '../models/listing.dart';
import 'listing_detail_screen.dart';
import '../widgets/listing_form.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsStreamProvider);
    final theme = Theme.of(context);
    final filter = ref.watch(listingFilterProvider);

    const categories = [
      'All',
      'Cafe',
      'Restaurant',
      'Hospital',
      'Pharmacy',
      'School',
      'Police Station',
      'Utility Office',
      'Library',
      'Park',
      'Tourist Attraction',
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Kigali City'), centerTitle: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search for a service',
                  ),
                  onChanged: (v) {
                    ref.read(listingFilterProvider.notifier).state =
                        ListingFilter(query: v, category: filter.category);
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected =
                          (cat == 'All' &&
                              (filter.category == null ||
                                  filter.category == '')) ||
                          filter.category == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(listingFilterProvider.notifier)
                                .state = ListingFilter(
                              query: filter.query,
                              category: cat == 'All' ? null : cat,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Near You',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listingsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No listings yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final Listing item = items[i];
                    return _DirectoryCard(listing: item, ref: ref);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListingForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  final Listing listing;
  final WidgetRef ref;
  const _DirectoryCard({required this.listing, required this.ref});

  // Simple distance estimate from central Kigali to listing
  String _distanceKm() {
    // Use the listing's distance if provided
    if (listing.distance != null) {
      return '${listing.distance!.toStringAsFixed(1)} km';
    }

    // Otherwise calculate from coordinates
    const kigali = LatLng(-1.9536, 30.0606);
    const earthRadius = 6371; // km
    double toRad(double deg) => deg * (math.pi / 180);

    final dLat = toRad(listing.latitude - kigali.latitude);
    final dLon = toRad(listing.longitude - kigali.longitude);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(toRad(kigali.latitude)) *
            math.cos(toRad(listing.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    if (distance.isNaN || distance.isInfinite) return '';
    return '${distance.toStringAsFixed(1)} km';
  }

  // Get color for category
  Color _getCategoryColor(String category, Color primaryColor) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'pharmacy':
        return Colors.green;
      case 'cafe':
        return Colors.brown;
      case 'school':
        return Colors.blue;
      case 'police station':
        return Colors.blue;
      case 'library':
        return Colors.purple;
      case 'restaurant':
        return Colors.orange;
      case 'park':
        return Colors.green;
      case 'tourist attraction':
        return Colors.amber;
      case 'utility office':
        return Colors.teal;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = _distanceKm();
    final categoryColor = _getCategoryColor(
      listing.category,
      theme.colorScheme.primary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(listing: listing),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.place, color: categoryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.address,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Dynamic rating
                          Icon(
                            Icons.star,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            listing.rating > 0
                                ? listing.rating.toStringAsFixed(1)
                                : 'No rating',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          if (listing.totalRatings > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              '(${listing.totalRatings})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (distance.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• $distance',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          // Category label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              listing.category,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
