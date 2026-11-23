import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/view_state.dart';
import '../../core/widgets/fade_up.dart';
import '../../core/widgets/meal_card.dart';
import '../../core/widgets/states.dart';
import '../../domain/models/meal.dart';
import '../../domain/repositories/repositories.dart';
import '../sync/sync_cubit.dart';
import 'favorite_toggle_button.dart';
import 'favorites_cubit.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        if (state.guest) {
          return EmptyState(
            icon: Icons.favorite_border,
            title: 'Sign in to save favorites',
            message: 'Guests can browse every recipe, but favorites need an account.',
            actionLabel: 'Sign in',
            onAction: () => context.push(Routes.login),
          );
        }
        return BlocBuilder<SyncCubit, SyncUiState>(
          buildWhen: (a, b) => a.phase != b.phase,
          builder: (context, sync) => switch (state.view) {
            ViewLoading() => const MealListSkeleton(),
            ViewError(:final failure) => ErrorState(
              message: failure.message,
              onRetry: () {},
            ),
            ViewEmpty() =>
              sync.phase == SyncPhase.restoring
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: AppSpacing.lg),
                          Text('Restoring your favorites…'),
                        ],
                      ),
                    )
                  : EmptyState(
                      icon: Icons.favorite_border,
                      title: 'No favorites yet',
                      message: 'Tap the heart on any recipe to save it here.',
                      actionLabel: 'Browse recipes',
                      onAction: () => context.go(Routes.home),
                    ),
            ViewData(:final data) => _FavoritesList(meals: data),
          },
        );
      },
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({required this.meals});

  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FavoritesCubit>();
    return ListView.separated(
      key: const PageStorageKey('favorites-list'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: meals.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final meal = meals[i];
        return Dismissible(
          key: ValueKey('fav-${meal.id}'),
          direction: DismissDirection.endToStart,
          // Swipe uses the same Yes / No dialog as the heart button.
          confirmDismiss: (_) async {
            final yes = await confirmRemoveFavorite(
              context,
              mealName: meal.name,
            );
            if (yes) await cubit.remove(meal.id);
            return false; // the list rebuilds from the stream
          },
          background: Container(
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: AppRadius.card,
            ),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          child: FadeUp(
            delay: Duration(milliseconds: 40 * (i % 6)),
            child: MealCard(
              meal: meal.toSummary(),
              fullMeal: meal,
              subtitle: [
                meal.category,
                meal.area,
              ].where((s) => s.isNotEmpty).join(' · '),
              onTap: () => context.push(Routes.mealPath(meal.id)),
            ),
          ),
        );
      },
    );
  }
}
