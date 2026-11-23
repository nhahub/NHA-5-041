import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/data/local/app_database.dart';
import 'package:food_planner/data/repositories/favorites_repository_impl.dart';
import 'package:food_planner/data/repositories/planner_repository_impl.dart';
import 'package:food_planner/domain/fakes/fakes.dart';
import 'package:food_planner/domain/models/user_and_plan.dart';
import 'package:food_planner/domain/result.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late FavoritesRepositoryImpl favorites;
  late PlannerRepositoryImpl planner;
  final meal = fakeMeals[0];
  final other = fakeMeals[1];

  setUp(() {
    db = AppDatabase.memory();
    favorites = FavoritesRepositoryImpl(FavoritesDao(db));
    planner = PlannerRepositoryImpl(PlannedDao(db));
  });
  tearDown(() => db.close());

  group('favorites', () {
    test('add then read keeps the full snapshot (offline details)', () async {
      await favorites.add('u1', meal);
      final all = await favorites.getAll('u1');
      expect(all.single, meal);
    });

    test('duplicate add keeps one row', () async {
      await favorites.add('u1', meal);
      await favorites.add('u1', meal);
      expect((await favorites.getAll('u1')).length, 1);
    });

    test('remove deletes only that meal', () async {
      await favorites.add('u1', meal);
      await favorites.add('u1', other);
      await favorites.remove('u1', meal.id);
      expect((await favorites.getAll('u1')).map((m) => m.id), [other.id]);
    });

    test('two users never see each other\'s favorites', () async {
      await favorites.add('u1', meal);
      await favorites.add('u2', other);
      expect((await favorites.getAll('u1')).map((m) => m.id), [meal.id]);
      expect((await favorites.getAll('u2')).map((m) => m.id), [other.id]);
      await favorites.clear('u1');
      expect(await favorites.getAll('u1'), isEmpty);
      expect(await favorites.getAll('u2'), isNotEmpty);
    });

    test('guest (empty user id) cannot add', () async {
      final r = await favorites.add('', meal);
      expect(r.failureOrNull, isA<GuestFailure>());
    });

    test('watchIsFavorite reacts to add and remove', () async {
      final states = <bool>[];
      final sub = favorites.watchIsFavorite('u1', meal.id).listen(states.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await favorites.add('u1', meal);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await favorites.remove('u1', meal.id);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(states, [false, true, false]);
    });

    test('newest favorite comes first', () async {
      await favorites.add('u1', meal);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await favorites.add('u1', other);
      expect((await favorites.getAll('u1')).first.id, other.id);
    });
  });

  group('planner', () {
    final d1 = DateTime(2026, 11, 14);
    final d2 = DateTime(2026, 11, 15);

    test('add and read back by day', () async {
      final r = await planner.add('u1', meal, d1);
      expect(r.isOk, isTrue);
      expect((await planner.plannedFor('u1', d1)).single.meal, meal);
      expect(await planner.plannedFor('u1', d2), isEmpty);
    });

    test('same meal twice on one day is rejected', () async {
      await planner.add('u1', meal, d1);
      final dup = await planner.add('u1', meal, DateTime(2026, 11, 14, 18, 30));
      expect(dup.failureOrNull, isA<DuplicateFailure>());
    });

    test('same meal on another day is allowed', () async {
      await planner.add('u1', meal, d1);
      expect((await planner.add('u1', meal, d2)).isOk, isTrue);
    });

    test('range is ordered by day and remove works', () async {
      await planner.add('u1', other, d2);
      final first = (await planner.add('u1', meal, d1)).valueOrNull!;
      final range = await planner.watchRange('u1', d1, d2).first;
      expect(range.map((p) => p.day), [d1, d2]);
      await planner.remove(first.id);
      expect((await planner.watchRange('u1', d1, d2).first).length, 1);
    });

    test('plans are per user and survive month/year boundaries', () async {
      await planner.add('u1', meal, DateTime(2026, 12, 31));
      await planner.add('u1', other, DateTime(2027, 1, 1));
      await planner.add('u2', meal, DateTime(2026, 12, 31));
      final range = await planner
          .watchRange('u1', DateTime(2026, 12, 30), DateTime(2027, 1, 2))
          .first;
      expect(range.length, 2);
    });

    test('reminder can be set and cleared', () async {
      final plan = (await planner.add('u1', meal, d1)).valueOrNull!;
      final at = DateTime(2026, 11, 14, 17);
      await planner.setReminder(plan.id, at);
      expect((await planner.plannedFor('u1', d1)).single.reminderAt, at);
      await planner.setReminder(plan.id, null);
      expect((await planner.plannedFor('u1', d1)).single.reminderAt, isNull);
    });

    test('day keys are calendar days, not timestamps', () {
      expect(dayKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
      expect(parseDayKey('2026-03-05'), DateTime(2026, 3, 5));
    });
  });

  test('schema version is 1 (bump needs a migration)', () {
    expect(db.schemaVersion, 1);
  });
}
