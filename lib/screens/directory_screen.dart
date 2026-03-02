import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/listing_provider.dart';
import '../models/listing.dart';
import 'listing_detail_screen.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by name',
                  ),
                  onChanged: (v) =>
                      ref
                          .read(listingFilterProvider.notifier)
                          .state = ListingFilter(
                        query: v,
                        category: ref.read(listingFilterProvider).category,
                      ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: ref.watch(listingFilterProvider).category,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.filter_list),
                    hintText: 'Filter by category',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    DropdownMenuItem(
                      value: 'Hospital',
                      child: Text('Hospital'),
                    ),
                    DropdownMenuItem(
                      value: 'Police Station',
                      child: Text('Police Station'),
                    ),
                    DropdownMenuItem(value: 'Library', child: Text('Library')),
                    DropdownMenuItem(
                      value: 'Utility Office',
                      child: Text('Utility Office'),
                    ),
                    DropdownMenuItem(
                      value: 'Restaurant',
                      child: Text('Restaurant'),
                    ),
                    DropdownMenuItem(value: 'Café', child: Text('Café')),
                    DropdownMenuItem(value: 'Park', child: Text('Park')),
                    DropdownMenuItem(
                      value: 'Tourist Attraction',
                      child: Text('Tourist Attraction'),
                    ),
                  ],
                  onChanged: (v) =>
                      ref
                          .read(listingFilterProvider.notifier)
                          .state = ListingFilter(
                        query: ref.read(listingFilterProvider).query,
                        category: v,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listingsAsync.when(
              data: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final Listing item = items[i];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.category),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(listing: item),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
