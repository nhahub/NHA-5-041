import 'package:equatable/equatable.dart';

import '../domain/result.dart';

/// Every screen exposes one of: Loading, Data, Empty or Error (typed failure).
sealed class ViewState<T> extends Equatable {
  const ViewState();

  @override
  List<Object?> get props => [];
}

class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

class ViewData<T> extends ViewState<T> {
  const ViewData(this.data);
  final T data;

  @override
  List<Object?> get props => [data];
}

class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

class ViewError<T> extends ViewState<T> {
  const ViewError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
