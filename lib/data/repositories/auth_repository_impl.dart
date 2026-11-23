import 'dart:async';
import 'dart:convert';

import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';
import '../auth/auth_backend.dart';
import '../storage/secure_store.dart';

/// Auth on top of an [AuthBackend]. Passwords are never stored here; only the
/// guest flag and a minimal user snapshot go to secure storage.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._backend, this._store);

  final AuthBackend _backend;
  final SecureStore _store;
  static const guestKey = 'is_guest';
  static const userKey = 'user_snapshot';

  AuthState _state = const AuthState.unknown();
  final _controller = StreamController<AuthState>.broadcast();

  @override
  AuthState get currentState => _state;

  @override
  Stream<AuthState> get authStateChanges async* {
    yield _state;
    yield* _controller.stream;
  }

  void _emit(AuthState s) {
    _state = s;
    _controller.add(s);
  }

  @override
  Future<AuthState> init() async {
    AppUser? user;
    try {
      user = await _backend.restore();
    } catch (_) {
      user = null;
    }
    if (user != null) {
      await _store.write(userKey, jsonEncode(user.toJson()));
      _emit(AuthState.authenticated(user));
    } else if (await _store.read(guestKey) == 'true') {
      _emit(const AuthState.guest());
    } else {
      _emit(const AuthState.unauthenticated());
    }
    return _state;
  }

  Future<Result<AppUser>> _run(Future<AppUser> Function() call) async {
    try {
      final user = await call();
      await _store.delete(guestKey);
      await _store.write(userKey, jsonEncode(user.toJson()));
      _emit(AuthState.authenticated(user));
      return Result.ok(user);
    } on AuthBackendException catch (e) {
      return Result.err(mapAuthErrorCode(e.code));
    } catch (_) {
      return Result.err(mapAuthErrorCode('unknown'));
    }
  }

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) => _run(() => _backend.signUp(name.trim(), email.trim(), password));

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) => _run(() => _backend.signIn(email.trim(), password));

  @override
  Future<Result<AppUser>> signInWithGoogle() => _run(_backend.signInWithGoogle);

  @override
  Future<void> continueAsGuest() async {
    await _store.write(guestKey, 'true');
    _emit(const AuthState.guest());
  }

  @override
  Future<void> signOut() async {
    try {
      await _backend.signOut();
    } catch (_) {
      // Local session is cleared regardless.
    }
    await _store.delete(guestKey);
    await _store.delete(userKey);
    _emit(const AuthState.unauthenticated());
  }
}
