import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/auth/require_auth.dart';
import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../reminders/reminder_sheet.dart';
import 'plan_actions_cubit.dart';

/// Details "Calendar" button: guests get the sign-in gate, signed-in users get
/// a sheet to plan the meal (date picker) or to change / remove the plan.
Future<void> openPlanSheet(
  BuildContext context, {
  required Meal meal,
  PlannedMeal? existing,
}) async {
  final allowed = await requireAuth(
    context,
    reason:
        'Planning meals needs an account. Guests can still browse everything.',
  );
  if (!allowed || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => PlanActionsCubit(
        planner: context.read<PlannerRepository>(),
        reminders: context.read<ReminderService>(),
        auth: context.read<AuthRepository>(),
      ),
      child: _PlanSheet(meal: meal, existing: existing, parentContext: context),
    ),
  );
}

class _PlanSheet extends StatefulWidget {
  const _PlanSheet({
    required this.meal,
    required this.existing,
    required this.parentContext,
  });

  final Meal meal;
  final PlannedMeal? existing;
  final BuildContext parentContext;

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  late DateTime _date = dateOnly(context.read<Clock>().now());
  String? _error;

  Future<void> _add() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final parent = widget.parentContext;
    final r = await context.read<PlanActionsCubit>().add(widget.meal, _date);
    await r.when(
      ok: (plan) async {
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Planned for ${DateFormat('EEE, d MMM').format(plan.day)}',
              ),
              action: SnackBarAction(
                label: 'Set reminder',
                onPressed: () {
                  if (parent.mounted) showReminderSheet(parent, plan);
                },
              ),
            ),
          );
      },
      err: (f) async => setState(() => _error = f.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.existing;
    final busy = context.watch<PlanActionsCubit>().state;
    final now = dateOnly(context.read<Clock>().now());
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            existing == null ? 'Add to calendar' : 'Planned meal',
            style: theme.textTheme.titleLarge,
          ),
          Text(
            widget.meal.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (existing == null) ...[
            CalendarDatePicker(
              initialDate: _date,
              firstDate: now,
              lastDate: DateTime(now.year + 1, now.month, now.day),
              onDateChanged: (d) => setState(() {
                _date = dateOnly(d);
                _error = null;
              }),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: busy ? null : _add,
              icon: const Icon(Icons.event_available),
              label: Text('Plan for ${DateFormat('EEE, d MMM').format(_date)}'),
            ),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(DateFormat('EEEE, d MMMM').format(existing.day)),
              subtitle: Text(
                existing.reminderAt == null
                    ? 'No reminder'
                    : 'Reminder at ${DateFormat.jm().format(existing.reminderAt!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final parent = widget.parentContext;
                Navigator.of(context).pop();
                if (parent.mounted) showReminderSheet(parent, existing);
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Reminder'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                minimumSize: const Size.fromHeight(AppSpacing.minTarget),
              ),
              onPressed: busy
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      await context.read<PlanActionsCubit>().remove(existing);
                      navigator.pop();
                    },
              icon: const Icon(Icons.event_busy),
              label: const Text('Remove from calendar'),
            ),
          ],
        ],
      ),
    );
  }
}
