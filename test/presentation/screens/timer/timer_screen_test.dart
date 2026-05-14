import 'package:brainforge/data/models/session_model.dart';
import 'package:brainforge/data/repositories/session_repository_impl.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/domain/repositories/session_repository.dart';
import 'package:brainforge/presentation/screens/timer/timer_provider.dart';
import 'package:brainforge/presentation/screens/timer/timer_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

Widget _wrap(Widget child, {TimerState? timerState}) {
  final mockAuth = MockFirebaseAuth();
  final mockFirestore = MockFirebaseFirestore();
  // ignore: unnecessary_lambdas
  when(() => mockAuth.authStateChanges())
      .thenAnswer((_) => const Stream.empty());
  final authNotifier = AuthStateNotifier(mockAuth, mockFirestore)
    ..state = const AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.student,
      uid: 'u1',
    );

  final mockSessionRepo = MockSessionRepository();
  when(() => mockSessionRepo.save(any())).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => authNotifier),
      sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
      if (timerState != null)
        timerProvider.overrideWith(
          () => _StubTimerNotifier(timerState),
        ),
    ],
    child: MaterialApp(home: child),
  );
}

class _StubTimerNotifier extends TimerNotifier {
  _StubTimerNotifier(this._initial);
  final TimerState _initial;

  @override
  TimerState build() {
    ref.onDispose(() {});
    return _initial;
  }

  @override
  Future<void> start(int _) async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      SessionModel(
        id: 'fallback',
        profileId: 'u1',
        startedAt: DateTime(2026),
        durationSeconds: 900,
        wasCompleted: false,
      ),
    );
  });

  testWidgets('shows duration picker when timer is idle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TimerScreen(),
        timerState: const TimerState.idle(),
      ),
    );

    expect(find.text('How long will you focus?'), findsOneWidget);
    for (final d in kTimerDurations) {
      expect(find.text('$d'), findsOneWidget);
    }
  });

  testWidgets('shows all three duration chips', (tester) async {
    await tester.pumpWidget(
      _wrap(const TimerScreen(), timerState: const TimerState.idle()),
    );

    expect(find.text('15'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('shows progress ring when timer is running', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TimerScreen(),
        timerState: const TimerState(
          status: TimerStatus.running,
          totalSeconds: 900,
          remainingSeconds: 450,
        ),
      ),
    );

    expect(find.textContaining('remaining'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });

  testWidgets('shows paused banner when timer is paused', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TimerScreen(),
        timerState: const TimerState(
          status: TimerStatus.paused,
          totalSeconds: 900,
          remainingSeconds: 400,
        ),
      ),
    );

    expect(find.textContaining('Paused'), findsOneWidget);
    expect(find.textContaining('paused'), findsWidgets);
  });

  testWidgets('displays "Focus Session" AppBar title', (tester) async {
    await tester.pumpWidget(
      _wrap(const TimerScreen(), timerState: const TimerState.idle()),
    );

    expect(find.text('Focus Session'), findsOneWidget);
  });

  testWidgets('start button is present on idle screen', (tester) async {
    await tester.pumpWidget(
      _wrap(const TimerScreen(), timerState: const TimerState.idle()),
    );

    expect(
      find.widgetWithText(ElevatedButton, 'Start 15 min session  🚀'),
      findsOneWidget,
    );
  });

  testWidgets('start button text updates for selected duration',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const TimerScreen(), timerState: const TimerState.idle()),
    );

    expect(find.textContaining('Start 15 min session'), findsOneWidget);
  });

  testWidgets('running timer shows pause and stop controls', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TimerScreen(),
        timerState: const TimerState(
          status: TimerStatus.running,
          totalSeconds: 900,
          remainingSeconds: 500,
        ),
      ),
    );

    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
  });

  testWidgets('paused timer shows resume control', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TimerScreen(),
        timerState: const TimerState(
          status: TimerStatus.paused,
          totalSeconds: 900,
          remainingSeconds: 500,
        ),
      ),
    );

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
  });
}
