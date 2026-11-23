import 'dart:convert';

import 'package:equatable/equatable.dart';

const _mealDbImages = 'https://www.themealdb.com/images';

/// One ingredient line of a meal (name + optional measure).
class Ingredient extends Equatable {
  const Ingredient({required this.name, this.measure = ''});

  final String name;
  final String measure;

  /// Image variants: `''` (full), `small`, `medium`, `large`.
  /// Names use underscores for spaces and keep their original casing.
  String imageUrl({String size = 'small'}) {
    final file = name.trim().replaceAll(' ', '_');
    final suffix = size.isEmpty ? '' : '-$size';
    return '$_mealDbImages/ingredients/${Uri.encodeComponent(file)}$suffix.png';
  }

  Map<String, dynamic> toJson() => {'name': name, 'measure': measure};

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    name: (json['name'] ?? '') as String,
    measure: (json['measure'] ?? '') as String,
  );

  @override
  List<Object?> get props => [name, measure];
}

/// Light item returned by filter endpoints.
class MealSummary extends Equatable {
  const MealSummary({required this.id, required this.name, this.thumb = ''});

  final String id;
  final String name;
  final String thumb;

  @override
  List<Object?> get props => [id, name, thumb];
}

/// Full meal as returned by lookup / random / search.
class Meal extends Equatable {
  const Meal({
    required this.id,
    required this.name,
    this.thumb = '',
    this.category = '',
    this.area = '',
    this.instructions = '',
    this.youtube = '',
    this.ingredients = const [],
  });

  final String id;
  final String name;
  final String thumb;
  final String category;
  final String area;
  final String instructions;
  final String youtube;
  final List<Ingredient> ingredients;

  MealSummary toSummary() => MealSummary(id: id, name: name, thumb: thumb);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'thumb': thumb,
    'category': category,
    'area': area,
    'instructions': instructions,
    'youtube': youtube,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as String,
    name: json['name'] as String,
    thumb: (json['thumb'] ?? '') as String,
    category: (json['category'] ?? '') as String,
    area: (json['area'] ?? '') as String,
    instructions: (json['instructions'] ?? '') as String,
    youtube: (json['youtube'] ?? '') as String,
    ingredients: ((json['ingredients'] ?? const []) as List)
        .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  factory Meal.decode(String source) =>
      Meal.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
    id,
    name,
    thumb,
    category,
    area,
    instructions,
    youtube,
    ingredients,
  ];
}

class MealCategory extends Equatable {
  const MealCategory({
    required this.id,
    required this.name,
    this.thumb = '',
    this.description = '',
  });

  final String id;
  final String name;
  final String thumb;
  final String description;

  @override
  List<Object?> get props => [id, name, thumb, description];
}

class Area extends Equatable {
  const Area(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

/// An ingredient entry in the global ingredient list (search by ingredient).
class IngredientItem extends Equatable {
  const IngredientItem({required this.name, this.description = ''});

  final String name;
  final String description;

  String imageUrl({String size = 'small'}) =>
      Ingredient(name: name).imageUrl(size: size);

  @override
  List<Object?> get props => [name, description];
}
