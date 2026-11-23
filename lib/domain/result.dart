import 'package:equatable/equatable.dart';

/// Typed failures shared by every repository.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'The server had a problem.']);
}

class EmptyFailure extends Failure {
  const EmptyFailure([super.message = 'Nothing found.']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Unexpected data received.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not save data.']);
}

class GuestFailure extends Failure {
  const GuestFailure([super.message = 'Sign in to use this feature.']);
}

class DuplicateFailure extends Failure {
  const DuplicateFailure([super.message = 'Already added.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid value.']);
}

enum AuthErrorKind {
  wrongPassword,
  userNotFound,
  emailInUse,
  weakPassword,
  invalidEmail,
  network,
  tooManyRequests,
  cancelled,
  unknown,
}

class AuthFailure extends Failure {
  const AuthFailure(this.kind, super.message);

  final AuthErrorKind kind;

  @override
  List<Object?> get props => [kind, message];
}

sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final failure) => err(failure),
  };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
