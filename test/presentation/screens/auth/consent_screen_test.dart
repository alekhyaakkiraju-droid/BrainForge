import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:brainforge/data/services/functions_service.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/screens/auth/consent_screen.dart';

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
  testWidgets('Continue button does nothing when checkbox is unchecked',
      (tester) async {
    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();

    // Tap without checking the box — onPressed is null.
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();

    expect(find.text('Saving consent…'), findsNothing);
  });

  testWidgets('Continue button is enabled after checkbox is checked',
      (tester) async {
    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('calls recordConsent when checked and tapped', (tester) async {
    final functions = MockFunctionsService();
    when(() => functions.recordConsent()).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrap(const ConsentScreen(), functions: functions),
    );
    await tester.pump();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pump();

    verify(() => functions.recordConsent()).called(1);
  });

  testWidgets('shows error message on FirebaseFunctionsException',
      (tester) async {
    final functions = MockFunctionsService();
    when(() => functions.recordConsent()).thenThrow(
      FirebaseFunctionsException(
        message: 'Consent recording failed.',
        code: 'internal',
      ),
    );

    await tester.pumpWidget(_wrap(const ConsentScreen(), functions: functions));
    await tester.pump();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Consent recording failed.'), findsOneWidget);
  });

  testWidgets('consent text mentions COPPA', (tester) async {
    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();
    expect(find.textContaining('COPPA'), findsOneWidget);
  });
}
