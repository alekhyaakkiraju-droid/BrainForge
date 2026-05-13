import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/router/app_router.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AuthStateNotifier _notifierForStatus(AuthStatus status) {
  final notifier = AuthStateNotifier();
  if (status == AuthStatus.authenticated) notifier.signIn();
  return notifier;
}

// Helper to build a full app under test.
Widget buildApp({required AuthStatus initialAuth}) => ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => _notifierForStatus(initialAuth),
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

    testWidgets('tap targets are at least ${AppSpacing.minTouchTarget}dp',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    });
  });

  group('AuthStateNotifier — redirect', () {
    testWidgets('unauthenticated user sees login screen', (tester) async {
      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.unauthenticated),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign In (Demo)'), findsOneWidget);
    });

    testWidgets('authenticated user skips login', (tester) async {
      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quest Board'), findsOneWidget);
      expect(find.text('Sign In (Demo)'), findsNothing);
    });
  });

  group('State preservation', () {
    testWidgets(
        'counter persists when navigating between tabs', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildApp(initialAuth: AuthStatus.authenticated),
      );
      await tester.pumpAndSettle();

      // Tap + on Quest Board counter
      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.add).first,
      );
      await tester.pumpAndSettle();

      // Navigate to Focus Timer
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      // Navigate back to Quest Board
      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pumpAndSettle();

      // Counter should still be 1
      expect(find.text('1'), findsOneWidget);
    });
  });
}
