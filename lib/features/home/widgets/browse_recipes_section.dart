import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_up.dart';
import '../../../core/widgets/meal_card.dart';
import '../../../core/widgets/states.dart';
import '../home_cubits.dart';

/// Paginated infinite-scroll list of recipes.
class BrowseRecipesSection extends StatelessWidget {
  const BrowseRecipesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseFeedCubit, BrowseFeedState>(
      builder: (context, state) {
        if (state.loading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Skeleton(height: 84, radius: AppRadius.md),
                  SizedBox(height: AppSpacing.md),
                  Skeleton(height: 84, radius: AppRadius.md),
                  SizedBox(height: AppSpacing.md),
                  Skeleton(height: 84, radius: AppRadius.md),
                ],
              ),
            ),
          );
        }
        if (state.meals.isEmpty && state.failure != null) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: BlocBuilder<ConnectivityCubit, ConnectionStatus>(
                builder: (context, conn) => ErrorState(
                  message: conn == ConnectionStatus.offline
                      ? 'You are offline. Your favorites are still available.'
                      : state.failure!.message,
                  onRetry: () => context.read<BrowseFeedCubit>().refresh(),
                  secondaryLabel: 'Open favorites',
                  onSecondary: () => context.go(Routes.favorites),
                ),
              ),
            ),
          );
        }
        if (state.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: EmptyState(
                title: 'No recipes found',
                message: 'Pull down to refresh.',
              ),
            ),
          );
        }
        final extra =
            state.loadingMore || state.failure != null || !state.hasMore
            ? 1
            : 0;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.separated(
            itemCount: state.meals.length + extra,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              if (i >= state.meals.length) {
                if (state.failure != null) {
                  return TextButton.icon(
                    onPressed: () => context.read<BrowseFeedCubit>().loadMore(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Could not load more. Retry'),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: state.hasMore
                        ? const CircularProgressIndicator()
                        : Text(
                            "You've reached the end",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                  ),
                );
              }
              final meal = state.meals[i];
              return FadeUp(
                delay: Duration(milliseconds: 60 * (i % 6)),
                child: MealCard(
                  meal: meal.toSummary(),
                  fullMeal: meal,
                  subtitle: [
                    meal.category,
                    meal.area,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  onTap: () => context.push(Routes.mealPath(meal.id)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
