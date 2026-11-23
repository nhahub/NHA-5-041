import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reminders/notification_helper.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

/// Notification permission (Android 13+ POST_NOTIFICATIONS).
abstract class NotificationPermission {
  Future<bool> isGranted();
  Future<bool> request();
}

class PluginNotificationPermission implements NotificationPermission {
  PluginNotificationPermission(this._helper);

  final NotificationHelper _helper;

  @override
  Future<bool> isGranted() => _helper.areEnabled();

  @override
  Future<bool> request() => _helper.requestPermission();
}

class AlwaysGrantedPermission implements NotificationPermission {
  @override
  Future<bool> isGranted() async => true;

  @override
  Future<bool> request() async => true;
}

/// Combines a plan's day with a time of day.
DateTime reminderDateTime(DateTime day, int hour, int minute) =>
    DateTime(day.year, day.month, day.day, hour, minute);

/// ViewModel behind the reminder sheet. State = busy flag.
class ReminderCubit extends Cubit<bool> {
  ReminderCubit({
    required ReminderService reminders,
    required PlannerRepository planner,
  }) : _reminders = reminders,
       _planner = planner,
       super(false);

  final ReminderService _reminders;
  final PlannerRepository _planner;

  /// Schedules (or reschedules) the reminder. Past times are rejected.
  Future<Result<void>> set(PlannedMeal plan, DateTime at) async {
    emit(true);
    try {
      final r = await _reminders.schedule(
        plannedId: plan.id,
        mealId: plan.meal.id,
        mealName: plan.meal.name,
        at: at,
      );
      if (r.isOk) await _planner.setReminder(plan.id, at);
      return r;
    } finally {
      if (!isClosed) emit(false);
    }
  }

  Future<void> clear(PlannedMeal plan) async {
    emit(true);
    try {
      await _reminders.cancel(plan.id);
      await _planner.setReminder(plan.id, null);
    } finally {
      if (!isClosed) emit(false);
    }
  }
}
