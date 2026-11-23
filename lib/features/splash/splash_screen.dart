import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';

/// Decides where to go after startup. Emits the destination route once both
/// the minimum splash time and the session restore are done.
class SplashCubit extends Cubit<String?> {
  SplashCubit(
    this._auth, {
    this.minDuration = const Duration(milliseconds: 2500),
    this.fallbackAfter = const Duration(seconds: 6),
  }) : super(null);

  final AuthRepository _auth;
  final Duration minDuration;

  /// If restoring the session is slow, stop waiting and use the current state.
  final Duration fallbackAfter;

  static String destinationFor(AuthState state) => switch (state.status) {
    AuthStatus.authenticated || AuthStatus.guest => Routes.home,
    AuthStatus.unauthenticated || AuthStatus.unknown => Routes.login,
  };

  Future<void> start() async {
    final minimum = Future<void>.delayed(minDuration);
    final restored = _auth.init().timeout(
      fallbackAfter,
      onTimeout: () => _auth.currentState,
    );
    final results = await Future.wait<Object?>([minimum, restored]);
    if (!isClosed) emit(destinationFor(results[1] as AuthState));
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => SplashCubit(ctx.read<AuthRepository>())..start(),
    child: BlocListener<SplashCubit, String?>(
      listener: (context, route) {
        if (route != null) context.go(route);
      },
      child: const _SplashView(),
    ),
  );
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Food Planner is loading',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Lottie.asset(
                  'assets/lottie/splash.json',
                  animate: !reduceMotion,
                  repeat: true,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.restaurant,
                    size: 96,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Food Planner', style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
