import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/core/auth/auth_cubit.dart';
import 'package:food_planner/core/auth/logout_flow.dart';
import 'package:food_planner/core/widgets/meal_card.dart';
import 'package:food_planner/core/widgets/states.dart';
import 'package:food_planner/domain/fakes/fakes.dart';
import 'package:food_planner/domain/models/meal.dart';
import 'package:food_planner/domain/models/user_and_plan.dart';
import 'package:food_planner/domain/repositories/repositories.dart';
import 'package:food_planner/features/favorites/favorite_toggle_button.dart';
import 'package:food_planner/features/meal_details/meal_details_screen.dart';

import '../helpers/pump_app.dart';

/// Opens a dialog from a button and reports what the dialog returned.
Future<bool?> openAndTap(
  WidgetTester tester,
  Future<bool> Function(BuildContext) open,
  String buttonLabel,
) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await open(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(buttonLabel));
  await tester.pumpAndSettle();
  return result;
}

Widget providersFor(
  Widget child, {
  AuthState auth = const AuthState.guest(),
  FakeFavoritesRepository? favorites,
}) {
  final favs = favorites ?? FakeFavoritesRepository();
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<FavoritesRepository>.value(value: favs),
      RepositoryProvider<MealRepository>.value(value: FakeMealRepository()),
    ],
    child: BlocProvider(
      create: (_) => AuthCubit(FakeAuthRepository(initial: auth)),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void main() {
  setUp(() => AppNetworkImage.offlineForTests = true);

  group('confirmRemoveFavorite', () {
    testWidgets('returns true on Yes', (tester) async {
      expect(
        await openAndTap(tester, (c) => confirmRemoveFavorite(c), 'Yes'),
        isTrue,
      );
    });

    testWidgets('returns false on No', (tester) async {
      expect(
        await openAndTap(tester, (c) => confirmRemoveFavorite(c), 'No'),
        isFalse,
      );
    });
  });

  group('confirmLogout', () {
    testWidgets('returns true on Yes', (tester) async {
      expect(await openAndTap(tester, confirmLogout, 'Yes'), isTrue);
    });

    testWidgets('returns false on No', (tester) async {
      expect(await openAndTap(tester, confirmLogout, 'No'), isFalse);
    });
  });

  group('shared states', () {
    testWidgets('EmptyState shows title, message and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        themed(
          EmptyState(
            title: 'Nothing',
            message: 'Try later',
            actionLabel: 'Go',
            onAction: () => tapped = true,
          ),
        ),
      );
      expect(find.text('Nothing'), findsOneWidget);
      expect(find.text('Try later'), findsOneWidget);
      await tester.tap(find.text('Go'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorState calls the retry callback', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        themed(ErrorState(message: 'Boom', onRetry: () => retries++)),
      );
      await tester.tap(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      expect(retries, 2);
      expect(find.text('Boom'), findsOneWidget);
    });

    testWidgets('OfflineBanner explains favorites still work', (tester) async {
      await tester.pumpWidget(themed(const OfflineBanner()));
      expect(find.textContaining('offline'), findsOneWidget);
    });
  });

  group('MealCard variants', () {
    const summary = MealSummary(
      id: '52772',
      name: 'Teriyaki Chicken Casserole',
    );

    for (final variant in MealCardVariant.values) {
      testWidgets('${variant.name} shows the name and handles taps', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          providersFor(
            SizedBox(
              height: 300,
              width: 300,
              child: MealCard(
                meal: summary,
                variant: variant,
                onTap: () => taps++,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
        await tester.tap(find.text('Teriyaki Chicken Casserole'));
        expect(taps, 1);
        // Every variant embeds the favorite heart.
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      });
    }

    testWidgets('image carries the shared hero tag', (tester) async {
      await tester.pumpWidget(
        providersFor(
          SizedBox(
            width: 300,
            height: 120,
            child: MealCard(meal: summary, onTap: () {}),
          ),
        ),
      );
      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'meal-hero-52772');
    });
  });

  group('FavoriteToggleButton', () {
    testWidgets('a guest sees the sign-in dialog', (tester) async {
      await tester.pumpWidget(
        providersFor(const FavoriteToggleButton(mealId: '52772')),
      );
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect(find.text('Sign in required'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in required'), findsNothing);
    });

    testWidgets('signed in: add, then remove only after confirming Yes', (
      tester,
    ) async {
      final favs = FakeFavoritesRepository();
      await tester.pumpWidget(
        providersFor(
          FavoriteToggleButton(mealId: fakeMeals[0].id, meal: fakeMeals[0]),
          auth: const AuthState.authenticated(signedInUser),
          favorites: favs,
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect((await favs.getAll('u1')).length, 1);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // No keeps it.
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();
      expect(find.text('Remove from favorites?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect((await favs.getAll('u1')).length, 1);

      // Yes removes it.
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(await favs.getAll('u1'), isEmpty);
    });
  });

  group('InstructionsSection (D7)', () {
    final steps = List.generate(
      6,
      (i) => 'Step text number ${i + 1} goes here.',
    );

    testWidgets('collapsed to the first 4 with See more', (tester) async {
      await tester.pumpWidget(
        themed(SingleChildScrollView(child: InstructionsSection(steps: steps))),
      );
      expect(find.textContaining('number 4'), findsOneWidget);
      expect(find.textContaining('number 5'), findsNothing);
      await tester.tap(find.textContaining('See more'));
      await tester.pump();
      expect(find.textContaining('number 6'), findsOneWidget);
      await tester.tap(find.textContaining('See less'));
      await tester.pump();
      expect(find.textContaining('number 6'), findsNothing);
    });

    testWidgets('four steps or fewer: no toggle', (tester) async {
      await tester.pumpWidget(
        themed(InstructionsSection(steps: steps.take(4).toList())),
      );
      expect(find.textContaining('See more'), findsNothing);
    });
  });
}
