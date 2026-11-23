import 'package:flutter/material.dart';

import '../../domain/models/meal.dart';
import '../../features/favorites/favorite_toggle_button.dart';
import '../router/routes.dart';
import '../theme/app_theme.dart';
import 'states.dart';

enum MealCardVariant { hero, row, tile }

/// One meal card in three variants: hero (Meal of the Day), list row and grid
/// tile. The image carries the shared hero tag `meal-hero-<id>`.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    this.variant = MealCardVariant.row,
    this.fullMeal,
    this.subtitle,
    this.heroEnabled = true,
  });

  const MealCard.hero({
    Key? key,
    required MealSummary meal,
    required VoidCallback onTap,
    Meal? fullMeal,
    String? subtitle,
    bool heroEnabled = true,
  }) : this(
         key: key,
         meal: meal,
         onTap: onTap,
         variant: MealCardVariant.hero,
         fullMeal: fullMeal,
         subtitle: subtitle,
         heroEnabled: heroEnabled,
       );

  const MealCard.tile({
    Key? key,
    required MealSummary meal,
    required VoidCallback onTap,
    Meal? fullMeal,
    bool heroEnabled = true,
  }) : this(
         key: key,
         meal: meal,
         onTap: onTap,
         variant: MealCardVariant.tile,
         fullMeal: fullMeal,
         heroEnabled: heroEnabled,
       );

  final MealSummary meal;
  final VoidCallback onTap;
  final MealCardVariant variant;

  /// Full meal when already known (avoids a lookup when favoriting).
  final Meal? fullMeal;
  final String? subtitle;
  final bool heroEnabled;

  Widget _image(
    BuildContext context, {
    int? cacheWidth,
    String size = 'medium',
  }) {
    final image = AppNetworkImage(
      AppNetworkImage.sized(meal.thumb, size),
      cacheWidth: cacheWidth,
    );
    if (!heroEnabled) return image;
    // Offstage tab branches must not take part in hero flights.
    return HeroMode(
      enabled: TickerMode.valuesOf(context).enabled,
      child: Hero(tag: Routes.heroTag(meal.id), child: image),
    );
  }

  Widget _heart() => FavoriteToggleButton(
    mealId: meal.id,
    meal: fullMeal,
    mealName: meal.name,
    onDark: variant != MealCardVariant.row,
  );

  @override
  Widget build(BuildContext context) => switch (variant) {
    MealCardVariant.hero => _buildHero(context),
    MealCardVariant.row => _buildRow(context),
    MealCardVariant.tile => _buildTile(context),
  };

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Meal of the day: ${meal.name}',
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _image(context, cacheWidth: 900, size: 'large'),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.scrim.withValues(alpha: 0),
                        AppColors.scrim.withValues(alpha: 0.75),
                      ],
                      stops: const [0.4, 1],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: AppSpacing.lg,
                  end: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.onScrim,
                          ),
                        ),
                      Text(
                        meal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.onScrim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  top: AppSpacing.xs,
                  end: AppSpacing.xs,
                  child: _heart(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: meal.name,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 84,
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: _image(context, cacheWidth: 252, size: 'small'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                _heart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: meal.name,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _image(context, cacheWidth: 400, size: 'medium'),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.scrim.withValues(alpha: 0),
                      AppColors.scrim.withValues(alpha: 0.7),
                    ],
                    stops: const [0.55, 1],
                  ),
                ),
              ),
              PositionedDirectional(
                start: AppSpacing.sm,
                end: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Text(
                  meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.onScrim,
                  ),
                ),
              ),
              PositionedDirectional(top: 0, end: 0, child: _heart()),
            ],
          ),
        ),
      ),
    );
  }
}
