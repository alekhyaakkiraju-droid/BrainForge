import 'package:brainforge/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure subclasses', () {
    test('NetworkFailure carries default message', () {
      const failure = NetworkFailure();
      expect(failure.message, 'A network error occurred.');
    });

    test('AuthFailure carries custom message', () {
      const failure = AuthFailure('Token expired');
      expect(failure.message, 'Token expired');
    });

    test('Equality holds for same type and message', () {
      const a = ServerFailure('oops');
      const b = ServerFailure('oops');
      expect(a, equals(b));
    });

    test('Equality fails for different messages', () {
      const a = ServerFailure('oops');
      const b = ServerFailure('other');
      expect(a, isNot(equals(b)));
    });

    test('Different subtypes are not equal', () {
      const a = NetworkFailure('x');
      const b = ServerFailure('x');
      expect(a, isNot(equals(b)));
    });
  });
}
