import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/view_state.dart';
import '../../../core/widgets/meal_card.dart';
import '../../../core/widgets/states.dart';
import '../../../domain/models/meal.dart';
import '../../../domain/result.dart';
import '../home_cubits.dart';

/// Featured meal of the day card.
class MealOfTheDaySection extends StatelessWidget {
  const MealOfTheDaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: BlocBuilder<MealOfDayCubit, ViewState<Meal>>(
        builder: (context, state) => switch (state) {
          ViewLoading() => const AspectRatio(
            aspectRatio: 16 / 10,
            child: Skeleton(radius: AppRadius.md),
          ),
          ViewData(:final data) => MealCard.hero(
            meal: data.toSummary(),
            fullMeal: data,
            subtitle: data.area.isEmpty
                ? 'Meal of the day'
                : 'Meal of the day · ${data.area}',
            onTap: () => context.push(Routes.mealPath(data.id)),
          ),
          ViewEmpty() => const SizedBox.shrink(),
          ViewError(:final failure) => SizedBox(
            height: 220,
            child: ErrorState(
              message: failure.message,
              onRetry: () => context.read<MealOfDayCubit>().load(),
              secondaryLabel: failure is NetworkFailure
                  ? 'Open favorites'
                  : null,
              onSecondary: () => context.go(Routes.favorites),
            ),
          ),
        },
      ),
    );
  }
}
