import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

/// Add / remove plans. Removing also cancels the reminder. State = busy flag.
class PlanActionsCubit extends Cubit<bool> {
  PlanActionsCubit({
    required PlannerRepository planner,
    required ReminderService reminders,
    required AuthRepository auth,
  }) : _planner = planner,
       _reminders = reminders,
       _auth = auth,
       super(false);

  final PlannerRepository _planner;
  final ReminderService _reminders;
  final AuthRepository _auth;

  Future<Result<PlannedMeal>> add(Meal meal, DateTime date) async {
    final uid = _auth.currentState.uid;
    if (uid == null) return const Result.err(GuestFailure());
    emit(true);
    try {
      return await _planner.add(uid, meal, date);
    } finally {
      if (!isClosed) emit(false);
    }
  }

  Future<void> remove(PlannedMeal plan) async {
    emit(true);
    try {
      await _reminders.cancel(plan.id);
      await _planner.remove(plan.id);
    } finally {
      if (!isClosed) emit(false);
    }
  }
}
