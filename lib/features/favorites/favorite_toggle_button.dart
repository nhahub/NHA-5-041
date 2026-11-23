import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/require_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

/// Yes / No confirmation before removing a favorite. Returns `true` on Yes.
Future<bool> confirmRemoveFavorite(
  BuildContext context, {
  String? mealName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove from favorites?'),
      content: Text(
        mealName == null
            ? 'This meal will be removed from your favorites.'
            : '"$mealName" will be removed from your favorites.',
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
  return result ?? false;
}

/// State = "is this meal a favorite of the current user".
class FavoriteToggleCubit extends Cubit<bool> {
  FavoriteToggleCubit({
    required this.userId,
    required this.mealId,
    required FavoritesRepository favorites,
    required MealRepository meals,
  }) : _favorites = favorites,
       _meals = meals,
       super(false) {
    final uid = userId;
    if (uid != null) {
      _sub = _favorites.watchIsFavorite(uid, mealId).listen(emit);
    }
  }

  final String? userId;
  final String mealId;
  final FavoritesRepository _favorites;
  final MealRepository _meals;
  StreamSubscription<bool>? _sub;

  /// Adds the meal; when only the id is known the full meal is looked up first
  /// so Details works offline later.
  Future<Result<void>> add(Meal? meal) async {
    final uid = userId;
    if (uid == null) return const Result.err(GuestFailure());
    var full = meal;
    if (full == null || full.instructions.isEmpty) {
      final looked = await _meals.lookup(mealId);
      full = looked.valueOrNull ?? full;
      if (full == null) {
        return Result.err(looked.failureOrNull ?? const NetworkFailure());
      }
    }
    return _favorites.add(uid, full);
  }

  Future<Result<void>> remove() {
    final uid = userId;
    if (uid == null) return Future.value(const Result.err(GuestFailure()));
    return _favorites.remove(uid, mealId);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

/// Heart button usable from anywhere: guests see the sign-in gate, removing
/// asks for confirmation, adding shows a small animation and a snackbar.
class FavoriteToggleButton extends StatelessWidget {
  const FavoriteToggleButton({
    super.key,
    required this.mealId,
    this.meal,
    this.mealName,
    this.onDark = false,
  });

  final String mealId;
  final Meal? meal;
  final String? mealName;

  /// Draws a scrim behind the icon for use over photos.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (a, b) => a.uid != b.uid,
      builder: (context, auth) => BlocProvider(
        key: ValueKey('${auth.uid}-$mealId'),
        create: (ctx) => FavoriteToggleCubit(
          userId: auth.uid,
          mealId: mealId,
          favorites: ctx.read<FavoritesRepository>(),
          meals: ctx.read<MealRepository>(),
        ),
        child: _Heart(
          meal: meal,
          mealName: mealName ?? meal?.name,
          onDark: onDark,
        ),
      ),
    );
  }
}

class _Heart extends StatelessWidget {
  const _Heart({
    required this.meal,
    required this.mealName,
    required this.onDark,
  });

  final Meal? meal;
  final String? mealName;
  final bool onDark;

  Future<void> _tap(BuildContext context) async {
    final cubit = context.read<FavoriteToggleCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final allowed = await requireAuth(
      context,
      reason: 'Guests can browse everything, but saving favorites needs an account.',
    );
    if (!allowed || !context.mounted) return;
    // The auth state changed while the dialog was open: use a fresh cubit.
    final current = context.read<FavoriteToggleCubit>();
    if (current.userId == null) return;
    if (current.state) {
      if (await confirmRemoveFavorite(context, mealName: mealName)) {
        await cubit.remove();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
      }
    } else {
      final r = await cubit.add(meal);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              r.when(ok: (_) => 'Added to favorites', err: (f) => f.message),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<FavoriteToggleCubit, bool>(
      builder: (context, isFav) {
        final icon = AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(isFav),
            color: isFav
                ? AppColors.heart
                : (onDark ? AppColors.onScrim : scheme.onSurfaceVariant),
          ),
        );
        return Semantics(
          button: true,
          label: isFav ? 'Remove from favorites' : 'Add to favorites',
          child: IconButton(
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTarget,
              minHeight: AppSpacing.minTarget,
            ),
            style: onDark
                ? IconButton.styleFrom(
                    backgroundColor: AppColors.scrim.withValues(alpha: 0.35),
                  )
                : null,
            onPressed: () => _tap(context),
            icon: icon,
          ),
        );
      },
    );
  }
}
