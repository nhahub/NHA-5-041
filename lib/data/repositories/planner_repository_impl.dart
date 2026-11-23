import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import '../local/app_database.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  PlannerRepositoryImpl(this._dao);

  final PlannedDao _dao;

  static PlannedMeal toPlanned(PlannedRow r) => PlannedMeal(
    id: r.id,
    meal: Meal.decode(r.snapshot),
    day: parseDayKey(r.day),
    reminderAt: r.reminderAt,
  );

  @override
  Stream<List<PlannedMeal>> watchRange(
    String userId,
    DateTime start,
    DateTime end,
  ) => _dao
      .watchRange(userId, dayKey(start), dayKey(end))
      .map((rows) => rows.map(toPlanned).toList());

  @override
  Future<List<PlannedMeal>> plannedFor(String userId, DateTime date) async =>
      (await _dao.forDay(userId, dayKey(date))).map(toPlanned).toList();

  @override
  Stream<PlannedMeal?> watchPlanFor(String userId, String mealId) => _dao
      .watchForMeal(userId, mealId)
      .map((r) => r == null ? null : toPlanned(r));

  @override
  Future<Result<PlannedMeal>> add(
    String userId,
    Meal meal,
    DateTime date,
  ) async {
    if (userId.isEmpty) return const Result.err(GuestFailure());
    final key = dayKey(date);
    if (await _dao.find(userId, meal.id, key) != null) {
      return const Result.err(
        DuplicateFailure('This meal is already planned for that day.'),
      );
    }
    try {
      final id = await _dao.insert(
        PlannedMealsCompanion.insert(
          mealId: meal.id,
          day: key,
          snapshot: meal.encode(),
          userId: userId,
        ),
      );
      return Result.ok(PlannedMeal(id: id, meal: meal, day: dateOnly(date)));
    } catch (_) {
      return const Result.err(StorageFailure());
    }
  }

  @override
  Future<void> remove(int id) => _dao.delete(id);

  @override
  Future<void> setReminder(int id, DateTime? reminderAt) =>
      _dao.setReminder(id, reminderAt);
}
