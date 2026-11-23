class Routes {
  const Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const search = '/search';
  static const calendar = '/calendar';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const about = '/about';
  static const gallery = '/theme-gallery';
  static const meal = '/meal/:id';
  static const meals = '/meals';

  static String mealPath(String id) => '/meal/$id';

  /// `type` is one of [MealListType.name]: category | area | ingredient.
  static String mealsPath(String type, String value) => Uri(
    path: meals,
    queryParameters: {'type': type, 'value': value},
  ).toString();

  static String heroTag(String mealId) => 'meal-hero-$mealId';
}
