import 'dart:async';

import '../models/meal.dart';
import '../models/user_and_plan.dart';
import '../repositories/repositories.dart';
import '../result.dart';

const fakeMeals = <Meal>[
  Meal(
    id: '52772',
    name: 'Teriyaki Chicken Casserole',
    thumb: 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
    category: 'Chicken',
    area: 'Japanese',
    instructions:
        'Preheat oven.\nMix the sauce.\nBake until golden.\nServe hot.',
    youtube: 'https://www.youtube.com/watch?v=4aZr5hZXP_s',
    ingredients: [
      Ingredient(name: 'Soy Sauce', measure: '3/4 cup'),
      Ingredient(name: 'Chicken Breasts', measure: '2'),
    ],
  ),
  Meal(
    id: '52771',
    name: 'Spicy Arrabiata Penne',
    thumb: 'https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg',
    category: 'Vegetarian',
    area: 'Italian',
    instructions: 'Boil the pasta.\nMake the sauce.\nCombine.',
    ingredients: [
      Ingredient(name: 'Penne Rigate', measure: '1 pound'),
      Ingredient(name: 'Garlic', measure: '3 cloves'),
    ],
  ),
  Meal(
    id: '52959',
    name: 'Baked salmon with fennel & tomatoes',
    thumb: 'https://www.themealdb.com/images/media/meals/1548772327.jpg',
    category: 'Seafood',
    area: 'British',
    instructions: 'Heat oven.\nBake salmon.',
    ingredients: [Ingredient(name: 'Salmon', measure: '2 fillets')],
  ),
];

class FakeMealRepository implements MealRepository {
  FakeMealRepository({this.meals = fakeMeals, this.failure});

  final List<Meal> meals;
  Failure? failure;
  int calls = 0;

  Result<T> _r<T>(T Function() ok) {
    calls++;
    return failure != null ? Result.err(failure!) : Result.ok(ok());
  }

  @override
  Future<Result<List<MealCategory>>> categories() async => _r(
    () => const [
      MealCategory(id: '1', name: 'Seafood', thumb: ''),
      MealCategory(id: '2', name: 'Chicken', thumb: ''),
      MealCategory(id: '3', name: 'Vegetarian', thumb: ''),
    ],
  );

  @override
  Future<Result<List<Area>>> areas() async =>
      _r(() => const [Area('Italian'), Area('Japanese'), Area('British')]);

  @override
  Future<Result<List<IngredientItem>>> ingredients() async => _r(
    () => const [
      IngredientItem(name: 'Chicken'),
      IngredientItem(name: 'Garlic'),
      IngredientItem(name: 'Salmon'),
    ],
  );

  @override
  Future<Result<List<MealSummary>>> byCategory(String c) async => _r(
    () =>
        meals.where((m) => m.category == c).map((m) => m.toSummary()).toList(),
  );

  @override
  Future<Result<List<MealSummary>>> byArea(String a) async => _r(
    () => meals.where((m) => m.area == a).map((m) => m.toSummary()).toList(),
  );

  @override
  Future<Result<List<MealSummary>>> byIngredient(String i) async =>
      _r(() => meals.map((m) => m.toSummary()).toList());

  @override
  Future<Result<Meal>> lookup(String id) async {
    calls++;
    if (failure != null) return Result.err(failure!);
    final found = meals.where((m) => m.id == id);
    return found.isEmpty
        ? const Result.err(EmptyFailure())
        : Result.ok(found.first);
  }

  @override
  Future<Result<Meal>> random() async => _r(() => meals.first);

  @override
  Future<Result<List<Meal>>> searchByLetter(String letter) async => _r(
    () => meals
        .where((m) => m.name.toLowerCase().startsWith(letter.toLowerCase()))
        .toList(),
  );
}

/// Emits [read]'s value now and after every change. Subscribes to [changes]
/// synchronously on listen, so no update can slip between the two.
Stream<T> _watch<T>(Stream<void> changes, Future<T> Function() read) {
  late StreamController<T> controller;
  StreamSubscription<void>? sub;
  controller = StreamController<T>(
    onListen: () {
      read().then((v) {
        if (!controller.isClosed) controller.add(v);
      });
      sub = changes.listen((_) {
        read().then((v) {
          if (!controller.isClosed) controller.add(v);
        });
      });
    },
    onCancel: () => sub?.cancel(),
  );
  return controller.stream;
}

class FakeFavoritesRepository implements FavoritesRepository {
  final Map<String, Map<String, Meal>> _data = {};
  final _changes = StreamController<void>.broadcast();

  Map<String, Meal> _of(String uid) => _data.putIfAbsent(uid, () => {});

  @override
  Stream<List<Meal>> watchFavorites(String userId) =>
      _watch(_changes.stream, () => getAll(userId));

  @override
  Stream<bool> watchIsFavorite(String userId, String mealId) => _watch(
    _changes.stream,
    () async => (await getAll(userId)).any((m) => m.id == mealId),
  );

