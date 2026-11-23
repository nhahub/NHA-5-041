import 'package:flutter/widgets.dart';

import '../core/auth/logout_flow.dart';
import '../core/prefs/preference_manager.dart';
import '../core/clock.dart';
import '../core/connectivity/connectivity_cubit.dart';
import '../data/local/app_database.dart';
import '../data/reminders/notification_helper.dart';
import '../data/reminders/reminder_service_impl.dart';
import '../data/auth/auth_backend.dart';
import '../data/remote/themealdb_client.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../data/repositories/meal_repository_impl.dart';
import '../data/repositories/planner_repository_impl.dart';
import '../data/repositories/sync_repository_impl.dart';
import '../data/storage/secure_store.dart';
import '../data/sync/cloud_favorites_store.dart';
import '../domain/fakes/fakes.dart';
import '../domain/repositories/repositories.dart';
import '../features/meal_details/meal_details_screen.dart' show VideoBuilder;
import '../features/profile/avatar_cubit.dart';
import '../features/reminders/reminder_cubit.dart';
import '../features/search/search_cubit.dart';

/// Everything the app needs, built once and handed down with constructor
/// injection (RepositoryProvider / BlocProvider). No static singletons.
class AppDependencies {
  AppDependencies({
    required this.prefManager,
    required this.auth,
    required this.meals,
    required this.favorites,
    required this.planner,
    required this.sync,
    required this.reminders,
    required this.permission,
    required this.connectivity,
    required this.avatarStore,
    required this.areaCatalog,
    this.notifications,
    this.videoBuilder,
    this.clock = const Clock(),
    this.useGoogleFonts = true,
    this.disposables = const [],
  }) : logout = LogoutFlow(auth: auth, sync: sync);

  final PreferenceManager prefManager;
  final AuthRepository auth;
  final MealRepository meals;
  final FavoritesRepository favorites;
  final PlannerRepository planner;
  final SyncRepository sync;
  final ReminderService reminders;
  final NotificationPermission permission;
  final ConnectivitySource connectivity;
  final AvatarStore avatarStore;
  final AreaCatalog areaCatalog;
  final NotificationHelper? notifications;

  /// Replaces the embedded YouTube player (tests have no WebView).
  final VideoBuilder? videoBuilder;
  final Clock clock;
  final bool useGoogleFonts;
  final LogoutFlow logout;
  final List<Future<void> Function()> disposables;

  /// Real implementations. [firebaseReady] picks Firebase or the local fallback.
  static AppDependencies production({
    required PreferenceManager prefManager,
    required bool firebaseReady,
  }) {
    const secure = FlutterSecureStore();
    final db = AppDatabase.open();
    final favorites = FavoritesRepositoryImpl(FavoritesDao(db));
    final notifications = NotificationHelper();
    return AppDependencies(
      prefManager: prefManager,
      auth: AuthRepositoryImpl(
        firebaseReady ? FirebaseAuthBackend() : LocalAuthBackend(secure),
        secure,
      ),
      meals: MealRepositoryImpl(TheMealDbClient(TheMealDbClient.createDio())),
      favorites: favorites,
      planner: PlannerRepositoryImpl(PlannedDao(db)),
      sync: SyncRepositoryImpl(
        local: favorites,
        cloud: firebaseReady
            ? FirestoreFavoritesStore()
            : const UnavailableFavoritesStore(),
      ),
      reminders: ReminderServiceImpl(),
      permission: PluginNotificationPermission(notifications),
      connectivity: PlusConnectivitySource(),
      avatarStore: FileAvatarStore(prefManager),
      areaCatalog: AssetAreaCatalog(),
      notifications: notifications,
      disposables: [db.close],
    );
  }

  /// In-memory fakes: used by widget and integration tests.
  static AppDependencies fake({
    required PreferenceManager prefManager,
    AuthRepository? auth,
    MealRepository? meals,
    FavoritesRepository? favorites,
    PlannerRepository? planner,
    SyncRepository? sync,
    ConnectivitySource? connectivity,
    Clock clock = const Clock(),
  }) => AppDependencies(
    prefManager: prefManager,
    auth: auth ?? FakeAuthRepository(),
    meals: meals ?? FakeMealRepository(),
    favorites: favorites ?? FakeFavoritesRepository(),
    planner: planner ?? FakePlannerRepository(),
    sync: sync ?? FakeSyncRepository(),
    reminders: FakeReminderService(),
    permission: AlwaysGrantedPermission(),
    connectivity: connectivity ?? _AlwaysOnline(),
    avatarStore: _NoAvatarStore(),
    areaCatalog: _FakeAreaCatalog(),
    videoBuilder: (context, id) => Text('player:$id'),
    clock: clock,
    useGoogleFonts: false,
  );
}

class _AlwaysOnline implements ConnectivitySource {
  @override
  Future<bool> checkOnline() async => true;

  @override
  Stream<bool> get onlineChanges => const Stream.empty();
}

class _NoAvatarStore implements AvatarStore {
  @override
  Future<void> clear(String uid) async {}

  @override
  Future<String?> load(String uid) async => null;

  @override
  Future<String> save(String uid, String pickedPath) async => pickedPath;
}

class _FakeAreaCatalog implements AreaCatalog {
  @override
  Future<List<SearchItem>> load() async => const [
    SearchItem(name: 'Italian', flag: '🇮🇹'),
    SearchItem(name: 'Japanese', flag: '🇯🇵'),
    SearchItem(name: 'British', flag: '🇬🇧'),
  ];
}
