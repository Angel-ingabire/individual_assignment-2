# Firebase Integration Experience with Flutter

## Overview

This document outlines my experience integrating Firebase with a Flutter application (Kigali City Services). The project implements authentication (email, Google, phone) and Firestore database for managing business listings.

---

## Firestore Database Structure

### Collections

The Firestore database consists of three main collections:

```
/users/{userId}
  - email: string
  - displayName: string
  - photoURL: string
  - createdAt: timestamp
  - provider: string (email|google|phone)
  - emailVerified: boolean
  - phoneNumber: string (optional)

/listings/{listingId}
  - name: string
  - category: string
  - address: string
  - contactNumber: string
  - description: string
  - latitude: double
  - longitude: double
  - createdBy: string (userId)
  - createdAt: timestamp
  - updatedAt: timestamp
  - rating: double (0.0 default)
  - totalRatings: int (0 default)
  - imageUrl: string (optional)
  - isBookmarked: boolean (false default)

/listings/{listingId}/reviews/{reviewId}
  - reviewerName: string
  - rating: double
  - comment: string
  - timestamp: timestamp
  - userId: string
  - listingId: string
```

### Design Decisions

1. **Denormalized Rating Data** - Ratings are stored directly on the listing document rather than computed from reviews subcollection. This trade-off:
   - ✅ Enables fast reads (no need to aggregate reviews)
   - ⚠️ Requires manual updates when reviews are added/deleted
   - ✅ Simplifies queries (no need for aggregation pipeline)

2. **Subcollection for Reviews** - Reviews are stored as a subcollection under each listing:
   - ✅ Maintains data integrity (reviews are tied to listing)
   - ✅ Enables efficient per-listing review queries
   - ⚠️ More expensive for global review queries

3. **isBookmarked Field on Listing** - Bookmark status is stored on the listing itself:
   - ✅ Simple to query user's bookmarked listings
   - ⚠️ Requires `SetOptions(merge: true)` to avoid overwriting other fields

---

## Listing Model Design

### Class Structure

The [`Listing`](lib/models/listing.dart:44) class implements immutable data patterns with a `copyWith` method:

```dart
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
  final double? distance;      // Optional - computed client-side
  final String? imageUrl;       // Optional - may not exist
  final bool isBookmarked;
}
```

### Null Safety Handling

All fields use null-safe operators with sensible defaults:

```dart
factory Listing.fromMap(String id, Map<String, dynamic> map) {
  return Listing(
    id: id,
    name: map['name'] ?? '',           // Default empty string
    category: map['category'] ?? '',
    rating: (map['rating'] ?? 0).toDouble(),  // Default 0.0
    totalRatings: map['totalRatings'] ?? 0,
    imageUrl: map['imageUrl'],         // Nullable - no default
    isBookmarked: map['isBookmarked'] ?? false,
    // ... etc
  );
}
```

### Trade-off: Required vs Optional Fields

**Required Fields:**
- `id`, `name`, `category`, `address`, `contactNumber`, `description`
- These form the core business listing data

**Optional Fields:**
- `imageUrl` - Not all listings have images
- `distance` - Only computed when user location is available

**Calculated Fields:**
- `rating` and `totalRatings` - Maintained through Firestore updates

---

## State Management Implementation

### Riverpod Architecture

The project uses **Riverpod** (`flutter_riverpod: ^2.6.1`) for state management with a provider-based architecture.

### Provider Structure

```
┌─────────────────────────────────────────────────────────┐
│                    Providers                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [FirebaseService]  ─────►  [ListingService]           │
│         │                         │                      │
│         ▼                         ▼                      │
│  [authStateChangesProvider]  [listingServiceProvider]  │
│         │                         │                      │
│                      │
│          ▼                         ▼ [AuthService]  ◄──────────  [ListingNotifier]         │
│         │                         │                      │
│         ▼                         ▼                      │
│  [userListingsProvider]    [listingsStreamProvider]    │
│  [bookmarkedListings]     [reviewsStreamProvider]     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Key Providers

#### 1. Auth State Provider

```dart
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});
```

Listens to Firebase Auth state changes and rebuilds UI automatically.

#### 2. Listings Stream Provider

```dart
final listingsStreamProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final filter = ref.watch(listingFilterProvider);
  final service = ref.watch(listingServiceProvider);
  return service.listingsStream(
    category: filter.category,
    nameQuery: filter.query,
  );
});
```

- Uses `autoDispose` to clean up when widget is removed
- Re-fetches when filter changes (via `ref.watch`)

#### 3. Filter State Provider

```dart
final listingFilterProvider = StateProvider<ListingFilter>(
  (ref) => ListingFilter(),
);
```

Manages search query and category filter state.

#### 4. Listing Operations Notifier

```dart
class ListingNotifier extends StateNotifier<AsyncValue<void>> {
  final ListingService _service;
  
