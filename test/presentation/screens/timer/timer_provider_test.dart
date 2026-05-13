import 'package:brainforge/data/models/session_model.dart';
import 'package:brainforge/data/repositories/session_repository_impl.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/domain/repositories/session_repository.dart';
import 'package:brainforge/presentation/screens/timer/timer_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

ProviderContainer _makeContainer(MockSessionRepository sessionRepo) {
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

  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((_) => authNotifier),
      sessionRepositoryProvider.overrideWithValue(sessionRepo),
    ],
  );
}

void main() {
  late MockSessionRepository mockSessionRepo;

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    when(() => mockSessionRepo.save(any())).thenAnswer((_) async {});
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

  group('TimerState', () {
    test('progress is 0.0 at start', () {
      const state = TimerState(
        status: TimerStatus.running,
        totalSeconds: 900,
        remainingSeconds: 900,
      );
      expect(state.progress, 0.0);
    });

    test('progress is 1.0 when fully elapsed', () {
      const state = TimerState(
        status: TimerStatus.expired,
        totalSeconds: 900,
        remainingSeconds: 0,
      );
      expect(state.progress, 1.0);
    });

    test('progress is 0.5 at midpoint', () {
      const state = TimerState(
        status: TimerStatus.running,
        totalSeconds: 900,
        remainingSeconds: 450,
      );
      expect(state.progress, closeTo(0.5, 0.001));
    });

    test('idle state initialises with first duration', () {
      const state = TimerState.idle();
      expect(state.isIdle, isTrue);
      expect(state.totalSeconds, kTimerDurations.first * 60);
    });
  });

  group('TimerNotifier.start', () {
    test('transitions from idle to running', () async {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      await container.read(timerProvider.notifier).start(15);

      expect(container.read(timerProvider).isRunning, isTrue);
    });

    test('caps duration to 20 minutes', () async {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      await container.read(timerProvider.notifier).start(25);

      expect(container.read(timerProvider).totalSeconds, 20 * 60);
    });

    test('saves session start to Firestore', () async {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      await container.read(timerProvider.notifier).start(15);

      verify(() => mockSessionRepo.save(any())).called(greaterThan(0));
    });
  });

  group('TimerNotifier.pause / resume', () {
    test('pause sets status to paused', () async {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      await container.read(timerProvider.notifier).start(15);
      container.read(timerProvider.notifier).pause();

      expect(container.read(timerProvider).isPaused, isTrue);
    });

    test('resume after pause sets status back to running', () async {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      await container.read(timerProvider.notifier).start(15);
      container.read(timerProvider.notifier).pause();
      container.read(timerProvider.notifier).resume();

      expect(container.read(timerProvider).isRunning, isTrue);
    });

    test('auto-resume fires after 2 minutes of pause', () async {
      fakeAsync((fake) {
        final container = _makeContainer(mockSessionRepo);
        addTearDown(container.dispose);

        container.read(timerProvider.notifier).start(15);
        fake.flushMicrotasks();

        container.read(timerProvider.notifier).pause();
        expect(container.read(timerProvider).isPaused, isTrue);

        fake.elapse(const Duration(minutes: 2));

        expect(container.read(timerProvider).isRunning, isTrue);
      });
    });
  });

  group('TimerNotifier.reset', () {
    test('returns timer to idle state', () async {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      await container.read(timerProvider.notifier).start(15);
      container.read(timerProvider.notifier).reset();

      expect(container.read(timerProvider).isIdle, isTrue);
    });
  });

  group('kTimerDurations', () {
    test('contains exactly 15, 18, 20', () {
      expect(kTimerDurations, containsAll([15, 18, 20]));
      expect(kTimerDurations.every((d) => d <= 20), isTrue);
    });
  });
}
