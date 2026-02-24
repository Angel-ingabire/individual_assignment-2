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
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name'),
              onChanged: (v) => ref.read(listingFilterProvider.notifier).state =
                  ListingFilter(query: v, category: ref.read(listingFilterProvider).category),
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: item))),
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
