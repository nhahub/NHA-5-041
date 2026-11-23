import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/data/remote/meal_dto.dart';
import 'package:food_planner/data/remote/themealdb_client.dart';
import 'package:food_planner/data/repositories/meal_repository_impl.dart';
import 'package:food_planner/domain/models/meal.dart';
import 'package:food_planner/domain/result.dart';

import '../fixtures/fixtures.dart';

/// Dio adapter that serves canned responses or errors.
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

MealRepositoryImpl repoWith(StubAdapter adapter) {
  final dio = TheMealDbClient.createDio()..httpClientAdapter = adapter;
  return MealRepositoryImpl(TheMealDbClient(dio));
}

void main() {
  group('MealDto', () {
    test('parses 20 ingredient columns, skipping null/empty/whitespace', () {
      final meal = MealDto.meals(loadFixture('meal_full')).single;
      expect(meal.id, '52772');
      expect(meal.ingredients.length, 9);
      expect(
        meal.ingredients.first,
        const Ingredient(name: 'soy sauce', measure: '3/4 cup'),
      );
      expect(meal.ingredients.any((i) => i.name.trim().isEmpty), isFalse);
      expect(meal.youtube, contains('4aZr5hZXP_s'));
    });

    test('handles null fields and whitespace-only ingredients', () {
      final meal = MealDto.meals(loadFixture('meal_nulls')).single;
      expect(meal.ingredients, [const Ingredient(name: 'Bread')]);
      expect(meal.category, '');
      expect(meal.thumb, '');
      expect(meal.instructions, '');
    });

    test('"meals": null gives an empty list, not a crash', () {
      expect(MealDto.meals(loadFixture('meals_null')), isEmpty);
      expect(MealDto.summaries(loadFixture('meals_null')), isEmpty);
    });

    test('parses categories, filter results and areas', () {
      expect(MealDto.categories(loadFixture('categories')).map((c) => c.name), [
        'Beef',
        'Seafood',
      ]);
      final summaries = MealDto.summaries(loadFixture('filter_results'));
      expect(summaries.length, 2);
      expect(summaries.first.id, '52959');
      expect(MealDto.areas(loadFixture('areas')).map((a) => a.name), [
        'Egyptian',
        'Italian',
      ]);
    });

    test('ingredient image url uses underscores and size suffix', () {
      expect(
        const Ingredient(name: 'Chicken Breast').imageUrl(size: 'small'),
        'https://www.themealdb.com/images/ingredients/Chicken_Breast-small.png',
      );
    });
  });

  group('MealRepositoryImpl (stubbed Dio)', () {
    test('success', () async {
      final repo = repoWith(StubAdapter((_) => json(loadFixture('meal_full'))));
      final r = await repo.lookup('52772');
      expect(r.valueOrNull?.name, 'Teriyaki Chicken Casserole');
    });

    test('null meals on lookup gives EmptyFailure', () async {
      final repo = repoWith(
        StubAdapter((_) => json(loadFixture('meals_null'))),
      );
      expect((await repo.lookup('0')).failureOrNull, isA<EmptyFailure>());
    });

    test('null meals on a filter gives an empty list', () async {
      final repo = repoWith(
        StubAdapter((_) => json(loadFixture('meals_null'))),
      );
      expect((await repo.byCategory('Nothing')).valueOrNull, isEmpty);
    });

    test('404 maps to ServerFailure', () async {
      final repo = repoWith(
        StubAdapter((_) => json({'error': 'no'}, status: 404)),
      );
      expect((await repo.random()).failureOrNull, isA<ServerFailure>());
    });

    test('timeout maps to NetworkFailure after one retry', () async {
      final adapter = StubAdapter(
        (o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final r = await repoWith(adapter).random();
      expect(r.failureOrNull, isA<NetworkFailure>());
      expect(adapter.calls, 2); // one retry for transient GET failures
    });

    test('malformed JSON maps to ParseFailure', () async {
      final repo = repoWith(
        StubAdapter(
          (_) => ResponseBody.fromString(
            'not json',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        ),
      );
      expect((await repo.categories()).failureOrNull, isA<ParseFailure>());
    });

    test(
      'categories are cached in memory (no refetch on tab switch)',
      () async {
        final adapter = StubAdapter((_) => json(loadFixture('categories')));
        final repo = repoWith(adapter);
        await repo.categories();
        await repo.categories();
        expect(adapter.calls, 1);
      },
    );

    test('ingredient filter sends underscores for spaces', () async {
      String? sent;
      final repo = repoWith(
        StubAdapter((o) {
          sent = o.queryParameters['i'] as String?;
          return json(loadFixture('filter_results'));
        }),
      );
      await repo.byIngredient('chicken breast');
      expect(sent, 'chicken_breast');
    });
  });
}
