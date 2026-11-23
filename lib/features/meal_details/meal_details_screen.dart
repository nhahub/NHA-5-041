import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/view_state.dart';
import '../../core/widgets/states.dart';
import '../../domain/models/meal.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import '../favorites/favorite_toggle_button.dart';
import '../planner/plan_sheet.dart';
import '../search/search_cubit.dart';
import 'instruction_parser.dart';
import 'meal_details_cubit.dart';

/// Builds the embedded video; replaced in widget tests (no WebView there).
typedef VideoBuilder = Widget Function(BuildContext context, String videoId);

/// Route `/meal/:id`. The image uses hero tag `meal-hero-<id>`.
class MealDetailsScreen extends StatelessWidget {
  const MealDetailsScreen({super.key, required this.mealId, this.videoBuilder});

  final String mealId;
  final VideoBuilder? videoBuilder;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => MealDetailsCubit(
      mealId: mealId,
      meals: ctx.read<MealRepository>(),
      favorites: ctx.read<FavoritesRepository>(),
      planner: ctx.read<PlannerRepository>(),
      auth: ctx.read<AuthRepository>(),
    )..load(),
    child: _DetailsView(mealId: mealId, videoBuilder: videoBuilder),
  );
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.mealId, this.videoBuilder});

  final String mealId;
  final VideoBuilder? videoBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealDetailsCubit, MealDetailsState>(
      builder: (context, state) => switch (state.view) {
        ViewLoading() => Scaffold(
          appBar: AppBar(),
          body: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Hero(
                tag: Routes.heroTag(mealId),
                child: const Skeleton(height: 260),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 220, height: 28, radius: AppRadius.sm),
                    SizedBox(height: AppSpacing.md),
                    Skeleton(width: 160, height: 20, radius: AppRadius.sm),
                    SizedBox(height: AppSpacing.xl),
                    Skeleton(height: 56, radius: AppRadius.sm),
                    SizedBox(height: AppSpacing.md),
                    Skeleton(height: 56, radius: AppRadius.sm),
                    SizedBox(height: AppSpacing.md),
                    Skeleton(height: 56, radius: AppRadius.sm),
                  ],
                ),
              ),
            ],
          ),
        ),
        ViewError(:final failure) => Scaffold(
          appBar: AppBar(),
          body: ErrorState(
            message: failure is EmptyFailure
                ? 'This meal could not be found.'
                : failure.message,
            onRetry: context.read<MealDetailsCubit>().load,
          ),
        ),
        ViewEmpty() => Scaffold(
          appBar: AppBar(),
          body: const EmptyState(title: 'Meal not found'),
        ),
        ViewData(:final data) => _DetailsBody(
          meal: data,
          state: state,
          videoBuilder: videoBuilder,
        ),
      },
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.meal,
    required this.state,
    this.videoBuilder,
  });

  final Meal meal;
  final MealDetailsState state;
  final VideoBuilder? videoBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = state.plan;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 300,
            backgroundColor: theme.colorScheme.surface,
            iconTheme: const IconThemeData(color: AppColors.onScrim),
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.scrim.withValues(alpha: 0.35),
                  foregroundColor: AppColors.onScrim,
                ),
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(Routes.home),
              ),
            ),
            actions: [
              FavoriteToggleButton(
                mealId: meal.id,
                meal: meal,
                mealName: meal.name,
                onDark: true,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: Routes.heroTag(meal.id),
                    child: AppNetworkImage(
                      AppNetworkImage.sized(meal.thumb, 'large'),
                      cacheWidth: 1000,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.scrim.withValues(alpha: 0.35),
                          AppColors.scrim.withValues(alpha: 0),
                          AppColors.scrim.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.fromCache)
            SliverToBoxAdapter(
              child: Container(
                color: theme.colorScheme.tertiaryContainer,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.offline_pin,
                      size: 18,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Offline: showing your saved copy of this meal.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                Semantics(
                  header: true,
                  child: Text(meal.name, style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (meal.category.isNotEmpty)
                      ActionChip(
                        avatar: const Icon(Icons.category_outlined, size: 18),
                        label: Text(meal.category),
                        onPressed: () => context.push(
                          Routes.mealsPath('category', meal.category),
                        ),
                      ),
                    if (meal.area.isNotEmpty) _AreaChip(area: meal.area),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      openPlanSheet(context, meal: meal, existing: plan),
                  icon: Icon(
                    plan == null
                        ? Icons.calendar_month_outlined
                        : Icons.event_available,
                  ),
                  label: Text(
                    plan == null
                        ? 'Add to calendar'
                        : 'Planned: ${DateFormat('EEE, d MMM').format(plan.day)}',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text('Ingredients', style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: AppSpacing.sm),
                _Ingredients(ingredients: meal.ingredients),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text(
                    'Instructions',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                InstructionsSection(
                  steps: InstructionParser.parse(meal.instructions),
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text('Video', style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: AppSpacing.sm),
                VideoSection(url: meal.youtube, builder: videoBuilder),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.area});

  final String area;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SearchItem>>(
      future: AssetAreaCatalog().load().catchError((_) => <SearchItem>[]),
      builder: (context, snap) {
        final flag = (snap.data ?? const <SearchItem>[])
            .where((i) => i.name == area)
            .map((i) => i.flag)
            .firstOrNull;
        return ActionChip(
          avatar: flag != null
              ? Text(flag)
              : const Icon(Icons.public, size: 18),
          label: Text(area),
          onPressed: () => context.push(Routes.mealsPath('area', area)),
        );
      },
    );
  }
}

class _Ingredients extends StatefulWidget {
  const _Ingredients({required this.ingredients});

  final List<Ingredient> ingredients;
  static const collapsedCount = 4;

  @override
  State<_Ingredients> createState() => _IngredientsState();
}

class _IngredientsState extends State<_Ingredients> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ingredients = widget.ingredients;
    if (ingredients.isEmpty) {
      return const Text('No ingredients listed.');
    }
    final collapsible = ingredients.length > _Ingredients.collapsedCount;
    final shown = _expanded || !collapsible
        ? ingredients
        : ingredients.take(_Ingredients.collapsedCount).toList();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: AppNetworkImage(
                    i.imageUrl(),
                    fit: BoxFit.contain,
                    cacheWidth: 144,
                    fallbackIcon: Icons.eco_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(i.name, style: theme.textTheme.bodyLarge)),
                if (i.measure.isNotEmpty)
                  Flexible(
                    child: Text(
                      i.measure,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (collapsible)
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.minTarget),
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _expanded
                  ? 'See less'
                  : 'See more (${ingredients.length})',
            ),
          ),
      ],
    );
  }
}

