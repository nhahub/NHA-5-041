# Food Planner (NHA-5-041)

Flutter (Android) app: discover recipes from TheMealDB, save favorites offline, back them up to Firebase, and plan your week with reminders.

**Stack:** Dart, Flutter (Material 3), `flutter_bloc` (Cubit = ViewModel), `go_router`, `dio` (Retrofit-style client), `drift` (Room equivalent), `flutter_secure_storage`, Firebase Auth / Google Sign-In / Firestore, `workmanager` + `flutter_local_notifications`, `lottie`, `youtube_player_iframe`.

## Run

```bash
flutter pub get
flutter run
```

Flutter 3.47.1 / Dart 3.13.1 (stable) was used. The app runs **without Firebase**: auth falls back to a local development backend (salted-hash accounts in secure storage), Google Sign-In reports "not configured", and cloud backup shows a clear "not configured" error.

### Enable Firebase
1. Create a Firebase project; enable Email/Password, Google and Firestore.
2. Add the Android app (`com.depi.foodplanner.food_planner`) with your debug/release SHA-1 + SHA-256.
3. Put `google-services.json` in `android/app/` (the Gradle plugin is applied automatically when it exists).
4. Deploy `firestore.rules`.

### Release
Create `android/key.properties` (git-ignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`, then `flutter build apk --release --obfuscate --split-debug-info=build/symbols`.

## Architecture
`Screen (widgets) -> Cubit (immutable state) -> Repository (contract) -> data source`. DI is constructor injection via `RepositoryProvider` / `BlocProvider` (`lib/app`). No static singletons. See `docs/ARCHITECTURE.md`.

## Tests
```bash
flutter test --coverage
flutter test integration_test   # on an emulator
```

## Notes
TheMealDB key `1` is for development and education; a public store release needs a supporter key.
