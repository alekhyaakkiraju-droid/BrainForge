import 'package:brainforge/data/models/session_model.dart';
import 'package:brainforge/data/repositories/session_repository_impl.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/domain/repositories/session_repository.dart';
import 'package:brainforge/presentation/screens/fun_break/fun_break_provider.dart';
import 'package:brainforge/presentation/screens/fun_break/fun_break_screen.dart';
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

class _StubFunBreakNotifier extends FunBreakNotifier {
  _StubFunBreakNotifier(this._stubState);
  final FunBreakState _stubState;

  @override
  FunBreakState build() {
    ref.onDispose(() {});
    return _stubState;
  }

  @override
  void selectActivity(BreakActivity activity) {
    state = state.withActivity(activity);
  }
}

Widget _wrap(Widget child, {required FunBreakState funBreakState}) {
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
      funBreakProvider.overrideWith(
        () => _StubFunBreakNotifier(funBreakState),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

FunBreakState _makingBreakState({
  BreakActivity activity = BreakActivity.breathing,
  int remaining = kBreakDurationSeconds,
  bool canReturn = false,
}) =>
    FunBreakState(
      activity: activity,
      remainingSeconds: remaining,
      canReturn: canReturn,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(
      SessionModel(
        id: 'fallback',
        profileId: 'u1',
        startedAt: DateTime(2026),
        durationSeconds: 180,
        wasCompleted: true,
      ),
    );
  });

  testWidgets('shows "Time for a break!" header during countdown',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(),
      ),
    );

    expect(find.textContaining('Time for a break!'), findsOneWidget);
  });

  testWidgets('shows countdown timer text during break', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(),
      ),
    );

    expect(find.textContaining('Break ends in'), findsOneWidget);
  });

  testWidgets('shows "Great work!" when break is complete', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(
          remaining: 0,
          canReturn: true,
        ),
      ),
    );

    expect(find.textContaining('Great work!'), findsOneWidget);
  });

  testWidgets('shows both activity tabs', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(),
      ),
    );

    // 'Breathe' appears in both the tab label and the breathing-phase text,
    // so we check for at least one occurrence of each.
    expect(find.textContaining('Breathe'), findsAtLeast(1));
    expect(find.textContaining('Dance'), findsAtLeast(1));
  });

  testWidgets('breathing activity is shown by default', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(),
      ),
    );

    expect(find.textContaining('Breathe in'), findsOneWidget);
  });

  testWidgets('dance activity shows move prompt', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(activity: BreakActivity.dance),
      ),
    );

    expect(find.textContaining('Next move'), findsOneWidget);
  });

  testWidgets('return button is disabled during countdown', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Almost there…'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('return button is enabled after break completion',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(canReturn: true),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Back to Quests! 🚀'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('progress indicator is visible during countdown', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FunBreakScreen(),
        funBreakState: _makingBreakState(remaining: 120),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
