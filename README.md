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
