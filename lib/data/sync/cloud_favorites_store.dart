import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/meal.dart';
import '../../domain/result.dart';

/// Remote copy of a user's favorites (Firestore: `users/{uid}/favorites/{mealId}`).
abstract class CloudFavoritesStore {
  Future<Set<String>> listIds(String uid);
  Future<List<Meal>> fetchAll(String uid);

  /// Applies upserts and deletes in batches of at most [batchLimit] ops.
  Future<void> applyChanges(
    String uid, {
    List<Meal> upserts = const [],
    List<String> deletes = const [],
  });
}

const batchLimit = 500;

class FirestoreFavoritesStore implements CloudFavoritesStore {
  FirestoreFavoritesStore([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'unavailable':
        case 'deadline-exceeded':
          throw const NetworkFailure();
        case 'permission-denied':
          throw const ServerFailure('Permission denied by cloud rules.');
        default:
          throw const ServerFailure('Cloud sync failed.');
      }
    }
  }

  @override
  Future<Set<String>> listIds(String uid) => _wrap(() async {
    final snap = await _col(uid).get();
    return snap.docs.map((d) => d.id).toSet();
  });

  @override
  Future<List<Meal>> fetchAll(String uid) => _wrap(() async {
    final snap = await _col(uid).get();
    return snap.docs
        .map((d) => Meal.fromJson({...d.data(), 'id': d.id}))
        .toList();
  });

  @override
  Future<void> applyChanges(
    String uid, {
    List<Meal> upserts = const [],
    List<String> deletes = const [],
  }) => _wrap(() async {
    final ops = <void Function(WriteBatch)>[
      for (final m in upserts)
        (b) => b.set(_col(uid).doc(m.id), {
          ...m.toJson()..remove('id'),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      for (final id in deletes) (b) => b.delete(_col(uid).doc(id)),
    ];
    for (var i = 0; i < ops.length; i += batchLimit) {
      final batch = _db.batch();
      for (final op in ops.skip(i).take(batchLimit)) {
        op(batch);
      }
      await batch.commit();
    }
  });
}

/// Used when Firebase is not configured (no `google-services.json`): every
/// call fails honestly so the UI shows "sync not configured" with Retry.
class UnavailableFavoritesStore implements CloudFavoritesStore {
  const UnavailableFavoritesStore();

  static const _failure = ServerFailure(
    'Cloud backup is not set up yet (Firebase is not configured).',
  );

  @override
  Future<Set<String>> listIds(String uid) async => throw _failure;

  @override
  Future<List<Meal>> fetchAll(String uid) async => throw _failure;

  @override
  Future<void> applyChanges(
    String uid, {
    List<Meal> upserts = const [],
    List<String> deletes = const [],
  }) async => throw _failure;
}

/// Used in tests.
class InMemoryFavoritesStore implements CloudFavoritesStore {
  final Map<String, Map<String, Meal>> data = {};
  Failure? failure;
  int batches = 0;

  Map<String, Meal> _of(String uid) => data.putIfAbsent(uid, () => {});

  void _check() {
    if (failure != null) throw failure!;
  }

  @override
  Future<Set<String>> listIds(String uid) async {
    _check();
    return _of(uid).keys.toSet();
  }

  @override
  Future<List<Meal>> fetchAll(String uid) async {
    _check();
    return _of(uid).values.toList();
  }

  @override
  Future<void> applyChanges(
    String uid, {
    List<Meal> upserts = const [],
    List<String> deletes = const [],
  }) async {
    _check();
    final total = upserts.length + deletes.length;
    batches += (total / batchLimit).ceil();
    for (final m in upserts) {
      _of(uid)[m.id] = m;
    }
    for (final id in deletes) {
      _of(uid).remove(id);
    }
  }
}
