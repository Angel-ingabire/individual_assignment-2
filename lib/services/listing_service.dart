import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';
import 'firebase_service.dart';

class ListingService {
  final CollectionReference _col = FirebaseService.firestore.collection(
    'listings',
  );

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

      // Sort newest first (serverTimestamp may arrive later; null-safe fallback already in model)
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
}
