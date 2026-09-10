# KothaFinder Nepal — production setup

## 1. Mobile app
1. Install Flutter 3.x and Android Studio.
2. From `app/`, run `flutter pub get`.
3. Create a Firebase project and enable Phone Authentication, Firestore, Storage and Cloud Messaging.
4. Install FlutterFire CLI and run `flutterfire configure` in `app/` to replace `lib/firebase_options.dart`.
5. Android: add Google Maps SDK key to `android/app/src/main/AndroidManifest.xml` under `<application>` using the `com.google.android.geo.API_KEY` metadata. iOS: add the Maps key to `AppDelegate`/Info.plist as required by Google Maps Flutter.
6. Add location permissions to AndroidManifest and NSLocationWhenInUseUsageDescription to iOS.
7. Deploy `firebase/firestore.rules` and `firebase/storage.rules`.

## 2. Backend
From `functions/`: `npm install && npm run build`. Deploy with Firebase CLI after selecting your project. `setAdminClaim` should only be callable by an already trusted admin account.

## 3. Admin web
Use `admin_web/public_config.example.js` as the shape for your real Firebase config, inject it before the app bundle, then run `npm install && npm run build`. Restrict the Firebase project/API keys and require admin custom claims; the UI is not a security boundary.

## 4. Moderation workflow
New listings enter `pending`. Admin can approve/reject. Only `approved + available` listings are public. Rejected/suspended listings stay visible to the owner but not public. Add report documents from the mobile client for fake listing, wrong price/location, already rented, scam and inappropriate content.

## 5. Production hardening
- Enable Firebase App Check.
- Configure SMS abuse/rate limits and phone auth regions.
- Add Terms, Privacy Policy, account deletion and data retention flows.
- Configure backups, monitoring and Crashlytics.
- Add payment provider webhook verification before enabling promotions.
- Test Firestore rules with the Firebase Emulator Suite.
- Do not ship admin credentials in the mobile app.
