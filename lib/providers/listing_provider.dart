import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/listing_service.dart';
import '../services/firebase_service.dart';
import '../models/listing.dart';

final listingServiceProvider = Provider<ListingService>((ref) => ListingService());

class ListingFilter {
  final String query;
  final String? category;
  ListingFilter({this.query = '', this.category});
}

final listingFilterProvider = StateProvider<ListingFilter>((ref) => ListingFilter());

final listingsStreamProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final filter = ref.watch(listingFilterProvider);
  final service = ref.watch(listingServiceProvider);
  return service.listingsStream(category: filter.category, nameQuery: filter.query);
});

final userListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final service = ref.watch(listingServiceProvider);
  final uid = FirebaseService.auth.currentUser?.uid;
  return service.userListingsStream(uid);
});
