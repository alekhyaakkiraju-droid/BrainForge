import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// Using a sealed class hierarchy ensures every call-site handles all
/// failure variants — the compiler enforces exhaustiveness.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'A network error occurred.']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'A local storage error occurred.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
