import '../errors/failures.dart';

/// Lightweight Either-style result type.
///
/// All repository and service methods return `Result<T>` so callers never
/// catch raw exceptions — they always handle typed [Failure] variants.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Err<T>;

  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Err() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Err(:final failure) => failure,
      };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onError,
  }) =>
      switch (this) {
        Success(:final data) => onSuccess(data),
        Err(:final failure) => onError(failure),
      };
}
