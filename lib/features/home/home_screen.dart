import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/prefs/preference_manager.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/view_state.dart';
import '../../core/widgets/meal_card.dart';
import '../../core/widgets/states.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import '../profile/user_avatar.dart';
import 'home_cubits.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => CategoriesCubit(ctx.read<MealRepository>())..load(),
        ),
        BlocProvider(
          create: (ctx) => MealOfDayCubit(
            ctx.read<MealRepository>(),
            ctx.read<PreferenceManager>(),
          )..load(),
        ),
        BlocProvider(
          create: (ctx) =>
              BrowseFeedCubit(ctx.read<MealRepository>())..loadMore(),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        context.read<BrowseFeedCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<CategoriesCubit>().load(),
      context.read<MealOfDayCubit>().load(force: true),
      context.read<BrowseFeedCubit>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [
          SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(child: _MealOfTheDay()),
          SliverToBoxAdapter(child: SectionHeader('Categories')),
          SliverToBoxAdapter(child: _CategoryRow()),
          SliverToBoxAdapter(child: SectionHeader('Browse recipes')),
          _BrowseList(),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final name = auth.user?.displayName ?? '';
        final greeting = name.isEmpty
            ? 'Hello, chef!'
            : 'Hello, ${name.split(' ').first}!';
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: theme.textTheme.headlineSmall),
                    Text(
                      'What shall we cook today?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              UserAvatar(radius: 24, onTap: () => context.go(Routes.profile)),
            ],
          ),
        );
      },
    );
  }
}

class _MealOfTheDay extends StatelessWidget {
  const _MealOfTheDay();

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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

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

class _BrowseList extends StatelessWidget {
  const _BrowseList();

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
              return _FadeUp(
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

/// Staggered fade-up used for list items.
class _FadeUp extends StatelessWidget {
  const _FadeUp({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300) + delay,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
