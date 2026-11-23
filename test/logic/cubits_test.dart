import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/core/clock.dart';
import 'package:food_planner/core/connectivity/connectivity_cubit.dart';
import 'package:food_planner/core/prefs/preference_manager.dart';
import 'package:food_planner/core/view_state.dart';
import 'package:food_planner/domain/fakes/fakes.dart';
import 'package:food_planner/domain/models/meal.dart';
import 'package:food_planner/domain/models/user_and_plan.dart';
import 'package:food_planner/domain/result.dart';
import 'package:food_planner/features/auth/auth_form_cubit.dart';
import 'package:food_planner/features/home/home_cubits.dart';
import 'package:food_planner/features/meal_details/meal_details_cubit.dart';
import 'package:food_planner/features/meal_list/meal_list_cubit.dart';
import 'package:food_planner/features/planner/planner_cubit.dart';
import 'package:food_planner/features/search/search_cubit.dart';
import 'package:food_planner/features/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Areas implements AreaCatalog {
  @override
  Future<List<SearchItem>> load() async => const [
    SearchItem(name: 'Italian'),
    SearchItem(name: 'Japanese'),
  ];
}

class _PagedRepo extends FakeMealRepository {
  _PagedRepo(this.byLetter);
  final Map<String, List<Meal>> byLetter;
  final List<String> asked = [];

  @override
  Future<Result<List<Meal>>> searchByLetter(String letter) async {
    asked.add(letter);
    return Result.ok(byLetter[letter] ?? const []);
  }
}

class _ControlledConnectivity implements ConnectivitySource {
  final controller = StreamController<bool>.broadcast();
  bool online = true;

  @override
  Future<bool> checkOnline() async => online;

  @override
  Stream<bool> get onlineChanges => controller.stream;
}

Meal m(String id, String name) => Meal(id: id, name: name);

