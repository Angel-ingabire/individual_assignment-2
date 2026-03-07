import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String reviewerName;
  final double rating;
  final String comment;
  final Timestamp timestamp;
  final String userId;
  final String listingId;

  Review({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.timestamp,
    required this.userId,
    required this.listingId,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      reviewerName: map['reviewerName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      userId: map['userId'] ?? '',
      listingId: map['listingId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'reviewerName': reviewerName,
    'rating': rating,
    'comment': comment,
    'timestamp': timestamp,
    'userId': userId,
    'listingId': listingId,
  };
}

class Listing {
  final String id;
  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;
  final Timestamp createdAt;
  final double rating;
  final int totalRatings;
  final double? distance;
  final String? imageUrl;
  final bool isBookmarked;

  Listing({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.createdAt,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.distance,
    this.imageUrl,
    this.isBookmarked = false,
  });

  Listing copyWith({
    String? id,
    String? name,
    String? category,
    String? address,
    String? contactNumber,
    String? description,
    double? latitude,
    double? longitude,
    String? createdBy,
    Timestamp? createdAt,
    double? rating,
    int? totalRatings,
    double? distance,
    String? imageUrl,
    bool? isBookmarked,
  }) {
    return Listing(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      distance: distance ?? this.distance,
      imageUrl: imageUrl ?? this.imageUrl,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  factory Listing.fromMap(String id, Map<String, dynamic> map) {
    return Listing(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      address: map['address'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      rating: (map['rating'] ?? 0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      distance: map['distance']?.toDouble(),
      imageUrl: map['imageUrl'],
      isBookmarked: map['isBookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'address': address,
    'contactNumber': contactNumber,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'rating': rating,
    'totalRatings': totalRatings,
    'distance': distance,
    'imageUrl': imageUrl,
    'isBookmarked': isBookmarked,
  };
}
