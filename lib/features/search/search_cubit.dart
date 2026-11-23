import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/view_state.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

enum SearchMode { categories, countries, ingredients }

/// One tile in the search grids.
class SearchItem extends Equatable {
  const SearchItem({required this.name, this.imageUrl = '', this.flag});

  final String name;
  final String imageUrl;

  /// Emoji flag for countries, `null` when unknown (globe icon fallback).
  final String? flag;

  @override
  List<Object?> get props => [name, imageUrl, flag];
}

/// Countries that really have meals (generated once by tools/gen_areas, D2).
abstract class AreaCatalog {
  Future<List<SearchItem>> load();
}

class AssetAreaCatalog implements AreaCatalog {
  AssetAreaCatalog([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Regional-indicator emoji for an ISO 3166-1 alpha-2 code.
  static String? flagEmoji(String? code) {
    if (code == null || code.length != 2) return null;
    final up = code.toUpperCase();
    return String.fromCharCodes(up.codeUnits.map((c) => 0x1F1E6 + (c - 0x41)));
  }

  @override
  Future<List<SearchItem>> load() async {
    final areas = (jsonDecode(
      await _bundle.loadString('assets/data/areas_with_meals.json'),
    ) as List).cast<String>();
    Map<String, dynamic> flags = {};
    try {
      flags = jsonDecode(
        await _bundle.loadString('assets/data/country_flags.json'),
      ) as Map<String, dynamic>;
    } catch (_) {}
    final items = [
      for (final a in areas)
        SearchItem(name: a, flag: flagEmoji(flags[a] as String?)),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }
}

class SearchState extends Equatable {
  const SearchState({
    this.mode = SearchMode.categories,
    this.data = const {},
    this.queries = const {},
    this.applied = const {},
  });

  final SearchMode mode;
  final Map<SearchMode, ViewState<List<SearchItem>>> data;

  /// What the user typed, per mode.
  final Map<SearchMode, String> queries;

  /// The (debounced) query actually used to filter, per mode.
  final Map<SearchMode, String> applied;

  ViewState<List<SearchItem>> get current => data[mode] ?? const ViewLoading();
  String get query => queries[mode] ?? '';

  /// Items of the current mode after local filtering.
  List<SearchItem> get visible {
    final view = current;
    if (view is! ViewData<List<SearchItem>>) return const [];
    return SearchCubit.filter(view.data, applied[mode] ?? '');
  }

  SearchState copyWith({
    SearchMode? mode,
    Map<SearchMode, ViewState<List<SearchItem>>>? data,
    Map<SearchMode, String>? queries,
    Map<SearchMode, String>? applied,
  }) => SearchState(
    mode: mode ?? this.mode,
    data: data ?? this.data,
    queries: queries ?? this.queries,
    applied: applied ?? this.applied,
  );

  @override
  List<Object?> get props => [mode, data, queries, applied];
}

/// Search filters ONLY the data already loaded for the current mode: typing
/// never triggers a network call.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._meals,
    this._areas, {
    this.debounce = const Duration(milliseconds: 250),
  }) : super(const SearchState());

  final MealRepository _meals;
  final AreaCatalog _areas;
  final Duration debounce;
  Timer? _timer;

  /// Trimmed, case-insensitive "contains"; empty query returns everything.
  static List<SearchItem> filter(List<SearchItem> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  void _put(SearchMode m, ViewState<List<SearchItem>> v) =>
      emit(state.copyWith(data: {...state.data, m: v}));

  Future<void> load(SearchMode m, {bool force = false}) async {
    final existing = state.data[m];
    if (!force && existing is ViewData<List<SearchItem>>) {
      return; // kept in memory: tab switches never refetch
    }
    _put(m, const ViewLoading());
    switch (m) {
      case SearchMode.categories:
        final r = await _meals.categories();
        _put(
          m,
          r.when(
            ok: (l) => l.isEmpty
                ? const ViewEmpty()
                : ViewData([
                    for (final c in l)
                      SearchItem(name: c.name, imageUrl: c.thumb),
                  ]),
            err: ViewError.new,
          ),
        );
      case SearchMode.countries:
        try {
          final items = await _areas.load();
          _put(m, items.isEmpty ? const ViewEmpty() : ViewData(items));
        } catch (_) {
          _put(
            m,
            const ViewError(ParseFailure('Could not load the countries list.')),
          );
        }
      case SearchMode.ingredients:
        final r = await _meals.ingredients();
        _put(
          m,
          r.when(
            ok: (l) => l.isEmpty
                ? const ViewEmpty()
                : ViewData([
                    for (final i in l)
                      SearchItem(name: i.name, imageUrl: i.imageUrl()),
                  ]),
            err: ViewError.new,
          ),
        );
    }
  }

  Future<void> setMode(SearchMode m) async {
    _timer?.cancel();
    emit(state.copyWith(mode: m));
    await load(m);
  }

  void setQuery(String text) {
    final m = state.mode;
    emit(state.copyWith(queries: {...state.queries, m: text}));
    _timer?.cancel();
    _timer = Timer(debounce, () {
      if (!isClosed) emit(state.copyWith(applied: {...state.applied, m: text}));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
