import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/view_state.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/result.dart';

class FavoritesState extends Equatable {
  const FavoritesState({this.guest = false, this.view = const ViewLoading()});

  final bool guest;
  final ViewState<List<Meal>> view;

  @override
  List<Object?> get props => [guest, view];
}

/// Reactive list of the current user's favorites (newest first). Switching
/// accounts re-subscribes, so users never see each other's data.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._favorites, this._auth) : super(const FavoritesState()) {
    _authSub = _auth.authStateChanges.listen(_onAuth);
  }

  final FavoritesRepository _favorites;
  final AuthRepository _auth;
  late final StreamSubscription<AuthState> _authSub;
  StreamSubscription<List<Meal>>? _favSub;

  void _onAuth(AuthState s) {
    _favSub?.cancel();
    final uid = s.uid;
    if (uid == null) {
      emit(FavoritesState(guest: s.isGuest, view: const ViewEmpty()));
      return;
    }
    emit(const FavoritesState());
    _favSub = _favorites
        .watchFavorites(uid)
        .listen(
          (list) => emit(
            FavoritesState(
              view: list.isEmpty ? const ViewEmpty() : ViewData(list),
            ),
          ),
          onError: (Object _) =>
              emit(const FavoritesState(view: ViewError(StorageFailure()))),
        );
  }

  Future<Result<void>> remove(String mealId) async {
    final uid = _auth.currentState.uid;
    if (uid == null) return const Result.err(GuestFailure());
    return _favorites.remove(uid, mealId);
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    _favSub?.cancel();
    return super.close();
  }
}
