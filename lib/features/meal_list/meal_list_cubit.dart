import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/view_state.dart';
import '../../domain/models/meal.dart';
import '../../domain/repositories/repositories.dart';

enum MealListType {
  category,
  area,
  ingredient;

  static MealListType? parse(String? value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return null;
  }
}

class MealListState extends Equatable {
  const MealListState({
    this.view = const ViewLoading(),
    this.query = '',
    this.applied = '',
  });

  final ViewState<List<MealSummary>> view;
  final String query;
  final String applied;

  /// Meals on screen after local filtering.
  List<MealSummary> get visible {
    final v = view;
    if (v is! ViewData<List<MealSummary>>) return const [];
    final q = applied.trim().toLowerCase();
    if (q.isEmpty) return v.data;
    return v.data.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  MealListState copyWith({
    ViewState<List<MealSummary>>? view,
    String? query,
    String? applied,
  }) => MealListState(
    view: view ?? this.view,
    query: query ?? this.query,
    applied: applied ?? this.applied,
  );

  @override
  List<Object?> get props => [view, query, applied];
}

/// One cubit for category, country and ingredient lists. Search on this screen
/// filters only the meals already shown (no network call per keystroke).
class MealListCubit extends Cubit<MealListState> {
  MealListCubit(
    this._meals, {
    required this.type,
    required this.value,
    this.debounce = const Duration(milliseconds: 250),
  }) : super(const MealListState());

  final MealRepository _meals;
  final MealListType type;
  final String value;
  final Duration debounce;
  Timer? _timer;

  Future<void> load() async {
    emit(state.copyWith(view: const ViewLoading()));
    final r = switch (type) {
      MealListType.category => await _meals.byCategory(value),
      MealListType.area => await _meals.byArea(value),
      MealListType.ingredient => await _meals.byIngredient(value),
    };
    if (isClosed) return;
    emit(
      state.copyWith(
        view: r.when(
          ok: (l) => l.isEmpty ? const ViewEmpty() : ViewData(l),
          err: ViewError.new,
        ),
      ),
    );
  }

  void setQuery(String text) {
    emit(state.copyWith(query: text));
    _timer?.cancel();
    _timer = Timer(debounce, () {
      if (!isClosed) emit(state.copyWith(applied: text));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
