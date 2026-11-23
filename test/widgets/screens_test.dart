import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/core/router/app_router.dart';
import 'package:food_planner/core/widgets/states.dart';
import 'package:food_planner/domain/fakes/fakes.dart';
import 'package:food_planner/domain/models/user_and_plan.dart';
import 'package:food_planner/domain/result.dart';
import 'package:food_planner/features/meal_details/meal_details_screen.dart';
import 'package:food_planner/features/options/about_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/pump_app.dart';

PackageInfo info(String version) => PackageInfo(
  appName: 'Food Planner',
  packageName: 'com.depi.foodplanner.food_planner',
  version: version,
  buildNumber: '7',
);

void main() {
  setUp(() => AppNetworkImage.offlineForTests = true);

  group('router redirect', () {
    test('unknown session goes to splash', () {
      expect(AppRouter.redirect(const AuthState.unknown(), '/home'), '/splash');
    });
    test('splash is never redirected', () {
      expect(AppRouter.redirect(const AuthState.unknown(), '/splash'), isNull);
      expect(
        AppRouter.redirect(const AuthState.unauthenticated(), '/splash'),
        isNull,
      );
    });
    test('signed out can only see login and sign up', () {
      const out = AuthState.unauthenticated();
      expect(AppRouter.redirect(out, '/home'), '/login');
      expect(AppRouter.redirect(out, '/meal/1'), '/login');
      expect(AppRouter.redirect(out, '/login'), isNull);
      expect(AppRouter.redirect(out, '/signup'), isNull);
    });
    test('guests may open every tab', () {
      for (final p in [
        '/home',
        '/search',
        '/calendar',
        '/favorites',
        '/profile',
        '/meal/1',
        '/login',
      ]) {
        expect(
          AppRouter.redirect(const AuthState.guest(), p),
          isNull,
          reason: p,
        );
      }
    });
    test('signed in users are not forced anywhere', () {
      expect(
        AppRouter.redirect(
          const AuthState.authenticated(signedInUser),
          '/home',
        ),
        isNull,
      );
    });
  });

  group('Splash', () {
    testWidgets('signed out: plays then opens Login', (tester) async {
      await pumpApp(
        tester,
        auth: const AuthState.unauthenticated(),
        location: '/splash',
      );
      expect(find.text('Food Planner'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('guest: opens Home', (tester) async {
      await pumpApp(tester, auth: const AuthState.guest(), location: '/splash');
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(find.text('What shall we cook today?'), findsOneWidget);
    });
  });

  group('Login', () {
    testWidgets('inline validators, then guest button opens Home', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: const AuthState.unauthenticated(),
        location: '/login',
      );
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '123',
      );
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);

      await tester.tap(find.text('Continue as Guest'));
      await settle(tester);
      expect(find.text('What shall we cook today?'), findsOneWidget);
    });

    testWidgets('valid login lands on Home', (tester) async {
      await pumpApp(
        tester,
        auth: const AuthState.unauthenticated(),
        location: '/login',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'mina@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password1',
      );
      await tester.tap(find.text('Log in'));
      await settle(tester);
      expect(find.text('What shall we cook today?'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    });

    testWidgets('show / hide password toggle', (tester) async {
      await pumpApp(
        tester,
        auth: const AuthState.unauthenticated(),
        location: '/login',
      );
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });

  group('Profile', () {
    testWidgets(
      'signed in: name, email, default avatar and the three actions',
      (tester) async {
        await pumpApp(tester, location: '/profile');
        await settle(tester);
        expect(find.text('Mina Ibrahim'), findsOneWidget);
        expect(find.text('mina@example.com'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsWidgets);
        expect(find.text('Favorite Meals'), findsOneWidget);
        expect(find.text('Planned Meals'), findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);
        expect(find.text('Favorites backup'), findsOneWidget); // sync card
      },
    );

    testWidgets('guest: shows Guest, Sign in and the backup hint', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: const AuthState.guest(),
        location: '/profile',
      );
      await settle(tester);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Sign in to back up your favorites'), findsOneWidget);
      // Favorites and planned meals still open for guests.
      expect(find.text('Favorite Meals'), findsOneWidget);
      expect(find.text('Planned Meals'), findsOneWidget);
    });

    testWidgets('Favorite Meals and Planned Meals buttons navigate', (
      tester,
    ) async {
      await pumpApp(tester, location: '/profile');
      await settle(tester);
      await tester.tap(find.text('Favorite Meals'));
      await settle(tester);
      expect(find.text('No favorites yet'), findsOneWidget);
      await tester.tap(find.text('Profile').last);
      await settle(tester);
      await tester.tap(find.text('Planned Meals'));
      await settle(tester);
      expect(find.text('Nothing planned this week'), findsOneWidget);
    });

    testWidgets('logout: No keeps the session, Yes signs out to Login', (
      tester,
    ) async {
      final app = await pumpApp(tester, location: '/profile');
      await settle(tester);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(app.auth.currentState.isAuthenticated, isTrue);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await settle(tester);
      expect(app.auth.currentState.status, AuthStatus.unauthenticated);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('Options menu + About', () {
    testWidgets('menu on every tab offers About and Logout', (tester) async {
      await pumpApp(tester, location: '/search');
      for (final tab in [
        'Home',
        'Search',
        'Calendar',
        'Favorites',
        'Profile',
      ]) {
        await tester.tap(find.text(tab).last);
        await settle(tester, 3);
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        // (the Profile tab also has its own Logout row, hence findsWidgets)
        expect(find.text('About'), findsWidgets, reason: tab);
        expect(find.text('Logout'), findsWidgets, reason: tab);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('About shows description, developers and the real version', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(versionLoader: () async => info('1.0.0')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Version 1.0.0 (7)'), findsOneWidget);
      expect(find.text('Developers'), findsOneWidget);
      for (final dev in ['Mohamed', 'Amr', 'Youssef', 'Abd Alrahman', 'Mina']) {
        expect(find.text(dev), findsOneWidget);
      }
      await tester.scrollUntilVisible(
        find.textContaining('TheMealDB'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Lottie'), findsOneWidget);
    });
  });

  group('Search tab', () {
    testWidgets('three modes with 2 / 3 / 3 columns and local filtering', (
      tester,
    ) async {
      await pumpApp(tester, location: '/search');
      await settle(tester);
      GridView grid() => tester.widget<GridView>(find.byType(GridView));
      int columns() =>
          (grid().gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount;

      expect(columns(), 2);
      expect(find.text('Seafood'), findsOneWidget);

      await tester.tap(find.text('Countries'));
      await settle(tester);
      expect(columns(), 3);
      expect(find.text('Italian'), findsOneWidget);
      expect(find.text('🇮🇹'), findsOneWidget);

      await tester.tap(find.text('Ingredients'));
      await settle(tester);
      expect(columns(), 3);
      expect(find.text('Garlic'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'sal');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Salmon'), findsOneWidget);
      expect(find.text('Garlic'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('tapping a category opens the meal list and filters it', (
      tester,
    ) async {
      await pumpApp(tester, location: '/search');
      await settle(tester);
      await tester.tap(find.text('Seafood'));
      await settle(tester);
      expect(find.text('Baked salmon with fennel & tomatoes'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('No results'), findsOneWidget);
    });
  });

  group('Home', () {
    testWidgets('meal of the day, categories and browse feed', (tester) async {
      await pumpApp(tester);
      await settle(tester, 10);
      expect(find.text('Hello, Mina!'), findsOneWidget);
      expect(find.text('Teriyaki Chicken Casserole'), findsWidgets);
      expect(find.text('Seafood'), findsOneWidget);
    });

    testWidgets(
      'network failure shows retryable errors with a Favorites shortcut',
      (tester) async {
        await pumpApp(
          tester,
          meals: FakeMealRepository(failure: const NetworkFailure()),
        );
        await settle(tester, 10);
        expect(find.text('Retry'), findsWidgets);
        expect(find.text('Open favorites'), findsWidgets);
      },
    );

    testWidgets('tapping a meal opens Details', (tester) async {
      await pumpApp(tester);
      await settle(tester, 10);
      await tester.tap(find.text('Spicy Arrabiata Penne').first);
      await settle(tester, 10);
      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('Instructions'), findsOneWidget);
    });
  });

  group('Meal Details', () {
    Widget video(BuildContext c, String id) => Text('player:$id');

    testWidgets(
      'shows image area, name, category, country, ingredients, steps and video',
      (tester) async {
        await pumpApp(tester, location: '/meal/52772');
        await settle(tester, 10);
        expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
        expect(find.text('Chicken'), findsWidgets);
        expect(find.text('Japanese'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Soy Sauce'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('3/4 cup'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byType(VideoSection),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Video'), findsOneWidget);
        expect(find.text('player:4aZr5hZXP_s'), findsOneWidget);
      },
    );

    testWidgets('meal without a video shows a friendly message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoSection(url: '', builder: video),
          ),
        ),
      );
      expect(find.textContaining('No video'), findsOneWidget);
    });

    testWidgets('embedded player is built in-page for a YouTube url', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoSection(
              url: 'https://www.youtube.com/watch?v=4aZr5hZXP_s',
              builder: video,
            ),
          ),
        ),
      );
      expect(find.text('player:4aZr5hZXP_s'), findsOneWidget);
    });

    testWidgets('error with Retry, then data', (tester) async {
      final repo = FakeMealRepository(failure: const NetworkFailure());
      await pumpApp(tester, location: '/meal/52772', meals: repo);
      await settle(tester, 6);
      expect(find.text('No internet connection.'), findsOneWidget);
      repo.failure = null;
      await tester.tap(find.text('Retry'));
      await settle(tester, 8);
      expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
    });

    testWidgets('guest tapping the heart sees the sign-in dialog', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: const AuthState.guest(),
        location: '/meal/52772',
      );
      await settle(tester, 10);
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();
      expect(find.text('Sign in required'), findsOneWidget);
    });

    testWidgets('guest tapping Add to calendar sees the sign-in dialog', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: const AuthState.guest(),
        location: '/meal/52772',
      );
      await settle(tester, 10);
      await tester.tap(find.text('Add to calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in required'), findsOneWidget);
    });
  });

  group('Favorites tab', () {
    testWidgets('guest sees Sign in to save favorites', (tester) async {
      await pumpApp(
        tester,
        auth: const AuthState.guest(),
        location: '/favorites',
      );
      await settle(tester);
      expect(find.text('Sign in to save favorites'), findsOneWidget);
    });

    testWidgets(
      'a favorite added elsewhere appears instantly and swipe-remove asks Yes/No',
      (tester) async {
        final app = await pumpApp(tester, location: '/favorites');
        await settle(tester);
        expect(find.text('No favorites yet'), findsOneWidget);
        await app.favorites.add('u1', fakeMeals[0]);
        await settle(tester);
        expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();
        expect(find.text('Remove from favorites?'), findsOneWidget);
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();
        expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await settle(tester);
        expect(find.text('No favorites yet'), findsOneWidget);
      },
    );

    testWidgets('two accounts never see each other\'s favorites', (
      tester,
    ) async {
      final app = await pumpApp(tester, location: '/favorites');
      await app.favorites.add('other-user', fakeMeals[1]);
      await settle(tester);
      expect(find.text('Spicy Arrabiata Penne'), findsNothing);
    });
  });

  group('Calendar tab', () {
    testWidgets('guest is asked to sign in', (tester) async {
      await pumpApp(
        tester,
        auth: const AuthState.guest(),
        location: '/calendar',
      );
      await settle(tester);
      expect(find.text('Sign in to plan your week'), findsOneWidget);
    });

    testWidgets('planned meal shows under today with its reminder state', (
      tester,
    ) async {
      final app = await pumpApp(tester, location: '/calendar');
      await settle(tester);
      expect(find.text('Nothing planned this week'), findsOneWidget);
      expect(find.text('Browse recipes'), findsOneWidget);
      await app.planner.add('u1', fakeMeals[0], DateTime.now());
      await settle(tester);
      expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
      expect(find.text('No reminder'), findsOneWidget);
    });

    testWidgets('remove asks for confirmation and offers Undo', (tester) async {
      final app = await pumpApp(tester, location: '/calendar');
      await app.planner.add('u1', fakeMeals[0], DateTime.now());
      await settle(tester);
      await tester.tap(find.byTooltip('Remove from plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await settle(tester);
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
    });
  });
}
