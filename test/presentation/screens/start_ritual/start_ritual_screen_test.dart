import 'package:audioplayers/audioplayers.dart';
import 'package:brainforge/core/router/app_router.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/screens/start_ritual/start_ritual_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

AuthStateNotifier _stubAuth(Ref ref) {
  final auth = MockFirebaseAuth();
  final firestore = MockFirebaseFirestore();
  // ignore: unnecessary_lambdas
  when(() => auth.authStateChanges()).thenAnswer((_) => const Stream.empty());
  return AuthStateNotifier(auth, firestore)
    ..state = const AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.student,
      uid: 'child-1',
    );
}

/// Wraps [child] with a minimal GoRouter so [context.go] does not throw.
Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(
    initialLocation: '/start-ritual',
    routes: [
      GoRoute(
        path: '/start-ritual',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: AppRoutes.questDetail,
        builder: (_, __) => const Scaffold(
          body: Text('Quest Detail'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(_stubAuth),
      ritualAudioPlayerProvider.overrideWithValue(_stubbedPlayer()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

MockAudioPlayer _stubbedPlayer() {
  final player = MockAudioPlayer();
  when(() => player.play(any())).thenAnswer((_) async {});
  return player;
}

void main() {
  setUpAll(() {
    // Stub AudioPlayer.play so it does nothing in tests.
    registerFallbackValue(UrlSource(''));
  });

  testWidgets('renders the error-builder rocket icon when Lottie asset missing',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(const StartRitualScreen(questId: 'q-1')),
    );
    await tester.pump();
    // The Lottie.asset errorBuilder shows a rocket icon when asset is absent.
    expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
  });

  testWidgets('tapping the screen skips ritual and shows quest detail',
      (tester) async {
    final mockPlayer = MockAudioPlayer();
    // ignore: unnecessary_lambdas
    when(
      () => mockPlayer.play(any()),
    ).thenAnswer((_) async => PlayerState.playing);

    final router = GoRouter(
      initialLocation: '/start-ritual',
      routes: [
        GoRoute(
          path: '/start-ritual',
          builder: (_, __) => const StartRitualScreen(questId: 'q-1'),
        ),
        GoRoute(
          path: AppRoutes.questDetail,
          builder: (_, __) => const Scaffold(
            body: Text('Quest Detail'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_stubAuth),
          ritualAudioPlayerProvider.overrideWithValue(mockPlayer),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump(); // Build first frame

    // Tap anywhere on the screen to skip.
    await tester.tapAt(const Offset(200, 200));
    await tester.pumpAndSettle();

    expect(find.text('Quest Detail'), findsOneWidget);
  });

  testWidgets('screen background is brand primary colour', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(const StartRitualScreen(questId: 'q-1')),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFF6C63FF));
  });
}
