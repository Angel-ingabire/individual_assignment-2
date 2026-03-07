import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/listing_service.dart';
import '../services/firebase_service.dart';
import '../models/listing.dart';

final listingServiceProvider = Provider<ListingService>(
  (ref) => ListingService(),
);

class ListingFilter {
  final String query;
  final String? category;
  ListingFilter({this.query = '', this.category});
}

final listingFilterProvider = StateProvider<ListingFilter>(
  (ref) => ListingFilter(),
);

final listingsStreamProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final filter = ref.watch(listingFilterProvider);
  final service = ref.watch(listingServiceProvider);
  return service.listingsStream(
    category: filter.category,
    nameQuery: filter.query,
  );
});

// Provider for a single listing
final listingProvider = StreamProvider.family<Listing?, String>((
  ref,
  listingId,
) {
  final service = ref.watch(listingServiceProvider);
  return service.listingStream(listingId);
});

// Provider for reviews of a specific listing
final reviewsStreamProvider = StreamProvider.family<List<Review>, String>((
  ref,
  listingId,
) {
  final service = ref.watch(listingServiceProvider);
  return service.reviewsStream(listingId);
});

final userListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final service = ref.watch(listingServiceProvider);
  final uid = FirebaseService.auth.currentUser?.uid;
  return service.userListingsStream(uid);
});

final bookmarkedListingsProvider = StreamProvider.autoDispose<List<Listing>>((
  ref,
) {
  final service = ref.watch(listingServiceProvider);
  final uid = FirebaseService.auth.currentUser?.uid;
  return service.bookmarkedListingsStream(uid);
});

// State notifier for managing listing operations
class ListingNotifier extends StateNotifier<AsyncValue<void>> {
  final ListingService _service;

  ListingNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addRating(String listingId, double rating) async {
    state = const AsyncValue.loading();
    try {
      await _service.addRating(listingId, rating);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReview(String listingId, Review review) async {
    state = const AsyncValue.loading();
    try {
      await _service.addReview(listingId, review);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleBookmark(String listingId, bool isBookmarked) async {
    state = const AsyncValue.loading();
    try {
      await _service.toggleBookmark(listingId, isBookmarked);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final listingNotifierProvider =
    StateNotifierProvider<ListingNotifier, AsyncValue<void>>((ref) {
      return ListingNotifier(ref.watch(listingServiceProvider));
    });
