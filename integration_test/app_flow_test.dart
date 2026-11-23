import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/app/app_dependencies.dart';
import 'package:food_planner/app/food_planner_app.dart';
import 'package:food_planner/core/widgets/states.dart';
import 'package:food_planner/domain/fakes/fakes.dart';
import 'package:food_planner/domain/models/user_and_plan.dart';
import 'package:food_planner/domain/result.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests run the real widget tree with fake repositories wherever
/// Firebase or the network would be involved.
///
///     flutter test integration_test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<AppDependencies> boot(
    WidgetTester tester, {
    AuthState auth = const AuthState.unauthenticated(),
    FakeFavoritesRepository? favorites,
    FakeMealRepository? meals,
  }) async {
    AppNetworkImage.offlineForTests = true;
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies.fake(
      prefs: await SharedPreferences.getInstance(),
      auth: FakeAuthRepository(initial: auth),
      favorites: favorites,
      meals: meals,
    );
    await tester.pumpWidget(FoodPlannerApp(deps: deps));
    // Splash: minimum 2.5 s, then routes on.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    return deps;
  }

  testWidgets('#1 guest: Home -> Category -> Meal Details', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seafood').first); // category on Home
    await tester.pumpAndSettle();
    expect(find.text('Baked salmon with fennel & tomatoes'), findsOneWidget);

    await tester.tap(find.text('Baked salmon with fennel & tomatoes'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('Instructions'), findsOneWidget);

    // A guest cannot favorite: the sign-in gate appears.
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(find.text('Sign in required'), findsOneWidget);
  });

  testWidgets(
    '#2 login -> favorite -> offline -> favorite still visible with Details',
    (tester) async {
      final favorites = FakeFavoritesRepository();
      final meals = FakeMealRepository();
      await boot(tester, favorites: favorites, meals: meals);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'mina@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password1',
      );
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      // Favorite a meal from Home.
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();
      expect((await favorites.getAll('uid-mina@example.com')), isNotEmpty);

      // "Airplane mode": every network call now fails.
      meals.failure = const NetworkFailure();

      await tester.tap(find.text('Favorites').last);
      await tester.pumpAndSettle();
      final saved = (await favorites.getAll('uid-mina@example.com')).first;
      expect(find.text(saved.name), findsWidgets);

      // Details still opens from the stored copy.
      await tester.tap(find.text(saved.name).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('saved copy'), findsOneWidget);
      expect(find.text('Ingredients'), findsOneWidget);
    },
  );
}
