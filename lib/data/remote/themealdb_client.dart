import 'package:dio/dio.dart';

/// Retrofit-style declaration of the TheMealDB endpoints.
///
/// Every method returns the decoded JSON envelope; parsing lives in
/// `meal_dto.dart` so it can be tested against real fixtures.
class TheMealDbClient {
  TheMealDbClient(this._dio);

  /// Free test key `1` - development and education only.
  static const baseUrl = 'https://www.themealdb.com/api/json/v1/1/';

  final Dio _dio;

  static Dio createDio() => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final response = await _dio.get<dynamic>(path, queryParameters: query);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Response is not a JSON object');
  }

  Future<Map<String, dynamic>> random() => _get('random.php');
  Future<Map<String, dynamic>> categories() => _get('categories.php');
  Future<Map<String, dynamic>> listAreas() => _get('list.php', {'a': 'list'});
  Future<Map<String, dynamic>> listIngredients() =>
      _get('list.php', {'i': 'list'});
  Future<Map<String, dynamic>> filterByCategory(String c) =>
      _get('filter.php', {'c': c});
  Future<Map<String, dynamic>> filterByArea(String a) =>
      _get('filter.php', {'a': a});
  Future<Map<String, dynamic>> filterByIngredient(String i) =>
      _get('filter.php', {'i': i});
  Future<Map<String, dynamic>> lookup(String id) =>
      _get('lookup.php', {'i': id});
  Future<Map<String, dynamic>> searchByLetter(String l) =>
      _get('search.php', {'f': l});
  Future<Map<String, dynamic>> searchByName(String s) =>
      _get('search.php', {'s': s});
}
