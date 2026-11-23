import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/meal.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import '../local/app_database.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._dao);

  final FavoritesDao _dao;

  static Meal toMeal(FavoriteRow r) => Meal(
    id: r.mealId,
    name: r.name,
    thumb: r.thumb,
    category: r.category,
    area: r.area,
    instructions: r.instructions,
    youtube: r.youtube,
    ingredients: (jsonDecode(r.ingredientsJson) as List)
        .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  @override
  Stream<List<Meal>> watchFavorites(String userId) =>
      _dao.watchAll(userId).map((rows) => rows.map(toMeal).toList());

  @override
  Stream<bool> watchIsFavorite(String userId, String mealId) =>
      _dao.watchIsFavorite(userId, mealId);

  @override
  Future<List<Meal>> getAll(String userId) async =>
      (await _dao.getAll(userId)).map(toMeal).toList();

  @override
  Future<Result<void>> add(String userId, Meal meal) async {
    if (userId.isEmpty) return const Result.err(GuestFailure());
    try {
      await _dao.insert(
        FavoritesCompanion.insert(
          userId: userId,
          mealId: meal.id,
          name: meal.name,
          thumb: Value(meal.thumb),
          category: Value(meal.category),
          area: Value(meal.area),
          instructions: Value(meal.instructions),
          youtube: Value(meal.youtube),
          ingredientsJson: Value(
            jsonEncode(meal.ingredients.map((i) => i.toJson()).toList()),
          ),
          addedAt: DateTime.now(),
        ),
      );
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(StorageFailure());
    }
  }

  @override
  Future<Result<void>> remove(String userId, String mealId) async {
    try {
      await _dao.delete(userId, mealId);
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(StorageFailure());
    }
  }

  @override
  Future<void> clear(String userId) => _dao.deleteAll(userId);
}
