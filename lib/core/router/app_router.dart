import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/user_and_plan.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/meal_details/meal_details_screen.dart';
import '../../features/meal_list/meal_list_cubit.dart';
import '../../features/meal_list/meal_list_screen.dart';
import '../../features/options/about_screen.dart';
import '../../features/planner/calendar_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../auth/auth_cubit.dart';
import '../theme/theme_gallery.dart';
import 'app_shell.dart';
import 'routes.dart';

/// Re-runs the router redirect whenever [stream] emits.
class StreamRefresh extends ChangeNotifier {
  StreamRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  const AppRouter._();

  /// Redirect rules, driven by [AuthState]:
  /// - unknown session  -> splash (it restores the session and routes on)
  /// - signed out       -> login / sign-up only
  /// - guest or signed in -> everywhere (the gate protects favorites & sync)
  static String? redirect(AuthState auth, String location) {
    if (location == Routes.splash) return null;
    switch (auth.status) {
      case AuthStatus.unknown:
        return Routes.splash;
      case AuthStatus.unauthenticated:
        final onAuthPage =
            location == Routes.login || location == Routes.signup;
        return onAuthPage ? null : Routes.login;
      case AuthStatus.guest:
      case AuthStatus.authenticated:
        return null;
    }
  }

  static GoRouter create(
    AuthCubit auth, {
    String initialLocation = Routes.splash,
    VideoBuilder? videoBuilder,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: StreamRefresh(auth.stream),
      redirect: (context, state) => redirect(auth.state, state.matchedLocation),
      routes: [
        GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: Routes.signup, builder: (_, _) => const SignUpScreen()),
        GoRoute(path: Routes.about, builder: (_, _) => const AboutScreen()),
        if (kDebugMode)
          GoRoute(
            path: Routes.gallery,
            builder: (_, _) => const ThemeGalleryScreen(),
          ),
        GoRoute(
          path: Routes.meal,
          builder: (_, state) => MealDetailsScreen(
            mealId: state.pathParameters['id']!,
            videoBuilder: videoBuilder,
          ),
        ),
        GoRoute(
          path: Routes.meals,
          builder: (_, state) {
            final type =
                MealListType.parse(state.uri.queryParameters['type']) ??
                MealListType.category;
            return MealListScreen(
              type: type,
              value: state.uri.queryParameters['value'] ?? '',
            );
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.home,
                  builder: (_, _) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.search,
                  builder: (_, _) => const SearchScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.calendar,
                  builder: (_, _) => const CalendarScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.favorites,
                  builder: (_, _) => const FavoritesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.profile,
                  builder: (_, _) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
