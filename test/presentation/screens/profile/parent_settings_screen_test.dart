import 'package:brainforge/data/services/deletion_request_service.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/screens/profile/parent_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeletionRequestService extends Mock
    implements DeletionRequestService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// FirebaseFirestore overrides ==; suppress lint for test-only mocking.
// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

AuthStateNotifier _stubParentNotifier(Ref ref) {
  final auth = MockFirebaseAuth();
  final firestore = MockFirebaseFirestore();
  // ignore: unnecessary_lambdas
  when(() => auth.authStateChanges())
      .thenAnswer((_) => const Stream.empty());
  return AuthStateNotifier(auth, firestore)
    ..state = const AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.parent,
      uid: 'parent-uid-1',
      displayName: 'Test Parent',
    );
}

Widget _wrap(Widget child, {DeletionRequestService? service}) => ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_stubParentNotifier),
        if (service != null)
          deletionRequestServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('shows CircularProgressIndicator while loading', (tester) async {
    final service = MockDeletionRequestService();
    // ignore: unnecessary_lambdas
    when(() => service.fetchChildProfiles('parent-uid-1'))
        .thenAnswer((_) => Future<List<ChildProfile>>.delayed(
              const Duration(seconds: 5),
              () => [],
            ));

    await tester.pumpWidget(
      _wrap(const ParentSettingsScreen(), service: service),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows "No child profiles found" when list is empty',
      (tester) async {
    final service = MockDeletionRequestService();
    // ignore: unnecessary_lambdas
    when(() => service.fetchChildProfiles('parent-uid-1'))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(
      _wrap(const ParentSettingsScreen(), service: service),
    );
    await tester.pumpAndSettle();

    expect(find.text('No child profiles found.'), findsOneWidget);
  });

  testWidgets('renders child card with username and Delete button',
      (tester) async {
    final service = MockDeletionRequestService();
    // ignore: unnecessary_lambdas
    when(() => service.fetchChildProfiles('parent-uid-1'))
        .thenAnswer((_) async => [
              const ChildProfile(
                uid: 'child-1',
                username: 'spacecat',
                avatarId: 'cat',
                ageRange: '8-10',
              ),
            ]);

    await tester.pumpWidget(
      _wrap(const ParentSettingsScreen(), service: service),
    );
    await tester.pumpAndSettle();

    expect(find.text('spacecat'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('confirmation dialog appears on Delete tap', (tester) async {
    final service = MockDeletionRequestService();
    // ignore: unnecessary_lambdas
    when(() => service.fetchChildProfiles('parent-uid-1'))
        .thenAnswer((_) async => [
              const ChildProfile(
                uid: 'child-1',
                username: 'spacecat',
                avatarId: 'cat',
                ageRange: '8-10',
              ),
            ]);

    await tester.pumpWidget(
      _wrap(const ParentSettingsScreen(), service: service),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Child Data'), findsOneWidget);
    expect(find.textContaining('Type "spacecat" to confirm'), findsOneWidget);
  });

  testWidgets('Delete button in dialog is disabled until username matches',
      (tester) async {
    final service = MockDeletionRequestService();
    // ignore: unnecessary_lambdas
    when(() => service.fetchChildProfiles('parent-uid-1'))
        .thenAnswer((_) async => [
              const ChildProfile(
                uid: 'child-1',
                username: 'spacecat',
                avatarId: 'cat',
                ageRange: '8-10',
              ),
            ]);

    await tester.pumpWidget(
      _wrap(const ParentSettingsScreen(), service: service),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Wrong username — confirm button should be disabled (onPressed == null).
    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pump();

    final confirmButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Delete permanently'),
    );
    expect(confirmButton.onPressed, isNull);

    // Correct username — confirm button becomes enabled.
    await tester.enterText(find.byType(TextField), 'spacecat');
    await tester.pump();

    final enabledButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Delete permanently'),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
