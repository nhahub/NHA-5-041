import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/clock.dart';
import '../../core/prefs/preference_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import 'reminder_cubit.dart';

const _explainedKey = 'reminder_permission_explained';

/// Asks for the notification permission at the moment of the first reminder,
/// with a short explanation. Returns true when reminders can be delivered.
Future<bool> ensureNotificationPermission(BuildContext context) async {
  final permission = context.read<NotificationPermission>();
  final prefManager = context.read<PreferenceManager>();
  final messenger = ScaffoldMessenger.of(context);
  if (await permission.isGranted()) return true;
  if (!context.mounted) return false;

  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: const Text('Allow notifications?'),
      content: const Text(
        'Food Planner needs permission to remind you on the day you planned to cook.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (proceed != true) return false;
  await prefManager.setBool(_explainedKey, true);
  final granted = await permission.request();
  if (!granted) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications are blocked. Turn them on in system settings > Apps > Food Planner.',
        ),
        duration: Duration(seconds: 6),
      ),
    );
  }
  return granted;
}

/// Pick a time for a planned meal; toggle on/off, change or delete it.
Future<void> showReminderSheet(BuildContext context, PlannedMeal plan) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => ReminderCubit(
        reminders: context.read<ReminderService>(),
        planner: context.read<PlannerRepository>(),
      ),
      child: _ReminderSheet(plan: plan, parentContext: context),
    ),
  );
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.plan, required this.parentContext});

  final PlannedMeal plan;
  final BuildContext parentContext;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late bool _enabled;
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.plan.reminderAt;
    _enabled = existing != null;
    _time = existing != null
        ? TimeOfDay.fromDateTime(existing)
        : const TimeOfDay(hour: 17, minute: 0);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final cubit = context.read<ReminderCubit>();
    final navigator = Navigator.of(context);
    final clock = context.read<Clock>();
    if (!_enabled) {
      await cubit.clear(widget.plan);
      if (mounted) navigator.pop();
      return;
    }
    if (!await ensureNotificationPermission(widget.parentContext)) return;
    final at = reminderDateTime(widget.plan.day, _time.hour, _time.minute);
    if (!at.isAfter(clock.now())) {
      setState(() => _error = 'Pick a time in the future.');
      return;
    }
    final r = await cubit.set(widget.plan, at);
    r.when(
      ok: (_) {
        if (mounted) navigator.pop();
      },
      err: (f) => setState(() => _error = f.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final past = widget.plan.day.isBefore(
      dateOnly(context.read<Clock>().now()),
    );
    final busy = context.watch<ReminderCubit>().state;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reminder', style: theme.textTheme.titleLarge),
          Text(
            '${widget.plan.meal.name} · ${DateFormat('EEEE, d MMM').format(widget.plan.day)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (past)
            const Text('Reminders cannot be set for past days.')
          else ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me'),
              value: _enabled,
              onChanged: busy ? null : (v) => setState(() => _enabled = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: _enabled && !busy,
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              trailing: Text(
                _time.format(context),
                style: theme.textTheme.titleMedium,
              ),
              onTap: _enabled ? _pickTime : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(_enabled ? 'Save reminder' : 'Turn off reminder'),
            ),
          ],
        ],
      ),
    );
  }
}
