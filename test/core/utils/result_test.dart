import 'package:brainforge/core/errors/failures.dart';
import 'package:brainforge/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('isSuccess returns true', () {
        const result = Success(42);
        expect(result.isSuccess, isTrue);
        expect(result.isError, isFalse);
      });

      test('dataOrNull returns data', () {
        const result = Success('hello');
        expect(result.dataOrNull, 'hello');
      });

      test('failureOrNull returns null', () {
        const result = Success(1);
        expect(result.failureOrNull, isNull);
      });

      test('fold calls onSuccess', () {
        const result = Success(10);
        final output = result.fold(
          onSuccess: (data) => 'got $data',
          onError: (_) => 'error',
        );
        expect(output, 'got 10');
      });
    });

    group('Err', () {
      test('isError returns true', () {
        const result = Err<int>(NetworkFailure());
        expect(result.isError, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('dataOrNull returns null', () {
        const result = Err<String>(AuthFailure());
        expect(result.dataOrNull, isNull);
      });

      test('failureOrNull returns failure', () {
        const failure = ServerFailure('oops');
        const result = Err<int>(failure);
        expect(result.failureOrNull, failure);
      });

      test('fold calls onError', () {
        const result = Err<int>(ValidationFailure('bad input'));
        final output = result.fold(
          onSuccess: (_) => 'success',
          onError: (f) => 'error: ${f.message}',
        );
        expect(output, 'error: bad input');
      });
    });
  });
}
