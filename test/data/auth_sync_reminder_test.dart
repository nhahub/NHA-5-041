import 'package:flutter_test/flutter_test.dart';
import 'package:food_planner/core/clock.dart';
import 'package:food_planner/data/auth/auth_backend.dart';
import 'package:food_planner/data/local/app_database.dart';
import 'package:food_planner/data/reminders/reminder_service_impl.dart';
import 'package:food_planner/data/repositories/auth_repository_impl.dart';
import 'package:food_planner/data/repositories/favorites_repository_impl.dart';
import 'package:food_planner/data/repositories/sync_repository_impl.dart';
import 'package:food_planner/data/storage/secure_store.dart';
import 'package:food_planner/data/sync/cloud_favorites_store.dart';
import 'package:food_planner/domain/fakes/fakes.dart';
import 'package:food_planner/domain/models/meal.dart';
import 'package:food_planner/domain/models/user_and_plan.dart';
import 'package:food_planner/domain/repositories/repositories.dart';
import 'package:food_planner/domain/result.dart';

void main() {
  group('auth error mapping', () {
    test('Firebase codes map to typed failures', () {
      expect(
        mapAuthErrorCode('wrong-password').kind,
        AuthErrorKind.wrongPassword,
      );
      expect(
        mapAuthErrorCode('invalid-credential').kind,
        AuthErrorKind.wrongPassword,
      );
      expect(
        mapAuthErrorCode('user-not-found').kind,
        AuthErrorKind.userNotFound,
      );
      expect(
        mapAuthErrorCode('email-already-in-use').kind,
        AuthErrorKind.emailInUse,
      );
      expect(
        mapAuthErrorCode('weak-password').kind,
        AuthErrorKind.weakPassword,
      );
      expect(
        mapAuthErrorCode('network-request-failed').kind,
        AuthErrorKind.network,
      );
      expect(
        mapAuthErrorCode('too-many-requests').kind,
        AuthErrorKind.tooManyRequests,
      );
      expect(mapAuthErrorCode('cancelled').kind, AuthErrorKind.cancelled);
      expect(mapAuthErrorCode('???').kind, AuthErrorKind.unknown);
    });
  });

  group('AuthRepositoryImpl with the local backend', () {
    late MemorySecureStore store;
    late AuthRepositoryImpl repo;

    setUp(() {
      store = MemorySecureStore();
      repo = AuthRepositoryImpl(LocalAuthBackend(store), store);
    });

    test('cold start without a session is unauthenticated', () async {
      expect((await repo.init()).status, AuthStatus.unauthenticated);
    });

    test('sign up signs in and the session survives a restart', () async {
      final r = await repo.signUp(
        name: 'Mina',
        email: 'mina@example.com',
        password: 'password1',
      );
      expect(r.isOk, isTrue);
      expect(repo.currentState.isAuthenticated, isTrue);

      final restarted = AuthRepositoryImpl(LocalAuthBackend(store), store);
      final state = await restarted.init();
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.displayName, 'Mina');
    });

    test('passwords are never stored in plain text', () async {
      await repo.signUp(
        name: 'A',
        email: 'a@example.com',
        password: 'supersecret1',
      );
      expect(store.data.values.any((v) => v.contains('supersecret1')), isFalse);
    });

    test('wrong password and unknown user give friendly failures', () async {
      await repo.signUp(
        name: 'A',
        email: 'a@example.com',
        password: 'password1',
      );
      await repo.signOut();
      final wrong = await repo.signIn(
        email: 'a@example.com',
        password: 'nope-nope',
      );
      expect(
        (wrong.failureOrNull as AuthFailure).kind,
        AuthErrorKind.wrongPassword,
      );
      final missing = await repo.signIn(
        email: 'x@example.com',
        password: 'password1',
      );
      expect(
        (missing.failureOrNull as AuthFailure).kind,
        AuthErrorKind.userNotFound,
      );
    });

    test('duplicate email is rejected', () async {
      await repo.signUp(
        name: 'A',
        email: 'a@example.com',
        password: 'password1',
      );
      final dup = await repo.signUp(
        name: 'B',
        email: 'a@example.com',
        password: 'password2',
      );
      expect((dup.failureOrNull as AuthFailure).kind, AuthErrorKind.emailInUse);
    });

    test(
      'guest mode persists across restarts and sign out clears everything',
      () async {
        await repo.continueAsGuest();
        expect(repo.currentState.isGuest, isTrue);
        final restarted = AuthRepositoryImpl(LocalAuthBackend(store), store);
        expect((await restarted.init()).status, AuthStatus.guest);

        await restarted.signUp(
          name: 'A',
          email: 'a@example.com',
          password: 'password1',
        );
        expect(store.data.containsKey(AuthRepositoryImpl.guestKey), isFalse);
        await restarted.signOut();
        expect(restarted.currentState.status, AuthStatus.unauthenticated);
        expect(store.data.containsKey(AuthRepositoryImpl.userKey), isFalse);
      },
    );

    test(
      'Google sign-in without Firebase fails with a clear message',
      () async {
        final r = await repo.signInWithGoogle();
        expect(r.failureOrNull!.message, contains('Firebase'));
      },
    );
  });

  group('sync', () {
    late AppDatabase db;
    late FavoritesRepositoryImpl local;
    late InMemoryFavoritesStore cloud;
    late SyncRepositoryImpl sync;
    final clock = FixedClock(DateTime(2026, 11, 20, 12));

    setUp(() {
      db = AppDatabase.memory();
      local = FavoritesRepositoryImpl(FavoritesDao(db));
      cloud = InMemoryFavoritesStore();
      sync = SyncRepositoryImpl(local: local, cloud: cloud, clock: clock);
    });
    tearDown(() => db.close());

    test('backup pushes local favorites and records lastSyncedAt', () async {
      await local.add('u1', fakeMeals[0]);
      await local.add('u1', fakeMeals[1]);
      final r = await sync.backup('u1');
      expect(r.valueOrNull, 2);
      expect(cloud.data['u1']!.keys, {fakeMeals[0].id, fakeMeals[1].id});
      expect(sync.statusFor('u1').lastSyncedAt, clock.now());
    });

    test('removals delete the cloud document', () async {
      await local.add('u1', fakeMeals[0]);
      await sync.backup('u1');
      await local.remove('u1', fakeMeals[0].id);
      await sync.backup('u1');
      expect(cloud.data['u1'], isEmpty);
    });

    test('backup batches at 500 operations', () async {
      final many = List.generate(1001, (i) => Meal(id: 'm$i', name: 'Meal $i'));
      await cloud.applyChanges('u1', upserts: many);
      expect(cloud.batches, 3);
    });

    test('guest is rejected before any call', () async {
      expect((await sync.backup('')).failureOrNull, isA<GuestFailure>());
      expect(
        (await sync.restoreIfEmpty('')).failureOrNull,
        isA<GuestFailure>(),
      );
      expect(cloud.data, isEmpty);
    });

    test('restore when local is empty and cloud has data', () async {
      await cloud.applyChanges('u1', upserts: [fakeMeals[0]]);
      final r = await sync.restoreIfEmpty('u1');
      expect(r.valueOrNull, 1);
      expect((await local.getAll('u1')).single.id, fakeMeals[0].id);
    });

    test('restore is idempotent', () async {
      await cloud.applyChanges('u1', upserts: [fakeMeals[0]]);
      await sync.restoreIfEmpty('u1');
      await sync.restoreIfEmpty('u1');
      expect((await local.getAll('u1')).length, 1);
    });

    test('restore does nothing when local is not empty', () async {
      await local.add('u1', fakeMeals[1]);
      await cloud.applyChanges('u1', upserts: [fakeMeals[0]]);
      expect((await sync.restoreIfEmpty('u1')).valueOrNull, 0);
      expect((await local.getAll('u1')).single.id, fakeMeals[1].id);
    });

    test('cloud empty too: stays empty (UI shows the empty state)', () async {
      expect((await sync.restoreIfEmpty('u1')).valueOrNull, 0);
      expect(await local.getAll('u1'), isEmpty);
    });

    test('network failure sets an error status that a retry clears', () async {
      await local.add('u1', fakeMeals[0]);
      cloud.failure = const NetworkFailure();
      final failed = await sync.backup('u1');
      expect(failed.failureOrNull, isA<NetworkFailure>());
      expect(sync.statusFor('u1').phase, SyncPhase.error);
      cloud.failure = null;
      await sync.backup('u1');
      expect(sync.statusFor('u1').phase, SyncPhase.idle);
    });

    test('another account\'s cloud data is never touched', () async {
      await local.add('u1', fakeMeals[0]);
      await cloud.applyChanges('u2', upserts: [fakeMeals[1]]);
      await sync.backup('u1');
      expect(cloud.data['u2']!.keys, {fakeMeals[1].id});
    });
  });

  group('reminders', () {
    test('delay is the difference to now', () {
      final now = DateTime(2026, 11, 20, 12);
      expect(
        ReminderServiceImpl.delayUntil(DateTime(2026, 11, 20, 12, 30), now),
        const Duration(minutes: 30),
      );
    });

    test('past or equal time is rejected', () {
      final now = DateTime(2026, 11, 20, 12);
      expect(ReminderServiceImpl.delayUntil(now, now), isNull);
      expect(
        ReminderServiceImpl.delayUntil(DateTime(2026, 11, 19), now),
        isNull,
      );
    });

    test('unique name per planned meal', () {
      expect(ReminderServiceImpl.uniqueName(7), 'reminder-7');
    });

    test(
      'scheduling a past time returns a validation failure (no platform call)',
      () async {
        final service = ReminderServiceImpl(
          clock: FixedClock(DateTime(2026, 11, 20, 12)),
        );
        final r = await service.schedule(
          plannedId: 1,
          mealId: '1',
          mealName: 'x',
          at: DateTime(2026, 11, 20, 11),
        );
        expect(r.failureOrNull, isA<ValidationFailure>());
      },
    );

    test('fake service: schedule then cancel', () async {
      final fake = FakeReminderService();
      await fake.schedule(
        plannedId: 1,
        mealId: '1',
        mealName: 'x',
        at: DateTime(2027),
      );
      expect(fake.scheduled, isNotEmpty);
      await fake.cancel(1);
      expect(fake.scheduled, isEmpty);
    });
  });
}
