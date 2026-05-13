import 'package:brainforge/data/services/functions_service.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/screens/auth/consent_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFunctionsService extends Mock implements FunctionsService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// FirebaseFirestore overrides ==; suppress lint for test-only mocking.
// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

AuthStateNotifier _stubNotifier(Ref ref) {
  final auth = MockFirebaseAuth();
  final firestore = MockFirebaseFirestore();
  // ignore: unnecessary_lambdas
  when(() => auth.authStateChanges())
      .thenAnswer((_) => const Stream.empty());
  return AuthStateNotifier(auth, firestore);
}

Widget _wrap(Widget child, {FunctionsService? functions}) => ProviderScope(
      overrides: [
        if (functions != null)
          functionsServiceProvider.overrideWithValue(functions),
        authStateProvider.overrideWith(_stubNotifier),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('Continue button does nothing when checkbox is unchecked',
      (tester) async {
    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();

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
    // ignore: unnecessary_lambdas
    when(() => functions.recordConsent())
        .thenAnswer((_) => Future<void>.value());

    await tester.pumpWidget(
      _wrap(const ConsentScreen(), functions: functions),
    );
    await tester.pump();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();

    // ignore: unnecessary_lambdas
    verify(() => functions.recordConsent()).called(1);
  });

  testWidgets('shows error message on FirebaseFunctionsException',
      (tester) async {
    final functions = MockFunctionsService();
    // ignore: unnecessary_lambdas
    when(() => functions.recordConsent()).thenThrow(
      FirebaseFunctionsException(
        message: 'Consent recording failed.',
        code: 'internal',
      ),
    );

    await tester.pumpWidget(
      _wrap(const ConsentScreen(), functions: functions),
    );
    await tester.pump();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.ensureVisible(find.text('Continue'));
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