void main() {
  group('MealOfDayCubit (fake clock)', () {
    late PreferenceManager prefManager;
    late FixedClock clock;

    setUp(() async {
      PreferenceManager.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      prefManager = await PreferenceManager.init();
      clock = FixedClock(DateTime(2026, 11, 20, 9));
    });

    MealOfDayCubit build(FakeMealRepository repo) =>
        MealOfDayCubit(repo, prefManager, clock: clock, scheduleRollover: false);

    test('same day returns the same meal (random called once)', () async {
      final repo = FakeMealRepository();
      final first = build(repo);
      await first.load();
      clock.current = DateTime(2026, 11, 20, 23, 59);
      final second = build(repo); // e.g. after an app restart
      await second.load();
      expect(repo.calls, 1);
      expect(
        (second.state as ViewData<Meal>).data,
        (first.state as ViewData<Meal>).data,
      );
    });

    test('next day fetches a new meal', () async {
      final repo = FakeMealRepository();
      await build(repo).load();
      clock.current = DateTime(2026, 11, 21, 0, 1);
      await build(repo).load();
      expect(repo.calls, 2);
    });

    test('offline with a cached (older) meal shows the cache', () async {
      final repo = FakeMealRepository();
      await build(repo).load();
      clock.current = DateTime(2026, 11, 22);
      repo.failure = const NetworkFailure();
      final cubit = build(repo);
      await cubit.load();
      expect(cubit.state, isA<ViewData<Meal>>());
    });

    test('offline with no cache shows an error', () async {
      final repo = FakeMealRepository(failure: const NetworkFailure());
      final cubit = build(repo);
      await cubit.load();
      expect(cubit.state, isA<ViewError<Meal>>());
    });
  });

  group('BrowseFeedCubit paging', () {
    test('goes through letters in order and de-duplicates', () async {
      final repo = _PagedRepo({
        'a': [m('1', 'Apple pie'), m('2', 'Apricot tart')],
        'b': [m('2', 'Apricot tart'), m('3', 'Beef stew')],
        'c': [m('4', 'Cake')],
      });
      final cubit = BrowseFeedCubit(repo, minPerPage: 3);
      await cubit.loadMore();
      // 'a' gives 2 meals, 'b' adds 1 new one (id 2 is a duplicate): page full.
      expect(repo.asked, ['a', 'b']);
      expect(cubit.state.meals.map((x) => x.id), ['1', '2', '3']);
      await cubit.loadMore(); // next page continues with 'c'
      // Continues with 'c' and keeps skipping empty letters until the end.
      expect(repo.asked.take(3).toList(), ['a', 'b', 'c']);
      expect(cubit.state.meals.map((x) => x.id), ['1', '2', '3', '4']);
    });

    test('skips empty letters until enough meals or the end', () async {
      final repo = _PagedRepo({
        'z': [m('9', 'Zucchini')],
      });
      final cubit = BrowseFeedCubit(repo, minPerPage: 1);
      await cubit.loadMore();
      expect(cubit.state.meals.single.id, '9');
      expect(cubit.state.hasMore, isFalse);
      await cubit.loadMore(); // end of list: no more calls
      expect(repo.asked.length, 26);
    });

    test(
      'failure keeps loaded meals and exposes the failure for retry',
      () async {
        final repo = FakeMealRepository(failure: const NetworkFailure());
        final cubit = BrowseFeedCubit(repo);
        await cubit.loadMore();
        expect(cubit.state.failure, isA<NetworkFailure>());
        expect(cubit.state.hasMore, isTrue);
      },
    );
  });

  group('ConnectivityCubit mapping', () {
    test('maps the source stream to online/offline', () async {
      final source = _ControlledConnectivity();
      final cubit = ConnectivityCubit(source);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, ConnectionStatus.online);
      source.controller.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, ConnectionStatus.offline);
      source.controller.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.isOnline, isTrue);
      await cubit.close();
    });

    test('starts offline when the first check says so', () async {
      final source = _ControlledConnectivity()..online = false;
      final cubit = ConnectivityCubit(source);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, ConnectionStatus.offline);
      await cubit.close();
    });
  });

  group('SearchCubit: local filtering only', () {
    List<SearchItem> items() => const [
      SearchItem(name: 'Chicken'),
      SearchItem(name: 'Chicken Breast'),
      SearchItem(name: 'Garlic'),
    ];

    test('filter is trimmed and case-insensitive; empty returns all', () {
      expect(SearchCubit.filter(items(), '  CHICK ').length, 2);
      expect(SearchCubit.filter(items(), 'garlic').single.name, 'Garlic');
      expect(SearchCubit.filter(items(), '').length, 3);
      expect(SearchCubit.filter(items(), '   ').length, 3);
      expect(SearchCubit.filter(items(), 'zzz'), isEmpty);
    });

    test('typing makes NO network call', () async {
      final repo = FakeMealRepository();
      final cubit = SearchCubit(
        repo,
        _Areas(),
        debounce: const Duration(milliseconds: 10),
      );
      await cubit.load(SearchMode.categories);
      final callsAfterLoad = repo.calls;
      for (final q in ['s', 'se', 'sea', 'seaf']) {
        cubit.setQuery(q);
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(repo.calls, callsAfterLoad);
      expect(cubit.state.visible.map((i) => i.name), ['Seafood']);
      await cubit.close();
    });

    test('debounce: filter applies only after the pause', () async {
      final cubit = SearchCubit(
        FakeMealRepository(),
        _Areas(),
        debounce: const Duration(milliseconds: 30),
      );
      await cubit.load(SearchMode.categories);
      cubit.setQuery('chi');
      expect(cubit.state.visible.length, 3); // not applied yet
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cubit.state.visible.single.name, 'Chicken');
      await cubit.close();
    });

    test(
      'mode switching keeps the query per mode and does not refetch',
      () async {
        final repo = FakeMealRepository();
        final cubit = SearchCubit(repo, _Areas(), debounce: Duration.zero);
        await cubit.load(SearchMode.categories);
        cubit.setQuery('sea');
        await cubit.setMode(SearchMode.countries);
        expect(cubit.state.query, '');
        cubit.setQuery('ita');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await cubit.setMode(SearchMode.categories);
        expect(cubit.state.query, 'sea');
        final calls = repo.calls;
        await cubit.setMode(SearchMode.countries);
        await cubit.setMode(SearchMode.categories);
        expect(repo.calls, calls); // lists stay in memory
        expect(cubit.state.queries[SearchMode.countries], 'ita');
        await cubit.close();
      },
    );

    test('network failure becomes an error state with retry', () async {
      final repo = FakeMealRepository(failure: const NetworkFailure());
      final cubit = SearchCubit(repo, _Areas());
      await cubit.load(SearchMode.ingredients);
      expect(
        cubit.state.data[SearchMode.ingredients],
        isA<ViewError<List<SearchItem>>>(),
      );
      repo.failure = null;
      await cubit.load(SearchMode.ingredients, force: true);
      expect(
        cubit.state.data[SearchMode.ingredients],
        isA<ViewData<List<SearchItem>>>(),
      );
      await cubit.close();
    });

    test('flag emoji from ISO code', () {
      expect(AssetAreaCatalog.flagEmoji('EG'), '🇪🇬');
      expect(AssetAreaCatalog.flagEmoji(''), isNull);
      expect(AssetAreaCatalog.flagEmoji(null), isNull);
    });
  });

  group('MealListCubit', () {
    test('loads by type and filters locally without refetching', () async {
      final repo = FakeMealRepository();
      final cubit = MealListCubit(
        repo,
        type: MealListType.category,
        value: 'Seafood',
        debounce: Duration.zero,
      );
      await cubit.load();
      final calls = repo.calls;
      expect(cubit.state.visible.length, 1);
      cubit.setQuery('nothing matches');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state.visible, isEmpty);
      expect(repo.calls, calls);
      await cubit.close();
    });

    test('empty list and error states', () async {
      final repo = FakeMealRepository();
      final empty = MealListCubit(
        repo,
        type: MealListType.area,
        value: 'Nowhere',
      );
      await empty.load();
      expect(empty.state.view, isA<ViewEmpty<List<MealSummary>>>());
      repo.failure = const NetworkFailure();
      await empty.load();
      expect(empty.state.view, isA<ViewError<List<MealSummary>>>());
      await empty.close();
    });

    test('type parsing', () {
      expect(MealListType.parse('area'), MealListType.area);
      expect(MealListType.parse('ingredient'), MealListType.ingredient);
      expect(MealListType.parse('nope'), isNull);
    });
  });

  group('SplashCubit routing', () {
    test('destination for each auth state', () {
      expect(
        SplashCubit.destinationFor(
          const AuthState.authenticated(AppUser(uid: 'u')),
        ),
        '/home',
      );
      expect(SplashCubit.destinationFor(const AuthState.guest()), '/home');
      expect(
        SplashCubit.destinationFor(const AuthState.unauthenticated()),
        '/login',
      );
      expect(SplashCubit.destinationFor(const AuthState.unknown()), '/login');
    });

    test('emits the destination after the minimum time', () async {
      final auth = FakeAuthRepository(initial: const AuthState.guest());
      final cubit = SplashCubit(
        auth,
        minDuration: const Duration(milliseconds: 20),
      );
      expect(cubit.state, isNull);
      await cubit.start();
      expect(cubit.state, '/home');
    });

    test('signed out goes to login', () async {
      final cubit = SplashCubit(
        FakeAuthRepository(),
        minDuration: Duration.zero,
      );
      await cubit.start();
      expect(cubit.state, '/login');
    });
  });

  group('AuthFormCubit', () {
    blocTest<AuthFormCubit, AuthFormState>(
      'sign in success',
      build: () => AuthFormCubit(FakeAuthRepository()),
      act: (c) => c.signIn('a@b.co', 'password1'),
      expect: () => [
        const AuthFormState(loading: true),
        const AuthFormState(success: true),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'failure shows the friendly message',
      build: () => AuthFormCubit(
        FakeAuthRepository()
          ..nextFailure = const AuthFailure(
            AuthErrorKind.wrongPassword,
            'Wrong email or password.',
          ),
      ),
      act: (c) => c.signIn('a@b.co', 'password1'),
      expect: () => [
        const AuthFormState(loading: true),
        const AuthFormState(error: 'Wrong email or password.'),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'cancelling Google shows no error',
      build: () => AuthFormCubit(
        FakeAuthRepository()
          ..nextFailure = const AuthFailure(
            AuthErrorKind.cancelled,
            'Sign-in was cancelled.',
          ),
      ),
      act: (c) => c.google(),
      expect: () => [const AuthFormState(loading: true), const AuthFormState()],
    );
  });

  group('MealDetailsCubit', () {
    late FakeFavoritesRepository favorites;
    late FakePlannerRepository planner;
    late FakeAuthRepository auth;

    setUp(() {
      favorites = FakeFavoritesRepository();
      planner = FakePlannerRepository();
      auth = FakeAuthRepository(
        initial: const AuthState.authenticated(AppUser(uid: 'u1')),
      );
    });

    MealDetailsCubit build(FakeMealRepository meals) => MealDetailsCubit(
      mealId: '52772',
      meals: meals,
      favorites: favorites,
      planner: planner,
      auth: auth,
    );

    test('loads data', () async {
      final cubit = build(FakeMealRepository());
      await cubit.load();
      expect(cubit.state.view, isA<ViewData<Meal>>());
      expect(cubit.state.fromCache, isFalse);
      await cubit.close();
    });

    test('network error for a non-favorite fails gracefully', () async {
      final cubit = build(FakeMealRepository(failure: const NetworkFailure()));
      await cubit.load();
      expect(cubit.state.view, isA<ViewError<Meal>>());
      await cubit.close();
    });

    test('offline favorite is served from its stored copy', () async {
      await favorites.add('u1', fakeMeals[0]);
      final cubit = build(FakeMealRepository(failure: const NetworkFailure()));
      await cubit.load();
      expect(cubit.state.view, isA<ViewData<Meal>>());
      expect(cubit.state.fromCache, isTrue);
      await cubit.close();
    });

    test('plan stream shows planned state', () async {
      final cubit = build(FakeMealRepository());
      await cubit.load();
      await planner.add('u1', fakeMeals[0], DateTime(2026, 11, 25));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.plan?.day, DateTime(2026, 11, 25));
      await cubit.close();
    });
  });

  group('Planner week (Saturday start, D6)', () {
    test('weekStartOf', () {
      // 2026-11-20 is a Friday -> week started Saturday 14 Nov.
      expect(weekStartOf(DateTime(2026, 11, 20)), DateTime(2026, 11, 14));
      expect(
        weekStartOf(DateTime(2026, 11, 14)),
        DateTime(2026, 11, 14),
      ); // Saturday itself
      expect(
        weekStartOf(DateTime(2026, 11, 15)),
        DateTime(2026, 11, 14),
      ); // Sunday
      expect(weekEndOf(DateTime(2026, 11, 20)), DateTime(2026, 11, 20));
    });

    test('week crossing a month and year boundary', () {
      expect(weekStartOf(DateTime(2027, 1, 1)), DateTime(2026, 12, 26));
      expect(weekEndOf(DateTime(2027, 1, 1)), DateTime(2027, 1, 1));
    });

    test(
      'cubit shows plans of the focused week and reacts to changes',
      () async {
        final planner = FakePlannerRepository();
        final auth = FakeAuthRepository(
          initial: const AuthState.authenticated(AppUser(uid: 'u1')),
        );
        final clock = FixedClock(DateTime(2026, 11, 20, 10));
        final cubit = PlannerCubit(planner, auth, clock: clock);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(cubit.state.guest, isFalse);
        await planner.add('u1', fakeMeals[0], DateTime(2026, 11, 20));
        await planner.add(
          'u1',
          fakeMeals[1],
          DateTime(2026, 11, 28),
        ); // next week
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(cubit.state.plans.length, 1);
        expect(cubit.state.selectedPlans.single.meal.id, fakeMeals[0].id);
        cubit.focusWeek(
          DateTime(2026, 11, 28),
        ); // Saturday: first day of next week
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(cubit.state.plans.single.meal.id, fakeMeals[1].id);
        await cubit.close();
      },
    );

    test('guests get the guest state', () async {
      final cubit = PlannerCubit(
        FakePlannerRepository(),
        FakeAuthRepository(initial: const AuthState.guest()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.guest, isTrue);
      await cubit.close();
    });
  });
}
