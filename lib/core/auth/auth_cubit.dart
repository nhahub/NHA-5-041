import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';

/// Exposes the [AuthState] to the UI and the router.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(_repo.currentState) {
    _sub = _repo.authStateChanges.listen(emit);
  }

  final AuthRepository _repo;
  late final StreamSubscription<AuthState> _sub;

  bool get isGuest => state.isGuest;
  bool get isSignedIn => state.isAuthenticated;

  Future<void> continueAsGuest() => _repo.continueAsGuest();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
