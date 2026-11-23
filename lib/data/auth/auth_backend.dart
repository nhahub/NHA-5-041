import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/user_and_plan.dart';
import '../../domain/result.dart';
import '../storage/secure_store.dart';

/// Thrown by backends; carries a Firebase-style error code.
class AuthBackendException implements Exception {
  const AuthBackendException(this.code);
  final String code;
}

/// Maps Firebase-style error codes to friendly typed failures.
AuthFailure mapAuthErrorCode(String code) => switch (code) {
  'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' =>
    const AuthFailure(AuthErrorKind.wrongPassword, 'Wrong email or password.'),
  'user-not-found' => const AuthFailure(
    AuthErrorKind.userNotFound,
    'No account found for this email.',
  ),
  'email-already-in-use' => const AuthFailure(
    AuthErrorKind.emailInUse,
    'This email is already registered.',
  ),
  'weak-password' => const AuthFailure(
    AuthErrorKind.weakPassword,
    'Password is too weak. Use at least 8 characters.',
  ),
  'invalid-email' => const AuthFailure(
    AuthErrorKind.invalidEmail,
    'That email address is not valid.',
  ),
  'network-request-failed' => const AuthFailure(
    AuthErrorKind.network,
    'No internet connection.',
  ),
  'too-many-requests' => const AuthFailure(
    AuthErrorKind.tooManyRequests,
    'Too many attempts. Please wait a bit and try again.',
  ),
  'cancelled' || 'canceled' || 'popup-closed-by-user' => const AuthFailure(
    AuthErrorKind.cancelled,
    'Sign-in was cancelled.',
  ),
  'google-not-configured' => const AuthFailure(
    AuthErrorKind.unknown,
    'Google Sign-In needs the Firebase project to be configured.',
  ),
  _ => const AuthFailure(
    AuthErrorKind.unknown,
    'Something went wrong. Try again.',
  ),
};

/// The identity provider behind [AuthRepositoryImpl].
abstract class AuthBackend {
  /// The user restored from the persisted session, if any.
  Future<AppUser?> restore();
  Future<AppUser> signUp(String name, String email, String password);
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}

class FirebaseAuthBackend implements AuthBackend {
  FirebaseAuthBackend([fb.FirebaseAuth? auth])
    : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;
  bool _googleReady = false;

  AppUser _map(fb.User u) => AppUser(
    uid: u.uid,
    displayName: u.displayName ?? '',
    email: u.email ?? '',
  );

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthBackendException(e.code);
    }
  }

  @override
  Future<AppUser?> restore() async {
    // Firebase persists the session; the first event carries the restored user.
    final user = await _auth.authStateChanges().first;
    return user == null ? null : _map(user);
  }

  @override
  Future<AppUser> signUp(String name, String email, String password) =>
      _wrap(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await cred.user!.updateDisplayName(name);
        await cred.user!.reload();
        return _map(_auth.currentUser ?? cred.user!);
      });

  @override
  Future<AppUser> signIn(String email, String password) => _wrap(() async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _map(cred.user!);
  });

  static const _serverClientId =
      '115235737148-nel8277dsicp2frf9065jr8pqqjpp6ut.apps.googleusercontent.com';

  @override
  Future<AppUser> signInWithGoogle() => _wrap(() async {
    try {
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize(
          serverClientId: _serverClientId,
        );
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthBackendException('google-not-configured');
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      return _map(cred.user!);
    } on GoogleSignInException catch (e) {
      throw AuthBackendException(
        e.code == GoogleSignInExceptionCode.canceled ? 'cancelled' : 'unknown',
      );
    }
  });

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google may never have been initialised; Firebase sign-out still runs.
    }
    await _auth.signOut();
  }
}

/// Offline development fallback used only when Firebase is not configured
/// (no `google-services.json`). Accounts live in secure storage as a salted
/// SHA-256 hash; plaintext passwords are never stored.
class LocalAuthBackend implements AuthBackend {
  LocalAuthBackend(this._store);

  final SecureStore _store;
  static const _sessionKey = 'local_auth_session';
  static const _accountsKey = 'local_auth_accounts';

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  Future<Map<String, dynamic>> _accounts() async {
    final raw = await _store.read(_accountsKey);
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveSession(AppUser u) =>
      _store.write(_sessionKey, jsonEncode(u.toJson()));

  @override
  Future<AppUser?> restore() async {
    final raw = await _store.read(_sessionKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> signUp(String name, String email, String password) async {
    final key = email.trim().toLowerCase();
    final accounts = await _accounts();
    if (accounts.containsKey(key)) {
      throw const AuthBackendException('email-already-in-use');
    }
    if (password.length < 8) throw const AuthBackendException('weak-password');
    final salt = base64Url.encode(
      List.generate(12, (_) => Random.secure().nextInt(256)),
    );
    final uid =
        'local-${sha256.convert(utf8.encode(key)).toString().substring(0, 16)}';
    accounts[key] = {
      'uid': uid,
      'name': name,
      'salt': salt,
      'hash': _hash(salt, password),
    };
    await _store.write(_accountsKey, jsonEncode(accounts));
    final user = AppUser(uid: uid, displayName: name, email: key);
    await _saveSession(user);
    return user;
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final key = email.trim().toLowerCase();
    final account = (await _accounts())[key] as Map<String, dynamic>?;
    if (account == null) throw const AuthBackendException('user-not-found');
    if (_hash(account['salt'] as String, password) != account['hash']) {
      throw const AuthBackendException('wrong-password');
    }
    final user = AppUser(
      uid: account['uid'] as String,
      displayName: account['name'] as String,
      email: key,
    );
    await _saveSession(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async =>
      throw const AuthBackendException('google-not-configured');

  @override
  Future<void> signOut() => _store.delete(_sessionKey);
}
