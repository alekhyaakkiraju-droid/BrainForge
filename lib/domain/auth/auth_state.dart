import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus {
  /// Firebase has not yet resolved the initial auth state.
  unknown,

  /// No user is signed in.
  unauthenticated,

  /// Parent account created but email not yet verified.
  parentUnverified,

  /// Email verified but parental consent not yet recorded.
  parentNeedsConsent,

  /// Consent recorded; parent must create at least one child profile.
  parentConsented,

  /// Fully authenticated (parent with ≥1 child, or student).
  authenticated,
}

enum UserRole { parent, student }

class AuthState {
  const AuthState({
    required this.status,
    this.role,
    this.uid,
    this.displayName,
  });

  static const initial = AuthState(status: AuthStatus.unknown);
  static const unauthenticated =
      AuthState(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final UserRole? role;
  final String? uid;
  final String? displayName;

  AuthState copyWith({
    AuthStatus? status,
    UserRole? role,
    String? uid,
    String? displayName,
  }) =>
      AuthState(
        status: status ?? this.status,
        role: role ?? this.role,
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          status == other.status &&
          role == other.role &&
          uid == other.uid &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(status, role, uid, displayName);
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._auth, this._firestore) : super(AuthState.initial) {
    _subscription =
        _auth.authStateChanges().listen(_onFirebaseAuthChange);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  late final StreamSubscription<User?> _subscription;

  /// Pass to GoRouter's [refreshListenable].
  final listenable = _AuthListenable();

  Future<void> _onFirebaseAuthChange(User? user) async {
    if (user == null) {
      _set(AuthState.unauthenticated);
      return;
    }
    await _resolveState(user);
  }

  Future<void> _resolveState(User user) async {
    // Force-refresh so latest custom claims are included.
    final token = await user.getIdTokenResult(true);
    final role = token.claims?['role'] as String?;

    if (role == 'student') {
      _set(AuthState(
        status: AuthStatus.authenticated,
        role: UserRole.student,
        uid: user.uid,
        displayName: user.displayName,
      ));
      return;
    }

    if (!user.emailVerified) {
      _set(AuthState(
        status: AuthStatus.parentUnverified,
        uid: user.uid,
      ));
      return;
    }

    final consent =
        await _firestore.collection('consents').doc(user.uid).get();
    if (!consent.exists) {
      _set(AuthState(
        status: AuthStatus.parentNeedsConsent,
        uid: user.uid,
      ));
      return;
    }

    // Parent has consent — check whether they've created a child yet.
    final children = await _firestore
        .collection('users')
        .where('parentId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (children.docs.isEmpty) {
      _set(AuthState(
        status: AuthStatus.parentConsented,
        role: UserRole.parent,
        uid: user.uid,
      ));
      return;
    }

    _set(AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.parent,
      uid: user.uid,
      displayName: user.displayName,
    ));
  }

  void _set(AuthState next) {
    state = next;
    listenable._notify();
  }

  /// Re-evaluates state after consent is recorded or a child is created.
  Future<void> refresh() async {
    final user = _auth.currentUser;
    if (user != null) await _resolveState(user);
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    listenable.dispose();
    super.dispose();
  }
}

/// Thin [ChangeNotifier] used only as a [Listenable] for GoRouter.
class _AuthListenable extends ChangeNotifier {
  void _notify() => notifyListeners();
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  ),
);
