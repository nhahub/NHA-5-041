import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/clock.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';

/// First day of the week containing [d]. The week starts on Saturday (D6).
DateTime weekStartOf(DateTime d) {
  final day = dateOnly(d);
  final offset = (day.weekday + 1) % 7; // Sat=0, Sun=1 ... Fri=6
  return DateTime(day.year, day.month, day.day - offset);
}

DateTime weekEndOf(DateTime d) {
  final s = weekStartOf(d);
  return DateTime(s.year, s.month, s.day + 6);
}

class PlannerState extends Equatable {
  const PlannerState({
    required this.focused,
    required this.selected,
    this.plans = const [],
    this.guest = false,
    this.loading = true,
  });

  final DateTime focused;
  final DateTime selected;

  /// Plans of the focused week, ordered by day.
  final List<PlannedMeal> plans;
  final bool guest;
  final bool loading;

  DateTime get weekStart => weekStartOf(focused);
  DateTime get weekEnd => weekEndOf(focused);

  List<PlannedMeal> plansOn(DateTime day) =>
      plans.where((p) => p.day == dateOnly(day)).toList();

  List<PlannedMeal> get selectedPlans => plansOn(selected);

  PlannerState copyWith({
    DateTime? focused,
    DateTime? selected,
    List<PlannedMeal>? plans,
    bool? guest,
    bool? loading,
  }) => PlannerState(
    focused: focused ?? this.focused,
    selected: selected ?? this.selected,
    plans: plans ?? this.plans,
    guest: guest ?? this.guest,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [focused, selected, plans, guest, loading];
}

/// Weekly calendar of planned meals.
class PlannerCubit extends Cubit<PlannerState> {
  PlannerCubit(this._planner, this._auth, {Clock clock = const Clock()})
    : _clock = clock,
      super(
        PlannerState(
          focused: dateOnly(clock.now()),
          selected: dateOnly(clock.now()),
        ),
      ) {
    _authSub = _auth.authStateChanges.listen((_) => _subscribe());
  }

  final PlannerRepository _planner;
  final AuthRepository _auth;
  final Clock _clock;
  late final StreamSubscription<AuthState> _authSub;
  StreamSubscription<List<PlannedMeal>>? _sub;

  DateTime get today => dateOnly(_clock.now());

  void _subscribe() {
    _sub?.cancel();
    final auth = _auth.currentState;
    final uid = auth.uid;
    if (uid == null) {
      emit(state.copyWith(plans: const [], guest: true, loading: false));
      return;
    }
    emit(state.copyWith(guest: false, loading: true));
    _sub = _planner
        .watchRange(uid, state.weekStart, state.weekEnd)
        .listen((plans) => emit(state.copyWith(plans: plans, loading: false)));
  }

  void selectDay(DateTime day) {
    final d = dateOnly(day);
    final sameWeek = weekStartOf(d) == state.weekStart;
    emit(state.copyWith(selected: d, focused: d));
    if (!sameWeek) _subscribe();
  }

  void focusWeek(DateTime focused) {
    final f = dateOnly(focused);
    if (weekStartOf(f) == state.weekStart) return;
    // Keep the same weekday selected in the new week.
    final delta = f.difference(state.focused).inDays;
    emit(
      state.copyWith(
        focused: f,
        selected: DateTime(
          state.selected.year,
          state.selected.month,
          state.selected.day + delta,
        ),
      ),
    );
    _subscribe();
  }

  void goToToday() => selectDay(today);

  @override
  Future<void> close() {
    _authSub.cancel();
    _sub?.cancel();
    return super.close();
  }
}
