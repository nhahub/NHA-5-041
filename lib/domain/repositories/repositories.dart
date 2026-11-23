import '../models/meal.dart';
import '../models/user_and_plan.dart';
import '../result.dart';

abstract class MealRepository {
  Future<Result<Meal>> random();
  Future<Result<List<MealCategory>>> categories();
  Future<Result<List<Area>>> areas();
  Future<Result<List<IngredientItem>>> ingredients();
  Future<Result<List<MealSummary>>> byCategory(String category);
  Future<Result<List<MealSummary>>> byArea(String area);
  Future<Result<List<MealSummary>>> byIngredient(String ingredient);
  Future<Result<Meal>> lookup(String id);
  Future<Result<List<Meal>>> searchByLetter(String letter);
}

abstract class FavoritesRepository {
  Stream<List<Meal>> watchFavorites(String userId);
  Stream<bool> watchIsFavorite(String userId, String mealId);
  Future<List<Meal>> getAll(String userId);
  Future<Result<void>> add(String userId, Meal meal);
  Future<Result<void>> remove(String userId, String mealId);
  Future<void> clear(String userId);
}

abstract class PlannerRepository {
  Stream<List<PlannedMeal>> watchRange(
    String userId,
    DateTime start,
    DateTime end,
  );
  Future<List<PlannedMeal>> plannedFor(String userId, DateTime date);
  Stream<PlannedMeal?> watchPlanFor(String userId, String mealId);
  Future<Result<PlannedMeal>> add(String userId, Meal meal, DateTime date);
  Future<void> remove(int id);
  Future<void> setReminder(int id, DateTime? reminderAt);
}

abstract class AuthRepository {
  /// Emits the current state first, then every change.
  Stream<AuthState> get authStateChanges;
  AuthState get currentState;

  /// Restores the persisted session. Call once at startup.
  Future<AuthState> init();
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });
  Future<Result<AppUser>> signInWithGoogle();
  Future<void> continueAsGuest();
  Future<void> signOut();
}

enum SyncPhase { idle, syncing, restoring, error }

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.lastSyncedAt,
    this.message,
    this.pending = false,
  });

  final SyncPhase phase;
  final DateTime? lastSyncedAt;
  final String? message;

  /// True when a change is waiting for connectivity.
  final bool pending;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncedAt,
    String? message,
    bool? pending,
    bool clearMessage = false,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    message: clearMessage ? null : (message ?? this.message),
    pending: pending ?? this.pending,
  );
}

abstract class SyncRepository {
  Stream<SyncStatus> watchStatus(String userId);
  SyncStatus statusFor(String userId);

  /// Makes the cloud copy equal to the local favorites. Returns count pushed.
  Future<Result<int>> backup(String userId);

  /// Restores from the cloud only when local favorites are empty.
  /// Returns the number of restored favorites (0 if nothing to do).
  Future<Result<int>> restoreIfEmpty(String userId);
}

abstract class ReminderService {
  /// Schedules a reminder for a planned meal. Rejects times in the past.
  Future<Result<void>> schedule({
    required int plannedId,
    required String mealId,
    required String mealName,
    required DateTime at,
  });
  Future<void> cancel(int plannedId);
}
