import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/view_state.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

class MealDetailsState extends Equatable {
  const MealDetailsState({
    this.view = const ViewLoading(),
    this.fromCache = false,
    this.plan,
  });

  final ViewState<Meal> view;

  /// The meal came from the stored favorite because the network failed.
  final bool fromCache;

  /// The signed-in user's plan for this meal, if any.
  final PlannedMeal? plan;

  MealDetailsState copyWith({
    ViewState<Meal>? view,
    bool? fromCache,
    PlannedMeal? plan,
    bool clearPlan = false,
  }) => MealDetailsState(
    view: view ?? this.view,
    fromCache: fromCache ?? this.fromCache,
    plan: clearPlan ? null : (plan ?? this.plan),
  );

  @override
  List<Object?> get props => [view, fromCache, plan];
}

/// One cubit per meal id (created with BlocProvider on the Details route).
class MealDetailsCubit extends Cubit<MealDetailsState> {
  MealDetailsCubit({
    required this.mealId,
    required MealRepository meals,
    required FavoritesRepository favorites,
    required PlannerRepository planner,
    required AuthRepository auth,
  }) : _meals = meals,
       _favorites = favorites,
       _planner = planner,
       _auth = auth,
       super(const MealDetailsState());

  final String mealId;
  final MealRepository _meals;
  final FavoritesRepository _favorites;
  final PlannerRepository _planner;
  final AuthRepository _auth;
  StreamSubscription<PlannedMeal?>? _planSub;

  Future<void> load() async {
    emit(state.copyWith(view: const ViewLoading()));
    _watchPlan();
    final r = await _meals.lookup(mealId);
    if (isClosed) return;
    switch (r) {
      case Ok<Meal>(:final value):
        emit(state.copyWith(view: ViewData(value), fromCache: false));
      case Err<Meal>(:final failure):
        // Offline: a favorited meal is shown from its stored copy.
        final uid = _auth.currentState.uid;
        Meal? stored;
        if (uid != null) {
          for (final m in await _favorites.getAll(uid)) {
            if (m.id == mealId) stored = m;
          }
        }
        if (isClosed) return;
        emit(
          stored != null
              ? state.copyWith(view: ViewData(stored), fromCache: true)
              : state.copyWith(view: ViewError(failure)),
        );
    }
  }

  void _watchPlan() {
    _planSub?.cancel();
    final uid = _auth.currentState.uid;
    if (uid == null) return;
    _planSub = _planner.watchPlanFor(uid, mealId).listen((p) {
      if (!isClosed) emit(state.copyWith(plan: p, clearPlan: p == null));
    });
  }

  @override
  Future<void> close() {
    _planSub?.cancel();
    return super.close();
  }
}
