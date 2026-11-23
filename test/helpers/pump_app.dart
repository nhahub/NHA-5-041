import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/app/app_dependencies.dart';
import 'package:food_planner/app/food_planner_app.dart';
import 'package:food_planner/core/prefs/preference_manager.dart';
import 'package:food_planner/core/widgets/states.dart';
import 'package:food_planner/domain/fakes/fakes.dart';
import 'package:food_planner/domain/models/user_and_plan.dart';
import 'package:food_planner/domain/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

const signedInUser = AppUser(
  uid: 'u1',
  displayName: 'Mina Ibrahim',
  email: 'mina@example.com',
);

class TestApp {
  TestApp(this.deps);

  final AppDependencies deps;
  FakeAuthRepository get auth => deps.auth as FakeAuthRepository;
  FakeFavoritesRepository get favorites =>
      deps.favorites as FakeFavoritesRepository;
  FakePlannerRepository get planner => deps.planner as FakePlannerRepository;
  FakeMealRepository get meals => deps.meals as FakeMealRepository;
}

/// Pumps the whole app on fakes (no Firebase, no network, no database).
Future<TestApp> pumpApp(
  WidgetTester tester, {
  AuthState auth = const AuthState.authenticated(signedInUser),
  String location = '/home',
  MealRepository? meals,
  Size size = const Size(420, 900),
}) async {
  AppNetworkImage.offlineForTests = true;
  PreferenceManager.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  final prefManager = await PreferenceManager.init();
  final deps = AppDependencies.fake(
    prefManager: prefManager,
    auth: FakeAuthRepository(initial: auth),
    meals: meals,
  );
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    FoodPlannerApp(deps: deps, initialLocation: location),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return TestApp(deps);
}

/// Lets async streams / futures settle without waiting on infinite animations.
Future<void> settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget themed(Widget child) => MaterialApp(home: Scaffold(body: child));
