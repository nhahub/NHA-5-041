import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

class AuthFormState extends Equatable {
  const AuthFormState({this.loading = false, this.error, this.success = false});

  final bool loading;
  final String? error;
  final bool success;

  @override
  List<Object?> get props => [loading, error, success];
}

/// ViewModel for the login and sign-up screens.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit(this._auth) : super(const AuthFormState());

  final AuthRepository _auth;

  Future<void> _run<T>(Future<Result<T>> Function() call) async {
    if (state.loading) return;
    emit(const AuthFormState(loading: true));
    final result = await call();
    result.when(
      ok: (_) => emit(const AuthFormState(success: true)),
      err: (f) {
        // Cancelling Google sign-in is not an error worth showing.
        final cancelled = f is AuthFailure && f.kind == AuthErrorKind.cancelled;
        emit(AuthFormState(error: cancelled ? null : f.message));
      },
    );
  }

  Future<void> signIn(String email, String password) =>
      _run(() => _auth.signIn(email: email, password: password));

  Future<void> signUp(String name, String email, String password) =>
      _run(() => _auth.signUp(name: name, email: email, password: password));

  Future<void> google() => _run(_auth.signInWithGoogle);

  Future<void> continueAsGuest() => _auth.continueAsGuest();
}
