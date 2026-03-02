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
    // Start with a base query
    Query q = _col;

    // Apply category filter if provided
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    // For name search, we need to handle it differently since
    // Firestore doesn't support both range filters and equality filters well
    // We'll fetch all results and filter in memory for name queries
    return q.orderBy('createdAt', descending: true).snapshots().map((snap) {
      var listings = snap.docs
          .map((d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

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
    return _col
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) {
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _col.doc(id).update(data);
  }

  Future<void> deleteListing(String id) => _col.doc(id).delete();
}
