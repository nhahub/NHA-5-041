import 'package:dio/dio.dart';

import '../../domain/models/meal.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import '../remote/meal_dto.dart';
import '../remote/themealdb_client.dart';

class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._client);

  final TheMealDbClient _client;

  // In-memory caches so tab switches never refetch the static lists.
  List<MealCategory>? _categories;
  List<Area>? _areas;
  List<IngredientItem>? _ingredients;

  /// Runs [call], retrying once for transient failures, and maps errors to
  /// typed [Failure]s.
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return Result.ok(await call());
      } on DioException catch (e) {
        final transient = switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.connectionError => true,
          _ => false,
        };
        if (transient && attempt == 0) continue;
        return Result.err(mapDioException(e));
      } on Failure catch (f) {
        return Result.err(f);
      } on FormatException {
        return const Result.err(ParseFailure());
      } on TypeError {
        return const Result.err(ParseFailure());
      }
    }
    return const Result.err(NetworkFailure());
  }

  static Failure mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        return ServerFailure(
          'Server error (${e.response?.statusCode ?? '?'}).',
        );
      default:
        return e.error is FormatException
            ? const ParseFailure()
            : const NetworkFailure();
    }
  }

  @override
  Future<Result<Meal>> random() => _guard(() async {
    final meals = MealDto.meals(await _client.random());
    if (meals.isEmpty) throw const EmptyFailure();
    return meals.first;
  });

  @override
  Future<Result<Meal>> lookup(String id) => _guard(() async {
    final meals = MealDto.meals(await _client.lookup(id));
    if (meals.isEmpty) throw const EmptyFailure();
    return meals.first;
  });

  @override
  Future<Result<List<MealCategory>>> categories() async {
    final cached = _categories;
    if (cached != null) return Result.ok(cached);
    final r = await _guard(
      () async => MealDto.categories(await _client.categories()),
    );
    _categories = r.valueOrNull ?? _categories;
    return r;
  }

  @override
  Future<Result<List<Area>>> areas() async {
    final cached = _areas;
    if (cached != null) return Result.ok(cached);
    final r = await _guard(
      () async => MealDto.areas(await _client.listAreas()),
    );
    _areas = r.valueOrNull ?? _areas;
    return r;
  }

  @override
  Future<Result<List<IngredientItem>>> ingredients() async {
    final cached = _ingredients;
    if (cached != null) return Result.ok(cached);
    final r = await _guard(
      () async => MealDto.ingredients(await _client.listIngredients()),
    );
    _ingredients = r.valueOrNull ?? _ingredients;
    return r;
  }

  @override
  Future<Result<List<MealSummary>>> byCategory(String category) => _guard(
    () async => MealDto.summaries(await _client.filterByCategory(category)),
  );

  @override
  Future<Result<List<MealSummary>>> byArea(String area) =>
      _guard(() async => MealDto.summaries(await _client.filterByArea(area)));

  @override
  Future<Result<List<MealSummary>>> byIngredient(String ingredient) => _guard(
    () async => MealDto.summaries(
      // The API expects underscores for spaces (chicken_breast).
      await _client.filterByIngredient(ingredient.trim().replaceAll(' ', '_')),
    ),
  );

  @override
  Future<Result<List<Meal>>> searchByLetter(String letter) =>
      _guard(() async => MealDto.meals(await _client.searchByLetter(letter)));
}
