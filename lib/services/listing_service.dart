import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';
import 'firebase_service.dart';

class ListingService {
  final CollectionReference _col = FirebaseService.firestore.collection('listings');

  Future<DocumentReference> createListing(Listing listing) {
    final data = listing.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    return _col.add(data);
  }

  Stream<List<Listing>> listingsStream({String? category, String? nameQuery}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (category != null && category.isNotEmpty) q = q.where('category', isEqualTo: category);
    if (nameQuery != null && nameQuery.isNotEmpty) {
      q = _col.orderBy('name').startAt([nameQuery]).endAt([nameQuery + '\uf8ff']);
    }
    return q.snapshots().map((snap) => snap.docs
        .map((d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<Listing>> userListingsStream(String? uid) {
    if (uid == null) return const Stream.empty();
    return _col.where('createdBy', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots().map((snap) =>
        snap.docs.map((d) => Listing.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) {
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _col.doc(id).update(data);
  }

  Future<void> deleteListing(String id) => _col.doc(id).delete();
}
