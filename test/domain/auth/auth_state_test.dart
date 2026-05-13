import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthStateNotifier', () {
    test('initial state is unauthenticated', () {
      final notifier = AuthStateNotifier();
      expect(notifier.state, AuthStatus.unauthenticated);
    });

    test('signIn transitions to authenticated', () {
      final notifier = AuthStateNotifier()..signIn();
      expect(notifier.state, AuthStatus.authenticated);
    });

    test('signOut transitions back to unauthenticated', () {
      final notifier = AuthStateNotifier()
        ..signIn()
        ..signOut();
      expect(notifier.state, AuthStatus.unauthenticated);
    });

    test('listenable notified on signIn', () {
      var notified = false;
      final notifier = AuthStateNotifier();
      notifier.listenable.addListener(() => notified = true);
      notifier.signIn();
      expect(notified, isTrue);
    });

    test('listenable notified on signOut', () {
      var notified = false;
      final notifier = AuthStateNotifier()..signIn();
      notifier.listenable.addListener(() => notified = true);
      notifier.signOut();
      expect(notified, isTrue);
    });
  });
}
