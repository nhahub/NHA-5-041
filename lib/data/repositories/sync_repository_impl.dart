import 'dart:async';

import '../../core/clock.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import '../sync/cloud_favorites_store.dart';

/// Backup/restore of favorites. Policy (see docs/SYNC.md): last write wins per
/// meal; removals delete the cloud document; restore only when local is empty.
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required FavoritesRepository local,
    required CloudFavoritesStore cloud,
    Clock clock = const Clock(),
  }) : _local = local,
       _cloud = cloud,
       _clock = clock;

  final FavoritesRepository _local;
  final CloudFavoritesStore _cloud;
  final Clock _clock;

  final Map<String, SyncStatus> _status = {};
  final _controller =
      StreamController<MapEntry<String, SyncStatus>>.broadcast();

  @override
  SyncStatus statusFor(String userId) => _status[userId] ?? const SyncStatus();

  @override
  Stream<SyncStatus> watchStatus(String userId) async* {
    yield statusFor(userId);
    yield* _controller.stream.where((e) => e.key == userId).map((e) => e.value);
  }

  void _set(String userId, SyncStatus s) {
    _status[userId] = s;
    _controller.add(MapEntry(userId, s));
  }

  @override
  Future<Result<int>> backup(String userId) async {
    if (userId.isEmpty) return const Result.err(GuestFailure());
    _set(
      userId,
      statusFor(userId).copyWith(phase: SyncPhase.syncing, clearMessage: true),
    );
    try {
      final local = await _local.getAll(userId);
      final cloudIds = await _cloud.listIds(userId);
      final localIds = local.map((m) => m.id).toSet();
      await _cloud.applyChanges(
        userId,
        upserts: local,
        deletes: cloudIds.difference(localIds).toList(),
      );
      _set(
        userId,
        SyncStatus(phase: SyncPhase.idle, lastSyncedAt: _clock.now()),
      );
      return Result.ok(local.length);
    } on Failure catch (f) {
      _set(
        userId,
        statusFor(userId).copyWith(phase: SyncPhase.error, message: f.message),
      );
      return Result.err(f);
    }
  }

  @override
  Future<Result<int>> restoreIfEmpty(String userId) async {
    if (userId.isEmpty) return const Result.err(GuestFailure());
    try {
      if ((await _local.getAll(userId)).isNotEmpty) return const Result.ok(0);
      _set(
        userId,
        statusFor(userId)
            .copyWith(phase: SyncPhase.restoring, clearMessage: true),
      );
      final remote = await _cloud.fetchAll(userId);
      for (final meal in remote) {
        await _local.add(userId, meal); // idempotent upsert
      }
      _set(
        userId,
        SyncStatus(phase: SyncPhase.idle, lastSyncedAt: _clock.now()),
      );
      return Result.ok(remote.length);
    } on Failure catch (f) {
      _set(
        userId,
        statusFor(userId).copyWith(phase: SyncPhase.error, message: f.message),
      );
      return Result.err(f);
    }
  }
}
