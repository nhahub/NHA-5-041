import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/clock.dart';
import '../../core/prefs/preference_manager.dart';
import '../../core/view_state.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

/// Horizontal category row.
class CategoriesCubit extends Cubit<ViewState<List<MealCategory>>> {
  CategoriesCubit(this._meals) : super(const ViewLoading());

  final MealRepository _meals;

  Future<void> load() async {
    emit(const ViewLoading());
    final r = await _meals.categories();
    if (isClosed) return;
    emit(
      r.when(
        ok: (list) => list.isEmpty ? const ViewEmpty() : ViewData(list),
        err: ViewError.new,
      ),
    );
  }
}

/// One random meal per calendar day. `{date, meal}` is persisted so it stays
/// the same all day, survives restarts and is shown offline from the cache.
class MealOfDayCubit extends Cubit<ViewState<Meal>> {
  MealOfDayCubit(
    this._meals,
    this._prefs, {
    Clock clock = const Clock(),
    bool scheduleRollover = true,
  }) : _clock = clock,
       _scheduleRollover = scheduleRollover,
       super(const ViewLoading());

  static const prefsKey = 'meal_of_the_day';

  final MealRepository _meals;
  final PreferenceManager _prefs;
  final Clock _clock;
  final bool _scheduleRollover;
  Timer? _timer;

  ({String date, Meal meal})? _cached() {
    final raw = _prefs.getString(prefsKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        date: json['date'] as String,
        meal: Meal.fromJson(Map<String, dynamic>.from(json['meal'] as Map)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> load({bool force = false}) async {
    final today = dayKey(_clock.now());
    final cached = _cached();
    if (!force && cached != null && cached.date == today) {
      emit(ViewData(cached.meal));
      _armRollover();
      return;
    }
    emit(const ViewLoading());
    final r = await _meals.random();
    if (isClosed) return;
    switch (r) {
      case Ok<Meal>(:final value):
        await _prefs.setString(
          prefsKey,
          jsonEncode({'date': today, 'meal': value.toJson()}),
        );
        emit(ViewData(value));
      case Err<Meal>(:final failure):
        // Offline with an older cached meal: show it rather than an error.
        emit(cached != null ? ViewData(cached.meal) : ViewError(failure));
    }
    _armRollover();
  }

  void _armRollover() {
    if (!_scheduleRollover) return;
    _timer?.cancel();
    final now = _clock.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now) + const Duration(seconds: 1), load);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class BrowseFeedState extends Equatable {
  const BrowseFeedState({
    this.meals = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.failure,
  });

  final List<Meal> meals;

  /// First page is loading.
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Failure? failure;

  bool get isEmpty => !loading && meals.isEmpty && failure == null && !hasMore;

  BrowseFeedState copyWith({
    List<Meal>? meals,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    Failure? failure,
    bool clearFailure = false,
  }) => BrowseFeedState(
    meals: meals ?? this.meals,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [meals, loading, loadingMore, hasMore, failure];
}

/// Browse Recipes: infinite scroll over `search.php?f=a` ... `z`, one letter
/// per page (decision D5). Letters without meals are skipped automatically.
class BrowseFeedCubit extends Cubit<BrowseFeedState> {
  BrowseFeedCubit(this._meals, {this.minPerPage = 8})
    : super(const BrowseFeedState());

  static const letters = 'abcdefghijklmnopqrstuvwxyz';

  final MealRepository _meals;
  final int minPerPage;
  int _next = 0;
  bool _busy = false;

  Future<void> refresh() async {
    _next = 0;
    _busy = false;
    emit(const BrowseFeedState());
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_busy || !state.hasMore) return;
    _busy = true;
    final first = state.meals.isEmpty;
    emit(
      state.copyWith(loading: first, loadingMore: !first, clearFailure: true),
    );

    final seen = {for (final m in state.meals) m.id};
    final all = [...state.meals];
    var added = 0;
    while (_next < letters.length && added < minPerPage) {
      final r = await _meals.searchByLetter(letters[_next]);
      if (isClosed) return;
      if (r case Err<List<Meal>>(:final failure)) {
        _busy = false;
        emit(
          state.copyWith(
            meals: all,
            loading: false,
            loadingMore: false,
            failure: failure,
          ),
        );
        return;
      }
      _next++;
      for (final m in r.valueOrNull ?? const <Meal>[]) {
        if (seen.add(m.id)) {
          all.add(m);
          added++;
        }
      }
    }
    _busy = false;
    emit(
      state.copyWith(
        meals: all,
        loading: false,
        loadingMore: false,
        hasMore: _next < letters.length,
      ),
    );
  }
}
