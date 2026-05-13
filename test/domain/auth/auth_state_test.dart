import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:brainforge/domain/auth/auth_state.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// FirebaseFirestore overrides ==; suppress lint for test-only mocking.
// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ── Tests ─────────────────────────────────────────────────────────────────────

/// Full state-resolution flows (parentUnverified, parentNeedsConsent, etc.)
/// depend on sealed Firestore chain types that cannot be mocked directly.
/// Those paths are exercised end-to-end by the redirect tests in
/// [app_shell_test.dart] via [_TestAuthNotifier].
///
/// These tests focus on the stream boundary and [AuthState] value semantics.
void main() {
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late StreamController<User?> authStream;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    authStream = StreamController<User?>.broadcast();
  });

  tearDown(() => authStream.close());

  test('initial state is AuthStatus.unknown', () {
    // ignore: unnecessary_lambdas
    when(() => auth.authStateChanges()).thenReturn(const Stream.empty());
    final notifier = AuthStateNotifier(auth, firestore);
    expect(notifier.state.status, AuthStatus.unknown);
    notifier.dispose();
  });

  test('transitions to unauthenticated when stream emits null', () async {
    // ignore: unnecessary_lambdas
    when(() => auth.authStateChanges()).thenReturn(authStream.stream);
    final notifier = AuthStateNotifier(auth, firestore);

    authStream.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.status, AuthStatus.unauthenticated);
    notifier.dispose();
  });

  test('listenable notifies on unauthenticated transition', () async {
    // ignore: unnecessary_lambdas
    when(() => auth.authStateChanges()).thenReturn(authStream.stream);
    final notifier = AuthStateNotifier(auth, firestore);

    var count = 0;
    notifier.listenable.addListener(() => count++);

    authStream.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(count, 1);
    notifier.dispose();
  });

  test('AuthState equality holds for same fields', () {
    const a = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.parent,
      uid: 'u1',
    );
    const b = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.parent,
      uid: 'u1',
    );
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('AuthState inequality when fields differ', () {
    const a = AuthState(status: AuthStatus.authenticated, uid: 'u1');
    const b = AuthState(status: AuthStatus.unauthenticated, uid: 'u1');
    expect(a, isNot(equals(b)));
  });

  test('AuthState.copyWith overrides specified fields', () {
    const original = AuthState(
      status: AuthStatus.parentUnverified,
      uid: 'u1',
    );
    final updated = original.copyWith(
      status: AuthStatus.authenticated,
      role: UserRole.parent,
    );
    expect(updated.status, AuthStatus.authenticated);
    expect(updated.role, UserRole.parent);
    expect(updated.uid, 'u1');
  });
}
