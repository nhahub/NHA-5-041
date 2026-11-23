import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/view_state.dart';
import '../../core/widgets/fade_up.dart';
import '../../core/widgets/meal_card.dart';
import '../../core/widgets/states.dart';
import '../../domain/repositories/repositories.dart';
import 'meal_list_cubit.dart';

/// Route `/meals?type=category|area|ingredient&value=...`
class MealListScreen extends StatelessWidget {
  const MealListScreen({super.key, required this.type, required this.value});

  final MealListType type;
  final String value;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) =>
        MealListCubit(ctx.read<MealRepository>(), type: type, value: value)
          ..load(),
    child: _MealListView(type: type, value: value),
  );
}

class _MealListView extends StatelessWidget {
  const _MealListView({required this.type, required this.value});

  final MealListType type;
  final String value;

  String get _title => switch (type) {
    MealListType.category => value,
    MealListType.area => '$value cuisine',
    MealListType.ingredient => 'With $value',
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MealListCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AppSearchField(
              hint: 'Search these meals',
              onChanged: cubit.setQuery,
            ),
          ),
          Expanded(
            child: BlocBuilder<MealListCubit, MealListState>(
              builder: (context, state) => switch (state.view) {
                ViewLoading() => const MealListSkeleton(),
                ViewEmpty() => EmptyState(
                  title: 'No meals found',
                  message: 'There are no meals for "$value" yet.',
                ),
                ViewError(:final failure) =>
                  BlocBuilder<ConnectivityCubit, ConnectionStatus>(
                    builder: (context, conn) => ErrorState(
                      message: conn == ConnectionStatus.offline
                          ? 'You are offline. Check your connection and retry.'
                          : failure.message,
                      onRetry: cubit.load,
                    ),
                  ),
                ViewData() => () {
                  final meals = state.visible;
                  if (meals.isEmpty) {
                    return EmptyState(
                      title: 'No results',
                      message: 'Nothing matches "${state.applied.trim()}".',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: meals.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) => FadeUp(
                      delay: Duration(milliseconds: 40 * (i % 6)),
                      child: MealCard(
                        meal: meals[i],
                        onTap: () => context.push(Routes.mealPath(meals[i].id)),
                      ),
                    ),
                  );
                }(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
