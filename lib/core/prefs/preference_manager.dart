import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight singleton wrapper around [SharedPreferences].
///
/// Call [PreferenceManager.init] once (typically in `main`) before using the
/// instance anywhere else.  After that every call to [PreferenceManager.instance]
/// returns the same pre-initialised object – no `await` needed.
///
/// ```dart
/// // In main():
/// await PreferenceManager.init();
///
/// // Anywhere else:
/// final theme = PreferenceManager.instance.getString('theme');
/// ```
class PreferenceManager {
  PreferenceManager._internal();

  static PreferenceManager? _instance;

  /// The underlying [SharedPreferences] instance.
  late final SharedPreferences _prefs;

  // ──────────────────── lifecycle ────────────────────

  /// Initialises the singleton.  Safe to call more than once – subsequent
  /// calls are no-ops and return the existing instance.
  static Future<PreferenceManager> init() async {
    if (_instance != null) return _instance!;
    final manager = PreferenceManager._internal();
    manager._prefs = await SharedPreferences.getInstance();
    _instance = manager;
    return manager;
  }

  /// Resets the singleton so the next [init] creates a fresh instance.
  ///
  /// **Only for tests** – call this in `setUp` before
  /// `SharedPreferences.setMockInitialValues`.
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  /// Returns the initialised singleton.
  ///
  /// Throws [StateError] if [init] has not been called yet.
  static PreferenceManager get instance {
    if (_instance == null) {
      throw StateError(
        'PreferenceManager.init() must be called before accessing the instance.',
      );
    }
    return _instance!;
  }

  /// Exposes the raw [SharedPreferences] for callers that need it
  /// (e.g. existing code that takes `SharedPreferences` as a parameter).
  SharedPreferences get prefs => _prefs;

  // ──────────────────── convenience getters ────────────────────

  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // ──────────────────── convenience setters ────────────────────

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // ──────────────────── removal ────────────────────

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();

  bool containsKey(String key) => _prefs.containsKey(key);
}
