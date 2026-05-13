import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/screens/auth/parent_signup_screen.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

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

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        authStateProvider.overrideWith((_) => _stubNotifier()),
      ],
      child: MaterialApp(home: child),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders email, password, and confirm password fields',
      (tester) async {
    await tester.pumpWidget(_wrap(const ParentSignupScreen()));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Email address'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Confirm password'),
      findsOneWidget,
    );
  });

  testWidgets('shows validation error for empty email', (tester) async {
    await tester.pumpWidget(_wrap(const ParentSignupScreen()));
    await tester.pump();

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
  });

  testWidgets('shows validation error for invalid email', (tester) async {
    await tester.pumpWidget(_wrap(const ParentSignupScreen()));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'not-an-email',
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter a valid email.'), findsOneWidget);
  });

  testWidgets('shows validation error when passwords do not match',
      (tester) async {
    await tester.pumpWidget(_wrap(const ParentSignupScreen()));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'different',
    );

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('shows validation error for short password', (tester) async {
    await tester.pumpWidget(_wrap(const ParentSignupScreen()));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      '123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      '123',
    );

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(
      find.text('Password must be at least 6 characters.'),
      findsWidgets,
    );
  });

  testWidgets('has a link back to sign-in', (tester) async {
    await tester.pumpWidget(_wrap(const ParentSignupScreen()));
    await tester.pump();

    expect(
      find.text('Already have an account? Sign in'),
      findsOneWidget,
    );
  });
}
