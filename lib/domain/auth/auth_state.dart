import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Auth state notifier — also a [ChangeNotifier] so GoRouter's
/// [refreshListenable] triggers re-evaluation of redirects on sign in/out.
class AuthStateNotifier extends StateNotifier<AuthStatus>
    with ChangeNotifier {
  AuthStateNotifier() : super(AuthStatus.unauthenticated);

  void signIn() {
    state = AuthStatus.authenticated;
    notifyListeners();
  }

  void signOut() {
    state = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthStatus>(
  (ref) => AuthStateNotifier(),
);
