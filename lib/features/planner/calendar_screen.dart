import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/clock.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/states.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../reminders/reminder_sheet.dart';
import 'plan_actions_cubit.dart';
import 'planner_cubit.dart';

/// Calendar tab and Profile's "Planned Meals" open this same screen.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (ctx) => PlannerCubit(
          ctx.read<PlannerRepository>(),
          ctx.read<AuthRepository>(),
          clock: ctx.read<Clock>(),
        ),
      ),
      BlocProvider(
        create: (ctx) => PlanActionsCubit(
          planner: ctx.read<PlannerRepository>(),
          reminders: ctx.read<ReminderService>(),
          auth: ctx.read<AuthRepository>(),
        ),
      ),
    ],
    child: const _CalendarView(),
  );
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clock = context.read<Clock>();
    return BlocBuilder<PlannerCubit, PlannerState>(
      builder: (context, state) {
        if (state.guest) {
          return EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'Sign in to plan your week',
            message: 'Guests can browse everything, but planning meals needs an account.',
            actionLabel: 'Sign in',
            onAction: () => context.push(Routes.login),
          );
        }
        final cubit = context.read<PlannerCubit>();
        final rangeLabel =
            '${DateFormat('d MMM').format(state.weekStart)} – ${DateFormat('d MMM').format(state.weekEnd)}';
        final today = dateOnly(clock.now());
        final selectedPlans = state.selectedPlans;
        return Column(
          children: [
            TableCalendar<PlannedMeal>(
              firstDay: DateTime(today.year - 1, 1, 1),
              lastDay: DateTime(today.year + 2, 12, 31),
              focusedDay: state.focused,
              currentDay: today,
              calendarFormat: CalendarFormat.week,
              availableCalendarFormats: const {CalendarFormat.week: 'Week'},
              startingDayOfWeek: StartingDayOfWeek.saturday,
              selectedDayPredicate: (d) => isSameDay(d, state.selected),
              eventLoader: state.plansOn,
              onDaySelected: (selected, focused) => cubit.selectDay(selected),
              onPageChanged: cubit.focusWeek,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (_, _) => rangeLabel,
                titleTextStyle: theme.textTheme.titleMedium!,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return PositionedDirectional(
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${events.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
                // Past days are dimmed.
                defaultBuilder: (context, day, focused) =>
                    dateOnly(day).isBefore(today)
                    ? Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: theme.colorScheme.onPrimary,
                ),
                markersMaxCount: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMMM').format(state.selected),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: cubit.goToToday,
                    child: const Text('Today'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.loading
                  ? const MealListSkeleton(count: 3)
                  : state.plans.isEmpty
                  ? EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'Nothing planned this week',
                      message: 'Pick a recipe and add it to your calendar.',
                      actionLabel: 'Browse recipes',
                      onAction: () => context.go(Routes.home),
                    )
                  : selectedPlans.isEmpty
                  ? const EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'No meals on this day',
                      message: 'Pick another day or plan something new.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: selectedPlans.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) => _PlanTile(
                        plan: selectedPlans[i],
                        past: state.selected.isBefore(today),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.past});

  final PlannedMeal plan;
  final bool past;

  Future<void> _remove(BuildContext context) async {
    final actions = context.read<PlanActionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from plan?'),
        content: Text(
          '"${plan.meal.name}" will be removed from ${DateFormat('EEE, d MMM').format(plan.day)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await actions.remove(plan);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Removed from plan'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => actions.add(plan.meal, plan.day),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminder = plan.reminderAt;
    return Opacity(
      opacity: past ? 0.6 : 1,
      child: Dismissible(
        key: ValueKey('plan-${plan.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          await _remove(context);
          return false;
        },
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: AppRadius.card,
          ),
          child: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
        child: Card(
          child: InkWell(
            onTap: () => context.push(Routes.mealPath(plan.meal.id)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: AppNetworkImage(
                        AppNetworkImage.sized(plan.meal.thumb, 'small'),
                        cacheWidth: 192,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.meal.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          reminder == null
                              ? 'No reminder'
                              : 'Reminder at ${DateFormat.jm().format(reminder)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reminder',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTarget,
                      minHeight: AppSpacing.minTarget,
                    ),
                    onPressed: past
                        ? null
                        : () => showReminderSheet(context, plan),
                    icon: Icon(
                      reminder == null
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove from plan',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTarget,
                      minHeight: AppSpacing.minTarget,
                    ),
                    onPressed: () => _remove(context),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
