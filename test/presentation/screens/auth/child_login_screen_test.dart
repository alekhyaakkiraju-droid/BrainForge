import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:brainforge/data/services/functions_service.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/screens/auth/child_login_screen.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockFunctionsService extends Mock implements FunctionsService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ── Helpers ───────────────────────────────────────────────────────────────────

AuthStateNotifier _stubNotifier() {
  final auth = MockFirebaseAuth();
  final firestore = MockFirebaseFirestore();
  when(() => auth.authStateChanges())
      .thenAnswer((_) => const Stream.empty());
  return AuthStateNotifier(auth, firestore);
}

Widget _wrap(Widget child, {FunctionsService? functions}) => ProviderScope(
      overrides: [
        if (functions != null)
          functionsServiceProvider.overrideWithValue(functions),
        authStateProvider.overrideWith((_) => _stubNotifier()),
      ],
      child: MaterialApp(home: child),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders username and PIN fields', (tester) async {
    await tester.pumpWidget(_wrap(const ChildLoginScreen()));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '4-digit PIN'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting empty form',
      (tester) async {
    await tester.pumpWidget(_wrap(const ChildLoginScreen()));
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your 4-digit PIN.'), findsOneWidget);
  });

  testWidgets('calls childSignIn with correct credentials', (tester) async {
    final functions = MockFunctionsService();
    when(() => functions.childSignIn(
              username: 'kid_one',
              pin: '1234',
            ))
        .thenAnswer((_) async => 'mock-token');

    await tester.pumpWidget(_wrap(const ChildLoginScreen(), functions: functions));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'kid_one',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '4-digit PIN'),
      '1234',
    );

    // Tap sign in — Firebase auth will throw because FirebaseAuth isn't
    // initialised in tests; we only verify the Cloud Function was called.
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    verify(() => functions.childSignIn(username: 'kid_one', pin: '1234'))
        .called(1);
  });

  testWidgets('shows friendly error for wrong PIN', (tester) async {
    final functions = MockFunctionsService();
    when(() => functions.childSignIn(
              username: any(named: 'username'),
              pin: any(named: 'pin'),
            ))
        .thenThrow(FirebaseFunctionsException(
          message: 'Incorrect PIN.',
          code: 'permission-denied',
        ));

    await tester.pumpWidget(
        _wrap(const ChildLoginScreen(), functions: functions));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'kid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '4-digit PIN'),
      '9999',
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
  });

  testWidgets('shows friendly error for unknown username', (tester) async {
    final functions = MockFunctionsService();
    when(() => functions.childSignIn(
              username: any(named: 'username'),
              pin: any(named: 'pin'),
            ))
        .thenThrow(FirebaseFunctionsException(
          message: 'Not found.',
          code: 'not-found',
        ));

    await tester.pumpWidget(
        _wrap(const ChildLoginScreen(), functions: functions));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'nobody',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '4-digit PIN'),
      '0000',
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Username not found. Check your username.'), findsOneWidget);
  });
}