/// Numbered steps, collapsed to the first four with "See more" / "See less".
class InstructionsSection extends StatefulWidget {
  const InstructionsSection({
    super.key,
    required this.steps,
    this.collapsedCount = 4,
  });

  final List<String> steps;
  final int collapsedCount;

  @override
  State<InstructionsSection> createState() => _InstructionsSectionState();
}

class _InstructionsSectionState extends State<InstructionsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.steps;
    if (steps.isEmpty) return const Text('No instructions available.');
    final collapsible = steps.length > widget.collapsedCount;
    final shown = _expanded || !collapsible
        ? steps
        : steps.take(widget.collapsedCount).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(shown[i], style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        if (collapsible)
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.minTarget),
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _expanded
                  ? 'See less'
                  : 'See more (${steps.length})',
            ),
          ),
      ],
    );
  }
}

/// Embedded YouTube player (never an external link).
class VideoSection extends StatefulWidget {
  const VideoSection({super.key, required this.url, this.builder});

  final String url;
  final VideoBuilder? builder;

  @override
  State<VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<VideoSection>
    with WidgetsBindingObserver {
  YoutubePlayerController? _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = widget.url.isEmpty
        ? null
        : YoutubePlayerController.convertUrlToId(widget.url);
    if (_videoId != null && widget.builder == null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: _videoId!,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pauseVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the screen stops playback.
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = _videoId;
    if (id == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.videocam_off_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('No video is available for this recipe.'),
            ),
          ],
        ),
      );
    }
    final builder = widget.builder;
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: builder != null
          ? builder(context, id)
          : YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
    );
  }
}
