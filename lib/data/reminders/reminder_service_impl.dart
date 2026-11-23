import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/clock.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import 'notification_helper.dart';

const mealReminderTask = 'mealReminder';

/// Entry point run by WorkManager in a background isolate.
@pragma('vm:entry-point')
void reminderCallbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    if (task != mealReminderTask || input == null) return true;
    final helper = NotificationHelper();
    await helper.init();
    final at = DateTime.tryParse('${input['at']}');
    final body = at == null
        ? 'Your planned meal is waiting.'
        : 'Planned for ${DateFormat('EEEE, d MMM').format(at)}.';
    await helper.showMealReminder(
      id: (input['plannedId'] as num).toInt(),
      mealId: '${input['mealId']}',
      mealName: '${input['mealName']}',
      body: body,
    );
    return true;
  });
}

/// Schedules reminders with WorkManager (deferrable, not exact: delivery may
/// be delayed by Doze or battery optimisers - documented in docs/REMINDERS.md).
class ReminderServiceImpl implements ReminderService {
  ReminderServiceImpl({Clock clock = const Clock()}) : _clock = clock;

  final Clock _clock;

  static String uniqueName(int plannedId) => 'reminder-$plannedId';

  /// Delay until [at]; `null` when [at] is not in the future.
  static Duration? delayUntil(DateTime at, DateTime now) {
    final d = at.difference(now);
    return d.isNegative || d == Duration.zero ? null : d;
  }

  @override
  Future<Result<void>> schedule({
    required int plannedId,
    required String mealId,
    required String mealName,
    required DateTime at,
  }) async {
    final delay = delayUntil(at, _clock.now());
    if (delay == null) {
      return const Result.err(ValidationFailure('Pick a time in the future.'));
    }
    await Workmanager().registerOneOffTask(
      uniqueName(plannedId),
      mealReminderTask,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      inputData: {
        'plannedId': plannedId,
        'mealId': mealId,
        'mealName': mealName,
        'at': at.toIso8601String(),
      },
    );
    return const Result.ok(null);
  }

  @override
  Future<void> cancel(int plannedId) =>
      Workmanager().cancelByUniqueName(uniqueName(plannedId));
}