  @override
  Future<List<Meal>> getAll(String userId) async =>
      _of(userId).values.toList().reversed.toList();

  @override
  Future<Result<void>> add(String userId, Meal meal) async {
    _of(userId)[meal.id] = meal;
    _changes.add(null);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> remove(String userId, String mealId) async {
    _of(userId).remove(mealId);
    _changes.add(null);
    return const Result.ok(null);
  }

  @override
  Future<void> clear(String userId) async {
    _of(userId).clear();
    _changes.add(null);
  }
}

class FakePlannerRepository implements PlannerRepository {
  final List<(String, PlannedMeal)> _rows = [];
  int _nextId = 1;
  final _changes = StreamController<void>.broadcast();

  List<PlannedMeal> _range(String uid, DateTime s, DateTime e) {
    final res =
        _rows
            .where(
              (r) =>
                  r.$1 == uid &&
                  !r.$2.day.isBefore(dateOnly(s)) &&
                  !r.$2.day.isAfter(dateOnly(e)),
            )
            .map((r) => r.$2)
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day));
    return res;
  }

  @override
  Stream<List<PlannedMeal>> watchRange(
    String userId,
    DateTime start,
    DateTime end,
  ) => _watch(_changes.stream, () async => _range(userId, start, end));

  @override
  Future<List<PlannedMeal>> plannedFor(String userId, DateTime date) async =>
      _range(userId, date, date);

  @override
  Stream<PlannedMeal?> watchPlanFor(String userId, String mealId) {
    Future<PlannedMeal?> find() async {
      final l =
          _rows
              .where((r) => r.$1 == userId && r.$2.meal.id == mealId)
              .map((r) => r.$2)
              .toList()
            ..sort((a, b) => a.day.compareTo(b.day));
      return l.isEmpty ? null : l.first;
    }

    return _watch(_changes.stream, find);
  }

  @override
  Future<Result<PlannedMeal>> add(
    String userId,
    Meal meal,
    DateTime date,
  ) async {
    final day = dateOnly(date);
    final dup = _rows.any(
      (r) => r.$1 == userId && r.$2.meal.id == meal.id && r.$2.day == day,
    );
    if (dup) {
      return const Result.err(
        DuplicateFailure('This meal is already planned for that day.'),
      );
    }
    final p = PlannedMeal(id: _nextId++, meal: meal, day: day);
    _rows.add((userId, p));
    _changes.add(null);
    return Result.ok(p);
  }

  @override
  Future<void> remove(int id) async {
    _rows.removeWhere((r) => r.$2.id == id);
    _changes.add(null);
  }

  @override
  Future<void> setReminder(int id, DateTime? reminderAt) async {
    final i = _rows.indexWhere((r) => r.$2.id == id);
    if (i < 0) return;
    final old = _rows[i];
    _rows[i] = (
      old.$1,
      PlannedMeal(
        id: id,
        meal: old.$2.meal,
        day: old.$2.day,
        reminderAt: reminderAt,
      ),
    );
    _changes.add(null);
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthState initial = const AuthState.unauthenticated()})
    : _state = initial;

  AuthState _state;
  final _controller = StreamController<AuthState>.broadcast();
  Failure? nextFailure;

  void _emit(AuthState s) {
    _state = s;
    _controller.add(s);
  }

  @override
  AuthState get currentState => _state;

  @override
  Stream<AuthState> get authStateChanges async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  Future<AuthState> init() async => _state;

  Result<AppUser> _user(String name, String email) {
    if (nextFailure != null) {
      final f = nextFailure!;
      nextFailure = null;
      return Result.err(f);
    }
    final u = AppUser(uid: 'uid-$email', displayName: name, email: email);
    _emit(AuthState.authenticated(u));
    return Result.ok(u);
  }

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) async => _user(name, email);

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async => _user(email.split('@').first, email);

  @override
  Future<Result<AppUser>> signInWithGoogle() async =>
      _user('Google User', 'google@example.com');

  @override
  Future<void> continueAsGuest() async => _emit(const AuthState.guest());

  @override
  Future<void> signOut() async => _emit(const AuthState.unauthenticated());
}

class FakeSyncRepository implements SyncRepository {
  int backups = 0;
  int restores = 0;

  @override
  SyncStatus statusFor(String userId) => const SyncStatus();

  @override
  Stream<SyncStatus> watchStatus(String userId) =>
      Stream.value(const SyncStatus());

  @override
  Future<Result<int>> backup(String userId) async {
    backups++;
    return const Result.ok(0);
  }

  @override
  Future<Result<int>> restoreIfEmpty(String userId) async {
    restores++;
    return const Result.ok(0);
  }
}

class FakeReminderService implements ReminderService {
  final Map<int, DateTime> scheduled = {};

  @override
  Future<Result<void>> schedule({
    required int plannedId,
    required String mealId,
    required String mealName,
    required DateTime at,
  }) async {
    scheduled[plannedId] = at;
    return const Result.ok(null);
  }

  @override
  Future<void> cancel(int plannedId) async => scheduled.remove(plannedId);
}
