import 'package:flutter_test/flutter_test.dart';
import 'package:bus_express/core/error/result.dart';

void main() {
  group('Result<T>', () {
    test('Success holds data', () {
      const success = Success<String>('hello');
      expect(success.data, 'hello');
    });

    test('Success type check', () {
      const result = Success<int>(42);
      expect(result, isA<Success<int>>());
      if (result case Success(:final data)) {
        expect(data, 42);
      }
    });

    test('Failure holds message and optional error', () {
      final failure = Failure<int>('something went wrong', error: Exception('e'));
      expect(failure.message, 'something went wrong');
      expect(failure.error, isA<Exception>());
    });

    test('Failure type check', () {
      const result = Failure<String>('fail');
      expect(result, isA<Failure<String>>());
      if (result case Failure(:final message)) {
        expect(message, 'fail');
      }
    });

    test('Failure without error', () {
      const failure = Failure<int>('no error object');
      expect(failure.error, isNull);
    });

    test('Failure.log does not throw', () {
      const failure = Failure<void>('log test');
      expect(() => failure.log(), returnsNormally);
    });

    test('pattern matching works', () {
      Result<String> result = const Success('ok');
      final msg = switch (result) {
        Success(data: final d) => 'success: $d',
        Failure(message: final m) => 'failure: $m',
      };
      expect(msg, 'success: ok');

      result = const Failure('err');
      final msg2 = switch (result) {
        Success(data: final d) => 'success: $d',
        Failure(message: final m) => 'failure: $m',
      };
      expect(msg2, 'failure: err');
    });
  });
}
