import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/router/app_router.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// FirebaseFirestore overrides ==; suppress lint for test-only mocking.
// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

/// Subclass that starts with a fixed [AuthState] without any real Firebase
/// calls — the stream is empty so [_resolveState] is never invoked.
class _TestAuthNotifier extends AuthStateNotifier {
  _TestAuthNotifier(
    AuthState initial,
    MockFirebaseAuth auth,
    MockFirebaseFirestore firestore,
  ) : super(auth, firestore) {
    state = initial;
  }
}

AuthStateNotifier _notifierWithStatus(AuthStatus status, Ref ref) {
  final auth = MockFirebaseAuth();
  final firestore = MockFirebaseFirestore();
  // ignore: unnecessary_lambdas
  when(() => auth.authStateChanges()).thenReturn(const Stream.empty());
  return _TestAuthNotifier(
    AuthState(
      status: status,
      role: status == AuthStatus.authenticated ? UserRole.parent : null,
    ),
    auth,
    firestore,
  );
}

Widget buildApp({required AuthStatus initialAuth}) => ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          // ignore: unnecessary_lambdas
          (ref) => _notifierWithStatus(initialAuth, ref),
        ),
      ],
      child: Consumer(
        builder: (_, ref, __) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: ref.watch(appRouterProvider),
        ),
      ),
    );

void main() {
  group('AppShell — navigation', () {
    testWidgets('bottom bar shown on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('side rail shown on wide screen', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets(
        'tap targets are at least ${AppSpacing.minTouchTarget}dp',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(
        bar.height,
        greaterThanOrEqualTo(AppSpacing.minTouchTarget),
      );
    });
  });

  group('AuthStateNotifier — redirect', () {
    testWidgets('unauthenticated user sees login screen', (tester) async {
      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.unauthenticated),
      );
      await tester.pumpAndSettle();

      expect(find.text('BrainForge'), findsOneWidget);
      expect(find.text('Parent sign-in'), findsOneWidget);
    });

    testWidgets('authenticated user sees quest board', (tester) async {
      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quest Board'), findsOneWidget);
      expect(find.text('Parent sign-in'), findsNothing);
    });

    testWidgets('parentUnverified user sees verify-email screen',
        (tester) async {
      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.parentUnverified),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check your inbox'), findsOneWidget);
    });

    testWidgets('parentNeedsConsent user sees consent screen',
        (tester) async {
      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.parentNeedsConsent),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parental Consent'), findsOneWidget);
    });

    testWidgets('parentConsented user sees create-child screen',
        (tester) async {
      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.parentConsented),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Child Profile'), findsOneWidget);
    });
  });

  group('State preservation', () {
    testWidgets('counter persists when navigating between tabs',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.add).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
