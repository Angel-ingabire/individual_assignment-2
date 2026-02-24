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
