import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';
import 'firebase_service.dart';

class ListingService {
  final CollectionReference _col = FirebaseService.firestore.collection(
    'listings',
  );

  // Subcollection for reviews
  CollectionReference _reviewsCol(String listingId) =>
      _col.doc(listingId).collection('reviews');

  Future<DocumentReference> createListing(Listing listing) {
    final data = listing.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    return _col.add(data);
  }

  Stream<List<Listing>> listingsStream({String? category, String? nameQuery}) {
    // IMPORTANT:
    // Avoid composite-index requirements by not combining `where(...)` + `orderBy(...)`.
    // For this assignment-sized dataset, we stream all listings and filter/sort in memory.
    return _col.snapshots().map((snap) {
      var listings = snap.docs
          .map((d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      // Sort by rating (highest first), then by creation date
      listings.sort((a, b) {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.createdAt.compareTo(a.createdAt);
      });

      // Filter by category if provided
      if (category != null && category.isNotEmpty) {
        final categoryLower = category.toLowerCase();
        listings = listings
            .where((l) => l.category.toLowerCase() == categoryLower)
            .toList();
      }

      // Filter by name if query is provided
      if (nameQuery != null && nameQuery.isNotEmpty) {
        final queryLower = nameQuery.toLowerCase();
        listings = listings
            .where((listing) => listing.name.toLowerCase().contains(queryLower))
            .toList();
      }

      return listings;
    });
  }

  Stream<Listing?> listingStream(String listingId) {
    return _col.doc(listingId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Listing.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  Stream<List<Listing>> userListingsStream(String? uid) {
    if (uid == null) return const Stream.empty();
    // Same index-avoidance approach as above (no `where` + `orderBy` combo).
    return _col.snapshots().map((snap) {
      var listings = snap.docs
          .map((d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>))
          .where((l) => l.createdBy == uid)
          .toList();
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) {
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _col.doc(id).update(data);
  }

  Future<void> deleteListing(String id) => _col.doc(id).delete();

  // Add a rating to a listing
  Future<void> addRating(String listingId, double rating) async {
    final doc = await _col.doc(listingId).get();
    if (!doc.exists) return;

    final currentData = doc.data() as Map<String, dynamic>;
    final currentRating = (currentData['rating'] ?? 0.0).toDouble();
    final currentTotalRatings = (currentData['totalRatings'] ?? 0) as int;

    // Calculate new average rating
    final newTotalRatings = currentTotalRatings + 1;
    final newRating =
        ((currentRating * currentTotalRatings) + rating) / newTotalRatings;

    await _col.doc(listingId).update({
      'rating': newRating,
      'totalRatings': newTotalRatings,
    });
  }

  // Add a review to a listing
  Future<DocumentReference> addReview(String listingId, Review review) async {
    final data = review.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    final reviewRef = await _reviewsCol(listingId).add(data);

    // Also update the listing's rating
    await addRating(listingId, review.rating);

    return reviewRef;
  }

  // Get reviews stream for a listing
  Stream<List<Review>> reviewsStream(String listingId) {
    return _reviewsCol(listingId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => Review.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // Toggle bookmark status
  Future<void> toggleBookmark(String listingId, bool isBookmarked) {
    return _col.doc(listingId).update({'isBookmarked': isBookmarked});
  }

  // Get bookmarked listings
  Stream<List<Listing>> bookmarkedListingsStream(String? uid) {
    if (uid == null) return const Stream.empty();
    return _col.snapshots().map((snap) {
      var listings = snap.docs
          .map((d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>))
          .where((l) => l.isBookmarked && l.createdBy == uid)
          .toList();
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }
}
