import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Drives authentication-state transitions.
///
/// Exposes [listenable] — a plain [ChangeNotifier] — so that GoRouter's
/// [refreshListenable] can trigger redirect re-evaluation on sign in/out
/// without conflicting with [StateNotifier]'s own [addListener] signature.
class AuthStateNotifier extends StateNotifier<AuthStatus> {
  AuthStateNotifier() : super(AuthStatus.unauthenticated);

  /// Pass this to GoRouter's [refreshListenable].
  final listenable = _AuthListenable();

  void signIn() {
    state = AuthStatus.authenticated;
    listenable._notify();
  }

  void signOut() {
    state = AuthStatus.unauthenticated;
    listenable._notify();
  }

  @override
  void dispose() {
    listenable.dispose();
    super.dispose();
  }
}

/// Thin [ChangeNotifier] wrapper used only as a [Listenable] for GoRouter.
class _AuthListenable extends ChangeNotifier {
  void _notify() => notifyListeners();
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthStatus>(
  (ref) => AuthStateNotifier(),
);
