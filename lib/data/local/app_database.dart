import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Favorites keep a FULL meal snapshot so Details works offline.
@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get userId => text()();
  TextColumn get mealId => text()();
  TextColumn get name => text()();
  TextColumn get thumb => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get area => text().withDefault(const Constant(''))();
  TextColumn get instructions => text().withDefault(const Constant(''))();
  TextColumn get youtube => text().withDefault(const Constant(''))();
  TextColumn get ingredientsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, mealId};
}

/// Planned meals: the day is a local calendar day string (`yyyy-MM-dd`),
/// never a timestamp, to avoid timezone bugs.
@DataClassName('PlannedRow')
class PlannedMeals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mealId => text()();
  TextColumn get day => text()();
  TextColumn get snapshot => text()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get userId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, mealId, day},
  ];
}

@DriftDatabase(tables: [Favorites, PlannedMeals])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// App-private on-disk database.
  factory AppDatabase.open() => AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'food_planner.sqlite')),
      );
    }),
  );

  /// In-memory database for tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Future schema changes go here, one `if (from < N)` block per version.
    },
  );
}

class FavoritesDao {
  FavoritesDao(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$FavoritesTable, FavoriteRow> _forUser(String userId) =>
      _db.select(_db.favorites)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]);

  Stream<List<FavoriteRow>> watchAll(String userId) => _forUser(userId).watch();

  Future<List<FavoriteRow>> getAll(String userId) => _forUser(userId).get();

  Stream<bool> watchIsFavorite(String userId, String mealId) =>
      (_db.select(_db.favorites)
            ..where((t) => t.userId.equals(userId) & t.mealId.equals(mealId)))
          .watch()
          .map((rows) => rows.isNotEmpty);

  Future<void> insert(FavoritesCompanion row) =>
      _db.into(_db.favorites).insertOnConflictUpdate(row);

  Future<void> delete(String userId, String mealId) => (_db.delete(
    _db.favorites,
  )..where((t) => t.userId.equals(userId) & t.mealId.equals(mealId))).go();

  Future<void> deleteAll(String userId) =>
      (_db.delete(_db.favorites)..where((t) => t.userId.equals(userId))).go();
}

class PlannedDao {
  PlannedDao(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$PlannedMealsTable, PlannedRow> _range(
    String userId,
    String startKey,
    String endKey,
  ) => _db.select(_db.plannedMeals)
    ..where(
      (t) =>
          t.userId.equals(userId) &
          t.day.isBiggerOrEqualValue(startKey) &
          t.day.isSmallerOrEqualValue(endKey),
    )
    ..orderBy([(t) => OrderingTerm.asc(t.day), (t) => OrderingTerm.asc(t.id)]);

  Stream<List<PlannedRow>> watchRange(
    String userId,
    String start,
    String end,
  ) => _range(userId, start, end).watch();

  Future<List<PlannedRow>> forDay(String userId, String day) =>
      _range(userId, day, day).get();

  Stream<PlannedRow?> watchForMeal(String userId, String mealId) =>
      (_db.select(_db.plannedMeals)
            ..where((t) => t.userId.equals(userId) & t.mealId.equals(mealId))
            ..orderBy([(t) => OrderingTerm.asc(t.day)])
            ..limit(1))
          .watchSingleOrNull();

  Future<PlannedRow?> find(String userId, String mealId, String day) =>
      (_db.select(_db.plannedMeals)..where(
            (t) =>
                t.userId.equals(userId) &
                t.mealId.equals(mealId) &
                t.day.equals(day),
          ))
          .getSingleOrNull();

  Future<int> insert(PlannedMealsCompanion row) =>
      _db.into(_db.plannedMeals).insert(row);

  Future<void> delete(int id) =>
      (_db.delete(_db.plannedMeals)..where((t) => t.id.equals(id))).go();

  Future<void> setReminder(int id, DateTime? at) =>
      (_db.update(_db.plannedMeals)..where((t) => t.id.equals(id))).write(
        PlannedMealsCompanion(reminderAt: Value(at)),
      );
}
