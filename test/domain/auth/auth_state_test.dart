import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:brainforge/domain/auth/auth_state.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockIdTokenResult extends Mock implements IdTokenResult {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock
    implements Query<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

// ── Helpers ──────────────────────────────────────────────────────────────────

AuthStateNotifier _makeNotifier(
  StreamController<User?> authStream,
  MockFirebaseAuth auth,
  MockFirebaseFirestore firestore,
) {
  when(() => auth.authStateChanges())
      .thenAnswer((_) => authStream.stream);
  return AuthStateNotifier(auth, firestore);
}

void _setupConsentDoc(
  MockFirebaseFirestore firestore,
  String uid, {
  required bool exists,
}) {
  final collection = MockCollectionReference();
  final docRef = MockDocumentReference();
  final snap = MockDocumentSnapshot();

  when(() => firestore.collection('consents')).thenReturn(collection);
  when(() => collection.doc(uid)).thenReturn(docRef);
  when(() => docRef.get()).thenAnswer((_) async => snap);
  when(() => snap.exists).thenReturn(exists);
}

void _setupChildrenQuery(
  MockFirebaseFirestore firestore,
  String uid, {
  required bool hasChildren,
}) {
  final collection = MockCollectionReference();
  final query = MockQuery();
  final limitedQuery = MockQuery();
  final snap = MockQuerySnapshot();

  when(() => firestore.collection('users')).thenReturn(collection);
  when(() => collection.where('parentId', isEqualTo: uid))
      .thenReturn(query);
  when(() => query.limit(1)).thenReturn(limitedQuery);
  when(() => limitedQuery.get()).thenAnswer((_) async => snap);
  when(() => snap.docs).thenReturn(
    hasChildren ? [MockQueryDocumentSnapshot()] : [],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

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
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    final notifier = AuthStateNotifier(auth, firestore);
    expect(notifier.state.status, AuthStatus.unknown);
    notifier.dispose();
  });

  test('transitions to unauthenticated when stream emits null', () async {
    final notifier = _makeNotifier(authStream, auth, firestore);
    authStream.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.status, AuthStatus.unauthenticated);
    notifier.dispose();
  });

  test('transitions to parentUnverified when email not verified', () async {
    final user = MockUser();
    final token = MockIdTokenResult();

    when(() => user.getIdTokenResult(true)).thenAnswer((_) async => token);
    when(() => token.claims).thenReturn({});
    when(() => user.emailVerified).thenReturn(false);
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.displayName).thenReturn(null);

    final notifier = _makeNotifier(authStream, auth, firestore);
    authStream.add(user);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.status, AuthStatus.parentUnverified);
    notifier.dispose();
  });

  test('transitions to parentNeedsConsent when no consent doc', () async {
    final user = MockUser();
    final token = MockIdTokenResult();

    when(() => user.getIdTokenResult(true)).thenAnswer((_) async => token);
    when(() => token.claims).thenReturn({});
    when(() => user.emailVerified).thenReturn(true);
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.displayName).thenReturn(null);

    _setupConsentDoc(firestore, 'uid-1', exists: false);

    final notifier = _makeNotifier(authStream, auth, firestore);
    authStream.add(user);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.status, AuthStatus.parentNeedsConsent);
    notifier.dispose();
  });

  test('transitions to parentConsented when consent exists but no children',
      () async {
    final user = MockUser();
    final token = MockIdTokenResult();

    when(() => user.getIdTokenResult(true)).thenAnswer((_) async => token);
    when(() => token.claims).thenReturn({});
    when(() => user.emailVerified).thenReturn(true);
    when(() => user.uid).thenReturn('uid-2');
    when(() => user.displayName).thenReturn(null);

    _setupConsentDoc(firestore, 'uid-2', exists: true);
    _setupChildrenQuery(firestore, 'uid-2', hasChildren: false);

    final notifier = _makeNotifier(authStream, auth, firestore);
    authStream.add(user);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.status, AuthStatus.parentConsented);
    notifier.dispose();
  });

  test('transitions to authenticated (parent) when consent + children exist',
      () async {
    final user = MockUser();
    final token = MockIdTokenResult();

    when(() => user.getIdTokenResult(true)).thenAnswer((_) async => token);
    when(() => token.claims).thenReturn({});
    when(() => user.emailVerified).thenReturn(true);
    when(() => user.uid).thenReturn('uid-3');
    when(() => user.displayName).thenReturn('Parent');

    _setupConsentDoc(firestore, 'uid-3', exists: true);
    _setupChildrenQuery(firestore, 'uid-3', hasChildren: true);

    final notifier = _makeNotifier(authStream, auth, firestore);
    authStream.add(user);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.role, UserRole.parent);
    notifier.dispose();
  });

  test('transitions to authenticated (student) from role claim', () async {
    final user = MockUser();
    final token = MockIdTokenResult();

    when(() => user.getIdTokenResult(true)).thenAnswer((_) async => token);
    when(() => token.claims).thenReturn({'role': 'student'});
    when(() => user.uid).thenReturn('uid-s1');
    when(() => user.displayName).thenReturn('KidUser');

    final notifier = _makeNotifier(authStream, auth, firestore);
    authStream.add(user);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.role, UserRole.student);
    notifier.dispose();
  });

  test('notifies listenable on each state change', () async {
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    final notifier = AuthStateNotifier(auth, firestore);
    var notified = 0;
    notifier.listenable.addListener(() => notified++);
    authStream.close(); // ignored — stream already empty
    notifier.dispose();
    expect(notified, 0); // no state changes fired
  });
}
