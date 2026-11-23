import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/view_state.dart';
import '../../../core/widgets/states.dart';
import '../../../domain/models/meal.dart';
import '../home_cubits.dart';

/// Horizontal scrolling row for meal categories.
class CategoryRowSection extends StatelessWidget {
  const CategoryRowSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: BlocBuilder<CategoriesCubit, ViewState<List<MealCategory>>>(
        builder: (context, state) => switch (state) {
          ViewLoading() => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, _) =>
                const Skeleton(width: 72, height: 72, radius: AppRadius.pill),
          ),
          ViewData(:final data) => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: data.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => CategoryTile(
              name: data[i].name,
              imageUrl: data[i].thumb,
              onTap: () =>
                  context.push(Routes.mealsPath('category', data[i].name)),
            ),
          ),
          ViewEmpty() => const Center(child: Text('No categories yet')),
          ViewError(:final failure) => InlineError(
            message: failure.message,
            onRetry: () => context.read<CategoriesCubit>().load(),
          ),
        },
      ),
    );
  }
}
