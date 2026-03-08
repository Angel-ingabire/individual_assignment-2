import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';
import '../providers/listing_provider.dart';
import '../services/firebase_service.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  // Get icon for category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'police station':
        return Icons.local_police;
      case 'library':
        return Icons.local_library;
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'school':
        return Icons.school;
      case 'park':
        return Icons.park;
      case 'tourist attraction':
        return Icons.attractions;
      case 'utility office':
        return Icons.business;
      default:
        return Icons.place;
    }
  }

  // Get color for category
  Color _getCategoryColor(String category, Color primaryColor) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'pharmacy':
        return Colors.green;
      case 'police station':
        return Colors.blue;
      case 'library':
        return Colors.purple;
      case 'restaurant':
        return Colors.orange;
      case 'cafe':
        return Colors.brown;
      case 'school':
        return Colors.blue;
      case 'park':
        return Colors.green;
      case 'tourist attraction':
        return Colors.amber;
      case 'utility office':
        return Colors.teal;
      default:
        return primaryColor;
    }
  }

  void _showAddReviewDialog() {
    double selectedRating = 5.0;
    final nameController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your name',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Rating'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        starValue <= selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = starValue.toDouble();
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    hintText: 'Share your experience...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
                  );
                  return;
                }

                final user = FirebaseService.auth.currentUser;
                final review = Review(
                  id: '',
                  reviewerName: nameController.text.trim(),
                  rating: selectedRating,
                  comment: commentController.text.trim(),
                  timestamp: Timestamp.now(),
                  userId: user?.uid ?? '',
                  listingId: widget.listing.id,
                );

                await ref
                    .read(listingNotifierProvider.notifier)
                    .addReview(widget.listing.id, review);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review added successfully!')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    double selectedRating = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate this Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tap a star to rate'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    icon: Icon(
                      starValue <= selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = starValue.toDouble();
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${selectedRating.toInt()} / 5',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(listingNotifierProvider.notifier)
                    .addRating(widget.listing.id, selectedRating);

                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Rating added!')));
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LatLng pos = LatLng(
      widget.listing.latitude,
      widget.listing.longitude,
    );
    final categoryColor = _getCategoryColor(
      widget.listing.category,
      theme.colorScheme.primary,
    );

    // Watch for reviews
    final reviewsAsync = ref.watch(reviewsStreamProvider(widget.listing.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('listings')
                    .doc(widget.listing.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  final isBookmarked =
                      snapshot.data?.get('isBookmarked') ?? false;
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final user = FirebaseService.auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to bookmark'),
                          ),
                        );
                        return;
                      }
                      await ref
                          .read(listingNotifierProvider.notifier)
                          .toggleBookmark(widget.listing.id, !isBookmarked);
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.listing.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      categoryColor.withOpacity(0.8),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(widget.listing.category),
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: categoryColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(widget.listing.category),
                          size: 16,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.listing.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rating section
                  _buildRatingSection(theme, categoryColor),
                  const SizedBox(height: 12),

                  // Address section
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on,
                    title: 'Address',
                    content: widget.listing.address.isNotEmpty
                        ? widget.listing.address
                        : 'No address provided',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),

                  // Contact section
                  _buildInfoCard(
                    context,
                    icon: Icons.phone,
                    title: 'Contact',
                    content: widget.listing.contactNumber.isNotEmpty
                        ? widget.listing.contactNumber
                        : 'No contact provided',
                    color: theme.colorScheme.primary,
                    onTap: widget.listing.contactNumber.isNotEmpty
                        ? () async {
                            final uri = Uri(
                              scheme: 'tel',
                              path: widget.listing.contactNumber,
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Description section
                  _buildInfoCard(
                    context,
                    icon: Icons.description,
                    title: 'Description',
                    content: widget.listing.description.isNotEmpty
                        ? widget.listing.description
                        : 'No description provided',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),

                  // Rate this service button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.star_border),
                      label: const Text('Rate this Service'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reviews section
                  Text(
                    'Reviews',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Add review button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddReviewDialog,
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Write a Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews list
                  reviewsAsync.when(
                    data: (reviews) {
                      if (reviews.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF062345),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No reviews yet. Be the first to review!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return _buildReviewCard(review, theme, categoryColor);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error loading reviews: $e')),
                  ),
                  const SizedBox(height: 20),

                  // Map section
                  Text(
                    'Location',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: kIsWeb
                        ? Container(
                            color: const Color(0xFF062345),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(16),
                            child: const Text(
                              'Map preview is available on Android/iOS builds.\n\n'
                              'On web, use the "Get Directions" button below to open Google Maps.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: pos,
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId(widget.listing.id),
                                position: pos,
                                infoWindow: InfoWindow(
                                  title: widget.listing.name,
                                  snippet: widget.listing.address,
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Navigate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${widget.listing.latitude},${widget.listing.longitude}',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Coordinates info
                  Center(
                    child: Text(
                      'Lat: ${widget.listing.latitude.toStringAsFixed(6)}, Lng: ${widget.listing.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme, Color categoryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF062345),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  widget.listing.rating > 0
                      ? widget.listing.rating.toStringAsFixed(1)
                      : '0.0',
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final rating = widget.listing.rating;
                    if (rating >= index + 1) {
                      return Icon(Icons.star, color: Colors.amber, size: 16);
                    } else if (rating >= index + 0.5) {
                      return Icon(
                        Icons.star_half,
                        color: Colors.amber,
                        size: 16,
                      );
                    } else {
                      return Icon(
                        Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Average Rating',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.listing.totalRatings > 0
                      ? '${widget.listing.totalRatings} ${widget.listing.totalRatings == 1 ? 'review' : 'reviews'}'
                      : 'No reviews yet',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showRatingDialog,
            icon: Icon(Icons.rate_review, color: categoryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review, ThemeData theme, Color categoryColor) {
    final reviewDate = review.timestamp.toDate();
    final formattedDate =
        '${reviewDate.day}/${reviewDate.month}/${reviewDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF062345),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (review.comment.isNotEmpty) ...[
            Text(
              review.comment,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            formattedDate,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF062345),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
