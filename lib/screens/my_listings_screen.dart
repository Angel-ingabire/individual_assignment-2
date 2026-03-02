import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/listing_provider.dart';
// listing_service is accessed via provider in this screen
import '../services/firebase_service.dart';
import '../models/listing.dart';
import '../widgets/listing_form.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseService.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Listings')),
        body: const Center(
          child: Text(
            'Please sign in to manage your listings',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final listingsAsync = ref.watch(userListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: listingsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('You have not added any listings yet'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final Listing item = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      item.address,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(listing: item),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListingForm(listing: item),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final service = ref.read(listingServiceProvider);
                            await service.deleteListing(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListingForm())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
