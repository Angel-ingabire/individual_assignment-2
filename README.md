## Kigali City Services & Places Directory (Flutter + Firebase)

### What’s included
- **Firebase Auth**: email/password + Google sign-in, email verification gate
- **Cloud Firestore**: `users` profiles + `listings` CRUD with real-time updates
- **Riverpod**: service + state separation (no Firestore calls inside UI widgets)
- **Google Maps**: embedded maps + open Google Maps navigation
- **Location permission**: requested at runtime; map won’t crash when denied

### Required setup

#### 1) Firebase project
In Firebase Console:
- Enable **Authentication → Email/Password**
- (Optional) Enable **Google** sign-in (and configure SHA-1 for Android if needed)
- Ensure **Cloud Firestore** is enabled

If you want owner-only writes, use the provided `firestore.rules`.

#### 2) Google Maps API key (required for maps to display)
Create a Google Maps key in Google Cloud and enable:
- **Maps SDK for Android**
- **Maps SDK for iOS**

**Android**
- Add to `android/local.properties` (recommended):

```properties
MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

**iOS**
- Put the key in `ios/Runner/Info.plist` under `GoogleMapsApiKey`.

### Run

```bash
flutter pub get
flutter run
```

If you see **“Building with plugins requires symlink support”** on Windows, enable Developer Mode:

```powershell
start ms-settings:developers
```

## Kigali City Services & Places Directory (stage-1)

This workspace contains the initial Flutter scaffold and Firebase + Riverpod wiring for the Kigali City Services directory app.

Local setup (Android)

1. Create a Firebase project at https://console.firebase.google.com/
2. Add an Android app to the Firebase project. Use the Android package name from [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml).
3. Download the generated `google-services.json` and place it at `android/app/google-services.json`.
4. For iOS, register the iOS app and add the required config (not covered in this initial stage).

After adding `google-services.json`, run:

```bash
flutter pub get
flutter run
```

Notes:
- This initial stage includes:
  - Firebase initialization (`firebase_core`) in `lib/main.dart`
  - Riverpod setup (`flutter_riverpod`)
  - Folder structure: `lib/models`, `lib/services`, `lib/providers`, `lib/screens`, `lib/widgets`
  - Placeholder screens for Directory, My Listings, Map View and Settings
  - A `Listing` model and simple `FirebaseService` wrapper

Next steps (to implement):
- Create Firebase project and add Android/iOS apps
- Implement Auth flows and Firestore listings CRUD
- Integrate Google Maps and geolocation

---

## Kigali City Services & Places Directory – Detailed Overview

This app is a small but complete example of a city services directory for Kigali.  
It uses Flutter for the UI, Firebase Authentication for login, Cloud Firestore for data, and Riverpod for state management.

The notes below are written from the point of view of someone building and maintaining the project, not from a marketing angle.

### 1. Features

- **Authentication**
  - Email/password registration and login.
  - Optional Google and phone authentication.
  - Email verification is enforced: unverified accounts are redirected to a separate verification screen until the email is confirmed.

- **Service/location listings**
  - Signed‑in users can create, edit and delete listings.
  - Each listing contains:
    - Name, category, address, phone number, description.
    - Latitude and longitude so it can be shown on a map.
    - `createdBy` UID and a timestamp.
  - Listings appear in a shared directory screen for all users.

- **Directory UX**
  - Search box at the top filters by listing name.
  - Horizontal chips let the user quickly restrict results to one category (Cafés, Pharmacies, Hospitals, etc.).
  - “My Listings” tab shows only what the current user created.
  - “Bookmarks” view shows listings the user has saved via the bookmark icon on the detail page.

- **Detail page and reviews**
  - Shows all stored information about the selected listing.
  - Displays average rating and total number of ratings.
  - Users can:
    - Tap “Rate this service” to add a star rating.
    - Tap “Write a review” to submit a rating plus a text comment.
  - Reviews are stored in a `reviews` subcollection and are streamed in real time.

- **Maps and navigation**
  - On Android/iOS, the detail screen embeds a `GoogleMap` widget with a marker at the listing’s coordinates.
  - “Get directions” opens Google Maps and starts navigation to that point.
  - On the web build, an explanatory message is shown instead of the embedded map (the web plugin is limited), but the “Get directions” button still opens Google Maps in the browser.

- **Map tab**
  - Separate tab that shows all listings as markers on the city map.
  - Uses the user’s location when permission is granted, but degrades gracefully when permission is denied.

- **Settings and profile**
  - Profile section shows:
    - Name (from Firestore / FirebaseAuth).
    - Email.
    - UID.
    - Email‑verified status.
  - An **Edit profile** bottom sheet lets the user update:
    - Full name.
    - Phone number.
    - City.
    - A short bio (“About you”).
  - Preferences section includes:
    - A simulated “Location notifications” switch.
    - Optional email verification button.
    - Sign‑out button.

---

### 2. Firestore structure (as used in this app)

The app uses three main locations in Firestore.

#### `users` collection

- Document ID: Firebase Auth UID.
- Relevant fields:
  - `email`
  - `displayName`
  - `phoneNumber`
  - `city`
  - `bio`
  - `photoURL`
  - `provider`
  - `emailVerified`
  - `createdAt`

These records are created on first sign‑up and then updated through the Settings → Edit Profile flow.

#### `listings` collection

- Document ID: auto‑generated.
- Fields:
  - `name`, `category`, `address`, `contactNumber`, `description`
  - `latitude`, `longitude`
  - `createdBy` (UID of the user who owns the listing)
  - `createdAt` (server timestamp)
  - `rating` (average rating, double)
  - `totalRatings` (int)
  - `distance` (optional, used for display only)
  - `imageUrl` (reserved for images)
  - `isBookmarked` (bool flag used by the bookmarks view)

#### `listings/{listingId}/reviews` subcollection

- One document per review.
- Fields:
  - `reviewerName`
  - `rating`
  - `comment`
  - `timestamp`
  - `userId`
  - `listingId`

---

### 3. Firestore security rules in plain language

The rules are written so that:

- Anyone (even guests) can read listings and reviews.
- Only authenticated users can create listings.
- The `createdBy` field of a listing must equal the UID of the user creating it.
- Only the creator of a listing can edit or delete it.
- Any signed‑in user can add a review, but the `userId` field on the review must match their UID.
- Each user can only read and update their own document in the `users` collection.

The actual `rules_version = '2'` file in the Firebase console mirrors this logic.

---

### 4. State management: how Riverpod is used

The app tries to keep a clear separation between UI, state, and Firestore access:

- **Services (`lib/services/`)**
  - `AuthService` holds all authentication logic and reads/writes the `users` collection.
  - `ListingService` wraps every Firestore query and mutation related to listings and reviews.
  - `LocationService` is a small helper for permission checks.

- **Providers (`lib/providers/`)**
  - `authStateChangesProvider` exposes the raw FirebaseAuth user stream.
  - `listingServiceProvider` gives access to a shared `ListingService` instance.
  - `listingFilterProvider` stores the current search query and selected category.
  - `listingsStreamProvider` listens to Firestore via `ListingService.listingsStream` and applies the filter.
  - `userListingsProvider` and `bookmarkedListingsProvider` narrow the stream down to the current user’s content.
  - `reviewsStreamProvider` streams reviews for the selected listing.
  - `listingNotifierProvider` handles write operations (rating, reviews, bookmark toggles) and exposes an `AsyncValue<void>` so the UI can react to loading/errors.

- **Widgets**
  - Screens use `ref.watch(...)` to rebuild when data changes.
  - Write operations go through `ref.read(listingNotifierProvider.notifier)` or `ref.read(authServiceProvider)`.
  - There are no direct `FirebaseFirestore.instance` calls from the widgets; all database interaction is funneled through the services.

This pattern keeps the code base small but still shows a proper separation of concerns for the assignment.

---

### 5. Running the app

1. Install packages:

   ```bash
   flutter pub get
   ```

2. Configure Firebase:
   - Create a project and add Android/iOS apps.
   - Place `google-services.json` inside `android/app/`.
   - Add the iOS configuration file under `ios/Runner` if you are targeting iOS.
   - Enable Authentication (email/password at minimum) and Cloud Firestore.

3. Configure Google Maps:
   - Create a Maps API key and enable the Android/iOS Maps SDKs.
   - Add the key to `android/local.properties` as `MAPS_API_KEY=...`.
   - Add the same key to `ios/Runner/Info.plist` for `GoogleMapsApiKey`.

4. Run:

   ```bash
   flutter run
   ```

On Android/iOS you will see embedded Google Maps; on web, the app runs with a text fallback and still opens directions in Google Maps in the browser.
