import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthStateNotifier', () {
    test('initial state is unauthenticated', () {
      final notifier = AuthStateNotifier();
      expect(notifier.state, AuthStatus.unauthenticated);
    });

    test('signIn transitions to authenticated', () {
      final notifier = AuthStateNotifier();
      notifier.signIn();
      expect(notifier.state, AuthStatus.authenticated);
    });

    test('signOut transitions back to unauthenticated', () {
      final notifier = AuthStateNotifier();
      notifier.signIn();
      notifier.signOut();
      expect(notifier.state, AuthStatus.unauthenticated);
    });

    test('notifyListeners is called on signIn', () {
      final notifier = AuthStateNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.signIn();
      expect(notified, isTrue);
    });

    test('notifyListeners is called on signOut', () {
      final notifier = AuthStateNotifier();
      notifier.signIn();
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.signOut();
      expect(notified, isTrue);
    });
  });
}
