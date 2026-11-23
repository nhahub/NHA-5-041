import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/connectivity/connectivity_cubit.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

class SyncUiState extends Equatable {
  const SyncUiState({
    this.phase = SyncPhase.idle,
    this.lastSyncedAt,
    this.message,
    this.pending = false,
    this.guest = false,
  });

  final SyncPhase phase;
  final DateTime? lastSyncedAt;
  final String? message;

  /// A change is waiting for connectivity.
  final bool pending;
  final bool guest;

  bool get busy => phase == SyncPhase.syncing || phase == SyncPhase.restoring;

  @override
  List<Object?> get props => [phase, lastSyncedAt, message, pending, guest];
}

/// Drives cloud sync (policy in docs/SYNC.md): restore on login when local is
/// empty, auto-backup after add/remove when signed in and online, queue and
/// retry when connectivity returns, manual "Sync now".
class SyncCubit extends Cubit<SyncUiState> {
  SyncCubit({
    required AuthRepository auth,
    required SyncRepository sync,
    required FavoritesRepository favorites,
    required ConnectivityCubit connectivity,
    this.debounce = const Duration(seconds: 2),
  }) : _auth = auth,
       _sync = sync,
       _favorites = favorites,
       _connectivity = connectivity,
       super(const SyncUiState()) {
    _authSub = _auth.authStateChanges.listen(_onAuth);
    _connSub = _connectivity.stream.listen(_onConnection);
  }

  final AuthRepository _auth;
  final SyncRepository _sync;
  final FavoritesRepository _favorites;
  final ConnectivityCubit _connectivity;
  final Duration debounce;

  late final StreamSubscription<AuthState> _authSub;
  late final StreamSubscription<ConnectionStatus> _connSub;
  StreamSubscription<SyncStatus>? _statusSub;
  StreamSubscription<List<Meal>>? _favSub;
  Timer? _timer;
  String? _uid;
  String? _signature;
  bool _pending = false;

  Future<void> _onAuth(AuthState s) async {
    _statusSub?.cancel();
    _favSub?.cancel();
    _timer?.cancel();
    _signature = null;
    _pending = false;
    _uid = s.uid;
    final uid = _uid;
    if (uid == null) {
      emit(SyncUiState(guest: s.isGuest));
      return;
    }
    emit(const SyncUiState());
    _statusSub = _sync.watchStatus(uid).listen(_onStatus);
    _favSub = _favorites.watchFavorites(uid).listen(_onFavorites);
    if (_connectivity.isOnline) await _sync.restoreIfEmpty(uid);
  }

  void _onStatus(SyncStatus s) {
    if (isClosed) return;
    emit(
      SyncUiState(
        phase: s.phase,
        lastSyncedAt: s.lastSyncedAt,
        message: s.message,
        pending: _pending,
      ),
    );
  }

  void _onFavorites(List<Meal> list) {
    final sig = (list.map((m) => m.id).toList()..sort()).join(',');
    if (_signature == null) {
      _signature = sig; // first snapshot: nothing changed yet
      return;
    }
    if (sig == _signature) return;
    _signature = sig;
    _scheduleBackup();
  }

  void _scheduleBackup() {
    _timer?.cancel();
    if (!_connectivity.isOnline) {
      _pending = true;
      emit(
        SyncUiState(
          phase: state.phase,
          lastSyncedAt: state.lastSyncedAt,
          pending: true,
        ),
      );
      return;
    }
    _timer = Timer(debounce, _backup);
  }

  Future<void> _backup() async {
    final uid = _uid;
    if (uid == null || isClosed) return;
    _pending = false;
    await _sync.backup(uid);
  }

  void _onConnection(ConnectionStatus c) {
    if (c == ConnectionStatus.online &&
        _uid != null &&
        (_pending || state.phase == SyncPhase.error)) {
      _backup();
    }
  }

  /// Manual "Sync now". No-op for guests (the UI shows a sign-in message).
  Future<Result<int>> syncNow() async {
    final uid = _uid;
    if (uid == null) return const Result.err(GuestFailure());
    if (!_connectivity.isOnline) {
      emit(
        SyncUiState(
          phase: SyncPhase.error,
          lastSyncedAt: state.lastSyncedAt,
          message:
              'You are offline. Changes will sync when you are back online.',
          pending: true,
        ),
      );
      _pending = true;
      return const Result.err(NetworkFailure());
    }
    return _sync.backup(uid);
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    _connSub.cancel();
    _statusSub?.cancel();
    _favSub?.cancel();
    _timer?.cancel();
    return super.close();
  }
}