  Future<void> addRating(String listingId, double rating) async {
    state = const AsyncValue.loading();
    try {
      await _service.addRating(listingId, rating);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  // ... addReview, toggleBookmark
}
```

Handles async mutations with loading/error states.

---

## Design Trade-offs and Technical Challenges

### Trade-off 1: In-Memory Filtering vs Firestore Queries

**Decision:** Fetch all listings and filter in memory.

**Rationale:**
- Avoids composite index requirements for `where() + orderBy()`
- Simpler for assignment-sized datasets (< 1000 listings)
- Better UX (instant filtering without network round-trips)

**Code Example:**
```dart
Stream<List<Listing>> listingsStream({String? category, String? nameQuery}) {
  return _col.snapshots().map((snap) {
    var listings = snap.docs
        .map((d) => Listing.fromMap(d.id, d.data()))
        .toList();
    
    // Filter in memory
    if (category != null && category.isNotEmpty) {
      listings = listings
          .where((l) => l.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    
    // Sort in memory
    listings.sort((a, b) => b.rating.compareTo(a.rating));
    
    return listings;
  });
}
```

**Impact:**
- ⚠️ Doesn't scale well to millions of listings
- ✅ Works well for small-to-medium applications
- ✅ No Firestore index management required

---

### Trade-off 2: Bookmarks Stored on Listing Documents

**Decision:** Store `isBookmarked` boolean on each listing document.

**Alternative Considered:** Create a separate `bookmarks` subcollection per user.

**Chosen Approach:**
```dart
// When toggling bookmark
await _col.doc(listingId).update({'isBookmarked': isBookmarked});
```

**Rationale:**
- Simpler query: filter by `isBookmarked == true && createdBy == userId`
- Single read to get bookmarked listings

**Alternative (Not Used):**
```dart
// Would require separate collection
users/{userId}/bookmarks/{listingId}
```

- More complex queries
- Better for multi-user collaboration features

---

### Trade-off 3: Rating Denormalization

**Decision:** Store rating directly on listing, update manually when reviews are added.

**Code:**
```dart
Future<void> addRating(String listingId, double rating) async {
  final doc = await _col.doc(listingId).get();
  final currentData = doc.data();
  final currentRating = (currentData['rating'] ?? 0.0).toDouble();
  final currentTotalRatings = (currentData['totalRatings'] ?? 0) as int;
  
  // Calculate new average
  final newTotalRatings = currentTotalRatings + 1;
  final newRating = 
      ((currentRating * currentTotalRatings) + rating) / newTotalRatings;
  
  await _col.doc(listingId).update({
    'rating': newRating,
    'totalRatings': newTotalRatings,
  });
}
```

**Rationale:**
- Fast reads (no aggregation needed)
- Simple queries (order by rating)

**Risk:**
- Data inconsistency if update fails after review is created
- Solution: Firestore transactions (not implemented in this version)

---

### Technical Challenge 1: Handling Missing User Context

**Problem:** Stream providers need user ID but user may not be authenticated yet.

**Solution:** Null-safe stream returns:
```dart
Stream<List<Listing>> userListingsStream(String? uid) {
  if (uid == null) return const Stream.empty();
  // ... stream listings where createdBy == uid
}
```

**Provider usage:**
```dart
final userListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final service = ref.watch(listingServiceProvider);
  final uid = FirebaseService.auth.currentUser?.uid;
  return service.userListingsStream(uid);
});
```

---

### Technical Challenge 2: Type Conversion for Firestore Data

**Problem:** Firestore returns various types (int, double) that need consistent handling.

**Solution:** Explicit type conversion:
```dart
latitude: (map['latitude'] ?? 0).toDouble(),  // Ensure double
totalRatings: map['totalRatings'] ?? 0,         // Keep int
isBookmarked: map['isBookmarked'] ?? false,    // Ensure boolean
```

---

### Technical Challenge 3: Timestamp Handling

**Problem:** Firestore timestamps and Dart DateTime are different types.

**Solution:** Use Firestore `Timestamp` directly:
```dart
final Timestamp createdAt;

// In fromMap:
createdAt: map['createdAt'] ?? Timestamp.now(),

// In toMap:
'createdAt': FieldValue.serverTimestamp(),
```

**Display Conversion:**
```dart
// In UI widgets
Text(_listing.createdAt.toDate().toString())
```

---

## Firebase Services Integrated

### Authentication
- **Firebase Auth** (`firebase_auth: ^6.1.4`)
- Email/Password authentication
- Google Sign-In
- Phone authentication with SMS verification

### Database
- **Cloud Firestore** (`cloud_firestore: ^6.1.2`)
- Listings collection with CRUD operations
- User profiles collection
- Reviews subcollection for listings

---

## Authentication Challenges & Solutions

### Challenge 1: Email Verification State Persistence

**Problem:** After a user verifies their email through the sent link, the app doesn't immediately recognize the updated verification status because `currentUser.emailVerified` is cached.

**Solution:** Implemented user reload after verification check:

```dart
Future<bool> isUserVerified() async {
  final user = _auth.currentUser;
  if (user == null) return false;
  
  // Reload to get latest verification status
  await user.reload();
  final refreshedUser = _auth.currentUser;
  return refreshedUser?.emailVerified ?? false;
}
```

**Key Learning:** Always call `user.reload()` before checking verification status in sessions where the user just verified.

---

### Challenge 2: Auth State Changes Not Reflecting Immediately

**Problem:** The `authStateChanges()` stream doesn't always emit immediately after email verification, causing the UI to show stale verification status.

**Solution:** Implemented explicit reload in the `AuthGate` component and added verification status checking:

```dart
Future<void> _checkVerificationStatus() async {
  final isVerified = await _authService.isUserVerified();
  if (mounted) {
    setState(() {
      _isVerified = isVerified;
      _isChecking = false;
    });
  }
}
```

---

### Challenge 3: Google Sign-In on Different Platforms

**Problem:** Google Sign-In requires platform-specific configuration (SHA-1 fingerprint for Android, URL schemes for iOS).

**Solution:** 
- Added SHA-1 fingerprint to Firebase console
- Configured OAuth consent screen
- Used `signInWithPopup` for web compatibility

---

### Challenge 4: Phone Authentication Timing Issues

**Problem:** The `verifyPhoneNumber` method is asynchronous but doesn't directly return the verification ID - it uses callbacks.

**Solution:** Used a delayed future to wait for the callback:

```dart
Future<String> sendPhoneVerification(String phoneNumber) async {
  String? verificationId;
  
  await _auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    codeSent: (String verificationIdInternal, int? resendToken) {
      verificationId = verificationIdInternal;
    },
    // ... other callbacks
  );
  
  await Future.delayed(const Duration(milliseconds: 1500));
  return verificationId ?? '';
}
```

---

## Firestore Integration Challenges

### Challenge 1: Composite Index Requirements

**Problem:** Using `where()` clause combined with `orderBy()` on different fields requires a Firestore composite index, which can cause errors during development.

**Error Example:**
```
PlatformException(9, 'FAILED_PRECONDITION: The query requires an index...', ...)
```

**Solution:** See "Trade-off 1: In-Memory Filtering" above.

---

### Challenge 2: Null Safety with Firestore Data

**Problem:** Firestore documents can have null fields, causing type errors when converting to Dart objects.

**Solution:** Used null-safe operators and default values in the model.

---

### Challenge 3: Server Timestamps Not Available Offline

**Problem:** Using `FieldValue.serverTimestamp()` requires an active network connection.

**Solution:** Created data maps with timestamps before async operations.

---

### Challenge 4: Firestore Security Rules Testing

**Problem:** Security rules work differently in the Firebase console emulator vs production.

**Solution:** Created comprehensive Firestore security rules:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }
    
    match /listings/{listingId} {
      allow read: if true;
      allow create: if isSignedIn() 
        && request.resource.data.createdBy == request.auth.uid;
      allow update, delete: if isSignedIn() 
        && resource.data.createdBy == request.auth.uid;
    }
  }
}
```

---

## Common Error Messages Encountered

### Authentication Errors

1. **"There is no user record corresponding to this identifier"**
   - User tried to sign in with email that doesn't exist
   
2. **"The password is invalid or the user does not have a password"**
   - Wrong password entered
   
3. **"We have blocked all requests from this device due to unusual activity"**
   - Too many failed login attempts
   
4. **"ERROR_REJECTED_CREDENTIALS"**
   - Google sign-in credential rejected

### Firestore Errors

1. **"PERMISSION_DENEDED: Missing or insufficient permissions"**
   - Security rules blocking the operation
   
2. **"The query requires an index..."**
   - Need to create composite index in Firebase console
   
3. **"Document not found"**
   - Trying to update/delete non-existent document

---

## Best Practices Implemented

### 1. Centralized Auth Service
All authentication logic is centralized in [`AuthService`](lib/services/auth_service.dart) for maintainability.

### 2. Error Handling
All Firebase operations are wrapped in try-catch blocks with user-friendly error messages displayed via Snackbars.

### 3. Auth Gate Pattern
Implemented [`AuthGate`](lib/main.dart:72) widget to handle auth state and navigation automatically.

### 4. Provider Type Detection
Created enum to track authentication provider type for different UI flows:

```dart
enum AuthProviderType { email, phone, google, unknown }
```

### 5. User Profile Synchronization
User profiles are created/updated in Firestore on sign-in to maintain additional user data beyond what's in Firebase Auth.

### 6. Immutable Models with copyWith
Used immutable model pattern with `copyWith` for predictable state updates.

### 7. Auto-Dispose Providers
Used `autoDispose` for stream providers to prevent memory leaks when widgets are removed.

---

## Dependencies Used

```yaml
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
google_sign_in: ^7.2.0
flutter_riverpod: ^2.6.1
```

---

## Conclusion

Firebase integration with Flutter provides a robust backend solution, but requires careful handling of authentication states and Firestore querying patterns. The main challenges encountered were:

1. Caching issues with email verification status
2. Composite index requirements for complex queries
3. Null safety handling for Firestore documents
4. Platform-specific configuration for social sign-in
5. State management integration with Firestore streams

Key architectural decisions included:
- Using in-memory filtering to avoid index complexity
- Storing computed ratings directly on documents
- Using Riverpod providers for reactive state management
- Implementing an AuthGate pattern for navigation control
- Using denormalized data for performance optimization

The implemented solutions provide a solid foundation for production-ready applications with proper error handling and security rules.
