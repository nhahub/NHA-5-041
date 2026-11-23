import '../../domain/models/meal.dart';

/// Parsing of TheMealDB payloads into domain models.
class MealDto {
  const MealDto._();

  static String _s(dynamic v) => v is String ? v.trim() : '';

  /// Turns `strIngredient1..20` / `strMeasure1..20` into a list, skipping
  /// null, empty or whitespace-only ingredient names.
  static List<Ingredient> parseIngredients(Map<String, dynamic> json) {
    final result = <Ingredient>[];
    for (var i = 1; i <= 20; i++) {
      final name = _s(json['strIngredient$i']);
      if (name.isEmpty) continue;
      result.add(Ingredient(name: name, measure: _s(json['strMeasure$i'])));
    }
    return result;
  }

  static Meal meal(Map<String, dynamic> json) => Meal(
    id: _s(json['idMeal']),
    name: _s(json['strMeal']),
    thumb: _s(json['strMealThumb']),
    category: _s(json['strCategory']),
    area: _s(json['strArea']),
    instructions: _s(json['strInstructions']),
    youtube: _s(json['strYoutube']),
    ingredients: parseIngredients(json),
  );

  static List<Map<String, dynamic>> _list(
    Map<String, dynamic> envelope,
    String key,
  ) {
    final raw = envelope[key];
    if (raw == null) return const []; // "meals": null => no result
    if (raw is! List) throw const FormatException('Expected a list');
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static List<Meal> meals(Map<String, dynamic> envelope) =>
      _list(envelope, 'meals').map(meal).toList();

  static List<MealSummary> summaries(Map<String, dynamic> envelope) =>
      _list(envelope, 'meals')
          .map(
            (j) => MealSummary(
              id: _s(j['idMeal']),
              name: _s(j['strMeal']),
              thumb: _s(j['strMealThumb']),
            ),
          )
          .where((m) => m.id.isNotEmpty)
          .toList();

  static List<MealCategory> categories(Map<String, dynamic> envelope) =>
      _list(envelope, 'categories')
          .map(
            (j) => MealCategory(
              id: _s(j['idCategory']),
              name: _s(j['strCategory']),
              thumb: _s(j['strCategoryThumb']),
              description: _s(j['strCategoryDescription']),
            ),
          )
          .toList();

  static List<Area> areas(Map<String, dynamic> envelope) =>
      _list(envelope, 'meals')
          .map((j) => _s(j['strArea']))
          .where((n) => n.isNotEmpty)
          .map(Area.new)
          .toList();

  static List<IngredientItem> ingredients(Map<String, dynamic> envelope) =>
      _list(envelope, 'meals')
          .map(
            (j) => IngredientItem(
              name: _s(j['strIngredient']),
              description: _s(j['strDescription']),
            ),
          )
          .where((i) => i.name.isNotEmpty)
          .toList();
}
